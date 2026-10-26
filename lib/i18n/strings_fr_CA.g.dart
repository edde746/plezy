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
import 'strings_fr.g.dart';

// Path: <root>
class TranslationsFrCa extends TranslationsFr with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsFrCa({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.frCa,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <fr-CA>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsFrCa _root = this; // ignore: unused_field

	@override 
	TranslationsFrCa $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsFrCa(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$cast$fr_CA cast = _Translations$cast$fr_CA._(_root);
	@override late final _Translations$appIcon$fr_CA appIcon = _Translations$appIcon$fr_CA._(_root);
	@override late final _Translations$auth$fr_CA auth = _Translations$auth$fr_CA._(_root);
	@override late final _Translations$common$fr_CA common = _Translations$common$fr_CA._(_root);
	@override late final _Translations$screens$fr_CA screens = _Translations$screens$fr_CA._(_root);
	@override late final _Translations$settings$fr_CA settings = _Translations$settings$fr_CA._(_root);
	@override late final _Translations$themeEditor$fr_CA themeEditor = _Translations$themeEditor$fr_CA._(_root);
	@override late final _Translations$search$fr_CA search = _Translations$search$fr_CA._(_root);
	@override late final _Translations$hotkeys$fr_CA hotkeys = _Translations$hotkeys$fr_CA._(_root);
	@override late final _Translations$fileInfo$fr_CA fileInfo = _Translations$fileInfo$fr_CA._(_root);
	@override late final _Translations$mediaMenu$fr_CA mediaMenu = _Translations$mediaMenu$fr_CA._(_root);
	@override late final _Translations$rateSheet$fr_CA rateSheet = _Translations$rateSheet$fr_CA._(_root);
	@override late final _Translations$accessibility$fr_CA accessibility = _Translations$accessibility$fr_CA._(_root);
	@override late final _Translations$videoControls$fr_CA videoControls = _Translations$videoControls$fr_CA._(_root);
	@override late final _Translations$messages$fr_CA messages = _Translations$messages$fr_CA._(_root);
	@override late final _Translations$subtitlingStyling$fr_CA subtitlingStyling = _Translations$subtitlingStyling$fr_CA._(_root);
	@override late final _Translations$mpvConfig$fr_CA mpvConfig = _Translations$mpvConfig$fr_CA._(_root);
	@override late final _Translations$profiles$fr_CA profiles = _Translations$profiles$fr_CA._(_root);
	@override late final _Translations$accountPreferences$fr_CA accountPreferences = _Translations$accountPreferences$fr_CA._(_root);
	@override late final _Translations$discover$fr_CA discover = _Translations$discover$fr_CA._(_root);
	@override late final _Translations$libraries$fr_CA libraries = _Translations$libraries$fr_CA._(_root);
	@override late final _Translations$hubDetail$fr_CA hubDetail = _Translations$hubDetail$fr_CA._(_root);
	@override late final _Translations$navigation$fr_CA navigation = _Translations$navigation$fr_CA._(_root);
	@override late final _Translations$explore$fr_CA explore = _Translations$explore$fr_CA._(_root);
	@override late final _Translations$liveTv$fr_CA liveTv = _Translations$liveTv$fr_CA._(_root);
	@override late final _Translations$collections$fr_CA collections = _Translations$collections$fr_CA._(_root);
	@override late final _Translations$playlists$fr_CA playlists = _Translations$playlists$fr_CA._(_root);
	@override late final _Translations$music$fr_CA music = _Translations$music$fr_CA._(_root);
	@override late final _Translations$watchTogether$fr_CA watchTogether = _Translations$watchTogether$fr_CA._(_root);
	@override late final _Translations$downloads$fr_CA downloads = _Translations$downloads$fr_CA._(_root);
	@override late final _Translations$companionRemote$fr_CA companionRemote = _Translations$companionRemote$fr_CA._(_root);
	@override late final _Translations$videoSettings$fr_CA videoSettings = _Translations$videoSettings$fr_CA._(_root);
	@override late final _Translations$performanceOverlay$fr_CA performanceOverlay = _Translations$performanceOverlay$fr_CA._(_root);
	@override late final _Translations$externalPlayer$fr_CA externalPlayer = _Translations$externalPlayer$fr_CA._(_root);
	@override late final _Translations$metadataEdit$fr_CA metadataEdit = _Translations$metadataEdit$fr_CA._(_root);
	@override late final _Translations$matchScreen$fr_CA matchScreen = _Translations$matchScreen$fr_CA._(_root);
	@override late final _Translations$seerr$fr_CA seerr = _Translations$seerr$fr_CA._(_root);
	@override late final _Translations$services$fr_CA services = _Translations$services$fr_CA._(_root);
	@override late final _Translations$addServer$fr_CA addServer = _Translations$addServer$fr_CA._(_root);
	@override late final _Translations$watchLink$fr_CA watchLink = _Translations$watchLink$fr_CA._(_root);
	@override late final _Translations$homeLayout$fr_CA homeLayout = _Translations$homeLayout$fr_CA._(_root);
	@override late final _Translations$fileSources$fr_CA fileSources = _Translations$fileSources$fr_CA._(_root);
	@override late final _Translations$lending$fr_CA lending = _Translations$lending$fr_CA._(_root);
}

// Path: cast
class _Translations$cast$fr_CA extends Translations$cast$fr {
	_Translations$cast$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Sous-titres';
	@override String get castToDevice => 'Diffuser sur l\'appareil';
}

// Path: appIcon
class _Translations$appIcon$fr_CA extends Translations$appIcon$fr {
	_Translations$appIcon$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get defaultIcon => 'Par défaut';
}

// Path: auth
class _Translations$auth$fr_CA extends Translations$auth$fr {
	_Translations$auth$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get quickConnect => 'Connexion rapide';
	@override String get useQuickConnect => 'Utiliser la connexion rapide';
	@override String get quickConnectCancel => 'Annuler';
}

// Path: common
class _Translations$common$fr_CA extends Translations$common$fr {
	_Translations$common$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Annuler';
	@override String get save => 'Sauvegarder';
	@override String get close => 'Fermer';
	@override String get reset => 'Réinitialiser';
	@override String get submit => 'Soumettre';
	@override String get retry => 'Réessayer';
	@override String get unknown => 'Inconnu';
	@override String get refresh => 'Rafraîchir';
	@override String get yes => 'Oui';
	@override String get no => 'Non';
	@override String get delete => 'Supprimer';
	@override String get edit => 'Modifier';
	@override String get shuffle => 'Lecture aléatoire';
	@override String get connect => 'Connexion';
	@override String get disconnect => 'Déconnecter';
	@override String get play => 'Lire';
	@override String get resume => 'Reprendre la lecture';
	@override String get error => 'Erreur';
	@override String get search => 'Rechercher';
	@override String get home => 'Accueil';
	@override String get back => 'Retour arrière';
	@override String get settings => 'Paramètres';
	@override String get mute => 'Muet';
	@override String get off => 'Désactivé';
	@override String get fullscreen => 'Plein écran';
	@override late final _Translations$common$mediaKind$fr_CA mediaKind = _Translations$common$mediaKind$fr_CA._(_root);
}

// Path: screens
class _Translations$screens$fr_CA extends Translations$screens$fr {
	_Translations$screens$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get subtitleStyling => 'Style des sous-titres';
	@override String get logs => 'Journaux';
}

// Path: settings
class _Translations$settings$fr_CA extends Translations$settings$fr {
	_Translations$settings$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Paramètres';
	@override String get language => 'Langue';
	@override String get theme => 'Thème';
	@override String get advanced => 'Avancé';
	@override String get systemTheme => 'Système';
	@override String get listView => 'Liste';
	@override String get contentScreensaverAllLibraries => 'Toutes les médiathèques';
	@override String get rowSizeLarge => 'Grand';
	@override String get continueWatchingPlay => 'Lire';
	@override String get episodePlay => 'Lire';
	@override String get playbackBufferLarge => 'Grand';
	@override String get playbackBufferExtraLarge => 'Très Grand';
	@override String get musicQualityTitle => 'Qualité de la musique';
	@override String get subtitleStyling => 'Style des sous-titres';
	@override String get cloudBackupUsername => 'Nom d\'utilisateur';
	@override String get cloudBackupPassword => 'Mot de passe';
	@override String get skipMarkerModeOff => 'Désactivé';
	@override String get downloads => 'Téléchargement';
	@override String get audioChannelLimit => 'Chaînes audio';
	@override String get audioChannelLimitStereo => 'Stéréo';
	@override String get hdrSdrConversionDevice => 'Appareil';
	@override String get hdrSdrConversionPlayer => 'Joueur';
	@override String get deinterlaceOff => 'Désactivé';
	@override String get deinterlaceVideo => 'Vidéo';
	@override String get general => 'Général';
	@override String get display => 'Affichage';
	@override String get liveTv => 'Télé en direct';
	@override String get player => 'Joueur';
	@override String get quality => 'Qualité';
	@override String get subtitles => 'Sous-titres';
	@override String get controls => 'Contrôles';
	@override String get scopePlaybackSpeed => 'Vitesse de lecture';
	@override String get scopeAspectRatio => 'Format de l\'image';
	@override String secondsUnit({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(seconds,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} seconde',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} secondes',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} secondes',
	);
	@override String minutesUnit({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(minutes,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minute',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minutes',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minutes',
	);
}

// Path: themeEditor
class _Translations$themeEditor$fr_CA extends Translations$themeEditor$fr {
	_Translations$themeEditor$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get custom => 'Personnalisation';
	@override String get preview => 'Prévisualisation';
	@override late final _Translations$themeEditor$slots$fr_CA slots = _Translations$themeEditor$slots$fr_CA._(_root);
}

// Path: search
class _Translations$search$fr_CA extends Translations$search$fr {
	_Translations$search$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get people => 'Personnes';
}

// Path: hotkeys
class _Translations$hotkeys$fr_CA extends Translations$hotkeys$fr {
	_Translations$hotkeys$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override late final _Translations$hotkeys$actions$fr_CA actions = _Translations$hotkeys$actions$fr_CA._(_root);
}

// Path: fileInfo
class _Translations$fileInfo$fr_CA extends Translations$fileInfo$fr {
	_Translations$fileInfo$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get overview => 'Survol';
	@override String get video => 'Vidéo';
	@override String get subtitles => 'Sous-titres';
	@override String get lyrics => 'Paroles';
	@override String get file => 'Fichier';
	@override String get codecTag => 'Balise de codec';
	@override String get resolution => 'Résolution';
	@override String get bitrate => 'Débit binaire';
	@override String get aspectRatio => 'Format de l\'image';
	@override String get profile => 'Profil';
	@override String get level => 'Niveau';
	@override String get bitDepth => 'Profondeur de couleur';
	@override String get pixelFormat => 'Format de pixel';
	@override String get colorSpace => 'Espace colorimétrique';
	@override String get colorPrimaries => 'Primaires colorimétriques';
	@override String get colorTransfer => 'Transfert de couleur';
	@override String get interlaced => 'Entrelacé';
	@override String get anamorphic => 'Anamorphique';
	@override String get language => 'Langue';
	@override String get channels => 'Chaînes';
	@override String get sampleRate => 'Taux d\'échantillonnage';
	@override String get path => 'Chemin';
	@override String get size => 'Taille';
	@override String get container => 'Conteneur';
	@override String get duration => 'Durée';
	@override String get protocol => 'Protocole';
	@override String get transcoding => 'Transcodage';
	@override String get subtitlesOff => 'Désactivé';
	@override String get flagDefault => 'Par défaut';
	@override String get flagForced => 'Forcé';
	@override String get flagExternal => 'Externe';
}

// Path: mediaMenu
class _Translations$mediaMenu$fr_CA extends Translations$mediaMenu$fr {
	_Translations$mediaMenu$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get deleteEpisodeConfirm => 'Supprimer l’épisode';
	@override String get rate => 'Évaluer';
	@override String get playFromBeginning => 'Lire depuis le début';
}

// Path: rateSheet
class _Translations$rateSheet$fr_CA extends Translations$rateSheet$fr {
	_Translations$rateSheet$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Évaluer';
	@override String get server => 'Serveur';
	@override String get favorite => 'Favori';
}

// Path: accessibility
class _Translations$accessibility$fr_CA extends Translations$accessibility$fr {
	_Translations$accessibility$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get mediaCardWatched => 'Vu';
	@override String get red => 'Rouge';
	@override String get green => 'Vert';
	@override String get blue => 'Bleu';
}

// Path: videoControls
class _Translations$videoControls$fr_CA extends Translations$videoControls$fr {
	_Translations$videoControls$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get subtitlesLabel => 'Sous-titres';
	@override String get stretch => 'Étirer';
	@override String get playNext => 'Lire le suivant';
	@override String get playButton => 'Lire';
	@override String get nextButton => 'Épisode suivant';
	@override String get previousChapterButton => 'Chapitre précédent';
	@override String get nextChapterButton => 'Prochain chapitre';
	@override String get muteButton => 'Muet';
	@override String get unmuteButton => 'Activer le son';
	@override String get qualityColumnHeader => 'Qualité';
	@override String get aspectRatioButton => 'Format de l\'image';
	@override String get language => 'Langue';
	@override String get nextEpisode => 'Épisode suivant';
}

// Path: messages
class _Translations$messages$fr_CA extends Translations$messages$fr {
	_Translations$messages$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get noResultsFound => 'Aucun résultat trouvé.';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$fr_CA extends Translations$subtitlingStyling$fr {
	_Translations$subtitlingStyling$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get text => 'Texte';
	@override String get textColor => 'Couleur du texte';
	@override String get bold => 'Gras';
	@override String get renderResolutionScreen => 'Résolution d\'écran';
	@override String get renderResolutionVideo => 'Résolution vidéo';
}

// Path: mpvConfig
class _Translations$mpvConfig$fr_CA extends Translations$mpvConfig$fr {
	_Translations$mpvConfig$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get deletePreset => 'Supprimer';
}

// Path: profiles
class _Translations$profiles$fr_CA extends Translations$profiles$fr {
	_Translations$profiles$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get delete => 'Supprimer';
	@override String get signOut => 'Se déconnecter';
	@override String get removePin => 'Enlever';
	@override String get add => 'Ajouter';
	@override String get connectionDefault => 'Par défaut';
	@override String get removeConnection => 'Enlever';
}

// Path: accountPreferences
class _Translations$accountPreferences$fr_CA extends Translations$accountPreferences$fr {
	_Translations$accountPreferences$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get preferredAudioLanguage => 'Langue audio préférée';
	@override String get preferredSubtitleLanguage => 'Langue de sous-titres préférée';
	@override late final _Translations$accountPreferences$watchedIndicatorOptions$fr_CA watchedIndicatorOptions = _Translations$accountPreferences$watchedIndicatorOptions$fr_CA._(_root);
}

// Path: discover
class _Translations$discover$fr_CA extends Translations$discover$fr {
	_Translations$discover$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get continueWatching => 'Continuer à visionner';
	@override String get nextUp => 'À suivre';
	@override String get recentlyAdded => 'Récemment ajouté';
	@override String get overview => 'Survol';
	@override String get director => 'Réalisateur';
	@override String get directors => 'Réalisateurs';
	@override String get movie => 'Film';
	@override String get moreLikeThis => 'Similaires';
}

// Path: libraries
class _Translations$libraries$fr_CA extends Translations$libraries$fr {
	_Translations$libraries$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Médiathèques';
	@override String get scanLibrary => 'Scanner la médiathèque';
	@override String get refreshMetadata => 'Actualiser les métadonnées';
	@override String get resetFilters => 'Réinitialiser les filtres';
	@override String get all => 'Tout';
	@override String get sort => 'Trier';
	@override String get sortBy => 'Trier par';
	@override String get filters => 'Filtres';
	@override String get folders => 'Dossiers';
	@override late final _Translations$libraries$tabs$fr_CA tabs = _Translations$libraries$tabs$fr_CA._(_root);
	@override late final _Translations$libraries$groupings$fr_CA groupings = _Translations$libraries$groupings$fr_CA._(_root);
	@override late final _Translations$libraries$filterCategories$fr_CA filterCategories = _Translations$libraries$filterCategories$fr_CA._(_root);
	@override late final _Translations$libraries$sortLabels$fr_CA sortLabels = _Translations$libraries$sortLabels$fr_CA._(_root);
	@override late final _Translations$libraries$advancedFilters$fr_CA advancedFilters = _Translations$libraries$advancedFilters$fr_CA._(_root);
}

// Path: hubDetail
class _Translations$hubDetail$fr_CA extends Translations$hubDetail$fr {
	_Translations$hubDetail$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Titre';
	@override String get dateAdded => 'Date d\'ajout';
}

// Path: navigation
class _Translations$navigation$fr_CA extends Translations$navigation$fr {
	_Translations$navigation$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Médiathèques';
	@override String get downloads => 'Téléchargement';
	@override String get liveTv => 'Télé en direct';
}

// Path: explore
class _Translations$explore$fr_CA extends Translations$explore$fr {
	_Translations$explore$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override late final _Translations$explore$status$fr_CA status = _Translations$explore$status$fr_CA._(_root);
	@override late final _Translations$explore$badge$fr_CA badge = _Translations$explore$badge$fr_CA._(_root);
	@override late final _Translations$explore$format$fr_CA format = _Translations$explore$format$fr_CA._(_root);
	@override late final _Translations$explore$sourceMaterial$fr_CA sourceMaterial = _Translations$explore$sourceMaterial$fr_CA._(_root);
	@override late final _Translations$explore$creditRole$fr_CA creditRole = _Translations$explore$creditRole$fr_CA._(_root);
	@override late final _Translations$explore$detail$fr_CA detail = _Translations$explore$detail$fr_CA._(_root);
}

// Path: liveTv
class _Translations$liveTv$fr_CA extends Translations$liveTv$fr {
	_Translations$liveTv$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Télé en direct';
	@override String get unknownHub => 'Inconnu';
	@override String get live => 'En direct';
	@override String get premiereBadge => 'Nouveau';
	@override String get channelsSection => 'Chaînes';
	@override String get programsSection => 'Programmes';
	@override String get favorites => 'Favoris';
	@override String get record => 'Enregistrer';
	@override String get recordSeries => 'Enregistrer la série';
	@override String get recordings => 'Enregistrements';
	@override String get manageRecording => 'Gérer l\'enregistrement';
	@override String get cancelRecording => 'Annuler l\'enregistrement';
	@override String get recordingScheduled => 'Enregistrement programmé.';
	@override String get editRuleAction => 'Modifier';
}

// Path: collections
class _Translations$collections$fr_CA extends Translations$collections$fr {
	_Translations$collections$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get deleteCollection => 'Supprimer la Collection';
	@override String get removeFromCollection => 'Retirer de la collection';
}

// Path: playlists
class _Translations$playlists$fr_CA extends Translations$playlists$fr {
	_Translations$playlists$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Listes de lecture';
	@override String get playlist => 'Liste de lecture';
	@override String get delete => 'Supprimer la Playlist';
	@override String get removeItem => 'Retirer de la liste de lecture';
}

// Path: music
class _Translations$music$fr_CA extends Translations$music$fr {
	_Translations$music$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get instantMix => 'Mix instantané';
	@override String get playNext => 'Lire le suivant';
	@override String get clearQueue => 'Effacer la file d\'attente';
	@override String get lyrics => 'Paroles';
	@override String get stopPlayback => 'Arrêter la lecture';
	@override String get previousTrack => 'Piste précédente';
	@override String get nextTrack => 'Prochaine piste';
	@override String get repeat => 'Répéter';
	@override String get repeatAll => 'Répéter tous';
	@override String get repeatOne => 'Répéter ce média en boucle';
	@override late final _Translations$music$discography$fr_CA discography = _Translations$music$discography$fr_CA._(_root);
	@override String sleepTimerMinutes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minute',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minutes',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minutes',
	);
}

// Path: watchTogether
class _Translations$watchTogether$fr_CA extends Translations$watchTogether$fr {
	_Translations$watchTogether$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get removeRoom => 'Enlever';
	@override String get hostBadge => 'Hôte';
	@override String get playerIdle => 'Inactif';
	@override String get remove => 'Enlever';
}

// Path: downloads
class _Translations$downloads$fr_CA extends Translations$downloads$fr {
	_Translations$downloads$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Téléchargement';
	@override String get tvShows => 'Séries Télé';
	@override String get movies => 'Films';
	@override String get music => 'Musique';
	@override String get downloadNow => 'Télécharger';
	@override String get downloadQueued => 'Téléchargement en file d\'attente.';
	@override String get deleteAll => 'Tout supprimer';
	@override String get allEpisodes => 'Tous les épisodes';
	@override String get syncRuleAvailable => 'Disponible';
}

// Path: companionRemote
class _Translations$companionRemote$fr_CA extends Translations$companionRemote$fr {
	_Translations$companionRemote$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override late final _Translations$companionRemote$remote$fr_CA remote = _Translations$companionRemote$remote$fr_CA._(_root);
}

// Path: videoSettings
class _Translations$videoSettings$fr_CA extends Translations$videoSettings$fr {
	_Translations$videoSettings$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'Vitesse de lecture';
	@override String get hdrToneMappingPlayer => 'Joueur';
	@override String get audioOutputStereo => 'Stéréo';
	@override String get audioEqualizerActive => 'Personnalisation';
}

// Path: performanceOverlay
class _Translations$performanceOverlay$fr_CA extends Translations$performanceOverlay$fr {
	_Translations$performanceOverlay$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get app => 'Application';
	@override String get sampleRate => 'Taux d\'échantillonnage';
	@override String get player => 'Joueur';
	@override String get playMethod => 'Méthode de lecture';
}

// Path: externalPlayer
class _Translations$externalPlayer$fr_CA extends Translations$externalPlayer$fr {
	_Translations$externalPlayer$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get off => 'Désactivé';
}

// Path: metadataEdit
class _Translations$metadataEdit$fr_CA extends Translations$metadataEdit$fr {
	_Translations$metadataEdit$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'Modifier';
	@override String get screenTitle => 'Modifier les métadonnées';
	@override String get title => 'Titre';
	@override String get sortTitle => 'Titre de tri';
	@override String get originalTitle => 'Titre original';
	@override String get releaseDate => 'Date de sortie';
	@override String get tagline => 'Slogan';
	@override String get poster => 'Affiche';
	@override String get allEpisodes => 'Tous les épisodes';
	@override String get never => 'Jamais';
	@override String get seasons => 'Saisons';
	@override String get hide => 'Cacher';
	@override String get preferredAudioLanguage => 'Langue audio préférée';
	@override String get preferredSubtitleLanguage => 'Langue de sous-titres préférée';
	@override String get tags => 'Étiquettes';
	@override String get director => 'Réalisateur';
	@override String get writer => 'Scénariste';
	@override String get producer => 'Producteur';
}

// Path: matchScreen
class _Translations$matchScreen$fr_CA extends Translations$matchScreen$fr {
	_Translations$matchScreen$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get titleHint => 'Titre';
	@override String get yearHint => 'Année';
	@override String get search => 'Rechercher';
}

// Path: seerr
class _Translations$seerr$fr_CA extends Translations$seerr$fr {
	_Translations$seerr$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get seasons => 'Saisons';
	@override String get advancedOptions => 'Avancé';
	@override String get tags => 'Étiquettes';
	@override String get statusAvailable => 'Disponible';
}

// Path: services
class _Translations$services$fr_CA extends Translations$services$fr {
	_Translations$services$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override late final _Translations$services$libraryFilter$fr_CA libraryFilter = _Translations$services$libraryFilter$fr_CA._(_root);
}

// Path: addServer
class _Translations$addServer$fr_CA extends Translations$addServer$fr {
	_Translations$addServer$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get username => 'Nom d\'utilisateur';
	@override String get password => 'Mot de passe';
	@override String get signIn => 'Se connecter';
}

// Path: watchLink
class _Translations$watchLink$fr_CA extends Translations$watchLink$fr {
	_Translations$watchLink$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get copy => 'Copier';
}

// Path: homeLayout
class _Translations$homeLayout$fr_CA extends Translations$homeLayout$fr {
	_Translations$homeLayout$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get home => 'Accueil';
	@override String get continueWatching => 'Continuer à visionner';
	@override String get recentlyAdded => 'Récemment ajouté';
	@override String get hide => 'Cacher';
	@override String get remove => 'Enlever';
}

// Path: fileSources
class _Translations$fileSources$fr_CA extends Translations$fileSources$fr {
	_Translations$fileSources$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get name => 'Nom';
	@override String get username => 'Nom d\'utilisateur';
	@override String get password => 'Mot de passe';
	@override String get connect => 'Connexion';
	@override String get cancel => 'Annuler';
	@override String get save => 'Sauvegarder';
	@override String get close => 'Fermer';
	@override String get refresh => 'Rafraîchir';
	@override String get continueReading => 'Continuer la lecture';
	@override String get continueListening => 'Reprendre l\'écoute';
	@override String get continueWatching => 'Continuer à visionner';
	@override String get play => 'Lire';
	@override String get stop => 'Arrêt';
	@override String get delete => 'Supprimer';
	@override String get speed => 'Vitesse de lecture';
	@override String get sleepOff => 'Désactivé';
	@override String get fontSize => 'Taille du texte';
	@override String get video => 'Vidéo';
	@override String get all => 'Tout';
	@override String get signIn => 'Se connecter';
	@override String get none => 'Aucun';
	@override String get fullscreen => 'Plein écran';
	@override String get audiobooks => 'Livres audio';
	@override String get leftToRight => 'Gauche à droite';
	@override String get rightToLeft => 'Droite à gauche';
	@override String minutes({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minute',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minutes',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minutes',
	);
	@override String get googleDrive => 'Google Drive';
}

// Path: lending
class _Translations$lending$fr_CA extends Translations$lending$fr {
	_Translations$lending$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Annuler';
}

// Path: common.mediaKind
class _Translations$common$mediaKind$fr_CA extends Translations$common$mediaKind$fr {
	_Translations$common$mediaKind$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get movie => 'Film';
	@override String get season => 'Saison';
	@override String get episode => 'Épisode';
	@override String get artist => 'Artiste';
	@override String get track => 'Piste';
	@override String get playlist => 'Liste de lecture';
	@override String get folder => 'Dossier';
}

// Path: themeEditor.slots
class _Translations$themeEditor$slots$fr_CA extends Translations$themeEditor$slots$fr {
	_Translations$themeEditor$slots$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get text => 'Texte';
}

// Path: hotkeys.actions
class _Translations$hotkeys$actions$fr_CA extends Translations$hotkeys$actions$fr {
	_Translations$hotkeys$actions$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get chapterNext => 'Prochain chapitre';
	@override String get chapterPrevious => 'Chapitre précédent';
	@override String get episodeNext => 'Épisode suivant';
}

// Path: accountPreferences.watchedIndicatorOptions
class _Translations$accountPreferences$watchedIndicatorOptions$fr_CA extends Translations$accountPreferences$watchedIndicatorOptions$fr {
	_Translations$accountPreferences$watchedIndicatorOptions$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get none => 'Jamais';
}

// Path: libraries.tabs
class _Translations$libraries$tabs$fr_CA extends Translations$libraries$tabs$fr {
	_Translations$libraries$tabs$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get browse => 'Parcourir';
	@override String get playlists => 'Listes de lecture';
}

// Path: libraries.groupings
class _Translations$libraries$groupings$fr_CA extends Translations$libraries$groupings$fr {
	_Translations$libraries$groupings$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get all => 'Tout';
	@override String get movies => 'Films';
	@override String get shows => 'Séries Télé';
	@override String get seasons => 'Saisons';
	@override String get episodes => 'Épisodes';
	@override String get artists => 'Artistes';
	@override String get tracks => 'Pistes';
	@override String get folders => 'Dossiers';
}

// Path: libraries.filterCategories
class _Translations$libraries$filterCategories$fr_CA extends Translations$libraries$filterCategories$fr {
	_Translations$libraries$filterCategories$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get year => 'Année';
	@override String get tag => 'Étiquette';
	@override String get unplayed => 'Non lu';
	@override String get favorites => 'Favoris';
}

// Path: libraries.sortLabels
class _Translations$libraries$sortLabels$fr_CA extends Translations$libraries$sortLabels$fr {
	_Translations$libraries$sortLabels$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Titre';
	@override String get dateAdded => 'Date d\'ajout';
	@override String get releaseDate => 'Date de sortie';
	@override String get communityRating => 'Évaluation de la communauté';
	@override String get datePlayed => 'Date d\'écoute';
	@override String get playCount => 'Nombre de lectures';
	@override String get runtime => 'Durée';
	@override String get premiereDate => 'Date de l\'avant-première';
	@override String get airTime => 'Heure de diffusion';
	@override String get random => 'Aléatoire';
	@override String get size => 'Taille';
}

// Path: libraries.advancedFilters
class _Translations$libraries$advancedFilters$fr_CA extends Translations$libraries$advancedFilters$fr {
	_Translations$libraries$advancedFilters$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get yes => 'Oui';
	@override String get no => 'Non';
}

// Path: explore.status
class _Translations$explore$status$fr_CA extends Translations$explore$status$fr {
	_Translations$explore$status$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get ended => 'Terminé';
	@override String get upcoming => 'À venir';
}

// Path: explore.badge
class _Translations$explore$badge$fr_CA extends Translations$explore$badge$fr {
	_Translations$explore$badge$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get available => 'Disponible';
}

// Path: explore.format
class _Translations$explore$format$fr_CA extends Translations$explore$format$fr {
	_Translations$explore$format$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get tv => 'Télé';
	@override String get movie => 'Film';
	@override String get music => 'Musique';
	@override String get other => 'Autre';
}

// Path: explore.sourceMaterial
class _Translations$explore$sourceMaterial$fr_CA extends Translations$explore$sourceMaterial$fr {
	_Translations$explore$sourceMaterial$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get novel => 'Roman';
	@override String get musicRelease => 'Musique';
	@override String get otherMedia => 'Autre';
}

// Path: explore.creditRole
class _Translations$explore$creditRole$fr_CA extends Translations$explore$creditRole$fr {
	_Translations$explore$creditRole$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get actor => 'Acteur';
	@override String get director => 'Réalisateur';
	@override String get writer => 'Scénariste';
	@override String get producer => 'Producteur';
	@override String get creator => 'Créateur';
	@override String get composer => 'Compositeur(trice)';
}

// Path: explore.detail
class _Translations$explore$detail$fr_CA extends Translations$explore$detail$fr {
	_Translations$explore$detail$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get originalTitle => 'Titre original';
	@override String get language => 'Langue';
	@override String get ended => 'Terminé';
	@override String get tags => 'Étiquettes';
	@override String get schedule => 'Planning';
}

// Path: music.discography
class _Translations$music$discography$fr_CA extends Translations$music$discography$fr {
	_Translations$music$discography$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get live => 'En direct';
}

// Path: companionRemote.remote
class _Translations$companionRemote$remote$fr_CA extends Translations$companionRemote$remote$fr {
	_Translations$companionRemote$remote$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get tabPlay => 'Lire';
	@override String get tabMore => 'Plus';
	@override String get tabLibraries => 'Médiathèques';
	@override String get tabSearch => 'Rechercher';
	@override String get tabDownloads => 'Téléchargement';
	@override String get tabSettings => 'Paramètres';
	@override String get previous => 'Précédent';
	@override String get next => 'Suivant';
	@override String get stop => 'Arrêt';
	@override String get volumeDown => 'Bas';
	@override String get volumeUp => 'Haut';
	@override String get fullscreen => 'Plein écran';
	@override String get subtitles => 'Sous-titres';
}

// Path: services.libraryFilter
class _Translations$services$libraryFilter$fr_CA extends Translations$services$libraryFilter$fr {
	_Translations$services$libraryFilter$fr_CA._(TranslationsFrCa root) : this._root = root, super.internal(root);

	final TranslationsFrCa _root; // ignore: unused_field

	// Translations
	@override String get modeBlacklist => 'Liste noire';
	@override String get libraries => 'Médiathèques';
}

/// The flat map containing all translations for locale <fr-CA>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsFrCa {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'cast.subtitle' => 'Sous-titres',
			'cast.castToDevice' => 'Diffuser sur l\'appareil',
			'appIcon.defaultIcon' => 'Par défaut',
			'auth.quickConnect' => 'Connexion rapide',
			'auth.useQuickConnect' => 'Utiliser la connexion rapide',
			'auth.quickConnectCancel' => 'Annuler',
			'common.cancel' => 'Annuler',
			'common.save' => 'Sauvegarder',
			'common.close' => 'Fermer',
			'common.reset' => 'Réinitialiser',
			'common.submit' => 'Soumettre',
			'common.retry' => 'Réessayer',
			'common.unknown' => 'Inconnu',
			'common.refresh' => 'Rafraîchir',
			'common.yes' => 'Oui',
			'common.no' => 'Non',
			'common.delete' => 'Supprimer',
			'common.edit' => 'Modifier',
			'common.shuffle' => 'Lecture aléatoire',
			'common.connect' => 'Connexion',
			'common.disconnect' => 'Déconnecter',
			'common.play' => 'Lire',
			'common.resume' => 'Reprendre la lecture',
			'common.error' => 'Erreur',
			'common.search' => 'Rechercher',
			'common.home' => 'Accueil',
			'common.back' => 'Retour arrière',
			'common.settings' => 'Paramètres',
			'common.mute' => 'Muet',
			'common.off' => 'Désactivé',
			'common.fullscreen' => 'Plein écran',
			'common.mediaKind.movie' => 'Film',
			'common.mediaKind.season' => 'Saison',
			'common.mediaKind.episode' => 'Épisode',
			'common.mediaKind.artist' => 'Artiste',
			'common.mediaKind.track' => 'Piste',
			'common.mediaKind.playlist' => 'Liste de lecture',
			'common.mediaKind.folder' => 'Dossier',
			'screens.subtitleStyling' => 'Style des sous-titres',
			'screens.logs' => 'Journaux',
			'settings.title' => 'Paramètres',
			'settings.language' => 'Langue',
			'settings.theme' => 'Thème',
			'settings.advanced' => 'Avancé',
			'settings.systemTheme' => 'Système',
			'settings.listView' => 'Liste',
			'settings.contentScreensaverAllLibraries' => 'Toutes les médiathèques',
			'settings.rowSizeLarge' => 'Grand',
			'settings.continueWatchingPlay' => 'Lire',
			'settings.episodePlay' => 'Lire',
			'settings.playbackBufferLarge' => 'Grand',
			'settings.playbackBufferExtraLarge' => 'Très Grand',
			'settings.musicQualityTitle' => 'Qualité de la musique',
			'settings.subtitleStyling' => 'Style des sous-titres',
			'settings.cloudBackupUsername' => 'Nom d\'utilisateur',
			'settings.cloudBackupPassword' => 'Mot de passe',
			'settings.skipMarkerModeOff' => 'Désactivé',
			'settings.downloads' => 'Téléchargement',
			'settings.audioChannelLimit' => 'Chaînes audio',
			'settings.audioChannelLimitStereo' => 'Stéréo',
			'settings.hdrSdrConversionDevice' => 'Appareil',
			'settings.hdrSdrConversionPlayer' => 'Joueur',
			'settings.deinterlaceOff' => 'Désactivé',
			'settings.deinterlaceVideo' => 'Vidéo',
			'settings.general' => 'Général',
			'settings.display' => 'Affichage',
			'settings.liveTv' => 'Télé en direct',
			'settings.player' => 'Joueur',
			'settings.quality' => 'Qualité',
			'settings.subtitles' => 'Sous-titres',
			'settings.controls' => 'Contrôles',
			'settings.scopePlaybackSpeed' => 'Vitesse de lecture',
			'settings.scopeAspectRatio' => 'Format de l\'image',
			'settings.secondsUnit' => ({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(seconds, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} seconde', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} secondes', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} secondes', ), 
			'settings.minutesUnit' => ({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(minutes, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minute', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minutes', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minutes', ), 
			'themeEditor.custom' => 'Personnalisation',
			'themeEditor.preview' => 'Prévisualisation',
			'themeEditor.slots.text' => 'Texte',
			'search.people' => 'Personnes',
			'hotkeys.actions.chapterNext' => 'Prochain chapitre',
			'hotkeys.actions.chapterPrevious' => 'Chapitre précédent',
			'hotkeys.actions.episodeNext' => 'Épisode suivant',
			'fileInfo.overview' => 'Survol',
			'fileInfo.video' => 'Vidéo',
			'fileInfo.subtitles' => 'Sous-titres',
			'fileInfo.lyrics' => 'Paroles',
			'fileInfo.file' => 'Fichier',
			'fileInfo.codecTag' => 'Balise de codec',
			'fileInfo.resolution' => 'Résolution',
			'fileInfo.bitrate' => 'Débit binaire',
			'fileInfo.aspectRatio' => 'Format de l\'image',
			'fileInfo.profile' => 'Profil',
			'fileInfo.level' => 'Niveau',
			'fileInfo.bitDepth' => 'Profondeur de couleur',
			'fileInfo.pixelFormat' => 'Format de pixel',
			'fileInfo.colorSpace' => 'Espace colorimétrique',
			'fileInfo.colorPrimaries' => 'Primaires colorimétriques',
			'fileInfo.colorTransfer' => 'Transfert de couleur',
			'fileInfo.interlaced' => 'Entrelacé',
			'fileInfo.anamorphic' => 'Anamorphique',
			'fileInfo.language' => 'Langue',
			'fileInfo.channels' => 'Chaînes',
			'fileInfo.sampleRate' => 'Taux d\'échantillonnage',
			'fileInfo.path' => 'Chemin',
			'fileInfo.size' => 'Taille',
			'fileInfo.container' => 'Conteneur',
			'fileInfo.duration' => 'Durée',
			'fileInfo.protocol' => 'Protocole',
			'fileInfo.transcoding' => 'Transcodage',
			'fileInfo.subtitlesOff' => 'Désactivé',
			'fileInfo.flagDefault' => 'Par défaut',
			'fileInfo.flagForced' => 'Forcé',
			'fileInfo.flagExternal' => 'Externe',
			'mediaMenu.deleteEpisodeConfirm' => 'Supprimer l’épisode',
			'mediaMenu.rate' => 'Évaluer',
			'mediaMenu.playFromBeginning' => 'Lire depuis le début',
			'rateSheet.title' => 'Évaluer',
			'rateSheet.server' => 'Serveur',
			'rateSheet.favorite' => 'Favori',
			'accessibility.mediaCardWatched' => 'Vu',
			'accessibility.red' => 'Rouge',
			'accessibility.green' => 'Vert',
			'accessibility.blue' => 'Bleu',
			'videoControls.subtitlesLabel' => 'Sous-titres',
			'videoControls.stretch' => 'Étirer',
			'videoControls.playNext' => 'Lire le suivant',
			'videoControls.playButton' => 'Lire',
			'videoControls.nextButton' => 'Épisode suivant',
			'videoControls.previousChapterButton' => 'Chapitre précédent',
			'videoControls.nextChapterButton' => 'Prochain chapitre',
			'videoControls.muteButton' => 'Muet',
			'videoControls.unmuteButton' => 'Activer le son',
			'videoControls.qualityColumnHeader' => 'Qualité',
			'videoControls.aspectRatioButton' => 'Format de l\'image',
			'videoControls.language' => 'Langue',
			'videoControls.nextEpisode' => 'Épisode suivant',
			'messages.noResultsFound' => 'Aucun résultat trouvé.',
			'subtitlingStyling.text' => 'Texte',
			'subtitlingStyling.textColor' => 'Couleur du texte',
			'subtitlingStyling.bold' => 'Gras',
			'subtitlingStyling.renderResolutionScreen' => 'Résolution d\'écran',
			'subtitlingStyling.renderResolutionVideo' => 'Résolution vidéo',
			'mpvConfig.deletePreset' => 'Supprimer',
			'profiles.delete' => 'Supprimer',
			'profiles.signOut' => 'Se déconnecter',
			'profiles.removePin' => 'Enlever',
			'profiles.add' => 'Ajouter',
			'profiles.connectionDefault' => 'Par défaut',
			'profiles.removeConnection' => 'Enlever',
			'accountPreferences.preferredAudioLanguage' => 'Langue audio préférée',
			'accountPreferences.preferredSubtitleLanguage' => 'Langue de sous-titres préférée',
			'accountPreferences.watchedIndicatorOptions.none' => 'Jamais',
			'discover.continueWatching' => 'Continuer à visionner',
			'discover.nextUp' => 'À suivre',
			'discover.recentlyAdded' => 'Récemment ajouté',
			'discover.overview' => 'Survol',
			'discover.director' => 'Réalisateur',
			'discover.directors' => 'Réalisateurs',
			'discover.movie' => 'Film',
			'discover.moreLikeThis' => 'Similaires',
			'libraries.title' => 'Médiathèques',
			'libraries.scanLibrary' => 'Scanner la médiathèque',
			'libraries.refreshMetadata' => 'Actualiser les métadonnées',
			'libraries.resetFilters' => 'Réinitialiser les filtres',
			'libraries.all' => 'Tout',
			'libraries.sort' => 'Trier',
			'libraries.sortBy' => 'Trier par',
			'libraries.filters' => 'Filtres',
			'libraries.folders' => 'Dossiers',
			'libraries.tabs.browse' => 'Parcourir',
			'libraries.tabs.playlists' => 'Listes de lecture',
			'libraries.groupings.all' => 'Tout',
			'libraries.groupings.movies' => 'Films',
			'libraries.groupings.shows' => 'Séries Télé',
			'libraries.groupings.seasons' => 'Saisons',
			'libraries.groupings.episodes' => 'Épisodes',
			'libraries.groupings.artists' => 'Artistes',
			'libraries.groupings.tracks' => 'Pistes',
			'libraries.groupings.folders' => 'Dossiers',
			'libraries.filterCategories.year' => 'Année',
			'libraries.filterCategories.tag' => 'Étiquette',
			'libraries.filterCategories.unplayed' => 'Non lu',
			'libraries.filterCategories.favorites' => 'Favoris',
			'libraries.sortLabels.title' => 'Titre',
			'libraries.sortLabels.dateAdded' => 'Date d\'ajout',
			'libraries.sortLabels.releaseDate' => 'Date de sortie',
			'libraries.sortLabels.communityRating' => 'Évaluation de la communauté',
			'libraries.sortLabels.datePlayed' => 'Date d\'écoute',
			'libraries.sortLabels.playCount' => 'Nombre de lectures',
			'libraries.sortLabels.runtime' => 'Durée',
			'libraries.sortLabels.premiereDate' => 'Date de l\'avant-première',
			'libraries.sortLabels.airTime' => 'Heure de diffusion',
			'libraries.sortLabels.random' => 'Aléatoire',
			'libraries.sortLabels.size' => 'Taille',
			'libraries.advancedFilters.yes' => 'Oui',
			'libraries.advancedFilters.no' => 'Non',
			'hubDetail.title' => 'Titre',
			'hubDetail.dateAdded' => 'Date d\'ajout',
			'navigation.libraries' => 'Médiathèques',
			'navigation.downloads' => 'Téléchargement',
			'navigation.liveTv' => 'Télé en direct',
			'explore.status.ended' => 'Terminé',
			'explore.status.upcoming' => 'À venir',
			'explore.badge.available' => 'Disponible',
			'explore.format.tv' => 'Télé',
			'explore.format.movie' => 'Film',
			'explore.format.music' => 'Musique',
			'explore.format.other' => 'Autre',
			'explore.sourceMaterial.novel' => 'Roman',
			'explore.sourceMaterial.musicRelease' => 'Musique',
			'explore.sourceMaterial.otherMedia' => 'Autre',
			'explore.creditRole.actor' => 'Acteur',
			'explore.creditRole.director' => 'Réalisateur',
			'explore.creditRole.writer' => 'Scénariste',
			'explore.creditRole.producer' => 'Producteur',
			'explore.creditRole.creator' => 'Créateur',
			'explore.creditRole.composer' => 'Compositeur(trice)',
			'explore.detail.originalTitle' => 'Titre original',
			'explore.detail.language' => 'Langue',
			'explore.detail.ended' => 'Terminé',
			'explore.detail.tags' => 'Étiquettes',
			'explore.detail.schedule' => 'Planning',
			'liveTv.title' => 'Télé en direct',
			'liveTv.unknownHub' => 'Inconnu',
			'liveTv.live' => 'En direct',
			'liveTv.premiereBadge' => 'Nouveau',
			'liveTv.channelsSection' => 'Chaînes',
			'liveTv.programsSection' => 'Programmes',
			'liveTv.favorites' => 'Favoris',
			'liveTv.record' => 'Enregistrer',
			'liveTv.recordSeries' => 'Enregistrer la série',
			'liveTv.recordings' => 'Enregistrements',
			'liveTv.manageRecording' => 'Gérer l\'enregistrement',
			'liveTv.cancelRecording' => 'Annuler l\'enregistrement',
			'liveTv.recordingScheduled' => 'Enregistrement programmé.',
			'liveTv.editRuleAction' => 'Modifier',
			'collections.deleteCollection' => 'Supprimer la Collection',
			'collections.removeFromCollection' => 'Retirer de la collection',
			'playlists.title' => 'Listes de lecture',
			'playlists.playlist' => 'Liste de lecture',
			'playlists.delete' => 'Supprimer la Playlist',
			'playlists.removeItem' => 'Retirer de la liste de lecture',
			'music.instantMix' => 'Mix instantané',
			'music.playNext' => 'Lire le suivant',
			'music.clearQueue' => 'Effacer la file d\'attente',
			'music.lyrics' => 'Paroles',
			'music.stopPlayback' => 'Arrêter la lecture',
			'music.previousTrack' => 'Piste précédente',
			'music.nextTrack' => 'Prochaine piste',
			'music.repeat' => 'Répéter',
			'music.repeatAll' => 'Répéter tous',
			'music.repeatOne' => 'Répéter ce média en boucle',
			'music.discography.live' => 'En direct',
			'music.sleepTimerMinutes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minute', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minutes', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minutes', ), 
			'watchTogether.removeRoom' => 'Enlever',
			'watchTogether.hostBadge' => 'Hôte',
			'watchTogether.playerIdle' => 'Inactif',
			'watchTogether.remove' => 'Enlever',
			'downloads.title' => 'Téléchargement',
			'downloads.tvShows' => 'Séries Télé',
			'downloads.movies' => 'Films',
			'downloads.music' => 'Musique',
			'downloads.downloadNow' => 'Télécharger',
			'downloads.downloadQueued' => 'Téléchargement en file d\'attente.',
			'downloads.deleteAll' => 'Tout supprimer',
			'downloads.allEpisodes' => 'Tous les épisodes',
			'downloads.syncRuleAvailable' => 'Disponible',
			'companionRemote.remote.tabPlay' => 'Lire',
			'companionRemote.remote.tabMore' => 'Plus',
			'companionRemote.remote.tabLibraries' => 'Médiathèques',
			'companionRemote.remote.tabSearch' => 'Rechercher',
			'companionRemote.remote.tabDownloads' => 'Téléchargement',
			'companionRemote.remote.tabSettings' => 'Paramètres',
			'companionRemote.remote.previous' => 'Précédent',
			'companionRemote.remote.next' => 'Suivant',
			'companionRemote.remote.stop' => 'Arrêt',
			'companionRemote.remote.volumeDown' => 'Bas',
			'companionRemote.remote.volumeUp' => 'Haut',
			'companionRemote.remote.fullscreen' => 'Plein écran',
			'companionRemote.remote.subtitles' => 'Sous-titres',
			'videoSettings.playbackSpeed' => 'Vitesse de lecture',
			'videoSettings.hdrToneMappingPlayer' => 'Joueur',
			'videoSettings.audioOutputStereo' => 'Stéréo',
			'videoSettings.audioEqualizerActive' => 'Personnalisation',
			'performanceOverlay.app' => 'Application',
			'performanceOverlay.sampleRate' => 'Taux d\'échantillonnage',
			'performanceOverlay.player' => 'Joueur',
			'performanceOverlay.playMethod' => 'Méthode de lecture',
			'externalPlayer.off' => 'Désactivé',
			'metadataEdit.editMetadata' => 'Modifier',
			'metadataEdit.screenTitle' => 'Modifier les métadonnées',
			'metadataEdit.title' => 'Titre',
			'metadataEdit.sortTitle' => 'Titre de tri',
			'metadataEdit.originalTitle' => 'Titre original',
			'metadataEdit.releaseDate' => 'Date de sortie',
			'metadataEdit.tagline' => 'Slogan',
			'metadataEdit.poster' => 'Affiche',
			'metadataEdit.allEpisodes' => 'Tous les épisodes',
			'metadataEdit.never' => 'Jamais',
			'metadataEdit.seasons' => 'Saisons',
			'metadataEdit.hide' => 'Cacher',
			'metadataEdit.preferredAudioLanguage' => 'Langue audio préférée',
			'metadataEdit.preferredSubtitleLanguage' => 'Langue de sous-titres préférée',
			'metadataEdit.tags' => 'Étiquettes',
			'metadataEdit.director' => 'Réalisateur',
			'metadataEdit.writer' => 'Scénariste',
			'metadataEdit.producer' => 'Producteur',
			'matchScreen.titleHint' => 'Titre',
			'matchScreen.yearHint' => 'Année',
			'matchScreen.search' => 'Rechercher',
			'seerr.seasons' => 'Saisons',
			'seerr.advancedOptions' => 'Avancé',
			'seerr.tags' => 'Étiquettes',
			'seerr.statusAvailable' => 'Disponible',
			'services.libraryFilter.modeBlacklist' => 'Liste noire',
			'services.libraryFilter.libraries' => 'Médiathèques',
			'addServer.username' => 'Nom d\'utilisateur',
			'addServer.password' => 'Mot de passe',
			'addServer.signIn' => 'Se connecter',
			'watchLink.copy' => 'Copier',
			'homeLayout.home' => 'Accueil',
			'homeLayout.continueWatching' => 'Continuer à visionner',
			'homeLayout.recentlyAdded' => 'Récemment ajouté',
			'homeLayout.hide' => 'Cacher',
			'homeLayout.remove' => 'Enlever',
			'fileSources.name' => 'Nom',
			'fileSources.username' => 'Nom d\'utilisateur',
			'fileSources.password' => 'Mot de passe',
			'fileSources.connect' => 'Connexion',
			'fileSources.cancel' => 'Annuler',
			'fileSources.save' => 'Sauvegarder',
			'fileSources.close' => 'Fermer',
			'fileSources.refresh' => 'Rafraîchir',
			'fileSources.continueReading' => 'Continuer la lecture',
			'fileSources.continueListening' => 'Reprendre l\'écoute',
			'fileSources.continueWatching' => 'Continuer à visionner',
			'fileSources.play' => 'Lire',
			'fileSources.stop' => 'Arrêt',
			'fileSources.delete' => 'Supprimer',
			'fileSources.speed' => 'Vitesse de lecture',
			'fileSources.sleepOff' => 'Désactivé',
			'fileSources.fontSize' => 'Taille du texte',
			'fileSources.video' => 'Vidéo',
			'fileSources.all' => 'Tout',
			'fileSources.signIn' => 'Se connecter',
			'fileSources.none' => 'Aucun',
			'fileSources.fullscreen' => 'Plein écran',
			'fileSources.audiobooks' => 'Livres audio',
			'fileSources.leftToRight' => 'Gauche à droite',
			'fileSources.rightToLeft' => 'Droite à gauche',
			'fileSources.minutes' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minute', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minutes', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minutes', ), 
			'fileSources.googleDrive' => 'Google Drive',
			'lending.cancel' => 'Annuler',
			_ => null,
		};
	}
}
