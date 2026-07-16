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
	@override late final _TranslationsAppFr app = _TranslationsAppFr._(_root);
	@override late final _TranslationsAuthFr auth = _TranslationsAuthFr._(_root);
	@override late final _TranslationsCommonFr common = _TranslationsCommonFr._(_root);
	@override late final _TranslationsScreensFr screens = _TranslationsScreensFr._(_root);
	@override late final _TranslationsUpdateFr update = _TranslationsUpdateFr._(_root);
	@override late final _TranslationsSettingsFr settings = _TranslationsSettingsFr._(_root);
	@override late final _TranslationsSearchFr search = _TranslationsSearchFr._(_root);
	@override late final _TranslationsHotkeysFr hotkeys = _TranslationsHotkeysFr._(_root);
	@override late final _TranslationsFileInfoFr fileInfo = _TranslationsFileInfoFr._(_root);
	@override late final _TranslationsMediaMenuFr mediaMenu = _TranslationsMediaMenuFr._(_root);
	@override late final _TranslationsRateSheetFr rateSheet = _TranslationsRateSheetFr._(_root);
	@override late final _TranslationsAccessibilityFr accessibility = _TranslationsAccessibilityFr._(_root);
	@override late final _TranslationsTooltipsFr tooltips = _TranslationsTooltipsFr._(_root);
	@override late final _TranslationsVideoControlsFr videoControls = _TranslationsVideoControlsFr._(_root);
	@override late final _TranslationsMessagesFr messages = _TranslationsMessagesFr._(_root);
	@override late final _TranslationsSubtitlingStylingFr subtitlingStyling = _TranslationsSubtitlingStylingFr._(_root);
	@override late final _TranslationsMpvConfigFr mpvConfig = _TranslationsMpvConfigFr._(_root);
	@override late final _TranslationsDialogFr dialog = _TranslationsDialogFr._(_root);
	@override late final _TranslationsProfilesFr profiles = _TranslationsProfilesFr._(_root);
	@override late final _TranslationsConnectionsFr connections = _TranslationsConnectionsFr._(_root);
	@override late final _TranslationsDiscoverFr discover = _TranslationsDiscoverFr._(_root);
	@override late final _TranslationsErrorsFr errors = _TranslationsErrorsFr._(_root);
	@override late final _TranslationsLibrariesFr libraries = _TranslationsLibrariesFr._(_root);
	@override late final _TranslationsAboutFr about = _TranslationsAboutFr._(_root);
	@override late final _TranslationsServerSelectionFr serverSelection = _TranslationsServerSelectionFr._(_root);
	@override late final _TranslationsHubDetailFr hubDetail = _TranslationsHubDetailFr._(_root);
	@override late final _TranslationsLogsFr logs = _TranslationsLogsFr._(_root);
	@override late final _TranslationsLicensesFr licenses = _TranslationsLicensesFr._(_root);
	@override late final _TranslationsNavigationFr navigation = _TranslationsNavigationFr._(_root);
	@override late final _TranslationsExploreFr explore = _TranslationsExploreFr._(_root);
	@override late final _TranslationsLiveTvFr liveTv = _TranslationsLiveTvFr._(_root);
	@override late final _TranslationsCollectionsFr collections = _TranslationsCollectionsFr._(_root);
	@override late final _TranslationsPlaylistsFr playlists = _TranslationsPlaylistsFr._(_root);
	@override late final _TranslationsMusicFr music = _TranslationsMusicFr._(_root);
	@override late final _TranslationsWatchTogetherFr watchTogether = _TranslationsWatchTogetherFr._(_root);
	@override late final _TranslationsDownloadsFr downloads = _TranslationsDownloadsFr._(_root);
	@override late final _TranslationsShadersFr shaders = _TranslationsShadersFr._(_root);
	@override late final _TranslationsCompanionRemoteFr companionRemote = _TranslationsCompanionRemoteFr._(_root);
	@override late final _TranslationsVideoSettingsFr videoSettings = _TranslationsVideoSettingsFr._(_root);
	@override late final _TranslationsPerformanceOverlayFr performanceOverlay = _TranslationsPerformanceOverlayFr._(_root);
	@override late final _TranslationsExternalPlayerFr externalPlayer = _TranslationsExternalPlayerFr._(_root);
	@override late final _TranslationsMetadataEditFr metadataEdit = _TranslationsMetadataEditFr._(_root);
	@override late final _TranslationsMatchScreenFr matchScreen = _TranslationsMatchScreenFr._(_root);
	@override late final _TranslationsServerTasksFr serverTasks = _TranslationsServerTasksFr._(_root);
	@override late final _TranslationsTraktFr trakt = _TranslationsTraktFr._(_root);
	@override late final _TranslationsSeerrFr seerr = _TranslationsSeerrFr._(_root);
	@override late final _TranslationsServicesFr services = _TranslationsServicesFr._(_root);
	@override late final _TranslationsAddServerFr addServer = _TranslationsAddServerFr._(_root);
}

// Path: app
class _TranslationsAppFr extends TranslationsAppEn {
	_TranslationsAppFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
}

// Path: auth
class _TranslationsAuthFr extends TranslationsAuthEn {
	_TranslationsAuthFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'S\'inscrire avec Plex';
	@override String get showQRCode => 'Afficher le QR Code';
	@override String get authenticate => 'S\'authentifier';
	@override String get authenticationTimeout => 'Délai d\'authentification expiré. Veuillez réessayer.';
	@override String get scanQRToSignIn => 'Scannez ce QR code pour vous connecter';
	@override String get waitingForAuth => 'En attente d\'authentification...\nConnectez-vous depuis votre navigateur.';
	@override String get useBrowser => 'Utiliser le navigateur';
	@override String get or => 'ou';
	@override String get connectToJellyfin => 'Se connecter à Jellyfin';
	@override String get useQuickConnect => 'Utiliser Quick Connect';
	@override String get quickConnectInstructions => 'Ouvrez Quick Connect dans Jellyfin et saisissez ce code.';
	@override String get quickConnectWaiting => 'En attente d\'approbation…';
	@override String get quickConnectCancel => 'Annuler';
	@override String get quickConnectExpired => 'Quick Connect a expiré. Réessayez.';
}

// Path: common
class _TranslationsCommonFr extends TranslationsCommonEn {
	_TranslationsCommonFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Annuler';
	@override String get save => 'Sauvegarder';
	@override String get close => 'Fermer';
	@override String get clear => 'Nettoyer';
	@override String get reset => 'Réinitialiser';
	@override String get later => 'Plus tard';
	@override String get submit => 'Soumettre';
	@override String get confirm => 'Confirmer';
	@override String get retry => 'Réessayer';
	@override String get logout => 'Se déconnecter';
	@override String get unknown => 'Inconnu';
	@override String get refresh => 'Rafraichir';
	@override String get yes => 'Oui';
	@override String get no => 'Non';
	@override String get delete => 'Supprimer';
	@override String get edit => 'Modifier';
	@override String get shuffle => 'Mélanger';
	@override String get addTo => 'Ajouter à...';
	@override String get createNew => 'Créer';
	@override String get connect => 'Connecter';
	@override String get disconnect => 'Déconnecter';
	@override String get play => 'Lire';
	@override String get pause => 'Pause';
	@override String get resume => 'Reprendre';
	@override String get error => 'Erreur';
	@override String get search => 'Recherche';
	@override String get home => 'Accueil';
	@override String get back => 'Retour';
	@override String get settings => 'Réglages';
	@override String get mute => 'Muet';
	@override String get ok => 'OK';
	@override String get off => 'Désactivé';
	@override String seasonNumber({required Object number}) => 'Saison ${number}';
	@override String episodeNumberTitle({required Object number, required Object title}) => 'Épisode ${number} - ${title}';
	@override String chapterNumber({required Object number}) => 'Chapitre ${number}';
	@override String get reconnect => 'Reconnecter';
	@override String get viewAll => 'Tout afficher';
	@override String get checkingNetwork => 'Vérification du réseau...';
	@override String get loadingServers => 'Chargement des serveurs...';
	@override String get connectingToServers => 'Connexion aux serveurs...';
	@override String get startingOfflineMode => 'Démarrage en mode hors-ligne...';
	@override String get loading => 'Chargement...';
	@override String get fullscreen => 'Plein écran';
	@override String get exitFullscreen => 'Quitter le plein écran';
	@override String get pressBackAgainToExit => 'Appuyez à nouveau sur retour pour quitter';
}

// Path: screens
class _TranslationsScreensFr extends TranslationsScreensEn {
	_TranslationsScreensFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Licences';
	@override String get switchProfile => 'Changer de profil';
	@override String get subtitleStyling => 'Configuration des sous-titres';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Logs';
}

// Path: update
class _TranslationsUpdateFr extends TranslationsUpdateEn {
	_TranslationsUpdateFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get available => 'Mise à jour disponible';
	@override String versionAvailable({required Object version}) => 'Version ${version} disponible';
	@override String currentVersion({required Object version}) => 'Installé: ${version}';
	@override String get skipVersion => 'Ignorer cette version';
	@override String get viewRelease => 'Voir la Release';
	@override String get latestVersion => 'Vous utilisez la dernière version';
	@override String get checkFailed => 'Échec de la vérification des mises à jour';
}

// Path: settings
class _TranslationsSettingsFr extends TranslationsSettingsEn {
	_TranslationsSettingsFr._(TranslationsFr root) : this._root = root, super.internal(root);

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
	@override String get episodePosterMode => 'Style du Poster d\'épisode';
	@override String get seriesPoster => 'Poster de série';
	@override String get seasonPoster => 'Poster de saison';
	@override String get episodeThumbnail => 'Miniature';
	@override String get showHeroSectionDescription => 'Afficher le carrousel de contenu en vedette sur l\'écran d\'accueil';
	@override String get secondsLabel => 'Secondes';
	@override String get minutesLabel => 'Minutes';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => 'Entrez la durée (${min}-${max})';
	@override String get systemTheme => 'Système';
	@override String get lightTheme => 'Clair';
	@override String get darkTheme => 'Sombre';
	@override String get oledTheme => 'OLED';
	@override String get libraryDensity => 'Densité des bibliothèques';
	@override String get compact => 'Compact';
	@override String get comfortable => 'Confortable';
	@override String get viewMode => 'Mode d\'affichage';
	@override String get gridView => 'Grille';
	@override String get listView => 'Liste';
	@override String get showHeroSection => 'Afficher la section Hero';
	@override String get continueWatchingAction => 'Action Continuer à regarder';
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
	@override String get showUnwatchedCount => 'Afficher le nombre non visionné';
	@override String get showUnwatchedCountDescription => 'Afficher le nombre d\'épisodes non visionnés pour les séries et saisons';
	@override String get showEpisodeNumberOnCards => 'Afficher le numéro d\'épisode sur les cartes';
	@override String get showEpisodeNumberOnCardsDescription => 'Afficher la saison et l\'épisode sur les cartes d\'épisode';
	@override String get showSeasonPostersOnTabs => 'Afficher les posters de saison sur les onglets';
	@override String get showSeasonPostersOnTabsDescription => 'Afficher l\'affiche de chaque saison au-dessus de son onglet';
	@override String get tvFullCardLayout => 'Cartes TV pleines';
	@override String get tvFullCardLayoutDescription => 'Utiliser des cartes TV avec image seule et noms des acteurs superposés';
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
	@override String get hardwareDecodingDescription => 'Utilisez l\'accélération matérielle lorsqu\'elle est disponible.';
	@override String get bufferSize => 'Taille du Buffer';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get bufferSizeAuto => 'Auto (Recommandé)';
	@override String bufferSizeWarning({required Object heap, required Object size}) => '${heap}MB de mémoire disponible. Un tampon de ${size}MB peut affecter la lecture.';
	@override String get defaultQualityTitle => 'Qualité par défaut';
	@override String get musicQualityTitle => 'Qualité de la musique';
	@override String get subtitleStyling => 'Stylisation des sous-titres';
	@override String get subtitleStylingDescription => 'Personnaliser l\'apparence des sous-titres';
	@override String get smallSkipDuration => 'Durée du petit saut';
	@override String get largeSkipDuration => 'Durée du grand saut';
	@override String get rewindOnResume => 'Rembobiner à la reprise';
	@override String secondsUnit({required Object seconds}) => '${seconds} secondes';
	@override String get defaultSleepTimer => 'Minuterie de mise en veille par défaut';
	@override String minutesUnit({required Object minutes}) => '${minutes} minutes';
	@override String get rememberTrackSelections => 'Mémoriser les sélections de pistes par émission/film';
	@override String get rememberTrackSelectionsDescription => 'Mémoriser les choix audio et sous-titres par titre';
	@override String get showChapterMarkersOnTimeline => 'Afficher les marqueurs de chapitres sur la barre de lecture';
	@override String get showChapterMarkersOnTimelineDescription => 'Segmenter la barre de lecture aux limites des chapitres';
	@override String get clickVideoTogglesPlayback => 'Cliquez sur la vidéo pour basculer entre lecture et pause.';
	@override String get clickVideoTogglesPlaybackDescription => 'Cliquer sur la vidéo pour lire/mettre en pause au lieu d\'afficher les contrôles.';
	@override String get videoPlayerControls => 'Commandes du lecteur vidéo';
	@override String get keyboardShortcuts => 'Raccourcis clavier';
	@override String get keyboardShortcutsDescription => 'Personnaliser les raccourcis clavier';
	@override String get videoPlayerNavigation => 'Navigation dans le lecteur vidéo';
	@override String get videoPlayerNavigationDescription => 'Utilisez les touches fléchées pour naviguer dans les commandes du lecteur vidéo.';
	@override String get watchTogetherRelay => 'Relais Regarder Ensemble';
	@override String get watchTogetherRelayDescription => 'Définir un relay personnalisé. Tout le monde doit utiliser le même serveur.';
	@override String get watchTogetherRelayHint => 'https://mon-relais.exemple.fr';
	@override String get crashReporting => 'Rapports de plantage';
	@override String get crashReportingDescription => 'Envoyer des rapports de plantage pour améliorer l\'application';
	@override String get debugLogging => 'Journalisation de débogage';
	@override String get debugLoggingDescription => 'Activer la journalisation détaillée pour le dépannage';
	@override String get viewLogs => 'Voir les logs';
	@override String get viewLogsDescription => 'Voir les logs d\'application';
	@override String get clearCache => 'Vider le cache';
	@override String get clearCacheDescription => 'Effacer les images et données en cache. Le contenu peut charger plus lentement.';
	@override String get clearCacheSuccess => 'Cache effacé avec succès';
	@override String get resetSettings => 'Réinitialiser les paramètres';
	@override String get resetSettingsDescription => 'Restaurer les paramètres par défaut. Action irréversible.';
	@override String get resetSettingsSuccess => 'Réinitialisation des paramètres réussie';
	@override String get backup => 'Sauvegarde';
	@override String get exportSettings => 'Exporter les paramètres';
	@override String get exportSettingsDescription => 'Enregistrer vos préférences dans un fichier';
	@override String get exportSettingsSuccess => 'Paramètres exportés';
	@override String get exportSettingsFailed => 'Impossible d\'exporter les paramètres';
	@override String get importSettings => 'Importer les paramètres';
	@override String get importSettingsDescription => 'Restaurer les préférences depuis un fichier';
	@override String get importSettingsConfirm => 'Cela remplacera vos paramètres actuels. Continuer ?';
	@override String get importSettingsSuccess => 'Paramètres importés';
	@override String get importSettingsFailed => 'Impossible d\'importer les paramètres';
	@override String get importSettingsInvalidFile => 'Ce fichier n\'est pas un export Plezy valide';
	@override String get importSettingsNoUser => 'Connectez-vous avant d\'importer les paramètres';
	@override String get shortcutsReset => 'Raccourcis réinitialisés aux valeurs par défaut';
	@override String get about => 'À propos';
	@override String get aboutDescription => 'Informations sur l\'application et licences';
	@override String get updates => 'Mises à jour';
	@override String get updateAvailable => 'Mise à jour disponible';
	@override String get checkForUpdates => 'Vérifier les mises à jour';
	@override String get autoCheckUpdatesOnStartup => 'Vérifier automatiquement les mises à jour au démarrage';
	@override String get autoCheckUpdatesOnStartupDescription => 'Notifier au lancement quand une mise à jour est disponible';
	@override String get validationErrorEnterNumber => 'Veuillez saisir un numéro valide';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'La durée doit être comprise entre ${min} et ${max} ${unit}';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Raccourci déjà attribué à ${action}';
	@override String shortcutUpdated({required Object action}) => 'Raccourci mis à jour pour ${action}';
	@override String get autoSkip => 'Skip automatique';
	@override String get autoSkipIntro => 'Skip automatique de l\'introduction';
	@override String get autoSkipIntroDescription => 'Skipper automatiquement l\'introduction après quelques secondes';
	@override String get autoSkipCredits => 'Skip automatique des crédits';
	@override String get autoSkipCreditsDescription => 'Passer les crédits et passer à l\'épisode suivant automatiquement';
	@override String get forceSkipMarkerFallback => 'Forcer les marqueurs de repli';
	@override String get forceSkipMarkerFallbackDescription => 'Utiliser les motifs de titres de chapitres même si Plex a des marqueurs';
	@override String get autoSkipDelay => 'Délai avant skip automatique';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Attendre ${seconds} secondes avant l\'auto-skip';
	@override String get introPattern => 'Modèle de marqueur d\'intro';
	@override String get introPatternDescription => 'Expression régulière pour reconnaître les marqueurs d\'intro dans les titres de chapitres';
	@override String get creditsPattern => 'Modèle de marqueur de générique';
	@override String get creditsPatternDescription => 'Expression régulière pour reconnaître les marqueurs de générique dans les titres de chapitres';
	@override String get invalidRegex => 'Expression régulière invalide';
	@override String get regex => 'Expression régulière';
	@override String get downloads => 'Téléchargement';
	@override String get downloadLocationDescription => 'Choisissez où stocker le contenu téléchargé';
	@override String get downloadLocationDefault => 'Par défaut (stockage de l\'application)';
	@override String get downloadLocationCustom => 'Emplacement personnalisé';
	@override String get selectFolder => 'Sélectionner un dossier';
	@override String get resetToDefault => 'Réinitialiser les paramètres par défaut';
	@override String currentPath({required Object path}) => 'Actuel: ${path}';
	@override String get downloadLocationChanged => 'Emplacement de téléchargement modifié';
	@override String get downloadLocationReset => 'Emplacement de téléchargement réinitialisé à la valeur par défaut';
	@override String get downloadLocationInvalid => 'Le dossier sélectionné n\'est pas accessible en écriture';
	@override String get downloadLocationSelectError => 'Échec de la sélection du dossier';
	@override String get downloadOnWifiOnly => 'Télécharger uniquement via WiFi';
	@override String get downloadOnWifiOnlyDescription => 'Empêcher les téléchargements lorsque vous utilisez les données cellulaires';
	@override String get autoRemoveWatchedDownloads => 'Supprimer automatiquement les téléchargements vus';
	@override String get autoRemoveWatchedDownloadsDescription => 'Supprimer automatiquement les téléchargements vus';
	@override String get cellularDownloadBlocked => 'Les téléchargements sont bloqués sur réseau mobile. Utilisez le WiFi ou modifiez le réglage.';
	@override String get maxVolume => 'Volume maximal';
	@override String get maxVolumeDescription => 'Autoriser l\'augmentation du volume au-delà de 100 % pour les médias silencieux';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Montrez ce que vous regardez sur Discord';
	@override String get services => 'Services';
	@override String get servicesDescription => 'Connectez Trakt, MyAnimeList, Seerr et plus';
	@override String get manageLibrariesDescription => 'Réorganiser et masquer les bibliothèques';
	@override String get companionRemoteServer => 'Serveur de télécommande';
	@override String get companionRemoteServerDescription => 'Autoriser les appareils mobiles de votre réseau à contrôler cette application';
	@override String get autoPip => 'Image dans l\'image automatique';
	@override String get autoPipDescription => 'Passer en picture-in-picture en quittant pendant la lecture';
	@override String get matchContentFrameRate => 'Fréquence d\'images du contenu correspondant';
	@override String get matchContentFrameRateDescription => 'Adapter la fréquence d\'affichage au contenu vidéo';
	@override String get matchRefreshRate => 'Adapter la fréquence de rafraîchissement';
	@override String get matchRefreshRateDescription => 'Adapter la fréquence d\'affichage en plein écran';
	@override String get matchDynamicRange => 'Adapter la plage dynamique';
	@override String get matchDynamicRangeDescription => 'Activer HDR pour le contenu HDR, puis revenir en SDR';
	@override String get displaySwitchDelay => 'Délai de changement d\'affichage';
	@override String get tunneledPlayback => 'Lecture tunnelée';
	@override String get tunneledPlaybackDescription => 'Utiliser le tunneling vidéo. Désactivez si la lecture HDR affiche un écran noir.';
	@override String get audioPassthrough => 'Audio Pass-Through';
	@override String get audioPassthroughDescription => 'Envoyez l\'audio Dolby/DTS vers votre ampli ou téléviseur sans réencodage, en conservant le son surround. Désactivez si vous n\'avez aucun son.';
	@override String get audioPassthroughDescriptionAppleTv => 'Transmet le Dolby Digital Plus (y compris Atmos) au système en bitstream. Le DTS et le TrueHD restent lus en PCM multicanal. De brèves coupures audio peuvent survenir lors des sauts.';
	@override String get audioDownmix => 'Downmix en stéréo';
	@override String get audioDownmixDescription => 'Réduit le son surround à deux canaux pour les enceintes stéréo ou le casque';
	@override String get downmixCenterBoost => 'Renforcement du canal central';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'Renforcement (dB)';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => 'Normaliser le volume lors du downmix';
	@override String get audioDownmixNormalizeDescription => 'Atténue le mixage pour éviter la saturation. Désactivez pour conserver le volume d\'origine (risque de distorsion sur les scènes fortes).';
	@override String get atmosDiagnostics => 'Test de sortie Atmos';
	@override String get atmosDiagnosticsDescription => 'Diagnostiquer la sortie Dolby Atmos en lisant des signaux de test via le lecteur système';
	@override String get atmosTestHlsAtmos => 'Flux Atmos d\'Apple';
	@override String get atmosTestHlsAtmosDescription => 'Flux Dolby Atmos réputé fiable. L\'ampli devrait afficher Dolby Atmos.';
	@override String get atmosTestHlsControl => 'Flux surround d\'Apple';
	@override String get atmosTestHlsControlDescription => 'Flux témoin sans Atmos. L\'ampli devrait afficher du surround sans Atmos.';
	@override String get atmosTestRawStream => 'Flux EAC3 brut';
	@override String get atmosTestRawStreamDescription => 'Diffuse le fichier de test exactement comme la lecture Atmos du lecteur. Nécessite l\'URL du fichier de test.';
	@override String get atmosTestRawFile => 'Fichier EAC3 brut';
	@override String get atmosTestRawFileDescription => 'Lit le fichier de test avec une longueur connue. Nécessite l\'URL du fichier de test.';
	@override String get atmosTestStop => 'Arrêter le test';
	@override String get atmosTestUrl => 'URL du fichier de test';
	@override String get atmosTestUrlDescription => 'URL HTTP d\'un fichier .ec3 Dolby Atmos brut (extrait par ex. avec ffmpeg)';
	@override String get atmosTestUrlMissing => 'Définissez d\'abord l\'URL du fichier de test';
	@override String get atmosTestStatus => 'État';
	@override String get dvConversionMode => 'Conversion Dolby Vision';
	@override String get dvConversionModeDescription => 'Choisissez comment ExoPlayer gère les fichiers Dolby Vision Profile 7.';
	@override String get dvConversionAuto => 'Auto';
	@override String get dvConversionNative => 'Natif / désactivé';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Utiliser la détection des capacités de l’appareil et le comportement de repli normal';
	@override String get dvConversionNativeDescription => 'Forcer le DV7 natif et bloquer la nouvelle tentative de conversion DV';
	@override String get dvConversionDv81Description => 'Forcer la conversion RPU intégrée vers Dolby Vision profil 8.1';
	@override String get dvConversionHevcStripDescription => 'Supprimer les couches RPU/EL Dolby Vision et présenter du HEVC simple';
	@override String get requireProfileSelectionOnOpen => 'Demander le profil à l\'ouverture';
	@override String get requireProfileSelectionOnOpenDescription => 'Afficher la sélection de profil à chaque ouverture de l\'application';
	@override String get forceTvMode => 'Forcer le mode TV';
	@override String get forceTvModeDescription => 'Forcer l\'interface TV. Pour appareils non détectés automatiquement. Redémarrage requis.';
	@override String get startInFullscreen => 'Démarrer en plein écran';
	@override String get startInFullscreenDescription => 'Ouvrir Plezy en mode plein écran au lancement';
	@override String get exitFullscreenOnPlayerClose => 'Quitter le plein écran à la fermeture du lecteur';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Quitter automatiquement le plein écran lors de la fermeture du lecteur vidéo';
	@override String get autoHidePerformanceOverlay => 'Masquer auto. superposition performances';
	@override String get autoHidePerformanceOverlayDescription => 'Faire apparaître/disparaître la superposition avec les contrôles de lecture';
	@override String get showNavBarLabels => 'Afficher les libellés de la barre de navigation';
	@override String get showNavBarLabelsDescription => 'Afficher les libellés sous les icônes de la barre de navigation';
	@override String get startupSection => 'Section de démarrage';
	@override String get liveTvDefaultFavorites => 'Chaînes favorites par défaut';
	@override String get liveTvDefaultFavoritesDescription => 'Afficher uniquement les chaînes favorites à l\'ouverture de la TV en direct';
	@override String get display => 'Affichage';
	@override String get homeScreen => 'Écran d\'accueil';
	@override String get navigation => 'Navigation';
	@override String get window => 'Fenêtre';
	@override String get content => 'Contenu';
	@override String get player => 'Lecteur';
	@override String get subtitlesAndConfig => 'Sous-titres et configuration';
	@override String get seekAndTiming => 'Recherche et minutage';
	@override String get behavior => 'Comportement';
}

// Path: search
class _TranslationsSearchFr extends TranslationsSearchEn {
	_TranslationsSearchFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Rechercher des films, des séries, de la musique...';
	@override String get tryDifferentTerm => 'Essayez un autre terme de recherche';
	@override String get searchYourMedia => 'Rechercher dans vos médias';
	@override String get enterTitleActorOrKeyword => 'Entrez un titre, un acteur ou un mot-clé';
}

// Path: hotkeys
class _TranslationsHotkeysFr extends TranslationsHotkeysEn {
	_TranslationsHotkeysFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Définir un raccourci pour ${actionName}';
	@override String get clearShortcut => 'Effacer le raccourci';
	@override String get noShortcutSet => 'Aucun raccourci défini';
	@override String get currentShortcut => 'Raccourci actuel :';
	@override String get pressToRecord => 'Sélectionner pour enregistrer un raccourci';
	@override String get recordingShortcut => 'Appuyez maintenant sur le raccourci';
	@override late final _TranslationsHotkeysActionsFr actions = _TranslationsHotkeysActionsFr._(_root);
}

// Path: fileInfo
class _TranslationsFileInfoFr extends TranslationsFileInfoEn {
	_TranslationsFileInfoFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Informations sur le fichier';
	@override String get video => 'Vidéo';
	@override String get audio => 'Audio';
	@override String get file => 'Fichier';
	@override String get advanced => 'Avancé';
	@override String get codec => 'Codec';
	@override String get resolution => 'Résolution';
	@override String get bitrate => 'Bitrate';
	@override String get frameRate => 'Fréquence d\'images';
	@override String get aspectRatio => 'Format d\'image';
	@override String get profile => 'Profil';
	@override String get bitDepth => 'Profondeur de bits';
	@override String get colorSpace => 'Espace colorimétrique';
	@override String get colorRange => 'Gamme de couleurs';
	@override String get colorPrimaries => 'Couleurs primaires';
	@override String get chromaSubsampling => 'Sous-échantillonnage chromatique';
	@override String get channels => 'Canaux';
	@override String get subtitles => 'Sous-titres';
	@override String get overallBitrate => 'Débit global';
	@override String get path => 'Chemin';
	@override String get size => 'Taille';
	@override String get container => 'Conteneur';
	@override String get duration => 'Durée';
	@override String get optimizedForStreaming => 'Optimisé pour le streaming';
	@override String get has64bitOffsets => 'Décalages 64 bits';
}

// Path: mediaMenu
class _TranslationsMediaMenuFr extends TranslationsMediaMenuEn {
	_TranslationsMediaMenuFr._(TranslationsFr root) : this._root = root, super.internal(root);

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
	@override String get deleteFromServer => 'Supprimer du serveur';
	@override String get confirmDelete => 'Supprimer ce média et ses fichiers de votre serveur ?';
	@override String get deleteMultipleWarning => 'Cela inclut tous les épisodes et leurs fichiers.';
	@override String get mediaDeletedSuccessfully => 'Élément média supprimé avec succès';
	@override String get mediaFailedToDelete => 'Échec de la suppression de l\'élément média';
	@override String get rate => 'Noter';
	@override String get playFromBeginning => 'Lire depuis le début';
	@override String get playVersion => 'Lire la version...';
}

// Path: rateSheet
class _TranslationsRateSheetFr extends TranslationsRateSheetEn {
	_TranslationsRateSheetFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Noter';
	@override String get server => 'Serveur';
	@override String get favorite => 'Favori';
	@override String get favorited => 'Ajouté aux favoris';
	@override String get saved => 'Enregistré';
	@override String get notAvailable => 'Aucune correspondance trouvée';
	@override String get noConnectedServices => 'Connectez un service dans les Réglages pour noter ici.';
}

// Path: accessibility
class _TranslationsAccessibilityFr extends TranslationsAccessibilityEn {
	_TranslationsAccessibilityFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, film';
	@override String mediaCardShow({required Object title}) => '${title}, show TV';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'visionné';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent} pourcentage visionné';
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
}

// Path: tooltips
class _TranslationsTooltipsFr extends TranslationsTooltipsEn {
	_TranslationsTooltipsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Lecture aléatoire';
	@override String get playTrailer => 'Lire la bande-annonce';
	@override String get markAsWatched => 'Marqué comme vu';
	@override String get markAsUnwatched => 'Marqué comme non vu';
}

// Path: videoControls
class _TranslationsVideoControlsFr extends TranslationsVideoControlsEn {
	_TranslationsVideoControlsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Audio';
	@override String get subtitlesLabel => 'Sous-titres';
	@override String get resetToZero => 'Réinitialiser à 0ms';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String minusTime({required Object amount, required Object unit}) => '-${amount}${unit}';
	@override String playsLater({required Object label}) => '${label} lire plus tard';
	@override String playsEarlier({required Object label}) => '${label} lire plus tôt';
	@override String get noOffset => 'Pas de décalage';
	@override String get letterbox => 'Boîte aux lettres';
	@override String get fillScreen => 'Remplir l\'écran';
	@override String get stretch => 'Etirer';
	@override String get lockRotation => 'Verrouillage de la rotation';
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
	@override String get autoPlayNext => 'Lecture automatique suivante';
	@override String get playNext => 'Lire l\'épisode suivant';
	@override String get playButton => 'Lire';
	@override String get pauseButton => 'Pause';
	@override String seekBackwardButton({required Object seconds}) => 'Reculer de ${seconds} secondes';
	@override String seekForwardButton({required Object seconds}) => 'Avancer de ${seconds} secondes';
	@override String get previousButton => 'Épisode précédent';
	@override String get nextButton => 'Épisode suivant';
	@override String get previousChapterButton => 'Chapitre précédent';
	@override String get nextChapterButton => 'Chapitre suivant';
	@override String get muteButton => 'Mute';
	@override String get unmuteButton => 'Dé-mute';
	@override String get settingsButton => 'Paramètres de lecture';
	@override String get tracksButton => 'Audio et sous-titres';
	@override String get chaptersButton => 'Chapitres';
	@override String get versionQualityButton => 'Version et qualité';
	@override String get versionColumnHeader => 'Version';
	@override String get qualityColumnHeader => 'Qualité';
	@override String get qualityOriginal => 'Originale';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => 'Transcodage indisponible — lecture en qualité originale';
	@override String get pipButton => 'Mode PiP (Picture-in-Picture)';
	@override String get aspectRatioButton => 'Format d\'image';
	@override String get ambientLighting => 'Éclairage ambiant';
	@override String get fullscreenButton => 'Passer en mode plein écran';
	@override String get exitFullscreenButton => 'Quitter le mode plein écran';
	@override String get alwaysOnTopButton => 'Toujours au premier plan';
	@override String get rotationLockButton => 'Verrouillage de rotation';
	@override String get lockScreen => 'Verrouiller l\'écran';
	@override String get screenLockButton => 'Verrouillage de l\'écran';
	@override String get longPressToUnlock => 'Appui long pour déverrouiller';
	@override String get timelineSlider => 'Timeline vidéo';
	@override String get volumeSlider => 'Niveau sonore';
	@override String endsAt({required Object time}) => 'Fin à ${time}';
	@override String get pipActive => 'Lecture en mode image dans l\'image';
	@override String get pipFailed => 'Échec du démarrage du mode image dans l\'image';
	@override String get screenshotSaved => 'Capture d\'écran enregistrée';
	@override String zoomPercent({required Object percent}) => 'Zoom ${percent} %';
	@override late final _TranslationsVideoControlsPipErrorsFr pipErrors = _TranslationsVideoControlsPipErrorsFr._(_root);
	@override String get chapters => 'Chapitres';
	@override String get noChaptersAvailable => 'Aucun chapitre disponible';
	@override String get queue => 'File d\'attente';
	@override String get noQueueItems => 'Aucun élément dans la file d\'attente';
	@override String get searchSubtitles => 'Rechercher des sous-titres';
	@override String get language => 'Langue';
	@override String get noSubtitlesFound => 'Aucun sous-titre trouvé';
	@override String get downloadedSubtitle => 'Téléchargé';
	@override String get noSubtitlesAvailable => 'Aucun sous-titre disponible';
	@override String get noAudioTracksAvailable => 'Aucune piste audio disponible';
	@override String get noTracksAvailable => 'Aucune piste disponible';
	@override String get subtitleDownloaded => 'Sous-titre téléchargé';
	@override String get subtitleDownloadFailed => 'Échec du téléchargement du sous-titre';
	@override String get searchLanguages => 'Rechercher des langues...';
}

// Path: messages
class _TranslationsMessagesFr extends TranslationsMessagesEn {
	_TranslationsMessagesFr._(TranslationsFr root) : this._root = root, super.internal(root);

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
	@override String get removedFromContinueWatching => 'Supprimer de "Continuer à regarder"';
	@override String errorLoading({required Object error}) => 'Erreur: ${error}';
	@override String get streamInterrupted => 'La lecture a été interrompue. Appuyez sur Lecture ou avancez pour réessayer.';
	@override String get liveStreamInterrupted => 'Le direct a été interrompu. Appuyez sur Lecture pour réessayer.';
	@override String get fileInfoNotAvailable => 'Informations sur le fichier non disponibles';
	@override String errorLoadingFileInfo({required Object error}) => 'Erreur lors du chargement des informations sur le fichier: ${error}';
	@override String get errorLoadingSeries => 'Erreur lors du chargement de la série';
	@override String get musicNotSupported => 'La lecture de musique n\'est pas encore prise en charge';
	@override String get noDescriptionAvailable => 'Aucune description disponible';
	@override String get noProfilesAvailable => 'Aucun profil disponible';
	@override String get contactAdminForProfiles => 'Contactez votre administrateur serveur pour ajouter des profils';
	@override String get unableToDetermineLibrarySection => 'Impossible de déterminer la section de la bibliothèque pour cet élément';
	@override String get logsCleared => 'Logs effacés';
	@override String get logsCopied => 'Logs copiés dans le presse-papier';
	@override String get noLogsAvailable => 'Aucun log disponible';
	@override String libraryScanning({required Object title}) => 'Scan de "${title}"...';
	@override String libraryScanStarted({required Object title}) => 'Scan de la bibliothèque démarrée pour "${title}"';
	@override String libraryScanFailed({required Object error}) => 'Échec du scan de la bibliothèque: ${error}';
	@override String metadataRefreshing({required Object title}) => 'Actualisation des métadonnées pour "${title}"...';
	@override String metadataRefreshStarted({required Object title}) => 'Actualisation des métadonnées lancée pour "${title}"';
	@override String metadataRefreshFailed({required Object error}) => 'Échec de l\'actualisation des métadonnées: ${error}';
	@override String get logoutConfirm => 'Êtes-vous sûr de vouloir vous déconnecter ?';
	@override String get noSeasonsFound => 'Aucune saison trouvée';
	@override String get seasonsLoadFailed => 'Impossible de charger les saisons';
	@override String get noEpisodesFound => 'Aucun épisode trouvé dans la première saison';
	@override String get noEpisodesFoundGeneral => 'Aucun épisode trouvé';
	@override String get episodesLoadFailed => 'Impossible de charger les épisodes';
	@override String get noResultsFound => 'Aucun résultat trouvé';
	@override String sleepTimerSet({required Object label}) => 'Minuterie de mise en veille réglée sur ${label}';
	@override String get noItemsAvailable => 'Aucun élément disponible';
	@override String get failedToCreatePlayQueueNoItems => 'Échec de la création de la file d\'attente de lecture - aucun élément';
	@override String failedPlayback({required Object action, required Object error}) => 'Echec de ${action}: ${error}';
	@override String get switchingToCompatiblePlayer => 'Passage au lecteur compatible...';
	@override String get serverLimitTitle => 'Échec de la lecture';
	@override String get serverLimitBody => 'Erreur serveur (HTTP 500). Une limite de bande passante/transcodage a probablement rejeté cette session. Demandez au propriétaire de l\'ajuster.';
	@override String get logsUploaded => 'Logs envoyés';
	@override String get logsUploadFailed => 'Échec de l\'envoi des logs';
	@override String get logId => 'ID du log';
}

// Path: subtitlingStyling
class _TranslationsSubtitlingStylingFr extends TranslationsSubtitlingStylingEn {
	_TranslationsSubtitlingStylingFr._(TranslationsFr root) : this._root = root, super.internal(root);

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
	@override String get bold => 'Gras';
	@override String get italic => 'Italique';
	@override String get renderResolution => 'Résolution de rendu';
	@override String get renderResolutionScreen => 'Résolution de l\'écran';
	@override String get renderResolutionVideo => 'Résolution de la vidéo';
}

// Path: mpvConfig
class _TranslationsMpvConfigFr extends TranslationsMpvConfigEn {
	_TranslationsMpvConfigFr._(TranslationsFr root) : this._root = root, super.internal(root);

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
}

// Path: dialog
class _TranslationsDialogFr extends TranslationsDialogEn {
	_TranslationsDialogFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Confirmer l\'action';
}

// Path: profiles
class _TranslationsProfilesFr extends TranslationsProfilesEn {
	_TranslationsProfilesFr._(TranslationsFr root) : this._root = root, super.internal(root);

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
	@override String get connectionDefault => 'Par défaut';
	@override String connectionAs({required Object displayName}) => 'en tant que ${displayName}';
	@override String get makeDefault => 'Définir par défaut';
	@override String get removeConnection => 'Retirer';
	@override String get profileRenamed => 'Profil renommé.';
	@override String borrowAddTo({required Object displayName}) => 'Ajouter à ${displayName}';
	@override String get borrowExplain => 'Emprunter la connexion d\'un autre profil. Les profils protégés par PIN exigent un PIN.';
	@override String get borrowEmpty => 'Rien à emprunter pour le moment.';
	@override String get borrowEmptySubtitle => 'Connectez d\'abord Plex ou Jellyfin à un autre profil.';
	@override String borrowFromProfile({required Object displayName}) => 'De ${displayName}';
	@override String get borrowConnectionBorrowed => 'Connexion empruntée.';
	@override String get borrowFailed => 'Impossible d\'emprunter la connexion.';
	@override String get incorrectPin => 'PIN incorrect.';
	@override String get incorrectPinTryAgain => 'PIN incorrect. Veuillez réessayer.';
	@override String get sourceProfileMissingParentAccount => 'Le profil source n\'a pas son compte parent.';
	@override String get failedToLoadHomeUsers => 'Impossible de charger vos utilisateurs Plex Home. Vérifiez votre connexion et réessayez.';
	@override String get failedToVerifyPin => 'Impossible de vérifier le PIN.';
	@override String get newProfile => 'Nouveau profil';
	@override String get profileNameHint => 'ex. Invités, Enfants, Salon familial';
	@override String get pinProtectionOptional => 'Protection par PIN (optionnelle)';
	@override String get pinExplain => 'PIN à 4 chiffres requis pour changer de profil.';
	@override String get continueButton => 'Continuer';
	@override String get pinsDontMatch => 'Les PIN ne correspondent pas';
}

// Path: connections
class _TranslationsConnectionsFr extends TranslationsConnectionsEn {
	_TranslationsConnectionsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Connexions';
	@override String get addConnection => 'Ajouter une connexion';
	@override String get addConnectionSubtitleNoProfile => 'Connectez-vous avec Plex ou connectez un serveur Jellyfin';
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'Ajouter à ${displayName} : Plex, Jellyfin ou une autre connexion de profil';
	@override String sessionExpiredOne({required Object name}) => 'Session expirée pour ${name}';
	@override String sessionExpiredMany({required Object count}) => 'Session expirée pour ${count} serveurs';
	@override String get signInAgain => 'Se reconnecter';
	@override String get editJellyfinTitle => 'Modifier la connexion Jellyfin';
	@override String editJellyfinIntro({required Object serverName}) => 'Ajoutez ou supprimez des URL pour ${serverName}. Plezy utilisera l\'URL joignable avec la latence la plus faible.';
}

// Path: discover
class _TranslationsDiscoverFr extends TranslationsDiscoverEn {
	_TranslationsDiscoverFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Découvrez';
	@override String get noContentAvailable => 'Aucun contenu disponible';
	@override String get addMediaToLibraries => 'Ajoutez des médias à votre bibliothèque';
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
	@override String get cast => 'Cast';
	@override String get extras => 'Bandes-annonces et Extras';
	@override String get studio => 'Studio';
	@override String get rating => 'Évaluation';
	@override String get movie => 'Film';
	@override String get tvShow => 'Show TV';
	@override String minutesLeft({required Object minutes}) => '${minutes} min restantes';
	@override String get moreLikeThis => 'Plus de contenus similaires';
}

// Path: errors
class _TranslationsErrorsFr extends TranslationsErrorsEn {
	_TranslationsErrorsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Recherche échouée: ${error}';
	@override String connectionTimeout({required Object context}) => 'Délai d\'attente de connexion dépassé pendant le chargement ${context}';
	@override String get connectionFailed => 'Impossible de se connecter au serveur multimédia';
	@override String unableToLoad({required Object context}) => 'Impossible de charger ${context}. Réessayez.';
	@override String get noClientAvailable => 'Aucun client disponible';
	@override String get pleaseEnterToken => 'Veuillez saisir un token';
	@override String get invalidToken => 'Token invalide';
	@override String failedToVerifyToken({required Object error}) => 'Échec de la vérification du token: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Impossible de changer de profil vers ${displayName}';
	@override String failedToDeleteProfile({required Object displayName}) => 'Impossible de supprimer ${displayName}';
	@override String get failedToRate => 'Impossible de mettre à jour la note';
}

// Path: libraries
class _TranslationsLibrariesFr extends TranslationsLibrariesEn {
	_TranslationsLibrariesFr._(TranslationsFr root) : this._root = root, super.internal(root);

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
	@override String emptyingTrash({required Object title}) => 'Vider les poubelles pour "${title}"...';
	@override String trashEmptied({required Object title}) => 'Poubelles vidées pour "${title}"';
	@override String failedToEmptyTrash({required Object error}) => 'Échec de la suppression des éléments supprimés: ${error}';
	@override String analyzing({required Object title}) => 'Analyse de "${title}"...';
	@override String analysisStarted({required Object title}) => 'L\'analyse a commencé pour "${title}"';
	@override String failedToAnalyze({required Object error}) => 'Échec de l\'analyse de la bibliothèque: ${error}';
	@override String get noLibrariesFound => 'Aucune bibliothèque trouvée';
	@override String get allLibrariesHidden => 'Toutes les bibliothèques sont masquées';
	@override String hiddenLibrariesCount({required Object count}) => 'Bibliothèques masquées (${count})';
	@override String get thisLibraryIsEmpty => 'Cette bibliothèque est vide';
	@override String get noItemsMatchFilters => 'Aucun élément ne correspond aux filtres actifs';
	@override String get resetFilters => 'Réinitialiser les filtres';
	@override String get all => 'Tout';
	@override String get clearAll => 'Tout effacer';
	@override String scanLibraryConfirm({required Object title}) => 'Êtes-vous sûr de vouloir lancer le scan de "${title}"?';
	@override String analyzeLibraryConfirm({required Object title}) => 'Êtes-vous sûr de vouloir analyser "${title}"?';
	@override String refreshMetadataConfirm({required Object title}) => 'Êtes-vous sûr de vouloir actualiser les métadonnées pour "${title}"?';
	@override String emptyTrashConfirm({required Object title}) => 'Êtes-vous sûr de vouloir vider la corbeille pour "${title}"?';
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
	@override late final _TranslationsLibrariesTabsFr tabs = _TranslationsLibrariesTabsFr._(_root);
	@override late final _TranslationsLibrariesGroupingsFr groupings = _TranslationsLibrariesGroupingsFr._(_root);
	@override late final _TranslationsLibrariesFilterCategoriesFr filterCategories = _TranslationsLibrariesFilterCategoriesFr._(_root);
	@override late final _TranslationsLibrariesSortLabelsFr sortLabels = _TranslationsLibrariesSortLabelsFr._(_root);
}

// Path: about
class _TranslationsAboutFr extends TranslationsAboutEn {
	_TranslationsAboutFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'À propos';
	@override String get openSourceLicenses => 'Licences Open Source';
	@override String versionLabel({required Object version}) => 'Version ${version}';
	@override String get appDescription => 'Un magnifique client Plex et Jellyfin pour Flutter';
	@override String get viewLicensesDescription => 'Afficher les licences des bibliothèques tierces';
}

// Path: serverSelection
class _TranslationsServerSelectionFr extends TranslationsServerSelectionEn {
	_TranslationsServerSelectionFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Aucun serveur trouvé pour ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Échec du chargement des serveurs: ${error}';
}

// Path: hubDetail
class _TranslationsHubDetailFr extends TranslationsHubDetailEn {
	_TranslationsHubDetailFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Titre';
	@override String get releaseYear => 'Année de sortie';
	@override String get dateAdded => 'Date d\'ajout';
	@override String get rating => 'Évaluation';
	@override String get noItemsFound => 'Aucun élément trouvé';
}

// Path: logs
class _TranslationsLogsFr extends TranslationsLogsEn {
	_TranslationsLogsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Effacer les logs';
	@override String get copyLogs => 'Copier les logs';
	@override String get uploadLogs => 'Envoyer les logs';
}

// Path: licenses
class _TranslationsLicensesFr extends TranslationsLicensesEn {
	_TranslationsLicensesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Package associés';
	@override String get license => 'Licence';
	@override String licenseNumber({required Object number}) => 'Licence ${number}';
	@override String licensesCount({required Object count}) => '${count} licences';
}

// Path: navigation
class _TranslationsNavigationFr extends TranslationsNavigationEn {
	_TranslationsNavigationFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Medias';
	@override String get downloads => 'Téléch.';
	@override String get liveTv => 'TV direct';
	@override String get explore => 'Explorer';
}

// Path: explore
class _TranslationsExploreFr extends TranslationsExploreEn {
	_TranslationsExploreFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Explorer';
	@override String get selectSource => 'Sélectionner la source';
	@override late final _TranslationsExploreRowsFr rows = _TranslationsExploreRowsFr._(_root);
	@override late final _TranslationsExploreStatusFr status = _TranslationsExploreStatusFr._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${n} épisode',
		other: '${n} épisodes',
	);
	@override String get cast => 'Cast';
	@override String get characters => 'Personnages';
	@override String get addToWatchlist => 'Ajouter à la liste de suivi';
	@override String get removeFromWatchlist => 'Retirer de la liste de suivi';
	@override String get watchlistUpdateFailed => 'Impossible de mettre à jour la liste de suivi';
	@override String get notInLibrary => 'Absent de votre bibliothèque';
	@override String get inTheseLibraries => 'Dans ces bibliothèques';
	@override String get checkingLibrary => 'Vérification de votre bibliothèque...';
	@override String get emptyTitle => 'Rien ici pour l\'instant';
	@override String emptyMessage({required Object source}) => 'Les rangées de ${source} apparaîtront ici une fois qu\'elles auront du contenu.';
	@override String searchHint({required Object source}) => 'Rechercher dans ${source}';
	@override String searchEmpty({required Object query}) => 'Aucun résultat pour "${query}"';
	@override String searchPrompt({required Object source}) => 'Recherchez des films et des séries sur ${source}.';
	@override String get searchFailed => 'Échec de la recherche. Vérifiez votre connexion et réessayez.';
}

// Path: liveTv
class _TranslationsLiveTvFr extends TranslationsLiveTvEn {
	_TranslationsLiveTvFr._(TranslationsFr root) : this._root = root, super.internal(root);

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
	@override String get now => 'Maintenant';
	@override String get today => 'Aujourd\'hui';
	@override String get tomorrow => 'Demain';
	@override String get midnight => 'Minuit';
	@override String get overnight => 'Nuit';
	@override String get morning => 'Matin';
	@override String get daytime => 'Journée';
	@override String get evening => 'Soirée';
	@override String get lateNight => 'Nuit tardive';
	@override String get whatsOn => 'En ce moment';
	@override String get watchChannel => 'Regarder la chaîne';
	@override String get favorites => 'Favoris';
	@override String get reorderFavorites => 'Réorganiser les favoris';
	@override String get favoritesLoadFailed => 'Impossible de charger les favoris. Vérifiez votre connexion et réessayez.';
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
	@override String get rulesProcessRequested => 'Réévaluation des règles demandée';
	@override String get recordShow => 'Enregistrer l\'émission';
}

// Path: collections
class _TranslationsCollectionsFr extends TranslationsCollectionsEn {
	_TranslationsCollectionsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Collections';
	@override String get collection => 'Collection';
	@override String get empty => 'La collection est vide';
	@override String get deleteCollection => 'Supprimer la collection';
	@override String deleteConfirm({required Object title}) => 'Supprimer "${title}" ? Action irréversible.';
	@override String get deleted => 'Collection supprimée';
	@override String get deleteFailed => 'Échec de la suppression de la collection';
	@override String deleteFailedWithError({required Object error}) => 'Échec de la suppression de la collection: ${error}';
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
	@override String removeFromCollectionError({required Object error}) => 'Erreur lors de la suppression de la collection: ${error}';
	@override String get searchCollections => 'Rechercher des collections...';
}

// Path: playlists
class _TranslationsPlaylistsFr extends TranslationsPlaylistsEn {
	_TranslationsPlaylistsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Playlists';
	@override String get playlist => 'Playlist';
	@override String get noPlaylists => 'Aucune playlist trouvée';
	@override String get create => 'Créer une playlist';
	@override String get playlistName => 'Nom de playlist';
	@override String get enterPlaylistName => 'Entrer le nom de playlist';
	@override String get delete => 'Supprimer la playlist';
	@override String get removeItem => 'Retirer de la playlist';
	@override String get smartPlaylist => 'Smart playlist';
	@override String itemCount({required Object count}) => '${count} éléments';
	@override String get oneItem => '1 élément';
	@override String get emptyPlaylist => 'Cette playlist est vide';
	@override String get deleteConfirm => 'Supprimer la playlist ?';
	@override String deleteMessage({required Object name}) => 'Êtes-vous sûr de vouloir supprimer "${name}"?';
	@override String get created => 'Playlist créée';
	@override String get deleted => 'Playlist supprimée';
	@override String get itemAdded => 'Ajouté à la playlist';
	@override String get itemRemoved => 'Retiré de la playlist';
	@override String get selectPlaylist => 'Sélectionner une playlist';
	@override String get searchPlaylists => 'Rechercher des playlists...';
	@override String get errorCreating => 'Échec de la création de playlist';
	@override String get errorDeleting => 'Échec de suppression de playlist';
	@override String get errorLoading => 'Échec de chargement de playlists';
	@override String get errorAdding => 'Échec d\'ajout dans la playlist';
	@override String get errorReordering => 'Échec de réordonnacement d\'élément de playlist';
	@override String get errorRemoving => 'Échec de suppression depuis la playlist';
}

// Path: music
class _TranslationsMusicFr extends TranslationsMusicEn {
	_TranslationsMusicFr._(TranslationsFr root) : this._root = root, super.internal(root);

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
}

// Path: watchTogether
class _TranslationsWatchTogetherFr extends TranslationsWatchTogetherEn {
	_TranslationsWatchTogetherFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Regarder ensemble';
	@override String get description => 'Regardez du contenu en synchronisation avec vos amis et votre famille';
	@override String get createSession => 'Créer une session';
	@override String get creating => 'Création...';
	@override String get joinSession => 'Rejoindre la session';
	@override String get joining => 'Rejoindre...';
	@override String get controlMode => 'Mode de contrôle';
	@override String get controlModeQuestion => 'Qui peut contrôler la lecture ?';
	@override String get hostOnly => 'Hôte uniquement';
	@override String get anyone => 'N\'importe qui';
	@override String get hostingSession => 'Session d\'hébergement';
	@override String get inSession => 'En session';
	@override String get sessionCode => 'Code de session';
	@override String get openSessionControls => 'Ouvrir les commandes de la session Regarder ensemble';
	@override String get copySessionCode => 'Copier le code de session';
	@override String get hostControlsPlayback => 'L\'hôte contrôle la lecture';
	@override String get anyoneCanControl => 'Tout le monde peut contrôler la lecture';
	@override String get hostControls => 'Commandes de l\'hôte';
	@override String get anyoneControls => 'Tout le monde contrôle';
	@override String get participants => 'Participants';
	@override String get host => 'Hôte';
	@override String get hostBadge => 'HOST';
	@override String get youAreHost => 'Vous êtes l\'hôte';
	@override String get watchingWithOthers => 'Regarder avec d\'autres personnes';
	@override String get endSession => 'Fin de session';
	@override String get leaveSession => 'Quitter la session';
	@override String get endSessionQuestion => 'Terminer la session ?';
	@override String get leaveSessionQuestion => 'Quitter la session ?';
	@override String get endSessionConfirm => 'Cela mettra fin à la session pour tous les participants.';
	@override String get leaveSessionConfirm => 'Vous allez être déconnecté de la session.';
	@override String get endSessionConfirmOverlay => 'Cela mettra fin à la session de visionnage pour tous les participants.';
	@override String get leaveSessionConfirmOverlay => 'Vous serez déconnecté de la session de visionnage.';
	@override String get end => 'Terminer';
	@override String get leave => 'Fin';
	@override String get syncing => 'Synchronisation...';
	@override String get joinWatchSession => 'Rejoindre la session de visionnage';
	@override String get enterCodeHint => 'Entrez le code à 5 caractères';
	@override String get pasteFromClipboard => 'Coller depuis le presse-papiers';
	@override String get pleaseEnterCode => 'Veuillez saisir un code de session';
	@override String get codeMustBe5Chars => 'Le code de session doit comporter 5 caractères';
	@override String get joinInstructions => 'Saisissez le code de session de l\'hôte pour rejoindre.';
	@override String get failedToCreate => 'Échec de la création de la session';
	@override String get failedToJoin => 'Échec de la connexion à la session';
	@override String get sessionCodeCopied => 'Code de session copié dans le presse-papiers';
	@override String get relayUnreachable => 'Serveur relay inaccessible. Un blocage ISP peut empêcher Watch Together.';
	@override String get reconnectingToHost => 'Reconnexion à l\'hôte...';
	@override String get currentPlayback => 'Lecture en cours';
	@override String get joinCurrentPlayback => 'Rejoindre la lecture en cours';
	@override String get joinCurrentPlaybackDescription => 'Revenez à ce que l\'hôte regarde actuellement';
	@override String get failedToOpenCurrentPlayback => 'Impossible d\'ouvrir la lecture en cours';
	@override String participantJoined({required Object name}) => '${name} a rejoint';
	@override String participantLeft({required Object name}) => '${name} est parti';
	@override String participantPaused({required Object name}) => '${name} a mis en pause';
	@override String participantResumed({required Object name}) => '${name} a repris';
	@override String participantSeeked({required Object name}) => '${name} a avancé';
	@override String participantBuffering({required Object name}) => '${name} met en mémoire tampon';
	@override String participantNeedsUpdate({required Object name}) => '${name} utilise une ancienne version de l’app — synchronisation indisponible';
	@override String resumingWithout({required Object name}) => 'Reprise sans ${name}';
	@override String get waitingForParticipants => 'En attente du chargement des autres...';
	@override String waitingForName({required Object name}) => 'En attente de ${name}...';
	@override String get recentRooms => 'Salons récents';
	@override String get renameRoom => 'Renommer le salon';
	@override String get removeRoom => 'Supprimer';
	@override String get guestSwitchUnavailable => 'Impossible de changer — serveur indisponible pour la synchronisation';
	@override String get guestSwitchFailed => 'Impossible de changer — contenu introuvable sur ce serveur';
}

// Path: downloads
class _TranslationsDownloadsFr extends TranslationsDownloadsEn {
	_TranslationsDownloadsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Téléchargements';
	@override String get manage => 'Gérer';
	@override String get tvShows => 'Show TV';
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
	@override String get serverErrorBitrate => 'Erreur serveur : le fichier peut dépasser la limite de bitrate distant';
	@override String episodesQueued({required Object count}) => '${count} épisodes en attente de téléchargement';
	@override String get downloadDeleted => 'Télécharger supprimé';
	@override String deleteConfirm({required Object title}) => 'Supprimer "${title}" de cet appareil ?';
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
	@override String syncRuleCreated({required Object count}) => 'Règle de synchronisation créée — ${count} épisodes non vus conservés';
	@override String get syncRuleUpdated => 'Règle de synchronisation mise à jour';
	@override String get syncRuleRemoved => 'Règle de synchronisation supprimée';
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
	@override String get syncRuleNotAvailableForProfile => 'Non disponible pour le profil actuel';
	@override String get syncRuleUnknownServer => 'Serveur inconnu';
	@override String get syncRuleListCreated => 'Règle de synchronisation créée';
}

// Path: shaders
class _TranslationsShadersFr extends TranslationsShadersEn {
	_TranslationsShadersFr._(TranslationsFr root) : this._root = root, super.internal(root);

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
class _TranslationsCompanionRemoteFr extends TranslationsCompanionRemoteEn {
	_TranslationsCompanionRemoteFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Télécommande compagnon';
	@override String connectedTo({required Object name}) => 'Connecté à ${name}';
	@override String get unknownDevice => 'Appareil inconnu';
	@override late final _TranslationsCompanionRemoteSessionFr session = _TranslationsCompanionRemoteSessionFr._(_root);
	@override late final _TranslationsCompanionRemotePairingFr pairing = _TranslationsCompanionRemotePairingFr._(_root);
	@override late final _TranslationsCompanionRemoteRemoteFr remote = _TranslationsCompanionRemoteRemoteFr._(_root);
	@override late final _TranslationsCompanionRemoteErrorsFr errors = _TranslationsCompanionRemoteErrorsFr._(_root);
}

// Path: videoSettings
class _TranslationsVideoSettingsFr extends TranslationsVideoSettingsEn {
	_TranslationsVideoSettingsFr._(TranslationsFr root) : this._root = root, super.internal(root);

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
	@override String get audioOutput => 'Sortie audio';
	@override String get performanceOverlay => 'Superposition de performance';
	@override String get audioPassthrough => 'Audio Pass-Through';
	@override String get audioNormalization => 'Normaliser le volume';
	@override String get audioDownmix => 'Downmix en stéréo';
}

// Path: performanceOverlay
class _TranslationsPerformanceOverlayFr extends TranslationsPerformanceOverlayEn {
	_TranslationsPerformanceOverlayFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get color => 'Couleur';
	@override String get performance => 'Performances';
	@override String get buffer => 'Tampon';
	@override String get app => 'App';
	@override String get decoder => 'Décodeur';
	@override String get rawDecoder => 'Décodeur brut';
	@override String get tunneling => 'Tunneling';
	@override String get aspect => 'Format';
	@override String get rotation => 'Rotation';
	@override String get dvSource => 'Source DV';
	@override String get dvPath => 'Chemin DV';
	@override String get p7Conversion => 'Conv. P7';
	@override String get sampleRate => 'Fréquence';
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
}

// Path: externalPlayer
class _TranslationsExternalPlayerFr extends TranslationsExternalPlayerEn {
	_TranslationsExternalPlayerFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Lecteur externe';
	@override String get useExternalPlayer => 'Utiliser un lecteur externe';
	@override String get useExternalPlayerDescription => 'Ouvrir les vidéos dans une autre app';
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
class _TranslationsMetadataEditFr extends TranslationsMetadataEditEn {
	_TranslationsMetadataEditFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'Modifier...';
	@override String get screenTitle => 'Modifier les métadonnées';
	@override String get basicInfo => 'Informations de base';
	@override String get artwork => 'Artwork';
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
	@override String get artworkUpdated => 'Artwork mis à jour';
	@override String get artworkUpdateFailed => 'Échec de la mise à jour de l\'artwork';
	@override String get noArtworkAvailable => 'Aucun artwork disponible';
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
	@override String get shownWithForeignAudio => 'Affichés avec audio étranger';
	@override String get alwaysEnabled => 'Toujours activé';
	@override String get tags => 'Tags';
	@override String get addTag => 'Ajouter un tag';
	@override String get genre => 'Genre';
	@override String get director => 'Réalisateur';
	@override String get writer => 'Scénariste';
	@override String get producer => 'Producteur';
	@override String get country => 'Pays';
	@override String get collection => 'Collection';
	@override String get label => 'Label';
	@override String get style => 'Style';
	@override String get mood => 'Ambiance';
}

// Path: matchScreen
class _TranslationsMatchScreenFr extends TranslationsMatchScreenEn {
	_TranslationsMatchScreenFr._(TranslationsFr root) : this._root = root, super.internal(root);

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
class _TranslationsServerTasksFr extends TranslationsServerTasksEn {
	_TranslationsServerTasksFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tâches du serveur';
	@override String get failedToLoad => 'Échec du chargement des tâches';
	@override String get noTasks => 'Aucune tâche en cours';
}

// Path: trakt
class _TranslationsTraktFr extends TranslationsTraktEn {
	_TranslationsTraktFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'Connecté';
	@override String connectedAs({required Object username}) => 'Connecté en tant que @${username}';
	@override String get disconnectConfirm => 'Déconnecter le compte Trakt ?';
	@override String get disconnectConfirmBody => 'Plezy cessera d\'envoyer des événements à Trakt. Vous pouvez reconnecter à tout moment.';
	@override String get scrobble => 'Scrobbling en temps réel';
	@override String get scrobbleDescription => 'Envoyer les événements de lecture, pause et arrêt à Trakt pendant la lecture.';
	@override String get watchedSync => 'Synchroniser le statut « vu »';
	@override String get watchedSyncDescription => 'Lorsque vous marquez un élément comme vu dans Plezy, il l\'est aussi sur Trakt.';
}

// Path: seerr
class _TranslationsSeerrFr extends TranslationsSeerrEn {
	_TranslationsSeerrFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => 'Connecter Seerr';
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
	@override String get disconnectConfirmBody => 'Plezy oubliera cette instance Seerr. Reconnectez à tout moment.';
	@override String get request => 'Demander';
	@override String get request4k => 'Demander en 4K';
	@override String get seasons => 'Saisons';
	@override String get allSeasons => 'Toutes les saisons';
	@override String get advancedOptions => 'Avancé';
	@override String get destinationServer => 'Serveur de destination';
	@override String get qualityProfile => 'Profil de qualité';
	@override String get rootFolder => 'Dossier racine';
	@override String get languageProfile => 'Profil de langue';
	@override String get requestSubmitted => 'Demande envoyée';
	@override String requestFailed({required Object error}) => 'Échec de la demande : ${error}';
	@override String get requestsLoadFailed => 'Impossible de charger les options de demande';
	@override String get nothingToRequest => 'Tout est déjà disponible ou demandé.';
	@override String get statusAvailable => 'Disponible';
	@override String get statusPartiallyAvailable => 'Partiellement disponible';
	@override String get statusRequested => 'Demandé';
	@override String get statusProcessing => 'En cours de traitement';
}

// Path: services
class _TranslationsServicesFr extends TranslationsServicesEn {
	_TranslationsServicesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Services';
	@override String get hubSubtitle => 'Synchronisez votre progression et demandez de nouveaux titres.';
	@override String get notConnected => 'Non connecté';
	@override String connectedAs({required Object username}) => 'Connecté en tant que @${username}';
	@override String get scrobble => 'Suivre la progression automatiquement';
	@override String get scrobbleDescription => 'Mettre à jour votre liste lorsque vous terminez un épisode ou un film.';
	@override String disconnectConfirm({required Object service}) => 'Déconnecter ${service} ?';
	@override String disconnectConfirmBody({required Object service}) => 'Plezy cessera de mettre à jour ${service}. Reconnectez à tout moment.';
	@override String connectFailed({required Object service}) => 'Échec de la connexion à ${service}. Réessayez.';
	@override late final _TranslationsServicesNamesFr names = _TranslationsServicesNamesFr._(_root);
	@override late final _TranslationsServicesDeviceCodeFr deviceCode = _TranslationsServicesDeviceCodeFr._(_root);
	@override late final _TranslationsServicesOauthProxyFr oauthProxy = _TranslationsServicesOauthProxyFr._(_root);
	@override late final _TranslationsServicesLibraryFilterFr libraryFilter = _TranslationsServicesLibraryFilterFr._(_root);
}

// Path: addServer
class _TranslationsAddServerFr extends TranslationsAddServerEn {
	_TranslationsAddServerFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get addJellyfinTitle => 'Ajouter un serveur Jellyfin';
	@override String get serverUrls => 'URL du serveur';
	@override String get serverUrlsHelper => 'Plusieurs URL possibles, séparées par des virgules.';
	@override String get findServer => 'Rechercher un serveur';
	@override String get searchingLocalServers => 'Recherche de serveurs Jellyfin locaux...';
	@override String get localServers => 'Serveurs Jellyfin locaux';
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
	@override String get enterJellyfinUrlError => 'Saisissez l\'URL de votre serveur Jellyfin';
	@override String get addConnectionTitle => 'Ajouter une connexion';
	@override String addConnectionTitleScoped({required Object name}) => 'Ajouter à ${name}';
	@override String get signInWithPlexCard => 'Se connecter avec Plex';
	@override String get signInWithPlexCardSubtitle => 'Autorisez cet appareil. Les serveurs partagés sont ajoutés.';
	@override String get signInWithPlexCardSubtitleScoped => 'Autorisez un compte Plex. Les utilisateurs Home deviennent des profils.';
	@override String get connectToJellyfinCard => 'Se connecter à Jellyfin';
	@override String get connectToJellyfinCardSubtitle => 'Saisissez l\'URL du serveur, le nom d\'utilisateur et le mot de passe.';
	@override String connectToJellyfinCardSubtitleScoped({required Object name}) => 'Connectez-vous à un serveur Jellyfin. Lié à ${name}.';
	@override String get borrowFromAnotherProfile => 'Emprunter à un autre profil';
	@override String get borrowFromAnotherProfileSubtitle => 'Réutiliser la connexion d\'un autre profil. Les profils protégés par PIN exigent un PIN.';
}

// Path: hotkeys.actions
class _TranslationsHotkeysActionsFr extends TranslationsHotkeysActionsEn {
	_TranslationsHotkeysActionsFr._(TranslationsFr root) : this._root = root, super.internal(root);

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
class _TranslationsVideoControlsPipErrorsFr extends TranslationsVideoControlsPipErrorsEn {
	_TranslationsVideoControlsPipErrorsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Nécessite Android 8.0 ou plus récent';
	@override String get iosVersion => 'Nécessite iOS 15.0 ou plus récent';
	@override String get permissionDisabled => 'Picture-in-picture est désactivé. Activez-le dans les paramètres système.';
	@override String get notSupported => 'Cet appareil ne prend pas en charge le mode image dans l\'image';
	@override String get voSwitchFailed => 'Échec du changement de sortie vidéo pour l\'image dans l\'image';
	@override String get failed => 'Échec du démarrage du mode image dans l\'image';
	@override String unknown({required Object error}) => 'Une erreur s\'est produite : ${error}';
}

// Path: libraries.tabs
class _TranslationsLibrariesTabsFr extends TranslationsLibrariesTabsEn {
	_TranslationsLibrariesTabsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Recommandé';
	@override String get browse => 'Parcourir';
	@override String get collections => 'Collections';
	@override String get playlists => 'Playlists';
}

// Path: libraries.groupings
class _TranslationsLibrariesGroupingsFr extends TranslationsLibrariesGroupingsEn {
	_TranslationsLibrariesGroupingsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Regroupement';
	@override String get all => 'Tous';
	@override String get movies => 'Films';
	@override String get shows => 'Show TV';
	@override String get seasons => 'Saisons';
	@override String get episodes => 'Épisodes';
	@override String get artists => 'Artistes';
	@override String get albums => 'Albums';
	@override String get tracks => 'Titres';
	@override String get folders => 'Dossiers';
}

// Path: libraries.filterCategories
class _TranslationsLibrariesFilterCategoriesFr extends TranslationsLibrariesFilterCategoriesEn {
	_TranslationsLibrariesFilterCategoriesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get genre => 'Genre';
	@override String get year => 'Année';
	@override String get contentRating => 'Classification';
	@override String get tag => 'Tag';
	@override String get unwatched => 'Non vus';
	@override String get unplayed => 'Non lu';
	@override String get favorites => 'Favoris';
}

// Path: libraries.sortLabels
class _TranslationsLibrariesSortLabelsFr extends TranslationsLibrariesSortLabelsEn {
	_TranslationsLibrariesSortLabelsFr._(TranslationsFr root) : this._root = root, super.internal(root);

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
}

// Path: explore.rows
class _TranslationsExploreRowsFr extends TranslationsExploreRowsEn {
	_TranslationsExploreRowsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'Liste de suivi';
	@override String get recommendedMovies => 'Films recommandés';
	@override String get recommendedShows => 'Show TV recommandés';
	@override String get trendingMovies => 'Films tendance';
	@override String get trendingShows => 'Show TV tendance';
	@override String get popularMovies => 'Films populaires';
	@override String get popularShows => 'Show TV populaires';
	@override String get suggestedAnime => 'Anime suggérés';
	@override String get airingAnime => 'Meilleurs anime en diffusion';
	@override String get popularAnime => 'Anime les plus populaires';
	@override String get trending => 'Tendances';
	@override String get upcomingMovies => 'Films à venir';
	@override String get upcomingShows => 'Show TV à venir';
}

// Path: explore.status
class _TranslationsExploreStatusFr extends TranslationsExploreStatusEn {
	_TranslationsExploreStatusFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get airing => 'En cours';
	@override String get ended => 'Terminée';
	@override String get canceled => 'Annulée';
	@override String get upcoming => 'À venir';
}

// Path: companionRemote.session
class _TranslationsCompanionRemoteSessionFr extends TranslationsCompanionRemoteSessionEn {
	_TranslationsCompanionRemoteSessionFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'Démarrage du serveur distant...';
	@override String get hostAddress => 'Adresse de l\'hôte';
	@override String get connected => 'Connecté';
	@override String get serverRunning => 'Serveur distant actif';
	@override String get serverStopped => 'Serveur distant arrêté';
	@override String get serverRunningDescription => 'Les appareils mobiles de votre réseau peuvent se connecter à cette app';
	@override String get serverStoppedDescription => 'Démarrez le serveur pour permettre aux appareils mobiles de se connecter';
	@override String get usePhoneToControl => 'Utilisez votre appareil mobile pour contrôler cette application';
	@override String get startServer => 'Démarrer le serveur';
	@override String get stopServer => 'Arrêter le serveur';
	@override String get minimize => 'Réduire';
}

// Path: companionRemote.pairing
class _TranslationsCompanionRemotePairingFr extends TranslationsCompanionRemotePairingEn {
	_TranslationsCompanionRemotePairingFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'Les appareils Plezy avec le même compte Plex apparaissent ici';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Connexion...';
	@override String get searchingForDevices => 'Recherche d\'appareils...';
	@override String get noDevicesFound => 'Aucun appareil trouvé sur votre réseau';
	@override String get noDevicesHint => 'Ouvrez Plezy sur ordinateur et utilisez le même WiFi';
	@override String get availableDevices => 'Appareils disponibles';
	@override String get manualConnection => 'Connexion manuelle';
	@override String get cryptoInitFailed => 'Impossible de démarrer la connexion sécurisée. Connectez-vous d\'abord à Plex.';
	@override String get validationHostRequired => 'Veuillez entrer l\'adresse de l\'hôte';
	@override String get validationHostFormat => 'Le format doit être IP:port (ex. 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'Connexion expirée. Utilisez le même réseau sur les deux appareils.';
	@override String get sessionNotFound => 'Appareil introuvable. Assurez-vous que Plezy fonctionne sur l\'hôte.';
	@override String get authFailed => 'Échec de l\'authentification. Les deux appareils doivent utiliser le même compte Plex.';
	@override String failedToConnect({required Object error}) => 'Échec de la connexion : ${error}';
}

// Path: companionRemote.remote
class _TranslationsCompanionRemoteRemoteFr extends TranslationsCompanionRemoteRemoteEn {
	_TranslationsCompanionRemoteRemoteFr._(TranslationsFr root) : this._root = root, super.internal(root);

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
	@override String get searchHint => 'Rechercher sur le bureau...';
}

// Path: companionRemote.errors
class _TranslationsCompanionRemoteErrorsFr extends TranslationsCompanionRemoteErrorsEn {
	_TranslationsCompanionRemoteErrorsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => 'Aucune interface réseau trouvée';
	@override String get authenticationFailed => 'Échec de l’authentification';
	@override String serverStartFailed({required Object error}) => 'Impossible de démarrer le serveur distant : ${error}';
	@override String commandFailed({required Object error}) => 'Impossible d’envoyer la commande à distance : ${error}';
	@override String get joinTimedOut => 'Délai dépassé lors de la connexion à la session';
	@override String get failedToConnectAnyAddress => 'Impossible de se connecter à une adresse';
	@override String connectionLostAfterAttempts({required Object attempts}) => 'Connexion perdue après ${attempts} tentatives';
	@override String get connectionLost => 'Connexion perdue';
}

// Path: services.names
class _TranslationsServicesNamesFr extends TranslationsServicesNamesEn {
	_TranslationsServicesNamesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
}

// Path: services.deviceCode
class _TranslationsServicesDeviceCodeFr extends TranslationsServicesDeviceCodeEn {
	_TranslationsServicesDeviceCodeFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Activer Plezy sur ${service}';
	@override String body({required Object url}) => 'Rendez-vous sur ${url} et entrez ce code :';
	@override String openToActivate({required Object service}) => 'Ouvrir ${service} pour activer';
	@override String get copyCode => 'Copier le code d\'activation';
	@override String get waitingForAuthorization => 'En attente d\'autorisation…';
	@override String get codeCopied => 'Code copié';
}

// Path: services.oauthProxy
class _TranslationsServicesOauthProxyFr extends TranslationsServicesOauthProxyEn {
	_TranslationsServicesOauthProxyFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Se connecter à ${service}';
	@override String get body => 'Scannez ce code QR ou ouvrez l\'URL sur n\'importe quel appareil.';
	@override String openToSignIn({required Object service}) => 'Ouvrir ${service} pour se connecter';
	@override String get copyUrl => 'Copier l\'URL de connexion';
	@override String get urlCopied => 'URL copiée';
}

// Path: services.libraryFilter
class _TranslationsServicesLibraryFilterFr extends TranslationsServicesLibraryFilterEn {
	_TranslationsServicesLibraryFilterFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Filtre de bibliothèques';
	@override String get subtitleAllSyncing => 'Synchronisation de toutes les bibliothèques';
	@override String get subtitleNoneSyncing => 'Aucune synchronisation';
	@override String subtitleBlocked({required Object count}) => '${count} bloquées';
	@override String subtitleAllowed({required Object count}) => '${count} autorisées';
	@override String get mode => 'Mode de filtrage';
	@override String get modeBlacklist => 'Liste noire';
	@override String get modeWhitelist => 'Liste blanche';
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
			'auth.signInWithPlex' => 'S\'inscrire avec Plex',
			'auth.showQRCode' => 'Afficher le QR Code',
			'auth.authenticate' => 'S\'authentifier',
			'auth.authenticationTimeout' => 'Délai d\'authentification expiré. Veuillez réessayer.',
			'auth.scanQRToSignIn' => 'Scannez ce QR code pour vous connecter',
			'auth.waitingForAuth' => 'En attente d\'authentification...\nConnectez-vous depuis votre navigateur.',
			'auth.useBrowser' => 'Utiliser le navigateur',
			'auth.or' => 'ou',
			'auth.connectToJellyfin' => 'Se connecter à Jellyfin',
			'auth.useQuickConnect' => 'Utiliser Quick Connect',
			'auth.quickConnectInstructions' => 'Ouvrez Quick Connect dans Jellyfin et saisissez ce code.',
			'auth.quickConnectWaiting' => 'En attente d\'approbation…',
			'auth.quickConnectCancel' => 'Annuler',
			'auth.quickConnectExpired' => 'Quick Connect a expiré. Réessayez.',
			'common.cancel' => 'Annuler',
			'common.save' => 'Sauvegarder',
			'common.close' => 'Fermer',
			'common.clear' => 'Nettoyer',
			'common.reset' => 'Réinitialiser',
			'common.later' => 'Plus tard',
			'common.submit' => 'Soumettre',
			'common.confirm' => 'Confirmer',
			'common.retry' => 'Réessayer',
			'common.logout' => 'Se déconnecter',
			'common.unknown' => 'Inconnu',
			'common.refresh' => 'Rafraichir',
			'common.yes' => 'Oui',
			'common.no' => 'Non',
			'common.delete' => 'Supprimer',
			'common.edit' => 'Modifier',
			'common.shuffle' => 'Mélanger',
			'common.addTo' => 'Ajouter à...',
			'common.createNew' => 'Créer',
			'common.connect' => 'Connecter',
			'common.disconnect' => 'Déconnecter',
			'common.play' => 'Lire',
			'common.pause' => 'Pause',
			'common.resume' => 'Reprendre',
			'common.error' => 'Erreur',
			'common.search' => 'Recherche',
			'common.home' => 'Accueil',
			'common.back' => 'Retour',
			'common.settings' => 'Réglages',
			'common.mute' => 'Muet',
			'common.ok' => 'OK',
			'common.off' => 'Désactivé',
			'common.seasonNumber' => ({required Object number}) => 'Saison ${number}',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => 'Épisode ${number} - ${title}',
			'common.chapterNumber' => ({required Object number}) => 'Chapitre ${number}',
			'common.reconnect' => 'Reconnecter',
			'common.viewAll' => 'Tout afficher',
			'common.checkingNetwork' => 'Vérification du réseau...',
			'common.loadingServers' => 'Chargement des serveurs...',
			'common.connectingToServers' => 'Connexion aux serveurs...',
			'common.startingOfflineMode' => 'Démarrage en mode hors-ligne...',
			'common.loading' => 'Chargement...',
			'common.fullscreen' => 'Plein écran',
			'common.exitFullscreen' => 'Quitter le plein écran',
			'common.pressBackAgainToExit' => 'Appuyez à nouveau sur retour pour quitter',
			'screens.licenses' => 'Licences',
			'screens.switchProfile' => 'Changer de profil',
			'screens.subtitleStyling' => 'Configuration des sous-titres',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'Logs',
			'update.available' => 'Mise à jour disponible',
			'update.versionAvailable' => ({required Object version}) => 'Version ${version} disponible',
			'update.currentVersion' => ({required Object version}) => 'Installé: ${version}',
			'update.skipVersion' => 'Ignorer cette version',
			'update.viewRelease' => 'Voir la Release',
			'update.latestVersion' => 'Vous utilisez la dernière version',
			'update.checkFailed' => 'Échec de la vérification des mises à jour',
			'settings.title' => 'Paramètres',
			'settings.supportDeveloper' => 'Soutenir Plezy',
			'settings.supportDeveloperDescription' => 'Faites un don via Liberapay pour financer le développement',
			'settings.language' => 'Langue',
			'settings.theme' => 'Thème',
			'settings.appearance' => 'Apparence',
			'settings.videoPlayback' => 'Lecture vidéo',
			'settings.videoPlaybackDescription' => 'Configurer le comportement de lecture',
			'settings.advanced' => 'Avancé',
			'settings.episodePosterMode' => 'Style du Poster d\'épisode',
			'settings.seriesPoster' => 'Poster de série',
			'settings.seasonPoster' => 'Poster de saison',
			'settings.episodeThumbnail' => 'Miniature',
			'settings.showHeroSectionDescription' => 'Afficher le carrousel de contenu en vedette sur l\'écran d\'accueil',
			'settings.secondsLabel' => 'Secondes',
			'settings.minutesLabel' => 'Minutes',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'm',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Entrez la durée (${min}-${max})',
			'settings.systemTheme' => 'Système',
			'settings.lightTheme' => 'Clair',
			'settings.darkTheme' => 'Sombre',
			'settings.oledTheme' => 'OLED',
			'settings.libraryDensity' => 'Densité des bibliothèques',
			'settings.compact' => 'Compact',
			'settings.comfortable' => 'Confortable',
			'settings.viewMode' => 'Mode d\'affichage',
			'settings.gridView' => 'Grille',
			'settings.listView' => 'Liste',
			'settings.showHeroSection' => 'Afficher la section Hero',
			'settings.continueWatchingAction' => 'Action Continuer à regarder',
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
			'settings.showUnwatchedCount' => 'Afficher le nombre non visionné',
			'settings.showUnwatchedCountDescription' => 'Afficher le nombre d\'épisodes non visionnés pour les séries et saisons',
			'settings.showEpisodeNumberOnCards' => 'Afficher le numéro d\'épisode sur les cartes',
			'settings.showEpisodeNumberOnCardsDescription' => 'Afficher la saison et l\'épisode sur les cartes d\'épisode',
			'settings.showSeasonPostersOnTabs' => 'Afficher les posters de saison sur les onglets',
			'settings.showSeasonPostersOnTabsDescription' => 'Afficher l\'affiche de chaque saison au-dessus de son onglet',
			'settings.tvFullCardLayout' => 'Cartes TV pleines',
			'settings.tvFullCardLayoutDescription' => 'Utiliser des cartes TV avec image seule et noms des acteurs superposés',
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
			'settings.hardwareDecodingDescription' => 'Utilisez l\'accélération matérielle lorsqu\'elle est disponible.',
			'settings.bufferSize' => 'Taille du Buffer',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}MB',
			'settings.bufferSizeAuto' => 'Auto (Recommandé)',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => '${heap}MB de mémoire disponible. Un tampon de ${size}MB peut affecter la lecture.',
			'settings.defaultQualityTitle' => 'Qualité par défaut',
			'settings.musicQualityTitle' => 'Qualité de la musique',
			'settings.subtitleStyling' => 'Stylisation des sous-titres',
			'settings.subtitleStylingDescription' => 'Personnaliser l\'apparence des sous-titres',
			'settings.smallSkipDuration' => 'Durée du petit saut',
			'settings.largeSkipDuration' => 'Durée du grand saut',
			'settings.rewindOnResume' => 'Rembobiner à la reprise',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} secondes',
			'settings.defaultSleepTimer' => 'Minuterie de mise en veille par défaut',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} minutes',
			'settings.rememberTrackSelections' => 'Mémoriser les sélections de pistes par émission/film',
			'settings.rememberTrackSelectionsDescription' => 'Mémoriser les choix audio et sous-titres par titre',
			'settings.showChapterMarkersOnTimeline' => 'Afficher les marqueurs de chapitres sur la barre de lecture',
			'settings.showChapterMarkersOnTimelineDescription' => 'Segmenter la barre de lecture aux limites des chapitres',
			'settings.clickVideoTogglesPlayback' => 'Cliquez sur la vidéo pour basculer entre lecture et pause.',
			'settings.clickVideoTogglesPlaybackDescription' => 'Cliquer sur la vidéo pour lire/mettre en pause au lieu d\'afficher les contrôles.',
			'settings.videoPlayerControls' => 'Commandes du lecteur vidéo',
			'settings.keyboardShortcuts' => 'Raccourcis clavier',
			'settings.keyboardShortcutsDescription' => 'Personnaliser les raccourcis clavier',
			'settings.videoPlayerNavigation' => 'Navigation dans le lecteur vidéo',
			'settings.videoPlayerNavigationDescription' => 'Utilisez les touches fléchées pour naviguer dans les commandes du lecteur vidéo.',
			'settings.watchTogetherRelay' => 'Relais Regarder Ensemble',
			'settings.watchTogetherRelayDescription' => 'Définir un relay personnalisé. Tout le monde doit utiliser le même serveur.',
			'settings.watchTogetherRelayHint' => 'https://mon-relais.exemple.fr',
			'settings.crashReporting' => 'Rapports de plantage',
			'settings.crashReportingDescription' => 'Envoyer des rapports de plantage pour améliorer l\'application',
			'settings.debugLogging' => 'Journalisation de débogage',
			'settings.debugLoggingDescription' => 'Activer la journalisation détaillée pour le dépannage',
			'settings.viewLogs' => 'Voir les logs',
			'settings.viewLogsDescription' => 'Voir les logs d\'application',
			'settings.clearCache' => 'Vider le cache',
			'settings.clearCacheDescription' => 'Effacer les images et données en cache. Le contenu peut charger plus lentement.',
			'settings.clearCacheSuccess' => 'Cache effacé avec succès',
			'settings.resetSettings' => 'Réinitialiser les paramètres',
			'settings.resetSettingsDescription' => 'Restaurer les paramètres par défaut. Action irréversible.',
			'settings.resetSettingsSuccess' => 'Réinitialisation des paramètres réussie',
			'settings.backup' => 'Sauvegarde',
			'settings.exportSettings' => 'Exporter les paramètres',
			'settings.exportSettingsDescription' => 'Enregistrer vos préférences dans un fichier',
			'settings.exportSettingsSuccess' => 'Paramètres exportés',
			'settings.exportSettingsFailed' => 'Impossible d\'exporter les paramètres',
			'settings.importSettings' => 'Importer les paramètres',
			'settings.importSettingsDescription' => 'Restaurer les préférences depuis un fichier',
			'settings.importSettingsConfirm' => 'Cela remplacera vos paramètres actuels. Continuer ?',
			'settings.importSettingsSuccess' => 'Paramètres importés',
			'settings.importSettingsFailed' => 'Impossible d\'importer les paramètres',
			'settings.importSettingsInvalidFile' => 'Ce fichier n\'est pas un export Plezy valide',
			'settings.importSettingsNoUser' => 'Connectez-vous avant d\'importer les paramètres',
			'settings.shortcutsReset' => 'Raccourcis réinitialisés aux valeurs par défaut',
			'settings.about' => 'À propos',
			'settings.aboutDescription' => 'Informations sur l\'application et licences',
			'settings.updates' => 'Mises à jour',
			'settings.updateAvailable' => 'Mise à jour disponible',
			'settings.checkForUpdates' => 'Vérifier les mises à jour',
			'settings.autoCheckUpdatesOnStartup' => 'Vérifier automatiquement les mises à jour au démarrage',
			'settings.autoCheckUpdatesOnStartupDescription' => 'Notifier au lancement quand une mise à jour est disponible',
			'settings.validationErrorEnterNumber' => 'Veuillez saisir un numéro valide',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'La durée doit être comprise entre ${min} et ${max} ${unit}',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Raccourci déjà attribué à ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Raccourci mis à jour pour ${action}',
			'settings.autoSkip' => 'Skip automatique',
			'settings.autoSkipIntro' => 'Skip automatique de l\'introduction',
			'settings.autoSkipIntroDescription' => 'Skipper automatiquement l\'introduction après quelques secondes',
			'settings.autoSkipCredits' => 'Skip automatique des crédits',
			'settings.autoSkipCreditsDescription' => 'Passer les crédits et passer à l\'épisode suivant automatiquement',
			'settings.forceSkipMarkerFallback' => 'Forcer les marqueurs de repli',
			'settings.forceSkipMarkerFallbackDescription' => 'Utiliser les motifs de titres de chapitres même si Plex a des marqueurs',
			'settings.autoSkipDelay' => 'Délai avant skip automatique',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Attendre ${seconds} secondes avant l\'auto-skip',
			'settings.introPattern' => 'Modèle de marqueur d\'intro',
			'settings.introPatternDescription' => 'Expression régulière pour reconnaître les marqueurs d\'intro dans les titres de chapitres',
			'settings.creditsPattern' => 'Modèle de marqueur de générique',
			'settings.creditsPatternDescription' => 'Expression régulière pour reconnaître les marqueurs de générique dans les titres de chapitres',
			'settings.invalidRegex' => 'Expression régulière invalide',
			'settings.regex' => 'Expression régulière',
			'settings.downloads' => 'Téléchargement',
			'settings.downloadLocationDescription' => 'Choisissez où stocker le contenu téléchargé',
			'settings.downloadLocationDefault' => 'Par défaut (stockage de l\'application)',
			'settings.downloadLocationCustom' => 'Emplacement personnalisé',
			'settings.selectFolder' => 'Sélectionner un dossier',
			'settings.resetToDefault' => 'Réinitialiser les paramètres par défaut',
			'settings.currentPath' => ({required Object path}) => 'Actuel: ${path}',
			'settings.downloadLocationChanged' => 'Emplacement de téléchargement modifié',
			'settings.downloadLocationReset' => 'Emplacement de téléchargement réinitialisé à la valeur par défaut',
			'settings.downloadLocationInvalid' => 'Le dossier sélectionné n\'est pas accessible en écriture',
			'settings.downloadLocationSelectError' => 'Échec de la sélection du dossier',
			'settings.downloadOnWifiOnly' => 'Télécharger uniquement via WiFi',
			'settings.downloadOnWifiOnlyDescription' => 'Empêcher les téléchargements lorsque vous utilisez les données cellulaires',
			'settings.autoRemoveWatchedDownloads' => 'Supprimer automatiquement les téléchargements vus',
			'settings.autoRemoveWatchedDownloadsDescription' => 'Supprimer automatiquement les téléchargements vus',
			'settings.cellularDownloadBlocked' => 'Les téléchargements sont bloqués sur réseau mobile. Utilisez le WiFi ou modifiez le réglage.',
			'settings.maxVolume' => 'Volume maximal',
			'settings.maxVolumeDescription' => 'Autoriser l\'augmentation du volume au-delà de 100 % pour les médias silencieux',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Montrez ce que vous regardez sur Discord',
			'settings.services' => 'Services',
			'settings.servicesDescription' => 'Connectez Trakt, MyAnimeList, Seerr et plus',
			'settings.manageLibrariesDescription' => 'Réorganiser et masquer les bibliothèques',
			'settings.companionRemoteServer' => 'Serveur de télécommande',
			'settings.companionRemoteServerDescription' => 'Autoriser les appareils mobiles de votre réseau à contrôler cette application',
			'settings.autoPip' => 'Image dans l\'image automatique',
			'settings.autoPipDescription' => 'Passer en picture-in-picture en quittant pendant la lecture',
			'settings.matchContentFrameRate' => 'Fréquence d\'images du contenu correspondant',
			'settings.matchContentFrameRateDescription' => 'Adapter la fréquence d\'affichage au contenu vidéo',
			'settings.matchRefreshRate' => 'Adapter la fréquence de rafraîchissement',
			'settings.matchRefreshRateDescription' => 'Adapter la fréquence d\'affichage en plein écran',
			'settings.matchDynamicRange' => 'Adapter la plage dynamique',
			'settings.matchDynamicRangeDescription' => 'Activer HDR pour le contenu HDR, puis revenir en SDR',
			'settings.displaySwitchDelay' => 'Délai de changement d\'affichage',
			'settings.tunneledPlayback' => 'Lecture tunnelée',
			'settings.tunneledPlaybackDescription' => 'Utiliser le tunneling vidéo. Désactivez si la lecture HDR affiche un écran noir.',
			'settings.audioPassthrough' => 'Audio Pass-Through',
			'settings.audioPassthroughDescription' => 'Envoyez l\'audio Dolby/DTS vers votre ampli ou téléviseur sans réencodage, en conservant le son surround. Désactivez si vous n\'avez aucun son.',
			'settings.audioPassthroughDescriptionAppleTv' => 'Transmet le Dolby Digital Plus (y compris Atmos) au système en bitstream. Le DTS et le TrueHD restent lus en PCM multicanal. De brèves coupures audio peuvent survenir lors des sauts.',
			'settings.audioDownmix' => 'Downmix en stéréo',
			'settings.audioDownmixDescription' => 'Réduit le son surround à deux canaux pour les enceintes stéréo ou le casque',
			'settings.downmixCenterBoost' => 'Renforcement du canal central',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'Renforcement (dB)',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => 'Normaliser le volume lors du downmix',
			'settings.audioDownmixNormalizeDescription' => 'Atténue le mixage pour éviter la saturation. Désactivez pour conserver le volume d\'origine (risque de distorsion sur les scènes fortes).',
			'settings.atmosDiagnostics' => 'Test de sortie Atmos',
			'settings.atmosDiagnosticsDescription' => 'Diagnostiquer la sortie Dolby Atmos en lisant des signaux de test via le lecteur système',
			'settings.atmosTestHlsAtmos' => 'Flux Atmos d\'Apple',
			'settings.atmosTestHlsAtmosDescription' => 'Flux Dolby Atmos réputé fiable. L\'ampli devrait afficher Dolby Atmos.',
			'settings.atmosTestHlsControl' => 'Flux surround d\'Apple',
			'settings.atmosTestHlsControlDescription' => 'Flux témoin sans Atmos. L\'ampli devrait afficher du surround sans Atmos.',
			'settings.atmosTestRawStream' => 'Flux EAC3 brut',
			'settings.atmosTestRawStreamDescription' => 'Diffuse le fichier de test exactement comme la lecture Atmos du lecteur. Nécessite l\'URL du fichier de test.',
			'settings.atmosTestRawFile' => 'Fichier EAC3 brut',
			'settings.atmosTestRawFileDescription' => 'Lit le fichier de test avec une longueur connue. Nécessite l\'URL du fichier de test.',
			'settings.atmosTestStop' => 'Arrêter le test',
			'settings.atmosTestUrl' => 'URL du fichier de test',
			'settings.atmosTestUrlDescription' => 'URL HTTP d\'un fichier .ec3 Dolby Atmos brut (extrait par ex. avec ffmpeg)',
			'settings.atmosTestUrlMissing' => 'Définissez d\'abord l\'URL du fichier de test',
			'settings.atmosTestStatus' => 'État',
			'settings.dvConversionMode' => 'Conversion Dolby Vision',
			'settings.dvConversionModeDescription' => 'Choisissez comment ExoPlayer gère les fichiers Dolby Vision Profile 7.',
			'settings.dvConversionAuto' => 'Auto',
			'settings.dvConversionNative' => 'Natif / désactivé',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Utiliser la détection des capacités de l’appareil et le comportement de repli normal',
			'settings.dvConversionNativeDescription' => 'Forcer le DV7 natif et bloquer la nouvelle tentative de conversion DV',
			'settings.dvConversionDv81Description' => 'Forcer la conversion RPU intégrée vers Dolby Vision profil 8.1',
			'settings.dvConversionHevcStripDescription' => 'Supprimer les couches RPU/EL Dolby Vision et présenter du HEVC simple',
			'settings.requireProfileSelectionOnOpen' => 'Demander le profil à l\'ouverture',
			'settings.requireProfileSelectionOnOpenDescription' => 'Afficher la sélection de profil à chaque ouverture de l\'application',
			'settings.forceTvMode' => 'Forcer le mode TV',
			'settings.forceTvModeDescription' => 'Forcer l\'interface TV. Pour appareils non détectés automatiquement. Redémarrage requis.',
			'settings.startInFullscreen' => 'Démarrer en plein écran',
			'settings.startInFullscreenDescription' => 'Ouvrir Plezy en mode plein écran au lancement',
			'settings.exitFullscreenOnPlayerClose' => 'Quitter le plein écran à la fermeture du lecteur',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Quitter automatiquement le plein écran lors de la fermeture du lecteur vidéo',
			'settings.autoHidePerformanceOverlay' => 'Masquer auto. superposition performances',
			'settings.autoHidePerformanceOverlayDescription' => 'Faire apparaître/disparaître la superposition avec les contrôles de lecture',
			'settings.showNavBarLabels' => 'Afficher les libellés de la barre de navigation',
			'settings.showNavBarLabelsDescription' => 'Afficher les libellés sous les icônes de la barre de navigation',
			'settings.startupSection' => 'Section de démarrage',
			'settings.liveTvDefaultFavorites' => 'Chaînes favorites par défaut',
			'settings.liveTvDefaultFavoritesDescription' => 'Afficher uniquement les chaînes favorites à l\'ouverture de la TV en direct',
			'settings.display' => 'Affichage',
			'settings.homeScreen' => 'Écran d\'accueil',
			'settings.navigation' => 'Navigation',
			'settings.window' => 'Fenêtre',
			'settings.content' => 'Contenu',
			'settings.player' => 'Lecteur',
			'settings.subtitlesAndConfig' => 'Sous-titres et configuration',
			'settings.seekAndTiming' => 'Recherche et minutage',
			'settings.behavior' => 'Comportement',
			'search.hint' => 'Rechercher des films, des séries, de la musique...',
			'search.tryDifferentTerm' => 'Essayez un autre terme de recherche',
			'search.searchYourMedia' => 'Rechercher dans vos médias',
			'search.enterTitleActorOrKeyword' => 'Entrez un titre, un acteur ou un mot-clé',
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
			'fileInfo.video' => 'Vidéo',
			'fileInfo.audio' => 'Audio',
			'fileInfo.file' => 'Fichier',
			'fileInfo.advanced' => 'Avancé',
			'fileInfo.codec' => 'Codec',
			'fileInfo.resolution' => 'Résolution',
			'fileInfo.bitrate' => 'Bitrate',
			'fileInfo.frameRate' => 'Fréquence d\'images',
			'fileInfo.aspectRatio' => 'Format d\'image',
			'fileInfo.profile' => 'Profil',
			'fileInfo.bitDepth' => 'Profondeur de bits',
			'fileInfo.colorSpace' => 'Espace colorimétrique',
			'fileInfo.colorRange' => 'Gamme de couleurs',
			'fileInfo.colorPrimaries' => 'Couleurs primaires',
			'fileInfo.chromaSubsampling' => 'Sous-échantillonnage chromatique',
			'fileInfo.channels' => 'Canaux',
			'fileInfo.subtitles' => 'Sous-titres',
			'fileInfo.overallBitrate' => 'Débit global',
			'fileInfo.path' => 'Chemin',
			'fileInfo.size' => 'Taille',
			'fileInfo.container' => 'Conteneur',
			'fileInfo.duration' => 'Durée',
			'fileInfo.optimizedForStreaming' => 'Optimisé pour le streaming',
			'fileInfo.has64bitOffsets' => 'Décalages 64 bits',
			'mediaMenu.markAsWatched' => 'Marquer comme vu',
			'mediaMenu.markAsUnwatched' => 'Marquer comme non visionné',
			'mediaMenu.removeFromContinueWatching' => 'Supprimer de la liste "Continuer à regarder"',
			'mediaMenu.viewDetails' => 'Voir les détails',
			'mediaMenu.goToSeries' => 'Aller à la série',
			'mediaMenu.shufflePlay' => 'Lecture aléatoire',
			'mediaMenu.shuffleNotAvailableOffline' => 'La lecture aléatoire n’est pas disponible hors ligne',
			'mediaMenu.fileInfo' => 'Informations sur le fichier',
			'mediaMenu.deleteFromServer' => 'Supprimer du serveur',
			'mediaMenu.confirmDelete' => 'Supprimer ce média et ses fichiers de votre serveur ?',
			'mediaMenu.deleteMultipleWarning' => 'Cela inclut tous les épisodes et leurs fichiers.',
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
			'rateSheet.noConnectedServices' => 'Connectez un service dans les Réglages pour noter ici.',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, film',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, show TV',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'visionné',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} pourcentage visionné',
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
			'tooltips.shufflePlay' => 'Lecture aléatoire',
			'tooltips.playTrailer' => 'Lire la bande-annonce',
			'tooltips.markAsWatched' => 'Marqué comme vu',
			'tooltips.markAsUnwatched' => 'Marqué comme non vu',
			'videoControls.audioLabel' => 'Audio',
			'videoControls.subtitlesLabel' => 'Sous-titres',
			'videoControls.resetToZero' => 'Réinitialiser à 0ms',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.minusTime' => ({required Object amount, required Object unit}) => '-${amount}${unit}',
			'videoControls.playsLater' => ({required Object label}) => '${label} lire plus tard',
			'videoControls.playsEarlier' => ({required Object label}) => '${label} lire plus tôt',
			'videoControls.noOffset' => 'Pas de décalage',
			'videoControls.letterbox' => 'Boîte aux lettres',
			'videoControls.fillScreen' => 'Remplir l\'écran',
			'videoControls.stretch' => 'Etirer',
			'videoControls.lockRotation' => 'Verrouillage de la rotation',
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
			'videoControls.autoPlayNext' => 'Lecture automatique suivante',
			'videoControls.playNext' => 'Lire l\'épisode suivant',
			'videoControls.playButton' => 'Lire',
			'videoControls.pauseButton' => 'Pause',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'Reculer de ${seconds} secondes',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'Avancer de ${seconds} secondes',
			'videoControls.previousButton' => 'Épisode précédent',
			'videoControls.nextButton' => 'Épisode suivant',
			'videoControls.previousChapterButton' => 'Chapitre précédent',
			'videoControls.nextChapterButton' => 'Chapitre suivant',
			'videoControls.muteButton' => 'Mute',
			'videoControls.unmuteButton' => 'Dé-mute',
			'videoControls.settingsButton' => 'Paramètres de lecture',
			'videoControls.tracksButton' => 'Audio et sous-titres',
			'videoControls.chaptersButton' => 'Chapitres',
			'videoControls.versionQualityButton' => 'Version et qualité',
			'videoControls.versionColumnHeader' => 'Version',
			'videoControls.qualityColumnHeader' => 'Qualité',
			'videoControls.qualityOriginal' => 'Originale',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => 'Transcodage indisponible — lecture en qualité originale',
			'videoControls.pipButton' => 'Mode PiP (Picture-in-Picture)',
			'videoControls.aspectRatioButton' => 'Format d\'image',
			'videoControls.ambientLighting' => 'Éclairage ambiant',
			'videoControls.fullscreenButton' => 'Passer en mode plein écran',
			'videoControls.exitFullscreenButton' => 'Quitter le mode plein écran',
			'videoControls.alwaysOnTopButton' => 'Toujours au premier plan',
			'videoControls.rotationLockButton' => 'Verrouillage de rotation',
			'videoControls.lockScreen' => 'Verrouiller l\'écran',
			'videoControls.screenLockButton' => 'Verrouillage de l\'écran',
			'videoControls.longPressToUnlock' => 'Appui long pour déverrouiller',
			'videoControls.timelineSlider' => 'Timeline vidéo',
			'videoControls.volumeSlider' => 'Niveau sonore',
			'videoControls.endsAt' => ({required Object time}) => 'Fin à ${time}',
			'videoControls.pipActive' => 'Lecture en mode image dans l\'image',
			'videoControls.pipFailed' => 'Échec du démarrage du mode image dans l\'image',
			'videoControls.screenshotSaved' => 'Capture d\'écran enregistrée',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Zoom ${percent} %',
			'videoControls.pipErrors.androidVersion' => 'Nécessite Android 8.0 ou plus récent',
			'videoControls.pipErrors.iosVersion' => 'Nécessite iOS 15.0 ou plus récent',
			'videoControls.pipErrors.permissionDisabled' => 'Picture-in-picture est désactivé. Activez-le dans les paramètres système.',
			'videoControls.pipErrors.notSupported' => 'Cet appareil ne prend pas en charge le mode image dans l\'image',
			'videoControls.pipErrors.voSwitchFailed' => 'Échec du changement de sortie vidéo pour l\'image dans l\'image',
			'videoControls.pipErrors.failed' => 'Échec du démarrage du mode image dans l\'image',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Une erreur s\'est produite : ${error}',
			'videoControls.chapters' => 'Chapitres',
			'videoControls.noChaptersAvailable' => 'Aucun chapitre disponible',
			'videoControls.queue' => 'File d\'attente',
			'videoControls.noQueueItems' => 'Aucun élément dans la file d\'attente',
			'videoControls.searchSubtitles' => 'Rechercher des sous-titres',
			'videoControls.language' => 'Langue',
			'videoControls.noSubtitlesFound' => 'Aucun sous-titre trouvé',
			'videoControls.downloadedSubtitle' => 'Téléchargé',
			'videoControls.noSubtitlesAvailable' => 'Aucun sous-titre disponible',
			'videoControls.noAudioTracksAvailable' => 'Aucune piste audio disponible',
			'videoControls.noTracksAvailable' => 'Aucune piste disponible',
			'videoControls.subtitleDownloaded' => 'Sous-titre téléchargé',
			'videoControls.subtitleDownloadFailed' => 'Échec du téléchargement du sous-titre',
			'videoControls.searchLanguages' => 'Rechercher des langues...',
			'messages.markedAsWatched' => 'Marqué comme vu',
			'messages.markedAsUnwatched' => 'Marqué comme non vu',
			'messages.markedAsWatchedOffline' => 'Marqué comme vu (se synchronisera lorsque vous serez en ligne)',
			'messages.markedAsUnwatchedOffline' => 'Marqué comme non vu (sera synchronisé lorsque vous serez en ligne)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Supprimé automatiquement : ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${n} téléchargement vu supprimé automatiquement', other: '${n} téléchargements vus supprimés automatiquement', ), 
			'messages.removedFromContinueWatching' => 'Supprimer de "Continuer à regarder"',
			'messages.errorLoading' => ({required Object error}) => 'Erreur: ${error}',
			'messages.streamInterrupted' => 'La lecture a été interrompue. Appuyez sur Lecture ou avancez pour réessayer.',
			'messages.liveStreamInterrupted' => 'Le direct a été interrompu. Appuyez sur Lecture pour réessayer.',
			'messages.fileInfoNotAvailable' => 'Informations sur le fichier non disponibles',
			_ => null,
		} ?? switch (path) {
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Erreur lors du chargement des informations sur le fichier: ${error}',
			'messages.errorLoadingSeries' => 'Erreur lors du chargement de la série',
			'messages.musicNotSupported' => 'La lecture de musique n\'est pas encore prise en charge',
			'messages.noDescriptionAvailable' => 'Aucune description disponible',
			'messages.noProfilesAvailable' => 'Aucun profil disponible',
			'messages.contactAdminForProfiles' => 'Contactez votre administrateur serveur pour ajouter des profils',
			'messages.unableToDetermineLibrarySection' => 'Impossible de déterminer la section de la bibliothèque pour cet élément',
			'messages.logsCleared' => 'Logs effacés',
			'messages.logsCopied' => 'Logs copiés dans le presse-papier',
			'messages.noLogsAvailable' => 'Aucun log disponible',
			'messages.libraryScanning' => ({required Object title}) => 'Scan de "${title}"...',
			'messages.libraryScanStarted' => ({required Object title}) => 'Scan de la bibliothèque démarrée pour "${title}"',
			'messages.libraryScanFailed' => ({required Object error}) => 'Échec du scan de la bibliothèque: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => 'Actualisation des métadonnées pour "${title}"...',
			'messages.metadataRefreshStarted' => ({required Object title}) => 'Actualisation des métadonnées lancée pour "${title}"',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'Échec de l\'actualisation des métadonnées: ${error}',
			'messages.logoutConfirm' => 'Êtes-vous sûr de vouloir vous déconnecter ?',
			'messages.noSeasonsFound' => 'Aucune saison trouvée',
			'messages.seasonsLoadFailed' => 'Impossible de charger les saisons',
			'messages.noEpisodesFound' => 'Aucun épisode trouvé dans la première saison',
			'messages.noEpisodesFoundGeneral' => 'Aucun épisode trouvé',
			'messages.episodesLoadFailed' => 'Impossible de charger les épisodes',
			'messages.noResultsFound' => 'Aucun résultat trouvé',
			'messages.sleepTimerSet' => ({required Object label}) => 'Minuterie de mise en veille réglée sur ${label}',
			'messages.noItemsAvailable' => 'Aucun élément disponible',
			'messages.failedToCreatePlayQueueNoItems' => 'Échec de la création de la file d\'attente de lecture - aucun élément',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Echec de ${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Passage au lecteur compatible...',
			'messages.serverLimitTitle' => 'Échec de la lecture',
			'messages.serverLimitBody' => 'Erreur serveur (HTTP 500). Une limite de bande passante/transcodage a probablement rejeté cette session. Demandez au propriétaire de l\'ajuster.',
			'messages.logsUploaded' => 'Logs envoyés',
			'messages.logsUploadFailed' => 'Échec de l\'envoi des logs',
			'messages.logId' => 'ID du log',
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
			'profiles.connectionDefault' => 'Par défaut',
			'profiles.connectionAs' => ({required Object displayName}) => 'en tant que ${displayName}',
			'profiles.makeDefault' => 'Définir par défaut',
			'profiles.removeConnection' => 'Retirer',
			'profiles.profileRenamed' => 'Profil renommé.',
			'profiles.borrowAddTo' => ({required Object displayName}) => 'Ajouter à ${displayName}',
			'profiles.borrowExplain' => 'Emprunter la connexion d\'un autre profil. Les profils protégés par PIN exigent un PIN.',
			'profiles.borrowEmpty' => 'Rien à emprunter pour le moment.',
			'profiles.borrowEmptySubtitle' => 'Connectez d\'abord Plex ou Jellyfin à un autre profil.',
			'profiles.borrowFromProfile' => ({required Object displayName}) => 'De ${displayName}',
			'profiles.borrowConnectionBorrowed' => 'Connexion empruntée.',
			'profiles.borrowFailed' => 'Impossible d\'emprunter la connexion.',
			'profiles.incorrectPin' => 'PIN incorrect.',
			'profiles.incorrectPinTryAgain' => 'PIN incorrect. Veuillez réessayer.',
			'profiles.sourceProfileMissingParentAccount' => 'Le profil source n\'a pas son compte parent.',
			'profiles.failedToLoadHomeUsers' => 'Impossible de charger vos utilisateurs Plex Home. Vérifiez votre connexion et réessayez.',
			'profiles.failedToVerifyPin' => 'Impossible de vérifier le PIN.',
			'profiles.newProfile' => 'Nouveau profil',
			'profiles.profileNameHint' => 'ex. Invités, Enfants, Salon familial',
			'profiles.pinProtectionOptional' => 'Protection par PIN (optionnelle)',
			'profiles.pinExplain' => 'PIN à 4 chiffres requis pour changer de profil.',
			'profiles.continueButton' => 'Continuer',
			'profiles.pinsDontMatch' => 'Les PIN ne correspondent pas',
			'connections.sectionTitle' => 'Connexions',
			'connections.addConnection' => 'Ajouter une connexion',
			'connections.addConnectionSubtitleNoProfile' => 'Connectez-vous avec Plex ou connectez un serveur Jellyfin',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'Ajouter à ${displayName} : Plex, Jellyfin ou une autre connexion de profil',
			'connections.sessionExpiredOne' => ({required Object name}) => 'Session expirée pour ${name}',
			'connections.sessionExpiredMany' => ({required Object count}) => 'Session expirée pour ${count} serveurs',
			'connections.signInAgain' => 'Se reconnecter',
			'connections.editJellyfinTitle' => 'Modifier la connexion Jellyfin',
			'connections.editJellyfinIntro' => ({required Object serverName}) => 'Ajoutez ou supprimez des URL pour ${serverName}. Plezy utilisera l\'URL joignable avec la latence la plus faible.',
			'discover.title' => 'Découvrez',
			'discover.noContentAvailable' => 'Aucun contenu disponible',
			'discover.addMediaToLibraries' => 'Ajoutez des médias à votre bibliothèque',
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
			'discover.cast' => 'Cast',
			'discover.extras' => 'Bandes-annonces et Extras',
			'discover.studio' => 'Studio',
			'discover.rating' => 'Évaluation',
			'discover.movie' => 'Film',
			'discover.tvShow' => 'Show TV',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} min restantes',
			'discover.moreLikeThis' => 'Plus de contenus similaires',
			'errors.searchFailed' => ({required Object error}) => 'Recherche échouée: ${error}',
			'errors.connectionTimeout' => ({required Object context}) => 'Délai d\'attente de connexion dépassé pendant le chargement ${context}',
			'errors.connectionFailed' => 'Impossible de se connecter au serveur multimédia',
			'errors.unableToLoad' => ({required Object context}) => 'Impossible de charger ${context}. Réessayez.',
			'errors.noClientAvailable' => 'Aucun client disponible',
			'errors.pleaseEnterToken' => 'Veuillez saisir un token',
			'errors.invalidToken' => 'Token invalide',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Échec de la vérification du token: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Impossible de changer de profil vers ${displayName}',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => 'Impossible de supprimer ${displayName}',
			'errors.failedToRate' => 'Impossible de mettre à jour la note',
			'libraries.title' => 'Bibliothèques',
			'libraries.fallbackTitle' => 'Bibliothèque',
			'libraries.scanLibraryFiles' => 'Scanner les fichiers de la bibliothèque',
			'libraries.scanLibrary' => 'Scanner la bibliothèque',
			'libraries.analyze' => 'Analyser',
			'libraries.analyzeLibrary' => 'Analyser la bibliothèque',
			'libraries.refreshMetadata' => 'Actualiser les métadonnées',
			'libraries.emptyTrash' => 'Vider la corbeille',
			'libraries.emptyingTrash' => ({required Object title}) => 'Vider les poubelles pour "${title}"...',
			'libraries.trashEmptied' => ({required Object title}) => 'Poubelles vidées pour "${title}"',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'Échec de la suppression des éléments supprimés: ${error}',
			'libraries.analyzing' => ({required Object title}) => 'Analyse de "${title}"...',
			'libraries.analysisStarted' => ({required Object title}) => 'L\'analyse a commencé pour "${title}"',
			'libraries.failedToAnalyze' => ({required Object error}) => 'Échec de l\'analyse de la bibliothèque: ${error}',
			'libraries.noLibrariesFound' => 'Aucune bibliothèque trouvée',
			'libraries.allLibrariesHidden' => 'Toutes les bibliothèques sont masquées',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'Bibliothèques masquées (${count})',
			'libraries.thisLibraryIsEmpty' => 'Cette bibliothèque est vide',
			'libraries.noItemsMatchFilters' => 'Aucun élément ne correspond aux filtres actifs',
			'libraries.resetFilters' => 'Réinitialiser les filtres',
			'libraries.all' => 'Tout',
			'libraries.clearAll' => 'Tout effacer',
			'libraries.scanLibraryConfirm' => ({required Object title}) => 'Êtes-vous sûr de vouloir lancer le scan de "${title}"?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => 'Êtes-vous sûr de vouloir analyser "${title}"?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => 'Êtes-vous sûr de vouloir actualiser les métadonnées pour "${title}"?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => 'Êtes-vous sûr de vouloir vider la corbeille pour "${title}"?',
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
			'libraries.groupings.shows' => 'Show TV',
			'libraries.groupings.seasons' => 'Saisons',
			'libraries.groupings.episodes' => 'Épisodes',
			'libraries.groupings.artists' => 'Artistes',
			'libraries.groupings.albums' => 'Albums',
			'libraries.groupings.tracks' => 'Titres',
			'libraries.groupings.folders' => 'Dossiers',
			'libraries.filterCategories.genre' => 'Genre',
			'libraries.filterCategories.year' => 'Année',
			'libraries.filterCategories.contentRating' => 'Classification',
			'libraries.filterCategories.tag' => 'Tag',
			'libraries.filterCategories.unwatched' => 'Non vus',
			'libraries.filterCategories.unplayed' => 'Non lu',
			'libraries.filterCategories.favorites' => 'Favoris',
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
			'about.title' => 'À propos',
			'about.openSourceLicenses' => 'Licences Open Source',
			'about.versionLabel' => ({required Object version}) => 'Version ${version}',
			'about.appDescription' => 'Un magnifique client Plex et Jellyfin pour Flutter',
			'about.viewLicensesDescription' => 'Afficher les licences des bibliothèques tierces',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'Aucun serveur trouvé pour ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Échec du chargement des serveurs: ${error}',
			'hubDetail.title' => 'Titre',
			'hubDetail.releaseYear' => 'Année de sortie',
			'hubDetail.dateAdded' => 'Date d\'ajout',
			'hubDetail.rating' => 'Évaluation',
			'hubDetail.noItemsFound' => 'Aucun élément trouvé',
			'logs.clearLogs' => 'Effacer les logs',
			'logs.copyLogs' => 'Copier les logs',
			'logs.uploadLogs' => 'Envoyer les logs',
			'licenses.relatedPackages' => 'Package associés',
			'licenses.license' => 'Licence',
			'licenses.licenseNumber' => ({required Object number}) => 'Licence ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} licences',
			'navigation.libraries' => 'Medias',
			'navigation.downloads' => 'Téléch.',
			'navigation.liveTv' => 'TV direct',
			'navigation.explore' => 'Explorer',
			'explore.title' => 'Explorer',
			'explore.selectSource' => 'Sélectionner la source',
			'explore.rows.watchlist' => 'Liste de suivi',
			'explore.rows.recommendedMovies' => 'Films recommandés',
			'explore.rows.recommendedShows' => 'Show TV recommandés',
			'explore.rows.trendingMovies' => 'Films tendance',
			'explore.rows.trendingShows' => 'Show TV tendance',
			'explore.rows.popularMovies' => 'Films populaires',
			'explore.rows.popularShows' => 'Show TV populaires',
			'explore.rows.suggestedAnime' => 'Anime suggérés',
			'explore.rows.airingAnime' => 'Meilleurs anime en diffusion',
			'explore.rows.popularAnime' => 'Anime les plus populaires',
			'explore.rows.trending' => 'Tendances',
			'explore.rows.upcomingMovies' => 'Films à venir',
			'explore.rows.upcomingShows' => 'Show TV à venir',
			'explore.status.airing' => 'En cours',
			'explore.status.ended' => 'Terminée',
			'explore.status.canceled' => 'Annulée',
			'explore.status.upcoming' => 'À venir',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${n} épisode', other: '${n} épisodes', ), 
			'explore.cast' => 'Cast',
			'explore.characters' => 'Personnages',
			'explore.addToWatchlist' => 'Ajouter à la liste de suivi',
			'explore.removeFromWatchlist' => 'Retirer de la liste de suivi',
			'explore.watchlistUpdateFailed' => 'Impossible de mettre à jour la liste de suivi',
			'explore.notInLibrary' => 'Absent de votre bibliothèque',
			'explore.inTheseLibraries' => 'Dans ces bibliothèques',
			'explore.checkingLibrary' => 'Vérification de votre bibliothèque...',
			'explore.emptyTitle' => 'Rien ici pour l\'instant',
			'explore.emptyMessage' => ({required Object source}) => 'Les rangées de ${source} apparaîtront ici une fois qu\'elles auront du contenu.',
			'explore.searchHint' => ({required Object source}) => 'Rechercher dans ${source}',
			'explore.searchEmpty' => ({required Object query}) => 'Aucun résultat pour "${query}"',
			'explore.searchPrompt' => ({required Object source}) => 'Recherchez des films et des séries sur ${source}.',
			'explore.searchFailed' => 'Échec de la recherche. Vérifiez votre connexion et réessayez.',
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
			'liveTv.now' => 'Maintenant',
			'liveTv.today' => 'Aujourd\'hui',
			'liveTv.tomorrow' => 'Demain',
			'liveTv.midnight' => 'Minuit',
			'liveTv.overnight' => 'Nuit',
			'liveTv.morning' => 'Matin',
			'liveTv.daytime' => 'Journée',
			'liveTv.evening' => 'Soirée',
			'liveTv.lateNight' => 'Nuit tardive',
			'liveTv.whatsOn' => 'En ce moment',
			'liveTv.watchChannel' => 'Regarder la chaîne',
			'liveTv.favorites' => 'Favoris',
			'liveTv.reorderFavorites' => 'Réorganiser les favoris',
			'liveTv.favoritesLoadFailed' => 'Impossible de charger les favoris. Vérifiez votre connexion et réessayez.',
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
			'liveTv.rulesProcessRequested' => 'Réévaluation des règles demandée',
			'liveTv.recordShow' => 'Enregistrer l\'émission',
			'collections.title' => 'Collections',
			'collections.collection' => 'Collection',
			'collections.empty' => 'La collection est vide',
			'collections.deleteCollection' => 'Supprimer la collection',
			'collections.deleteConfirm' => ({required Object title}) => 'Supprimer "${title}" ? Action irréversible.',
			'collections.deleted' => 'Collection supprimée',
			'collections.deleteFailed' => 'Échec de la suppression de la collection',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Échec de la suppression de la collection: ${error}',
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
			'collections.removeFromCollectionError' => ({required Object error}) => 'Erreur lors de la suppression de la collection: ${error}',
			'collections.searchCollections' => 'Rechercher des collections...',
			'playlists.title' => 'Playlists',
			'playlists.playlist' => 'Playlist',
			'playlists.noPlaylists' => 'Aucune playlist trouvée',
			'playlists.create' => 'Créer une playlist',
			'playlists.playlistName' => 'Nom de playlist',
			'playlists.enterPlaylistName' => 'Entrer le nom de playlist',
			'playlists.delete' => 'Supprimer la playlist',
			'playlists.removeItem' => 'Retirer de la playlist',
			'playlists.smartPlaylist' => 'Smart playlist',
			'playlists.itemCount' => ({required Object count}) => '${count} éléments',
			'playlists.oneItem' => '1 élément',
			'playlists.emptyPlaylist' => 'Cette playlist est vide',
			'playlists.deleteConfirm' => 'Supprimer la playlist ?',
			'playlists.deleteMessage' => ({required Object name}) => 'Êtes-vous sûr de vouloir supprimer "${name}"?',
			'playlists.created' => 'Playlist créée',
			'playlists.deleted' => 'Playlist supprimée',
			'playlists.itemAdded' => 'Ajouté à la playlist',
			'playlists.itemRemoved' => 'Retiré de la playlist',
			'playlists.selectPlaylist' => 'Sélectionner une playlist',
			'playlists.searchPlaylists' => 'Rechercher des playlists...',
			'playlists.errorCreating' => 'Échec de la création de playlist',
			'playlists.errorDeleting' => 'Échec de suppression de playlist',
			'playlists.errorLoading' => 'Échec de chargement de playlists',
			'playlists.errorAdding' => 'Échec d\'ajout dans la playlist',
			'playlists.errorReordering' => 'Échec de réordonnacement d\'élément de playlist',
			'playlists.errorRemoving' => 'Échec de suppression depuis la playlist',
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
			'watchTogether.title' => 'Regarder ensemble',
			'watchTogether.description' => 'Regardez du contenu en synchronisation avec vos amis et votre famille',
			'watchTogether.createSession' => 'Créer une session',
			'watchTogether.creating' => 'Création...',
			'watchTogether.joinSession' => 'Rejoindre la session',
			'watchTogether.joining' => 'Rejoindre...',
			'watchTogether.controlMode' => 'Mode de contrôle',
			'watchTogether.controlModeQuestion' => 'Qui peut contrôler la lecture ?',
			'watchTogether.hostOnly' => 'Hôte uniquement',
			'watchTogether.anyone' => 'N\'importe qui',
			'watchTogether.hostingSession' => 'Session d\'hébergement',
			'watchTogether.inSession' => 'En session',
			'watchTogether.sessionCode' => 'Code de session',
			'watchTogether.openSessionControls' => 'Ouvrir les commandes de la session Regarder ensemble',
			'watchTogether.copySessionCode' => 'Copier le code de session',
			'watchTogether.hostControlsPlayback' => 'L\'hôte contrôle la lecture',
			'watchTogether.anyoneCanControl' => 'Tout le monde peut contrôler la lecture',
			'watchTogether.hostControls' => 'Commandes de l\'hôte',
			'watchTogether.anyoneControls' => 'Tout le monde contrôle',
			'watchTogether.participants' => 'Participants',
			'watchTogether.host' => 'Hôte',
			'watchTogether.hostBadge' => 'HOST',
			'watchTogether.youAreHost' => 'Vous êtes l\'hôte',
			'watchTogether.watchingWithOthers' => 'Regarder avec d\'autres personnes',
			'watchTogether.endSession' => 'Fin de session',
			'watchTogether.leaveSession' => 'Quitter la session',
			'watchTogether.endSessionQuestion' => 'Terminer la session ?',
			'watchTogether.leaveSessionQuestion' => 'Quitter la session ?',
			'watchTogether.endSessionConfirm' => 'Cela mettra fin à la session pour tous les participants.',
			'watchTogether.leaveSessionConfirm' => 'Vous allez être déconnecté de la session.',
			'watchTogether.endSessionConfirmOverlay' => 'Cela mettra fin à la session de visionnage pour tous les participants.',
			'watchTogether.leaveSessionConfirmOverlay' => 'Vous serez déconnecté de la session de visionnage.',
			'watchTogether.end' => 'Terminer',
			'watchTogether.leave' => 'Fin',
			'watchTogether.syncing' => 'Synchronisation...',
			'watchTogether.joinWatchSession' => 'Rejoindre la session de visionnage',
			'watchTogether.enterCodeHint' => 'Entrez le code à 5 caractères',
			'watchTogether.pasteFromClipboard' => 'Coller depuis le presse-papiers',
			'watchTogether.pleaseEnterCode' => 'Veuillez saisir un code de session',
			'watchTogether.codeMustBe5Chars' => 'Le code de session doit comporter 5 caractères',
			'watchTogether.joinInstructions' => 'Saisissez le code de session de l\'hôte pour rejoindre.',
			'watchTogether.failedToCreate' => 'Échec de la création de la session',
			'watchTogether.failedToJoin' => 'Échec de la connexion à la session',
			'watchTogether.sessionCodeCopied' => 'Code de session copié dans le presse-papiers',
			'watchTogether.relayUnreachable' => 'Serveur relay inaccessible. Un blocage ISP peut empêcher Watch Together.',
			'watchTogether.reconnectingToHost' => 'Reconnexion à l\'hôte...',
			'watchTogether.currentPlayback' => 'Lecture en cours',
			'watchTogether.joinCurrentPlayback' => 'Rejoindre la lecture en cours',
			'watchTogether.joinCurrentPlaybackDescription' => 'Revenez à ce que l\'hôte regarde actuellement',
			'watchTogether.failedToOpenCurrentPlayback' => 'Impossible d\'ouvrir la lecture en cours',
			'watchTogether.participantJoined' => ({required Object name}) => '${name} a rejoint',
			'watchTogether.participantLeft' => ({required Object name}) => '${name} est parti',
			'watchTogether.participantPaused' => ({required Object name}) => '${name} a mis en pause',
			'watchTogether.participantResumed' => ({required Object name}) => '${name} a repris',
			'watchTogether.participantSeeked' => ({required Object name}) => '${name} a avancé',
			'watchTogether.participantBuffering' => ({required Object name}) => '${name} met en mémoire tampon',
			'watchTogether.participantNeedsUpdate' => ({required Object name}) => '${name} utilise une ancienne version de l’app — synchronisation indisponible',
			'watchTogether.resumingWithout' => ({required Object name}) => 'Reprise sans ${name}',
			'watchTogether.waitingForParticipants' => 'En attente du chargement des autres...',
			'watchTogether.waitingForName' => ({required Object name}) => 'En attente de ${name}...',
			'watchTogether.recentRooms' => 'Salons récents',
			'watchTogether.renameRoom' => 'Renommer le salon',
			'watchTogether.removeRoom' => 'Supprimer',
			'watchTogether.guestSwitchUnavailable' => 'Impossible de changer — serveur indisponible pour la synchronisation',
			'watchTogether.guestSwitchFailed' => 'Impossible de changer — contenu introuvable sur ce serveur',
			'downloads.title' => 'Téléchargements',
			'downloads.manage' => 'Gérer',
			'downloads.tvShows' => 'Show TV',
			'downloads.movies' => 'Films',
			_ => null,
		} ?? switch (path) {
			'downloads.music' => 'Musique',
			'downloads.tracksQueued' => ({required Object count}) => '${count} titres en file d\'attente de téléchargement',
			'downloads.noDownloads' => 'Aucun téléchargement pour le moment',
			'downloads.noDownloadsDescription' => 'Le contenu téléchargé apparaîtra ici pour être consulté hors ligne.',
			'downloads.downloadNow' => 'Télécharger',
			'downloads.deleteDownload' => 'Supprimer le téléchargement',
			'downloads.retryDownload' => 'Réessayer le téléchargement',
			'downloads.downloadQueued' => 'Téléchargement en attente',
			'downloads.downloadResumed' => 'Téléchargement repris',
			'downloads.serverErrorBitrate' => 'Erreur serveur : le fichier peut dépasser la limite de bitrate distant',
			'downloads.episodesQueued' => ({required Object count}) => '${count} épisodes en attente de téléchargement',
			'downloads.downloadDeleted' => 'Télécharger supprimé',
			'downloads.deleteConfirm' => ({required Object title}) => 'Supprimer "${title}" de cet appareil ?',
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
			'downloads.syncRuleCreated' => ({required Object count}) => 'Règle de synchronisation créée — ${count} épisodes non vus conservés',
			'downloads.syncRuleUpdated' => 'Règle de synchronisation mise à jour',
			'downloads.syncRuleRemoved' => 'Règle de synchronisation supprimée',
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
			'downloads.syncRuleNotAvailableForProfile' => 'Non disponible pour le profil actuel',
			'downloads.syncRuleUnknownServer' => 'Serveur inconnu',
			'downloads.syncRuleListCreated' => 'Règle de synchronisation créée',
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
			'companionRemote.session.startingServer' => 'Démarrage du serveur distant...',
			'companionRemote.session.hostAddress' => 'Adresse de l\'hôte',
			'companionRemote.session.connected' => 'Connecté',
			'companionRemote.session.serverRunning' => 'Serveur distant actif',
			'companionRemote.session.serverStopped' => 'Serveur distant arrêté',
			'companionRemote.session.serverRunningDescription' => 'Les appareils mobiles de votre réseau peuvent se connecter à cette app',
			'companionRemote.session.serverStoppedDescription' => 'Démarrez le serveur pour permettre aux appareils mobiles de se connecter',
			'companionRemote.session.usePhoneToControl' => 'Utilisez votre appareil mobile pour contrôler cette application',
			'companionRemote.session.startServer' => 'Démarrer le serveur',
			'companionRemote.session.stopServer' => 'Arrêter le serveur',
			'companionRemote.session.minimize' => 'Réduire',
			'companionRemote.pairing.discoveryDescription' => 'Les appareils Plezy avec le même compte Plex apparaissent ici',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Connexion...',
			'companionRemote.pairing.searchingForDevices' => 'Recherche d\'appareils...',
			'companionRemote.pairing.noDevicesFound' => 'Aucun appareil trouvé sur votre réseau',
			'companionRemote.pairing.noDevicesHint' => 'Ouvrez Plezy sur ordinateur et utilisez le même WiFi',
			'companionRemote.pairing.availableDevices' => 'Appareils disponibles',
			'companionRemote.pairing.manualConnection' => 'Connexion manuelle',
			'companionRemote.pairing.cryptoInitFailed' => 'Impossible de démarrer la connexion sécurisée. Connectez-vous d\'abord à Plex.',
			'companionRemote.pairing.validationHostRequired' => 'Veuillez entrer l\'adresse de l\'hôte',
			'companionRemote.pairing.validationHostFormat' => 'Le format doit être IP:port (ex. 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'Connexion expirée. Utilisez le même réseau sur les deux appareils.',
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
			'companionRemote.remote.searchHint' => 'Rechercher sur le bureau...',
			'companionRemote.errors.noNetworkInterface' => 'Aucune interface réseau trouvée',
			'companionRemote.errors.authenticationFailed' => 'Échec de l’authentification',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'Impossible de démarrer le serveur distant : ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'Impossible d’envoyer la commande à distance : ${error}',
			'companionRemote.errors.joinTimedOut' => 'Délai dépassé lors de la connexion à la session',
			'companionRemote.errors.failedToConnectAnyAddress' => 'Impossible de se connecter à une adresse',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => 'Connexion perdue après ${attempts} tentatives',
			'companionRemote.errors.connectionLost' => 'Connexion perdue',
			'videoSettings.playbackSpeed' => 'Vitesse de lecture',
			'videoSettings.normalSpeed' => 'Normale',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'Actif (${duration})',
			'videoSettings.zoom' => 'Zoom',
			'videoSettings.sleepTimer' => 'Minuterie de mise en veille',
			'videoSettings.audioSync' => 'Synchronisation audio',
			'videoSettings.subtitleSync' => 'Synchronisation des sous-titres',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.audioOutput' => 'Sortie audio',
			'videoSettings.performanceOverlay' => 'Superposition de performance',
			'videoSettings.audioPassthrough' => 'Audio Pass-Through',
			'videoSettings.audioNormalization' => 'Normaliser le volume',
			'videoSettings.audioDownmix' => 'Downmix en stéréo',
			'performanceOverlay.color' => 'Couleur',
			'performanceOverlay.performance' => 'Performances',
			'performanceOverlay.buffer' => 'Tampon',
			'performanceOverlay.app' => 'App',
			'performanceOverlay.decoder' => 'Décodeur',
			'performanceOverlay.rawDecoder' => 'Décodeur brut',
			'performanceOverlay.tunneling' => 'Tunneling',
			'performanceOverlay.aspect' => 'Format',
			'performanceOverlay.rotation' => 'Rotation',
			'performanceOverlay.dvSource' => 'Source DV',
			'performanceOverlay.dvPath' => 'Chemin DV',
			'performanceOverlay.p7Conversion' => 'Conv. P7',
			'performanceOverlay.sampleRate' => 'Fréquence',
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
			'externalPlayer.title' => 'Lecteur externe',
			'externalPlayer.useExternalPlayer' => 'Utiliser un lecteur externe',
			'externalPlayer.useExternalPlayerDescription' => 'Ouvrir les vidéos dans une autre app',
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
			'metadataEdit.artwork' => 'Artwork',
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
			'metadataEdit.artworkUpdated' => 'Artwork mis à jour',
			'metadataEdit.artworkUpdateFailed' => 'Échec de la mise à jour de l\'artwork',
			'metadataEdit.noArtworkAvailable' => 'Aucun artwork disponible',
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
			'metadataEdit.shownWithForeignAudio' => 'Affichés avec audio étranger',
			'metadataEdit.alwaysEnabled' => 'Toujours activé',
			'metadataEdit.tags' => 'Tags',
			'metadataEdit.addTag' => 'Ajouter un tag',
			'metadataEdit.genre' => 'Genre',
			'metadataEdit.director' => 'Réalisateur',
			'metadataEdit.writer' => 'Scénariste',
			'metadataEdit.producer' => 'Producteur',
			'metadataEdit.country' => 'Pays',
			'metadataEdit.collection' => 'Collection',
			'metadataEdit.label' => 'Label',
			'metadataEdit.style' => 'Style',
			'metadataEdit.mood' => 'Ambiance',
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
			'trakt.disconnectConfirmBody' => 'Plezy cessera d\'envoyer des événements à Trakt. Vous pouvez reconnecter à tout moment.',
			'trakt.scrobble' => 'Scrobbling en temps réel',
			'trakt.scrobbleDescription' => 'Envoyer les événements de lecture, pause et arrêt à Trakt pendant la lecture.',
			'trakt.watchedSync' => 'Synchroniser le statut « vu »',
			'trakt.watchedSyncDescription' => 'Lorsque vous marquez un élément comme vu dans Plezy, il l\'est aussi sur Trakt.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Connecter Seerr',
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
			'seerr.disconnectConfirmBody' => 'Plezy oubliera cette instance Seerr. Reconnectez à tout moment.',
			'seerr.request' => 'Demander',
			'seerr.request4k' => 'Demander en 4K',
			'seerr.seasons' => 'Saisons',
			'seerr.allSeasons' => 'Toutes les saisons',
			'seerr.advancedOptions' => 'Avancé',
			'seerr.destinationServer' => 'Serveur de destination',
			'seerr.qualityProfile' => 'Profil de qualité',
			'seerr.rootFolder' => 'Dossier racine',
			'seerr.languageProfile' => 'Profil de langue',
			'seerr.requestSubmitted' => 'Demande envoyée',
			'seerr.requestFailed' => ({required Object error}) => 'Échec de la demande : ${error}',
			'seerr.requestsLoadFailed' => 'Impossible de charger les options de demande',
			'seerr.nothingToRequest' => 'Tout est déjà disponible ou demandé.',
			'seerr.statusAvailable' => 'Disponible',
			'seerr.statusPartiallyAvailable' => 'Partiellement disponible',
			'seerr.statusRequested' => 'Demandé',
			'seerr.statusProcessing' => 'En cours de traitement',
			'services.title' => 'Services',
			'services.hubSubtitle' => 'Synchronisez votre progression et demandez de nouveaux titres.',
			'services.notConnected' => 'Non connecté',
			'services.connectedAs' => ({required Object username}) => 'Connecté en tant que @${username}',
			'services.scrobble' => 'Suivre la progression automatiquement',
			'services.scrobbleDescription' => 'Mettre à jour votre liste lorsque vous terminez un épisode ou un film.',
			'services.disconnectConfirm' => ({required Object service}) => 'Déconnecter ${service} ?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'Plezy cessera de mettre à jour ${service}. Reconnectez à tout moment.',
			'services.connectFailed' => ({required Object service}) => 'Échec de la connexion à ${service}. Réessayez.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.deviceCode.title' => ({required Object service}) => 'Activer Plezy sur ${service}',
			'services.deviceCode.body' => ({required Object url}) => 'Rendez-vous sur ${url} et entrez ce code :',
			'services.deviceCode.openToActivate' => ({required Object service}) => 'Ouvrir ${service} pour activer',
			'services.deviceCode.copyCode' => 'Copier le code d\'activation',
			'services.deviceCode.waitingForAuthorization' => 'En attente d\'autorisation…',
			'services.deviceCode.codeCopied' => 'Code copié',
			'services.oauthProxy.title' => ({required Object service}) => 'Se connecter à ${service}',
			'services.oauthProxy.body' => 'Scannez ce code QR ou ouvrez l\'URL sur n\'importe quel appareil.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => 'Ouvrir ${service} pour se connecter',
			'services.oauthProxy.copyUrl' => 'Copier l\'URL de connexion',
			'services.oauthProxy.urlCopied' => 'URL copiée',
			'services.libraryFilter.title' => 'Filtre de bibliothèques',
			'services.libraryFilter.subtitleAllSyncing' => 'Synchronisation de toutes les bibliothèques',
			'services.libraryFilter.subtitleNoneSyncing' => 'Aucune synchronisation',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} bloquées',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} autorisées',
			'services.libraryFilter.mode' => 'Mode de filtrage',
			'services.libraryFilter.modeBlacklist' => 'Liste noire',
			'services.libraryFilter.modeWhitelist' => 'Liste blanche',
			'services.libraryFilter.modeHintBlacklist' => 'Synchroniser toutes les bibliothèques sauf celles cochées ci-dessous.',
			'services.libraryFilter.modeHintWhitelist' => 'Synchroniser uniquement les bibliothèques cochées ci-dessous.',
			'services.libraryFilter.libraries' => 'Bibliothèques',
			'services.libraryFilter.noLibraries' => 'Aucune bibliothèque disponible',
			'addServer.addJellyfinTitle' => 'Ajouter un serveur Jellyfin',
			'addServer.serverUrls' => 'URL du serveur',
			'addServer.serverUrlsHelper' => 'Plusieurs URL possibles, séparées par des virgules.',
			'addServer.findServer' => 'Rechercher un serveur',
			'addServer.searchingLocalServers' => 'Recherche de serveurs Jellyfin locaux...',
			'addServer.localServers' => 'Serveurs Jellyfin locaux',
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
			'addServer.enterJellyfinUrlError' => 'Saisissez l\'URL de votre serveur Jellyfin',
			'addServer.addConnectionTitle' => 'Ajouter une connexion',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => 'Ajouter à ${name}',
			'addServer.signInWithPlexCard' => 'Se connecter avec Plex',
			'addServer.signInWithPlexCardSubtitle' => 'Autorisez cet appareil. Les serveurs partagés sont ajoutés.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Autorisez un compte Plex. Les utilisateurs Home deviennent des profils.',
			'addServer.connectToJellyfinCard' => 'Se connecter à Jellyfin',
			'addServer.connectToJellyfinCardSubtitle' => 'Saisissez l\'URL du serveur, le nom d\'utilisateur et le mot de passe.',
			'addServer.connectToJellyfinCardSubtitleScoped' => ({required Object name}) => 'Connectez-vous à un serveur Jellyfin. Lié à ${name}.',
			'addServer.borrowFromAnotherProfile' => 'Emprunter à un autre profil',
			'addServer.borrowFromAnotherProfileSubtitle' => 'Réutiliser la connexion d\'un autre profil. Les profils protégés par PIN exigent un PIN.',
			_ => null,
		};
	}
}
