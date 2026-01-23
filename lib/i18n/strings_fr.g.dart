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
class TranslationsFr with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsFr({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.fr,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <fr>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

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
	@override late final _TranslationsPinEntryFr pinEntry = _TranslationsPinEntryFr._(_root);
	@override late final _TranslationsFileInfoFr fileInfo = _TranslationsFileInfoFr._(_root);
	@override late final _TranslationsMediaMenuFr mediaMenu = _TranslationsMediaMenuFr._(_root);
	@override late final _TranslationsAccessibilityFr accessibility = _TranslationsAccessibilityFr._(_root);
	@override late final _TranslationsTooltipsFr tooltips = _TranslationsTooltipsFr._(_root);
	@override late final _TranslationsVideoControlsFr videoControls = _TranslationsVideoControlsFr._(_root);
	@override late final _TranslationsUserStatusFr userStatus = _TranslationsUserStatusFr._(_root);
	@override late final _TranslationsMessagesFr messages = _TranslationsMessagesFr._(_root);
	@override late final _TranslationsSubtitlingStylingFr subtitlingStyling = _TranslationsSubtitlingStylingFr._(_root);
	@override late final _TranslationsMpvConfigFr mpvConfig = _TranslationsMpvConfigFr._(_root);
	@override late final _TranslationsDialogFr dialog = _TranslationsDialogFr._(_root);
	@override late final _TranslationsDiscoverFr discover = _TranslationsDiscoverFr._(_root);
	@override late final _TranslationsErrorsFr errors = _TranslationsErrorsFr._(_root);
	@override late final _TranslationsLibrariesFr libraries = _TranslationsLibrariesFr._(_root);
	@override late final _TranslationsAboutFr about = _TranslationsAboutFr._(_root);
	@override late final _TranslationsServerSelectionFr serverSelection = _TranslationsServerSelectionFr._(_root);
	@override late final _TranslationsHubDetailFr hubDetail = _TranslationsHubDetailFr._(_root);
	@override late final _TranslationsLogsFr logs = _TranslationsLogsFr._(_root);
	@override late final _TranslationsLicensesFr licenses = _TranslationsLicensesFr._(_root);
	@override late final _TranslationsNavigationFr navigation = _TranslationsNavigationFr._(_root);
	@override late final _TranslationsCollectionsFr collections = _TranslationsCollectionsFr._(_root);
	@override late final _TranslationsPlaylistsFr playlists = _TranslationsPlaylistsFr._(_root);
	@override late final _TranslationsWatchTogetherFr watchTogether = _TranslationsWatchTogetherFr._(_root);
	@override late final _TranslationsDownloadsFr downloads = _TranslationsDownloadsFr._(_root);
}

// Path: app
class _TranslationsAppFr implements TranslationsAppEn {
	_TranslationsAppFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
	@override String get loading => 'Chargement...';
}

// Path: auth
class _TranslationsAuthFr implements TranslationsAuthEn {
	_TranslationsAuthFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'S\'inscrire avec Plex';
	@override String get showQRCode => 'Afficher le QR Code';
	@override String get cancel => 'Annuler';
	@override String get authenticate => 'S\'authentifier';
	@override String get retry => 'Réessayer';
	@override String get debugEnterToken => 'Debug: Entrez votre token Plex';
	@override String get plexTokenLabel => 'Token d\'authentification Plex';
	@override String get plexTokenHint => 'Entrez votre token Plex.tv';
	@override String get authenticationTimeout => 'Délai d\'authentification expiré. Veuillez réessayer.';
	@override String get scanQRCodeInstruction => 'Scannez ce code QR avec un appareil connecté à Plex pour vous authentifier.';
	@override String get waitingForAuth => 'En attente d\'authentification...\nVeuillez vous connecter dans votre navigateur.';
}

// Path: common
class _TranslationsCommonFr implements TranslationsCommonEn {
	_TranslationsCommonFr._(this._root);

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
	@override String get shuffle => 'Mélanger';
	@override String get addTo => 'Ajouter à...';
}

// Path: screens
class _TranslationsScreensFr implements TranslationsScreensEn {
	_TranslationsScreensFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Licenses';
	@override String get switchProfile => 'Changer de profil';
	@override String get subtitleStyling => 'Configuration des sous-titres';
	@override String get mpvConfig => 'Configuration MPV';
	@override String get search => 'Recherche';
	@override String get logs => 'Logs';
}

// Path: update
class _TranslationsUpdateFr implements TranslationsUpdateEn {
	_TranslationsUpdateFr._(this._root);

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
class _TranslationsSettingsFr implements TranslationsSettingsEn {
	_TranslationsSettingsFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Paramètres';
	@override String get language => 'Langue';
	@override String get theme => 'Thème';
	@override String get appearance => 'Apparence';
	@override String get videoPlayback => 'Lecture vidéo';
	@override String get advanced => 'Avancé';
	@override String get episodePosterMode => 'Style du Poster d\'épisode';
	@override String get seriesPoster => 'Poster de série';
	@override String get seriesPosterDescription => 'Afficher le poster de série pour tous les épisodes';
	@override String get seasonPoster => 'Poster de saison';
	@override String get seasonPosterDescription => 'Afficher le poster spécifique à la saison pour les épisodes';
	@override String get episodeThumbnail => 'Mignature d\'épisode';
	@override String get episodeThumbnailDescription => 'Afficher les vignettes des captures d\'écran des épisodes au format 16:9';
	@override String get showHeroSectionDescription => 'Afficher le carrousel de contenu en vedette sur l\'écran d\'accueil';
	@override String get secondsLabel => 'Secondes';
	@override String get minutesLabel => 'Minutes';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => 'Entrez la durée (${min}-${max})';
	@override String get systemTheme => 'Système';
	@override String get systemThemeDescription => 'Suivre les paramètres système';
	@override String get lightTheme => 'Light';
	@override String get darkTheme => 'Dark';
	@override String get libraryDensity => 'Densité des bibliothèques';
	@override String get compact => 'Compact';
	@override String get compactDescription => 'Cartes plus petites, plus d\'éléments visibles';
	@override String get normal => 'Normal';
	@override String get normalDescription => 'Taille par défaut';
	@override String get comfortable => 'Confortable';
	@override String get comfortableDescription => 'Cartes plus grandes, moins d\'éléments visibles';
	@override String get viewMode => 'Mode d\'affichage';
	@override String get gridView => 'Grille';
	@override String get gridViewDescription => 'Afficher les éléments dans une disposition en grille';
	@override String get listView => 'Liste';
	@override String get listViewDescription => 'Afficher les éléments dans une liste';
	@override String get showHeroSection => 'Afficher la section Hero';
	@override String get useGlobalHubs => 'Utiliser la disposition Plex Home';
	@override String get useGlobalHubsDescription => 'Afficher les hubs de la page d\'accueil comme le client Plex officiel. Lorsque cette option est désactivée, affiche à la place les recommandations par bibliothèque.';
	@override String get showServerNameOnHubs => 'Afficher le nom du serveur sur les hubs';
	@override String get showServerNameOnHubsDescription => 'Toujours afficher le nom du serveur dans les titres des hubs. Lorsque cette option est désactivée, seuls les noms de hubs en double s\'affichent.';
	@override String get playerBackend => 'Moteur de lecture';
	@override String get exoPlayer => 'ExoPlayer (Recommandé)';
	@override String get exoPlayerDescription => 'Lecteur natif Android avec meilleur support matériel';
	@override String get mpv => 'MPV';
	@override String get mpvDescription => 'Lecteur avancé avec plus de fonctionnalités et support des sous-titres ASS';
	@override String get hardwareDecoding => 'Décodage matériel';
	@override String get hardwareDecodingDescription => 'Utilisez l\'accélération matérielle lorsqu\'elle est disponible.';
	@override String get bufferSize => 'Taille du Buffer';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get subtitleStyling => 'Stylisation des sous-titres';
	@override String get subtitleStylingDescription => 'Personnaliser l\'apparence des sous-titres';
	@override String get smallSkipDuration => 'Small Skip Duration';
	@override String get largeSkipDuration => 'Large Skip Duration';
	@override String secondsUnit({required Object seconds}) => '${seconds} secondes';
	@override String get defaultSleepTimer => 'Minuterie de mise en veille par défaut';
	@override String minutesUnit({required Object minutes}) => '${minutes} minutes';
	@override String get rememberTrackSelections => 'Mémoriser les sélections de pistes par émission/film';
	@override String get rememberTrackSelectionsDescription => 'Enregistrer automatiquement les préférences linguistiques pour l\'audio et les sous-titres lorsque vous changez de piste pendant la lecture';
	@override String get clickVideoTogglesPlayback => 'Cliquez sur la vidéo pour basculer entre lecture et pause.';
	@override String get clickVideoTogglesPlaybackDescription => 'Si cette option est activée, cliquer sur le lecteur vidéo lancera ou mettra en pause la vidéo. Sinon, le clic affichera ou masquera les commandes de lecture.';
	@override String get videoPlayerControls => 'Commandes du lecteur vidéo';
	@override String get keyboardShortcuts => 'Raccourcis clavier';
	@override String get keyboardShortcutsDescription => 'Personnaliser les raccourcis clavier';
	@override String get videoPlayerNavigation => 'Navigation dans le lecteur vidéo';
	@override String get videoPlayerNavigationDescription => 'Utilisez les touches fléchées pour naviguer dans les commandes du lecteur vidéo.';
	@override String get debugLogging => 'Journalisation de débogage';
	@override String get debugLoggingDescription => 'Activer la journalisation détaillée pour le dépannage';
	@override String get viewLogs => 'Voir les logs';
	@override String get viewLogsDescription => 'Voir les logs d\'application';
	@override String get clearCache => 'Vider le cache';
	@override String get clearCacheDescription => 'Cela effacera toutes les images et données mises en cache. Le chargement du contenu de l\'application peut prendre plus de temps après avoir effacé le cache.';
	@override String get clearCacheSuccess => 'Cache effacé avec succès';
	@override String get resetSettings => 'Réinitialiser les paramètres';
	@override String get resetSettingsDescription => 'Cela réinitialisera tous les paramètres à leurs valeurs par défaut. Cette action ne peut pas être annulée.';
	@override String get resetSettingsSuccess => 'Réinitialisation des paramètres réussie';
	@override String get shortcutsReset => 'Raccourcis réinitialisés aux valeurs par défaut';
	@override String get about => 'À propos';
	@override String get aboutDescription => 'Informations sur l\'application et licences';
	@override String get updates => 'Mises à jour';
	@override String get updateAvailable => 'Mise à jour disponible';
	@override String get checkForUpdates => 'Vérifier les mises à jour';
	@override String get validationErrorEnterNumber => 'Veuillez saisir un numéro valide';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'La durée doit être comprise entre ${min} et ${max} ${unit}';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Raccourci déjà attribué à ${action}';
	@override String shortcutUpdated({required Object action}) => 'Raccourci mis à jour pour ${action}';
	@override String get autoSkip => 'Skip automatique';
	@override String get autoSkipIntro => 'Skip automatique de l\'introduction';
	@override String get autoSkipIntroDescription => 'Skipper automatiquement l\'introduction après quelques secondes';
	@override String get autoSkipCredits => 'Skip automatique des crédits';
	@override String get autoSkipCreditsDescription => 'Passer les crédits et passer à l\'épisode suivant automatiquement';
	@override String get autoSkipDelay => 'Délai avant skip automatique';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Attendre ${seconds} secondes avant l\'auto-skip';
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
	@override String get cellularDownloadBlocked => 'Les téléchargements sont désactivés sur les données cellulaires. Connectez-vous au Wi-Fi ou modifiez le paramètre.';
	@override String get maxVolume => 'Volume maximal';
	@override String get maxVolumeDescription => 'Autoriser l\'augmentation du volume au-delà de 100 % pour les médias silencieux';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get maxVolumeHint => 'Entrez le volume maximal (100-300)';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Montrez ce que vous regardez sur Discord';
	@override String get matchContentFrameRate => 'Fréquence d\'images du contenu correspondant';
	@override String get matchContentFrameRateDescription => 'Ajustez la fréquence de rafraîchissement de l\'écran en fonction du contenu vidéo, ce qui réduit les saccades et économise la batterie';
}

// Path: search
class _TranslationsSearchFr implements TranslationsSearchEn {
	_TranslationsSearchFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Rechercher des films, des séries, de la musique...';
	@override String get tryDifferentTerm => 'Essayez un autre terme de recherche';
	@override String get searchYourMedia => 'Rechercher dans vos médias';
	@override String get enterTitleActorOrKeyword => 'Entrez un titre, un acteur ou un mot-clé';
}

// Path: hotkeys
class _TranslationsHotkeysFr implements TranslationsHotkeysEn {
	_TranslationsHotkeysFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Définir un raccourci pour ${actionName}';
	@override String get clearShortcut => 'Effacer le raccourci';
	@override late final _TranslationsHotkeysActionsFr actions = _TranslationsHotkeysActionsFr._(_root);
}

// Path: pinEntry
class _TranslationsPinEntryFr implements TranslationsPinEntryEn {
	_TranslationsPinEntryFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get enterPin => 'Entrer le code PIN';
	@override String get showPin => 'Afficher le code PIN';
	@override String get hidePin => 'Masquer le code PIN';
}

// Path: fileInfo
class _TranslationsFileInfoFr implements TranslationsFileInfoEn {
	_TranslationsFileInfoFr._(this._root);

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
	@override String get channels => 'Channels';
	@override String get path => 'Chemin';
	@override String get size => 'Taille';
	@override String get container => 'Conteneur';
	@override String get duration => 'Durée';
	@override String get optimizedForStreaming => 'Optimisé pour le streaming';
	@override String get has64bitOffsets => 'Décalages 64 bits';
}

// Path: mediaMenu
class _TranslationsMediaMenuFr implements TranslationsMediaMenuEn {
	_TranslationsMediaMenuFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Marquer comme vu';
	@override String get markAsUnwatched => 'Marquer comme non visionné';
	@override String get removeFromContinueWatching => 'Supprimer de la liste "Continuer à regarder"';
	@override String get goToSeries => 'Aller à la série';
	@override String get goToSeason => 'Aller à la saison';
	@override String get shufflePlay => 'Lecture aléatoire';
	@override String get fileInfo => 'Informations sur le fichier';
}

// Path: accessibility
class _TranslationsAccessibilityFr implements TranslationsAccessibilityEn {
	_TranslationsAccessibilityFr._(this._root);

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
}

// Path: tooltips
class _TranslationsTooltipsFr implements TranslationsTooltipsEn {
	_TranslationsTooltipsFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Lecture aléatoire';
	@override String get markAsWatched => 'Marqué comme vu';
	@override String get markAsUnwatched => 'Marqué comme non vu';
}

// Path: videoControls
class _TranslationsVideoControlsFr implements TranslationsVideoControlsEn {
	_TranslationsVideoControlsFr._(this._root);

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
	@override String get sleepTimer => 'Minuterie de mise en veille';
	@override String get timerActive => 'Minuterie active';
	@override String playbackWillPauseIn({required Object duration}) => 'La lecture sera mise en pause dans ${duration}';
	@override String get sleepTimerCompleted => 'Minuterie de mise en veille terminée - lecture en pause';
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
	@override String get settingsButton => 'Paramètres vidéo';
	@override String get audioTrackButton => 'Pistes audio';
	@override String get subtitlesButton => 'Sous-titres';
	@override String get chaptersButton => 'Chapitres';
	@override String get versionsButton => 'Versions vidéo';
	@override String get pipButton => 'Mode PiP (Picture-in-Picture)';
	@override String get aspectRatioButton => 'Format d\'image';
	@override String get fullscreenButton => 'Passer en mode plein écran';
	@override String get exitFullscreenButton => 'Quitter le mode plein écran';
	@override String get alwaysOnTopButton => 'Always on top';
	@override String get rotationLockButton => 'Verrouillage de rotation';
	@override String get timelineSlider => 'Timeline vidéo';
	@override String get volumeSlider => 'Niveau sonore';
	@override String get backButton => 'Retour';
	@override String get pipFailed => 'Échec du démarrage du mode image dans l\'image';
	@override late final _TranslationsVideoControlsPipErrorsFr pipErrors = _TranslationsVideoControlsPipErrorsFr._(_root);
}

// Path: userStatus
class _TranslationsUserStatusFr implements TranslationsUserStatusEn {
	_TranslationsUserStatusFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get admin => 'Admin';
	@override String get restricted => 'Restreint';
	@override String get protected => 'Protégé';
	@override String get current => 'ACTUEL';
}

// Path: messages
class _TranslationsMessagesFr implements TranslationsMessagesEn {
	_TranslationsMessagesFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Marqué comme vu';
	@override String get markedAsUnwatched => 'Marqué comme non vu';
	@override String get markedAsWatchedOffline => 'Marqué comme vu (se synchronisera lorsque vous serez en ligne)';
	@override String get markedAsUnwatchedOffline => 'Marqué comme non vu (sera synchronisé lorsque vous serez en ligne)';
	@override String get removedFromContinueWatching => 'Supprimer de "Continuer à regarder"';
	@override String errorLoading({required Object error}) => 'Erreur: ${error}';
	@override String get fileInfoNotAvailable => 'Informations sur le fichier non disponibles';
	@override String errorLoadingFileInfo({required Object error}) => 'Erreur lors du chargement des informations sur le fichier: ${error}';
	@override String get errorLoadingSeries => 'Erreur lors du chargement de la série';
	@override String get errorLoadingSeason => 'Erreur lors du chargement de la saison';
	@override String get musicNotSupported => 'La lecture de musique n\'est pas encore prise en charge';
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
	@override String get noEpisodesFound => 'Aucun épisode trouvé dans la première saison';
	@override String get noEpisodesFoundGeneral => 'Aucun épisode trouvé';
	@override String get noResultsFound => 'Aucun résultat trouvé';
	@override String sleepTimerSet({required Object label}) => 'Minuterie de mise en veille réglée sur ${label}';
	@override String get noItemsAvailable => 'Aucun élément disponible';
	@override String get failedToCreatePlayQueue => 'Échec de la création de la file d\'attente de lecture';
	@override String get failedToCreatePlayQueueNoItems => 'Échec de la création de la file d\'attente de lecture - aucun élément';
	@override String failedPlayback({required Object action, required Object error}) => 'Echec de ${action}: ${error}';
	@override String get switchingToCompatiblePlayer => 'Passage au lecteur compatible...';
}

// Path: subtitlingStyling
class _TranslationsSubtitlingStylingFr implements TranslationsSubtitlingStylingEn {
	_TranslationsSubtitlingStylingFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get stylingOptions => 'Options de style';
	@override String get fontSize => 'Taille de la police';
	@override String get textColor => 'Couleur du texte';
	@override String get borderSize => 'Taille de la bordure';
	@override String get borderColor => 'Couleur de la bordure';
	@override String get backgroundOpacity => 'Opacité d\'arrière-plan';
	@override String get backgroundColor => 'Couleur d\'arrière-plan';
}

// Path: mpvConfig
class _TranslationsMpvConfigFr implements TranslationsMpvConfigEn {
	_TranslationsMpvConfigFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Configuration MPV';
	@override String get description => 'Paramètres avancés du lecteur vidéo';
	@override String get properties => 'Propriétés';
	@override String get presets => 'Préréglages';
	@override String get noProperties => 'Aucune propriété configurée';
	@override String get noPresets => 'Aucun préréglage enregistré';
	@override String get addProperty => 'Ajouter une propriété';
	@override String get editProperty => 'Modifier la propriété';
	@override String get deleteProperty => 'Supprimer la propriété';
	@override String get propertyKey => 'Clé';
	@override String get propertyKeyHint => 'e.g., hwdec, demuxer-max-bytes';
	@override String get propertyValue => 'Valeur';
	@override String get propertyValueHint => 'e.g., auto, 256000000';
	@override String get saveAsPreset => 'Enregistrer comme préréglage...';
	@override String get presetName => 'Nom du préréglage';
	@override String get presetNameHint => 'Entrez un nom pour ce préréglage';
	@override String get loadPreset => 'Charger';
	@override String get deletePreset => 'Supprimer';
	@override String get presetSaved => 'Préréglage enregistré';
	@override String get presetLoaded => 'Préréglage chargé';
	@override String get presetDeleted => 'Préréglage supprimé';
	@override String get confirmDeletePreset => 'Êtes-vous sûr de vouloir supprimer ce préréglage ?';
	@override String get confirmDeleteProperty => 'Êtes-vous sûr de vouloir supprimer cette propriété ?';
	@override String entriesCount({required Object count}) => '${count} entrées';
}

// Path: dialog
class _TranslationsDialogFr implements TranslationsDialogEn {
	_TranslationsDialogFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Confirmer l\'action';
	@override String get cancel => 'Annuler';
	@override String get playNow => 'Lire maintenant';
}

// Path: discover
class _TranslationsDiscoverFr implements TranslationsDiscoverEn {
	_TranslationsDiscoverFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Découvrez';
	@override String get switchProfile => 'Changer de profil';
	@override String get logout => 'Déconnexion';
	@override String get noContentAvailable => 'Aucun contenu disponible';
	@override String get addMediaToLibraries => 'Ajoutez des médias à votre bibliothèque';
	@override String get continueWatching => 'Continuer à regarder';
	@override String get play => 'Lire';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get pause => 'Pause';
	@override String get overview => 'Aperçu';
	@override String get cast => 'Cast';
	@override String get seasons => 'Saisons';
	@override String get studio => 'Studio';
	@override String get rating => 'Évaluation';
	@override String get watched => 'Vu';
	@override String episodeCount({required Object count}) => '${count} épisodes';
	@override String watchedProgress({required Object watched, required Object total}) => '${watched}/${total} vu';
	@override String get movie => 'Film';
	@override String get tvShow => 'Show TV';
	@override String minutesLeft({required Object minutes}) => '${minutes} min restantes';
}

// Path: errors
class _TranslationsErrorsFr implements TranslationsErrorsEn {
	_TranslationsErrorsFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Recherche échouée: ${error}';
	@override String connectionTimeout({required Object context}) => 'Délai d\'attente de connexion dépassé pendant le chargement ${context}';
	@override String get connectionFailed => 'Impossible de se connecter au serveur Plex';
	@override String failedToLoad({required Object context, required Object error}) => 'Échec du chargement ${context}: ${error}';
	@override String get noClientAvailable => 'Aucun client disponible';
	@override String authenticationFailed({required Object error}) => 'Échec de l\'authentification: ${error}';
	@override String get couldNotLaunchUrl => 'Impossible de lancer l\'URL d\'authentification';
	@override String get pleaseEnterToken => 'Veuillez saisir un token';
	@override String get invalidToken => 'Token invalide';
	@override String failedToVerifyToken({required Object error}) => 'Échec de la vérification du token: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Impossible de changer de profil vers ${displayName}';
}

// Path: libraries
class _TranslationsLibrariesFr implements TranslationsLibrariesEn {
	_TranslationsLibrariesFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bibliothèques';
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
	@override String get thisLibraryIsEmpty => 'Cette bibliothèque est vide';
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
}

// Path: about
class _TranslationsAboutFr implements TranslationsAboutEn {
	_TranslationsAboutFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'À propos';
	@override String get openSourceLicenses => 'Licences Open Source';
	@override String versionLabel({required Object version}) => 'Version ${version}';
	@override String get appDescription => 'Un magnifique client Plex pour Flutter';
	@override String get viewLicensesDescription => 'Afficher les licences des bibliothèques tierces';
}

// Path: serverSelection
class _TranslationsServerSelectionFr implements TranslationsServerSelectionEn {
	_TranslationsServerSelectionFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get allServerConnectionsFailed => 'Impossible de se connecter à un serveur. Veuillez vérifier votre connexion réseau et réessayer.';
	@override String get noServersFound => 'Aucun serveur trouvé';
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Aucun serveur trouvé pour ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Échec du chargement des serveurs: ${error}';
}

// Path: hubDetail
class _TranslationsHubDetailFr implements TranslationsHubDetailEn {
	_TranslationsHubDetailFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Titre';
	@override String get releaseYear => 'Année de sortie';
	@override String get dateAdded => 'Date d\'ajout';
	@override String get rating => 'Évaluation';
	@override String get noItemsFound => 'Aucun élément trouvé';
}

// Path: logs
class _TranslationsLogsFr implements TranslationsLogsEn {
	_TranslationsLogsFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Effacer les logs';
	@override String get copyLogs => 'Copier les logs';
	@override String get error => 'Erreur:';
	@override String get stackTrace => 'Liste des appels:';
}

// Path: licenses
class _TranslationsLicensesFr implements TranslationsLicensesEn {
	_TranslationsLicensesFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Package associés';
	@override String get license => 'Licence';
	@override String licenseNumber({required Object number}) => 'Licence ${number}';
	@override String licensesCount({required Object count}) => '${count} licences';
}

// Path: navigation
class _TranslationsNavigationFr implements TranslationsNavigationEn {
	_TranslationsNavigationFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get home => 'Accueil';
	@override String get search => 'Rechercher';
	@override String get libraries => 'Bibliothèques';
	@override String get settings => 'Paramètres';
	@override String get downloads => 'Téléchargements';
}

// Path: collections
class _TranslationsCollectionsFr implements TranslationsCollectionsEn {
	_TranslationsCollectionsFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Collections';
	@override String get collection => 'Collection';
	@override String get empty => 'La collection est vide';
	@override String get unknownLibrarySection => 'Impossible de supprimer : section de bibliothèque inconnue';
	@override String get deleteCollection => 'Supprimer la collection';
	@override String deleteConfirm({required Object title}) => 'Êtes-vous sûr de vouloir supprimer "${title}" ? Cette action ne peut pas être annulée.';
	@override String get deleted => 'Collection supprimée';
	@override String get deleteFailed => 'Échec de la suppression de la collection';
	@override String deleteFailedWithError({required Object error}) => 'Échec de la suppression de la collection: ${error}';
	@override String failedToLoadItems({required Object error}) => 'Échec du chargement des éléments de la collection: ${error}';
	@override String get selectCollection => 'Sélectionner une collection';
	@override String get createNewCollection => 'Créer une nouvelle collection';
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
}

// Path: playlists
class _TranslationsPlaylistsFr implements TranslationsPlaylistsEn {
	_TranslationsPlaylistsFr._(this._root);

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
	@override String get selectPlaylist => 'Select Playlist';
	@override String get createNewPlaylist => 'Créer une nouvelle playlist';
	@override String get errorCreating => 'Échec de la création de playlist';
	@override String get errorDeleting => 'Échec de suppression de playlist';
	@override String get errorLoading => 'Échec de chargement de playlists';
	@override String get errorAdding => 'Échec d\'ajout dans la playlist';
	@override String get errorReordering => 'Échec de réordonnacement d\'élément de playlist';
	@override String get errorRemoving => 'Échec de suppression depuis la playlist';
}

// Path: watchTogether
class _TranslationsWatchTogetherFr implements TranslationsWatchTogetherEn {
	_TranslationsWatchTogetherFr._(this._root);

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
	@override String get participant => 'participant';
	@override String get joinWatchSession => 'Rejoindre la session de visionnage';
	@override String get enterCodeHint => 'Entrez le code à 8 caractères';
	@override String get pasteFromClipboard => 'Coller depuis le presse-papiers';
	@override String get pleaseEnterCode => 'Veuillez saisir un code de session';
	@override String get codeMustBe8Chars => 'Le code de session doit comporter 8 caractères';
	@override String get joinInstructions => 'Entrez le code de session partagé par l\'hôte pour rejoindre sa session de visionnage.';
	@override String get failedToCreate => 'Échec de la création de la session';
	@override String get failedToJoin => 'Échec de la connexion à la session';
	@override String get sessionCodeCopied => 'Code de session copié dans le presse-papiers';
}

// Path: downloads
class _TranslationsDownloadsFr implements TranslationsDownloadsEn {
	_TranslationsDownloadsFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Téléchargements';
	@override String get manage => 'Gérer';
	@override String get tvShows => 'Show TV';
	@override String get movies => 'Films';
	@override String get noDownloads => 'Aucun téléchargement pour le moment';
	@override String get noDownloadsDescription => 'Le contenu téléchargé apparaîtra ici pour être consulté hors ligne.';
	@override String get downloadNow => 'Télécharger';
	@override String get deleteDownload => 'Supprimer le téléchargement';
	@override String get retryDownload => 'Réessayer le téléchargement';
	@override String get downloadQueued => 'Téléchargement en attente';
	@override String episodesQueued({required Object count}) => '${count} épisodes en attente de téléchargement';
	@override String get downloadDeleted => 'Télécharger supprimé';
	@override String deleteConfirm({required Object title}) => 'Êtes-vous sûr de vouloir supprimer "${title}" ? Cela supprimera le fichier téléchargé de votre appareil.';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Suppression de ${title}... (${current} sur ${total})';
}

// Path: hotkeys.actions
class _TranslationsHotkeysActionsFr implements TranslationsHotkeysActionsEn {
	_TranslationsHotkeysActionsFr._(this._root);

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
	@override String get speedIncrease => 'Augmenter la vitesse';
	@override String get speedDecrease => 'Réduire la vitesse';
	@override String get speedReset => 'Réinitialiser la vitesse';
	@override String get subSeekNext => 'Rechercher le sous-titre suivant';
	@override String get subSeekPrev => 'Rechercher le sous-titre précédent';
}

// Path: videoControls.pipErrors
class _TranslationsVideoControlsPipErrorsFr implements TranslationsVideoControlsPipErrorsEn {
	_TranslationsVideoControlsPipErrorsFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Nécessite Android 8.0 ou plus récent';
	@override String get permissionDisabled => 'L\'autorisation Image dans l\'image est désactivée. Activez-la dans Paramètres > Applications > Plezy > Image dans l\'image';
	@override String get notSupported => 'Cet appareil ne prend pas en charge le mode image dans l\'image';
	@override String get failed => 'Échec du démarrage du mode image dans l\'image';
	@override String unknown({required Object error}) => 'Une erreur s\'est produite : ${error}';
}

// Path: libraries.tabs
class _TranslationsLibrariesTabsFr implements TranslationsLibrariesTabsEn {
	_TranslationsLibrariesTabsFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Recommandé';
	@override String get browse => 'Parcourir';
	@override String get collections => 'Collections';
	@override String get playlists => 'Playlists';
}

// Path: libraries.groupings
class _TranslationsLibrariesGroupingsFr implements TranslationsLibrariesGroupingsEn {
	_TranslationsLibrariesGroupingsFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get all => 'Tous';
	@override String get movies => 'Films';
	@override String get shows => 'Show TV';
	@override String get seasons => 'Saisons';
	@override String get episodes => 'Épisodes';
	@override String get folders => 'Dossiers';
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
			'app.loading' => 'Chargement...',
			'auth.signInWithPlex' => 'S\'inscrire avec Plex',
			'auth.showQRCode' => 'Afficher le QR Code',
			'auth.cancel' => 'Annuler',
			'auth.authenticate' => 'S\'authentifier',
			'auth.retry' => 'Réessayer',
			'auth.debugEnterToken' => 'Debug: Entrez votre token Plex',
			'auth.plexTokenLabel' => 'Token d\'authentification Plex',
			'auth.plexTokenHint' => 'Entrez votre token Plex.tv',
			'auth.authenticationTimeout' => 'Délai d\'authentification expiré. Veuillez réessayer.',
			'auth.scanQRCodeInstruction' => 'Scannez ce code QR avec un appareil connecté à Plex pour vous authentifier.',
			'auth.waitingForAuth' => 'En attente d\'authentification...\nVeuillez vous connecter dans votre navigateur.',
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
			'common.shuffle' => 'Mélanger',
			'common.addTo' => 'Ajouter à...',
			'screens.licenses' => 'Licenses',
			'screens.switchProfile' => 'Changer de profil',
			'screens.subtitleStyling' => 'Configuration des sous-titres',
			'screens.mpvConfig' => 'Configuration MPV',
			'screens.search' => 'Recherche',
			'screens.logs' => 'Logs',
			'update.available' => 'Mise à jour disponible',
			'update.versionAvailable' => ({required Object version}) => 'Version ${version} disponible',
			'update.currentVersion' => ({required Object version}) => 'Installé: ${version}',
			'update.skipVersion' => 'Ignorer cette version',
			'update.viewRelease' => 'Voir la Release',
			'update.latestVersion' => 'Vous utilisez la dernière version',
			'update.checkFailed' => 'Échec de la vérification des mises à jour',
			'settings.title' => 'Paramètres',
			'settings.language' => 'Langue',
			'settings.theme' => 'Thème',
			'settings.appearance' => 'Apparence',
			'settings.videoPlayback' => 'Lecture vidéo',
			'settings.advanced' => 'Avancé',
			'settings.episodePosterMode' => 'Style du Poster d\'épisode',
			'settings.seriesPoster' => 'Poster de série',
			'settings.seriesPosterDescription' => 'Afficher le poster de série pour tous les épisodes',
			'settings.seasonPoster' => 'Poster de saison',
			'settings.seasonPosterDescription' => 'Afficher le poster spécifique à la saison pour les épisodes',
			'settings.episodeThumbnail' => 'Mignature d\'épisode',
			'settings.episodeThumbnailDescription' => 'Afficher les vignettes des captures d\'écran des épisodes au format 16:9',
			'settings.showHeroSectionDescription' => 'Afficher le carrousel de contenu en vedette sur l\'écran d\'accueil',
			'settings.secondsLabel' => 'Secondes',
			'settings.minutesLabel' => 'Minutes',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'm',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Entrez la durée (${min}-${max})',
			'settings.systemTheme' => 'Système',
			'settings.systemThemeDescription' => 'Suivre les paramètres système',
			'settings.lightTheme' => 'Light',
			'settings.darkTheme' => 'Dark',
			'settings.libraryDensity' => 'Densité des bibliothèques',
			'settings.compact' => 'Compact',
			'settings.compactDescription' => 'Cartes plus petites, plus d\'éléments visibles',
			'settings.normal' => 'Normal',
			'settings.normalDescription' => 'Taille par défaut',
			'settings.comfortable' => 'Confortable',
			'settings.comfortableDescription' => 'Cartes plus grandes, moins d\'éléments visibles',
			'settings.viewMode' => 'Mode d\'affichage',
			'settings.gridView' => 'Grille',
			'settings.gridViewDescription' => 'Afficher les éléments dans une disposition en grille',
			'settings.listView' => 'Liste',
			'settings.listViewDescription' => 'Afficher les éléments dans une liste',
			'settings.showHeroSection' => 'Afficher la section Hero',
			'settings.useGlobalHubs' => 'Utiliser la disposition Plex Home',
			'settings.useGlobalHubsDescription' => 'Afficher les hubs de la page d\'accueil comme le client Plex officiel. Lorsque cette option est désactivée, affiche à la place les recommandations par bibliothèque.',
			'settings.showServerNameOnHubs' => 'Afficher le nom du serveur sur les hubs',
			'settings.showServerNameOnHubsDescription' => 'Toujours afficher le nom du serveur dans les titres des hubs. Lorsque cette option est désactivée, seuls les noms de hubs en double s\'affichent.',
			'settings.playerBackend' => 'Moteur de lecture',
			'settings.exoPlayer' => 'ExoPlayer (Recommandé)',
			'settings.exoPlayerDescription' => 'Lecteur natif Android avec meilleur support matériel',
			'settings.mpv' => 'MPV',
			'settings.mpvDescription' => 'Lecteur avancé avec plus de fonctionnalités et support des sous-titres ASS',
			'settings.hardwareDecoding' => 'Décodage matériel',
			'settings.hardwareDecodingDescription' => 'Utilisez l\'accélération matérielle lorsqu\'elle est disponible.',
			'settings.bufferSize' => 'Taille du Buffer',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}MB',
			'settings.subtitleStyling' => 'Stylisation des sous-titres',
			'settings.subtitleStylingDescription' => 'Personnaliser l\'apparence des sous-titres',
			'settings.smallSkipDuration' => 'Small Skip Duration',
			'settings.largeSkipDuration' => 'Large Skip Duration',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} secondes',
			'settings.defaultSleepTimer' => 'Minuterie de mise en veille par défaut',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} minutes',
			'settings.rememberTrackSelections' => 'Mémoriser les sélections de pistes par émission/film',
			'settings.rememberTrackSelectionsDescription' => 'Enregistrer automatiquement les préférences linguistiques pour l\'audio et les sous-titres lorsque vous changez de piste pendant la lecture',
			'settings.clickVideoTogglesPlayback' => 'Cliquez sur la vidéo pour basculer entre lecture et pause.',
			'settings.clickVideoTogglesPlaybackDescription' => 'Si cette option est activée, cliquer sur le lecteur vidéo lancera ou mettra en pause la vidéo. Sinon, le clic affichera ou masquera les commandes de lecture.',
			'settings.videoPlayerControls' => 'Commandes du lecteur vidéo',
			'settings.keyboardShortcuts' => 'Raccourcis clavier',
			'settings.keyboardShortcutsDescription' => 'Personnaliser les raccourcis clavier',
			'settings.videoPlayerNavigation' => 'Navigation dans le lecteur vidéo',
			'settings.videoPlayerNavigationDescription' => 'Utilisez les touches fléchées pour naviguer dans les commandes du lecteur vidéo.',
			'settings.debugLogging' => 'Journalisation de débogage',
			'settings.debugLoggingDescription' => 'Activer la journalisation détaillée pour le dépannage',
			'settings.viewLogs' => 'Voir les logs',
			'settings.viewLogsDescription' => 'Voir les logs d\'application',
			'settings.clearCache' => 'Vider le cache',
			'settings.clearCacheDescription' => 'Cela effacera toutes les images et données mises en cache. Le chargement du contenu de l\'application peut prendre plus de temps après avoir effacé le cache.',
			'settings.clearCacheSuccess' => 'Cache effacé avec succès',
			'settings.resetSettings' => 'Réinitialiser les paramètres',
			'settings.resetSettingsDescription' => 'Cela réinitialisera tous les paramètres à leurs valeurs par défaut. Cette action ne peut pas être annulée.',
			'settings.resetSettingsSuccess' => 'Réinitialisation des paramètres réussie',
			'settings.shortcutsReset' => 'Raccourcis réinitialisés aux valeurs par défaut',
			'settings.about' => 'À propos',
			'settings.aboutDescription' => 'Informations sur l\'application et licences',
			'settings.updates' => 'Mises à jour',
			'settings.updateAvailable' => 'Mise à jour disponible',
			'settings.checkForUpdates' => 'Vérifier les mises à jour',
			'settings.validationErrorEnterNumber' => 'Veuillez saisir un numéro valide',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'La durée doit être comprise entre ${min} et ${max} ${unit}',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Raccourci déjà attribué à ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Raccourci mis à jour pour ${action}',
			'settings.autoSkip' => 'Skip automatique',
			'settings.autoSkipIntro' => 'Skip automatique de l\'introduction',
			'settings.autoSkipIntroDescription' => 'Skipper automatiquement l\'introduction après quelques secondes',
			'settings.autoSkipCredits' => 'Skip automatique des crédits',
			'settings.autoSkipCreditsDescription' => 'Passer les crédits et passer à l\'épisode suivant automatiquement',
			'settings.autoSkipDelay' => 'Délai avant skip automatique',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Attendre ${seconds} secondes avant l\'auto-skip',
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
			'settings.cellularDownloadBlocked' => 'Les téléchargements sont désactivés sur les données cellulaires. Connectez-vous au Wi-Fi ou modifiez le paramètre.',
			'settings.maxVolume' => 'Volume maximal',
			'settings.maxVolumeDescription' => 'Autoriser l\'augmentation du volume au-delà de 100 % pour les médias silencieux',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.maxVolumeHint' => 'Entrez le volume maximal (100-300)',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Montrez ce que vous regardez sur Discord',
			'settings.matchContentFrameRate' => 'Fréquence d\'images du contenu correspondant',
			'settings.matchContentFrameRateDescription' => 'Ajustez la fréquence de rafraîchissement de l\'écran en fonction du contenu vidéo, ce qui réduit les saccades et économise la batterie',
			'search.hint' => 'Rechercher des films, des séries, de la musique...',
			'search.tryDifferentTerm' => 'Essayez un autre terme de recherche',
			'search.searchYourMedia' => 'Rechercher dans vos médias',
			'search.enterTitleActorOrKeyword' => 'Entrez un titre, un acteur ou un mot-clé',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'Définir un raccourci pour ${actionName}',
			'hotkeys.clearShortcut' => 'Effacer le raccourci',
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
			'hotkeys.actions.speedIncrease' => 'Augmenter la vitesse',
			'hotkeys.actions.speedDecrease' => 'Réduire la vitesse',
			'hotkeys.actions.speedReset' => 'Réinitialiser la vitesse',
			'hotkeys.actions.subSeekNext' => 'Rechercher le sous-titre suivant',
			'hotkeys.actions.subSeekPrev' => 'Rechercher le sous-titre précédent',
			'pinEntry.enterPin' => 'Entrer le code PIN',
			'pinEntry.showPin' => 'Afficher le code PIN',
			'pinEntry.hidePin' => 'Masquer le code PIN',
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
			'fileInfo.channels' => 'Channels',
			'fileInfo.path' => 'Chemin',
			'fileInfo.size' => 'Taille',
			'fileInfo.container' => 'Conteneur',
			'fileInfo.duration' => 'Durée',
			'fileInfo.optimizedForStreaming' => 'Optimisé pour le streaming',
			'fileInfo.has64bitOffsets' => 'Décalages 64 bits',
			'mediaMenu.markAsWatched' => 'Marquer comme vu',
			'mediaMenu.markAsUnwatched' => 'Marquer comme non visionné',
			'mediaMenu.removeFromContinueWatching' => 'Supprimer de la liste "Continuer à regarder"',
			'mediaMenu.goToSeries' => 'Aller à la série',
			'mediaMenu.goToSeason' => 'Aller à la saison',
			'mediaMenu.shufflePlay' => 'Lecture aléatoire',
			'mediaMenu.fileInfo' => 'Informations sur le fichier',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, film',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, show TV',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'visionné',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} pourcentage visionné',
			'accessibility.mediaCardUnwatched' => 'non visionné',
			'accessibility.tapToPlay' => 'Appuyez pour lire',
			'tooltips.shufflePlay' => 'Lecture aléatoire',
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
			'videoControls.sleepTimer' => 'Minuterie de mise en veille',
			'videoControls.timerActive' => 'Minuterie active',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'La lecture sera mise en pause dans ${duration}',
			'videoControls.sleepTimerCompleted' => 'Minuterie de mise en veille terminée - lecture en pause',
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
			'videoControls.settingsButton' => 'Paramètres vidéo',
			'videoControls.audioTrackButton' => 'Pistes audio',
			'videoControls.subtitlesButton' => 'Sous-titres',
			'videoControls.chaptersButton' => 'Chapitres',
			'videoControls.versionsButton' => 'Versions vidéo',
			'videoControls.pipButton' => 'Mode PiP (Picture-in-Picture)',
			'videoControls.aspectRatioButton' => 'Format d\'image',
			'videoControls.fullscreenButton' => 'Passer en mode plein écran',
			'videoControls.exitFullscreenButton' => 'Quitter le mode plein écran',
			'videoControls.alwaysOnTopButton' => 'Always on top',
			'videoControls.rotationLockButton' => 'Verrouillage de rotation',
			'videoControls.timelineSlider' => 'Timeline vidéo',
			'videoControls.volumeSlider' => 'Niveau sonore',
			'videoControls.backButton' => 'Retour',
			'videoControls.pipFailed' => 'Échec du démarrage du mode image dans l\'image',
			'videoControls.pipErrors.androidVersion' => 'Nécessite Android 8.0 ou plus récent',
			'videoControls.pipErrors.permissionDisabled' => 'L\'autorisation Image dans l\'image est désactivée. Activez-la dans Paramètres > Applications > Plezy > Image dans l\'image',
			'videoControls.pipErrors.notSupported' => 'Cet appareil ne prend pas en charge le mode image dans l\'image',
			'videoControls.pipErrors.failed' => 'Échec du démarrage du mode image dans l\'image',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Une erreur s\'est produite : ${error}',
			'userStatus.admin' => 'Admin',
			'userStatus.restricted' => 'Restreint',
			'userStatus.protected' => 'Protégé',
			'userStatus.current' => 'ACTUEL',
			'messages.markedAsWatched' => 'Marqué comme vu',
			'messages.markedAsUnwatched' => 'Marqué comme non vu',
			'messages.markedAsWatchedOffline' => 'Marqué comme vu (se synchronisera lorsque vous serez en ligne)',
			'messages.markedAsUnwatchedOffline' => 'Marqué comme non vu (sera synchronisé lorsque vous serez en ligne)',
			'messages.removedFromContinueWatching' => 'Supprimer de "Continuer à regarder"',
			'messages.errorLoading' => ({required Object error}) => 'Erreur: ${error}',
			'messages.fileInfoNotAvailable' => 'Informations sur le fichier non disponibles',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Erreur lors du chargement des informations sur le fichier: ${error}',
			'messages.errorLoadingSeries' => 'Erreur lors du chargement de la série',
			'messages.errorLoadingSeason' => 'Erreur lors du chargement de la saison',
			'messages.musicNotSupported' => 'La lecture de musique n\'est pas encore prise en charge',
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
			'messages.noEpisodesFound' => 'Aucun épisode trouvé dans la première saison',
			'messages.noEpisodesFoundGeneral' => 'Aucun épisode trouvé',
			'messages.noResultsFound' => 'Aucun résultat trouvé',
			'messages.sleepTimerSet' => ({required Object label}) => 'Minuterie de mise en veille réglée sur ${label}',
			'messages.noItemsAvailable' => 'Aucun élément disponible',
			'messages.failedToCreatePlayQueue' => 'Échec de la création de la file d\'attente de lecture',
			'messages.failedToCreatePlayQueueNoItems' => 'Échec de la création de la file d\'attente de lecture - aucun élément',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Echec de ${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Passage au lecteur compatible...',
			'subtitlingStyling.stylingOptions' => 'Options de style',
			'subtitlingStyling.fontSize' => 'Taille de la police',
			'subtitlingStyling.textColor' => 'Couleur du texte',
			'subtitlingStyling.borderSize' => 'Taille de la bordure',
			'subtitlingStyling.borderColor' => 'Couleur de la bordure',
			'subtitlingStyling.backgroundOpacity' => 'Opacité d\'arrière-plan',
			'subtitlingStyling.backgroundColor' => 'Couleur d\'arrière-plan',
			'mpvConfig.title' => 'Configuration MPV',
			'mpvConfig.description' => 'Paramètres avancés du lecteur vidéo',
			'mpvConfig.properties' => 'Propriétés',
			'mpvConfig.presets' => 'Préréglages',
			'mpvConfig.noProperties' => 'Aucune propriété configurée',
			'mpvConfig.noPresets' => 'Aucun préréglage enregistré',
			'mpvConfig.addProperty' => 'Ajouter une propriété',
			'mpvConfig.editProperty' => 'Modifier la propriété',
			'mpvConfig.deleteProperty' => 'Supprimer la propriété',
			'mpvConfig.propertyKey' => 'Clé',
			'mpvConfig.propertyKeyHint' => 'e.g., hwdec, demuxer-max-bytes',
			'mpvConfig.propertyValue' => 'Valeur',
			'mpvConfig.propertyValueHint' => 'e.g., auto, 256000000',
			'mpvConfig.saveAsPreset' => 'Enregistrer comme préréglage...',
			'mpvConfig.presetName' => 'Nom du préréglage',
			'mpvConfig.presetNameHint' => 'Entrez un nom pour ce préréglage',
			'mpvConfig.loadPreset' => 'Charger',
			'mpvConfig.deletePreset' => 'Supprimer',
			'mpvConfig.presetSaved' => 'Préréglage enregistré',
			'mpvConfig.presetLoaded' => 'Préréglage chargé',
			'mpvConfig.presetDeleted' => 'Préréglage supprimé',
			'mpvConfig.confirmDeletePreset' => 'Êtes-vous sûr de vouloir supprimer ce préréglage ?',
			'mpvConfig.confirmDeleteProperty' => 'Êtes-vous sûr de vouloir supprimer cette propriété ?',
			'mpvConfig.entriesCount' => ({required Object count}) => '${count} entrées',
			'dialog.confirmAction' => 'Confirmer l\'action',
			'dialog.cancel' => 'Annuler',
			'dialog.playNow' => 'Lire maintenant',
			'discover.title' => 'Découvrez',
			'discover.switchProfile' => 'Changer de profil',
			'discover.logout' => 'Déconnexion',
			'discover.noContentAvailable' => 'Aucun contenu disponible',
			'discover.addMediaToLibraries' => 'Ajoutez des médias à votre bibliothèque',
			'discover.continueWatching' => 'Continuer à regarder',
			'discover.play' => 'Lire',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.pause' => 'Pause',
			'discover.overview' => 'Aperçu',
			'discover.cast' => 'Cast',
			'discover.seasons' => 'Saisons',
			'discover.studio' => 'Studio',
			'discover.rating' => 'Évaluation',
			'discover.watched' => 'Vu',
			'discover.episodeCount' => ({required Object count}) => '${count} épisodes',
			'discover.watchedProgress' => ({required Object watched, required Object total}) => '${watched}/${total} vu',
			'discover.movie' => 'Film',
			'discover.tvShow' => 'Show TV',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} min restantes',
			'errors.searchFailed' => ({required Object error}) => 'Recherche échouée: ${error}',
			'errors.connectionTimeout' => ({required Object context}) => 'Délai d\'attente de connexion dépassé pendant le chargement ${context}',
			'errors.connectionFailed' => 'Impossible de se connecter au serveur Plex',
			'errors.failedToLoad' => ({required Object context, required Object error}) => 'Échec du chargement ${context}: ${error}',
			'errors.noClientAvailable' => 'Aucun client disponible',
			'errors.authenticationFailed' => ({required Object error}) => 'Échec de l\'authentification: ${error}',
			'errors.couldNotLaunchUrl' => 'Impossible de lancer l\'URL d\'authentification',
			'errors.pleaseEnterToken' => 'Veuillez saisir un token',
			'errors.invalidToken' => 'Token invalide',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Échec de la vérification du token: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Impossible de changer de profil vers ${displayName}',
			'libraries.title' => 'Bibliothèques',
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
			'libraries.thisLibraryIsEmpty' => 'Cette bibliothèque est vide',
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
			'libraries.groupings.all' => 'Tous',
			'libraries.groupings.movies' => 'Films',
			'libraries.groupings.shows' => 'Show TV',
			'libraries.groupings.seasons' => 'Saisons',
			'libraries.groupings.episodes' => 'Épisodes',
			'libraries.groupings.folders' => 'Dossiers',
			'about.title' => 'À propos',
			'about.openSourceLicenses' => 'Licences Open Source',
			'about.versionLabel' => ({required Object version}) => 'Version ${version}',
			'about.appDescription' => 'Un magnifique client Plex pour Flutter',
			'about.viewLicensesDescription' => 'Afficher les licences des bibliothèques tierces',
			'serverSelection.allServerConnectionsFailed' => 'Impossible de se connecter à un serveur. Veuillez vérifier votre connexion réseau et réessayer.',
			'serverSelection.noServersFound' => 'Aucun serveur trouvé',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'Aucun serveur trouvé pour ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Échec du chargement des serveurs: ${error}',
			'hubDetail.title' => 'Titre',
			'hubDetail.releaseYear' => 'Année de sortie',
			'hubDetail.dateAdded' => 'Date d\'ajout',
			'hubDetail.rating' => 'Évaluation',
			'hubDetail.noItemsFound' => 'Aucun élément trouvé',
			'logs.clearLogs' => 'Effacer les logs',
			'logs.copyLogs' => 'Copier les logs',
			'logs.error' => 'Erreur:',
			'logs.stackTrace' => 'Liste des appels:',
			'licenses.relatedPackages' => 'Package associés',
			'licenses.license' => 'Licence',
			'licenses.licenseNumber' => ({required Object number}) => 'Licence ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} licences',
			'navigation.home' => 'Accueil',
			'navigation.search' => 'Rechercher',
			'navigation.libraries' => 'Bibliothèques',
			'navigation.settings' => 'Paramètres',
			'navigation.downloads' => 'Téléchargements',
			'collections.title' => 'Collections',
			'collections.collection' => 'Collection',
			'collections.empty' => 'La collection est vide',
			'collections.unknownLibrarySection' => 'Impossible de supprimer : section de bibliothèque inconnue',
			'collections.deleteCollection' => 'Supprimer la collection',
			'collections.deleteConfirm' => ({required Object title}) => 'Êtes-vous sûr de vouloir supprimer "${title}" ? Cette action ne peut pas être annulée.',
			'collections.deleted' => 'Collection supprimée',
			'collections.deleteFailed' => 'Échec de la suppression de la collection',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Échec de la suppression de la collection: ${error}',
			'collections.failedToLoadItems' => ({required Object error}) => 'Échec du chargement des éléments de la collection: ${error}',
			'collections.selectCollection' => 'Sélectionner une collection',
			'collections.createNewCollection' => 'Créer une nouvelle collection',
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
			'playlists.selectPlaylist' => 'Select Playlist',
			'playlists.createNewPlaylist' => 'Créer une nouvelle playlist',
			'playlists.errorCreating' => 'Échec de la création de playlist',
			'playlists.errorDeleting' => 'Échec de suppression de playlist',
			'playlists.errorLoading' => 'Échec de chargement de playlists',
			'playlists.errorAdding' => 'Échec d\'ajout dans la playlist',
			'playlists.errorReordering' => 'Échec de réordonnacement d\'élément de playlist',
			'playlists.errorRemoving' => 'Échec de suppression depuis la playlist',
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
			'watchTogether.hostControlsPlayback' => 'L\'hôte contrôle la lecture',
			'watchTogether.anyoneCanControl' => 'Tout le monde peut contrôler la lecture',
			'watchTogether.hostControls' => 'Commandes de l\'hôte',
			'watchTogether.anyoneControls' => 'Tout le monde contrôle',
			'watchTogether.participants' => 'Participants',
			_ => null,
		} ?? switch (path) {
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
			'watchTogether.participant' => 'participant',
			'watchTogether.joinWatchSession' => 'Rejoindre la session de visionnage',
			'watchTogether.enterCodeHint' => 'Entrez le code à 8 caractères',
			'watchTogether.pasteFromClipboard' => 'Coller depuis le presse-papiers',
			'watchTogether.pleaseEnterCode' => 'Veuillez saisir un code de session',
			'watchTogether.codeMustBe8Chars' => 'Le code de session doit comporter 8 caractères',
			'watchTogether.joinInstructions' => 'Entrez le code de session partagé par l\'hôte pour rejoindre sa session de visionnage.',
			'watchTogether.failedToCreate' => 'Échec de la création de la session',
			'watchTogether.failedToJoin' => 'Échec de la connexion à la session',
			'watchTogether.sessionCodeCopied' => 'Code de session copié dans le presse-papiers',
			'downloads.title' => 'Téléchargements',
			'downloads.manage' => 'Gérer',
			'downloads.tvShows' => 'Show TV',
			'downloads.movies' => 'Films',
			'downloads.noDownloads' => 'Aucun téléchargement pour le moment',
			'downloads.noDownloadsDescription' => 'Le contenu téléchargé apparaîtra ici pour être consulté hors ligne.',
			'downloads.downloadNow' => 'Télécharger',
			'downloads.deleteDownload' => 'Supprimer le téléchargement',
			'downloads.retryDownload' => 'Réessayer le téléchargement',
			'downloads.downloadQueued' => 'Téléchargement en attente',
			'downloads.episodesQueued' => ({required Object count}) => '${count} épisodes en attente de téléchargement',
			'downloads.downloadDeleted' => 'Télécharger supprimé',
			'downloads.deleteConfirm' => ({required Object title}) => 'Êtes-vous sûr de vouloir supprimer "${title}" ? Cela supprimera le fichier téléchargé de votre appareil.',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Suppression de ${title}... (${current} sur ${total})',
			_ => null,
		};
	}
}
