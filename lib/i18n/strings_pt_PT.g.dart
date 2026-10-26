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
import 'strings_pt.g.dart';

// Path: <root>
class TranslationsPtPt extends TranslationsPt with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsPtPt({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ptPt,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <pt-PT>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsPtPt _root = this; // ignore: unused_field

	@override 
	TranslationsPtPt $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsPtPt(meta: meta ?? this.$meta);

	// Translations
	@override late final Translations$cast$pt_PT cast = Translations$cast$pt_PT.internal(_root);
	@override late final Translations$appIcon$pt_PT appIcon = Translations$appIcon$pt_PT.internal(_root);
	@override late final Translations$auth$pt_PT auth = Translations$auth$pt_PT.internal(_root);
	@override late final Translations$common$pt_PT common = Translations$common$pt_PT.internal(_root);
	@override late final Translations$screens$pt_PT screens = Translations$screens$pt_PT.internal(_root);
	@override late final Translations$settings$pt_PT settings = Translations$settings$pt_PT.internal(_root);
	@override late final Translations$themeEditor$pt_PT themeEditor = Translations$themeEditor$pt_PT.internal(_root);
	@override late final Translations$search$pt_PT search = Translations$search$pt_PT.internal(_root);
	@override late final Translations$hotkeys$pt_PT hotkeys = Translations$hotkeys$pt_PT.internal(_root);
	@override late final Translations$fileInfo$pt_PT fileInfo = Translations$fileInfo$pt_PT.internal(_root);
	@override late final Translations$mediaMenu$pt_PT mediaMenu = Translations$mediaMenu$pt_PT.internal(_root);
	@override late final Translations$rateSheet$pt_PT rateSheet = Translations$rateSheet$pt_PT.internal(_root);
	@override late final Translations$accessibility$pt_PT accessibility = Translations$accessibility$pt_PT.internal(_root);
	@override late final Translations$videoControls$pt_PT videoControls = Translations$videoControls$pt_PT.internal(_root);
	@override late final Translations$messages$pt_PT messages = Translations$messages$pt_PT.internal(_root);
	@override late final Translations$subtitlingStyling$pt_PT subtitlingStyling = Translations$subtitlingStyling$pt_PT.internal(_root);
	@override late final Translations$mpvConfig$pt_PT mpvConfig = Translations$mpvConfig$pt_PT.internal(_root);
	@override late final Translations$profiles$pt_PT profiles = Translations$profiles$pt_PT.internal(_root);
	@override late final Translations$accountPreferences$pt_PT accountPreferences = Translations$accountPreferences$pt_PT.internal(_root);
	@override late final Translations$discover$pt_PT discover = Translations$discover$pt_PT.internal(_root);
	@override late final Translations$libraries$pt_PT libraries = Translations$libraries$pt_PT.internal(_root);
	@override late final Translations$hubDetail$pt_PT hubDetail = Translations$hubDetail$pt_PT.internal(_root);
	@override late final Translations$navigation$pt_PT navigation = Translations$navigation$pt_PT.internal(_root);
	@override late final Translations$explore$pt_PT explore = Translations$explore$pt_PT.internal(_root);
	@override late final Translations$liveTv$pt_PT liveTv = Translations$liveTv$pt_PT.internal(_root);
	@override late final Translations$collections$pt_PT collections = Translations$collections$pt_PT.internal(_root);
	@override late final Translations$playlists$pt_PT playlists = Translations$playlists$pt_PT.internal(_root);
	@override late final Translations$music$pt_PT music = Translations$music$pt_PT.internal(_root);
	@override late final Translations$watchTogether$pt_PT watchTogether = Translations$watchTogether$pt_PT.internal(_root);
	@override late final Translations$downloads$pt_PT downloads = Translations$downloads$pt_PT.internal(_root);
	@override late final Translations$companionRemote$pt_PT companionRemote = Translations$companionRemote$pt_PT.internal(_root);
	@override late final Translations$videoSettings$pt_PT videoSettings = Translations$videoSettings$pt_PT.internal(_root);
	@override late final Translations$performanceOverlay$pt_PT performanceOverlay = Translations$performanceOverlay$pt_PT.internal(_root);
	@override late final Translations$externalPlayer$pt_PT externalPlayer = Translations$externalPlayer$pt_PT.internal(_root);
	@override late final Translations$metadataEdit$pt_PT metadataEdit = Translations$metadataEdit$pt_PT.internal(_root);
	@override late final Translations$matchScreen$pt_PT matchScreen = Translations$matchScreen$pt_PT.internal(_root);
	@override late final Translations$seerr$pt_PT seerr = Translations$seerr$pt_PT.internal(_root);
	@override late final Translations$services$pt_PT services = Translations$services$pt_PT.internal(_root);
	@override late final Translations$addServer$pt_PT addServer = Translations$addServer$pt_PT.internal(_root);
	@override late final Translations$watchLink$pt_PT watchLink = Translations$watchLink$pt_PT.internal(_root);
	@override late final Translations$homeLayout$pt_PT homeLayout = Translations$homeLayout$pt_PT.internal(_root);
	@override late final Translations$fileSources$pt_PT fileSources = Translations$fileSources$pt_PT.internal(_root);
	@override late final Translations$lending$pt_PT lending = Translations$lending$pt_PT.internal(_root);
	@override late final Translations$sourceSetup$pt_PT sourceSetup = Translations$sourceSetup$pt_PT.internal(_root);
}

// Path: cast
class Translations$cast$pt_PT extends Translations$cast$pt {
	Translations$cast$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Legendas';
	@override String get castToDevice => 'Transmitir para dispositivo';
}

// Path: appIcon
class Translations$appIcon$pt_PT extends Translations$appIcon$pt {
	Translations$appIcon$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get defaultIcon => 'Predefinição';
}

// Path: auth
class Translations$auth$pt_PT extends Translations$auth$pt {
	Translations$auth$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get quickConnect => 'Ligação rápida';
	@override String get useQuickConnect => 'Utilizar Ligação rápida';
	@override String get quickConnectCancel => 'Cancelar';
}

// Path: common
class Translations$common$pt_PT extends Translations$common$pt {
	Translations$common$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Cancelar';
	@override String get save => 'Guardar';
	@override String get close => 'Fechar';
	@override String get reset => 'Repor';
	@override String get submit => 'Enviar';
	@override String get retry => 'Tentar novamente';
	@override String get unknown => 'Desconhecido';
	@override String get refresh => 'Atualizar';
	@override String get yes => 'Sim';
	@override String get no => 'Não';
	@override String get delete => 'Eliminar';
	@override String get edit => 'Editar';
	@override String get shuffle => 'Aleatório';
	@override String get connect => 'Ligar';
	@override String get disconnect => 'Desligar';
	@override String get play => 'Reproduzir';
	@override String get pause => 'Pausar';
	@override String get resume => 'Retomar';
	@override String get error => 'Erro';
	@override String get search => 'Pesquisar';
	@override String get home => 'Página inicial';
	@override String get back => 'Voltar';
	@override String get settings => 'Definições';
	@override String get mute => 'Desativar som';
	@override String get off => 'Desativado';
	@override String get fullscreen => 'Ecrã inteiro';
	@override late final Translations$common$mediaKind$pt_PT mediaKind = Translations$common$mediaKind$pt_PT.internal(_root);
}

// Path: screens
class Translations$screens$pt_PT extends Translations$screens$pt {
	Translations$screens$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get subtitleStyling => 'Estilo de legendas';
	@override String get logs => 'Registos';
}

// Path: settings
class Translations$settings$pt_PT extends Translations$settings$pt {
	Translations$settings$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Definições';
	@override String get language => 'Idioma';
	@override String get theme => 'Tema';
	@override String get advanced => 'Definições avançadas';
	@override String get systemTheme => 'Sistema';
	@override String get listView => 'Lista';
	@override String get contentScreensaverAllLibraries => 'Todas as bibliotecas';
	@override String get rowSizeLarge => 'Grande';
	@override String get continueWatchingPlay => 'Reproduzir';
	@override String get episodePlay => 'Reproduzir';
	@override String get visualEffectsAuto => 'Automático';
	@override String get playbackBufferLarge => 'Grande';
	@override String get playbackBufferExtraLarge => 'Extragrande';
	@override String get musicQualityTitle => 'Qualidade da música';
	@override String get subtitleStyling => 'Estilo de legendas';
	@override String get cloudBackupUsername => 'Nome de utilizador';
	@override String get cloudBackupPassword => 'Palavra-passe';
	@override String get skipMarkerModeOff => 'Desativado';
	@override String get downloads => 'Transferências';
	@override String get audioChannelLimit => 'Canais de áudio';
	@override String get audioChannelLimitStereo => 'Estéreo';
	@override String get dvConversionAuto => 'Automático';
	@override String get hdrSdrConversionAuto => 'Automático';
	@override String get hdrSdrConversionDevice => 'Dispositivo';
	@override String get hdrSdrConversionPlayer => 'Leitor';
	@override String get deinterlaceOff => 'Desativado';
	@override String get deinterlaceVideo => 'Vídeo';
	@override String get general => 'Geral';
	@override String get display => 'Visualização';
	@override String get navigation => 'Navegação';
	@override String get liveTv => 'TV em direto';
	@override String get player => 'Leitor';
	@override String get audio => 'Áudio';
	@override String get quality => 'Qualidade';
	@override String get subtitles => 'Legendas';
	@override String get controls => 'Controlos';
	@override String get scopePlaybackSpeed => 'Velocidade de reprodução';
	@override String get scopeAspectRatio => 'Proporção da imagem';
	@override String secondsUnit({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(seconds,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} segundos',
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} segundo',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} segundos',
	);
	@override String minutesUnit({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(minutes,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minutos',
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minuto',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minutos',
	);
}

// Path: themeEditor
class Translations$themeEditor$pt_PT extends Translations$themeEditor$pt {
	Translations$themeEditor$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get custom => 'Personalizado';
	@override String get preview => 'Antevisão';
	@override late final Translations$themeEditor$slots$pt_PT slots = Translations$themeEditor$slots$pt_PT.internal(_root);
}

// Path: search
class Translations$search$pt_PT extends Translations$search$pt {
	Translations$search$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get people => 'Pessoas';
}

// Path: hotkeys
class Translations$hotkeys$pt_PT extends Translations$hotkeys$pt {
	Translations$hotkeys$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override late final Translations$hotkeys$actions$pt_PT actions = Translations$hotkeys$actions$pt_PT.internal(_root);
}

// Path: fileInfo
class Translations$fileInfo$pt_PT extends Translations$fileInfo$pt {
	Translations$fileInfo$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get overview => 'Sinopse';
	@override String get video => 'Vídeo';
	@override String get audio => 'Áudio';
	@override String get subtitles => 'Legendas';
	@override String get lyrics => 'Letras';
	@override String get file => 'Ficheiro';
	@override String get codecTag => 'Etiqueta do codec';
	@override String get resolution => 'Resolução';
	@override String get bitrate => 'Taxa de bits';
	@override String get rotation => 'Rotação';
	@override String get aspectRatio => 'Proporção da imagem';
	@override String get profile => 'Perfil';
	@override String get level => 'Nível';
	@override String get bitDepth => 'Profundidade de bits';
	@override String get pixelFormat => 'Formato dos píxeis';
	@override String get colorSpace => 'Espaço de cor';
	@override String get colorPrimaries => 'Cores primárias';
	@override String get colorTransfer => 'Transferência de cor';
	@override String get interlaced => 'Entrelaçado';
	@override String get anamorphic => 'Anamórfico';
	@override String get language => 'Idioma';
	@override String get channels => 'Canais';
	@override String get sampleRate => 'Taxa de amostragem';
	@override String get path => 'Caminho';
	@override String get size => 'Tamanho';
	@override String get container => 'Contentor';
	@override String get duration => 'Duração';
	@override String get protocol => 'Protocolo';
	@override String get transcoding => 'Transcodificação';
	@override String get subtitlesOff => 'Desativado';
	@override String get flagDefault => 'Predefinição';
	@override String get flagForced => 'Forçado';
	@override String get flagExternal => 'Externo';
}

// Path: mediaMenu
class Translations$mediaMenu$pt_PT extends Translations$mediaMenu$pt {
	Translations$mediaMenu$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get deleteEpisodeConfirm => 'Eliminar episódio';
	@override String get rate => 'Classificar';
	@override String get playFromBeginning => 'Reproduzir do início';
}

// Path: rateSheet
class Translations$rateSheet$pt_PT extends Translations$rateSheet$pt {
	Translations$rateSheet$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Classificar';
	@override String get server => 'Servidor';
	@override String get favorite => 'Favorito';
}

// Path: accessibility
class Translations$accessibility$pt_PT extends Translations$accessibility$pt {
	Translations$accessibility$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get mediaCardWatched => 'Visto';
	@override String get red => 'Vermelho';
	@override String get green => 'Verde';
	@override String get blue => 'Azul';
}

// Path: videoControls
class Translations$videoControls$pt_PT extends Translations$videoControls$pt {
	Translations$videoControls$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Áudio';
	@override String get subtitlesLabel => 'Legendas';
	@override String get stretch => 'Esticar';
	@override String get playNext => 'Reproduzir a seguir';
	@override String get playButton => 'Reproduzir';
	@override String get pauseButton => 'Pausar';
	@override String get nextButton => 'Próximo episódio';
	@override String get previousChapterButton => 'Capítulo anterior';
	@override String get nextChapterButton => 'Próximo capítulo';
	@override String get muteButton => 'Desativar som';
	@override String get unmuteButton => 'Ativar som';
	@override String get versionColumnHeader => 'Versão';
	@override String get qualityColumnHeader => 'Qualidade';
	@override String get aspectRatioButton => 'Proporção da imagem';
	@override String get language => 'Idioma';
	@override String get nextEpisode => 'Próximo episódio';
}

// Path: messages
class Translations$messages$pt_PT extends Translations$messages$pt {
	Translations$messages$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get noResultsFound => 'Sem resultados.';
}

// Path: subtitlingStyling
class Translations$subtitlingStyling$pt_PT extends Translations$subtitlingStyling$pt {
	Translations$subtitlingStyling$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get text => 'Texto';
	@override String get textColor => 'Cor do texto';
	@override String get bold => 'Negrito';
	@override String get renderResolutionScreen => 'Resolução de ecrã';
	@override String get renderResolutionVideo => 'Resolução de vídeo';
}

// Path: mpvConfig
class Translations$mpvConfig$pt_PT extends Translations$mpvConfig$pt {
	Translations$mpvConfig$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get deletePreset => 'Eliminar';
}

// Path: profiles
class Translations$profiles$pt_PT extends Translations$profiles$pt {
	Translations$profiles$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get delete => 'Eliminar';
	@override String get signOut => 'Terminar sessão';
	@override String get removePin => 'Remover';
	@override String get add => 'Adicionar';
	@override String get connectionDefault => 'Predefinição';
	@override String get removeConnection => 'Remover';
}

// Path: accountPreferences
class Translations$accountPreferences$pt_PT extends Translations$accountPreferences$pt {
	Translations$accountPreferences$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get preferredAudioLanguage => 'Idioma de áudio preferido';
	@override String get preferredSubtitleLanguage => 'Idioma preferido das legendas';
	@override late final Translations$accountPreferences$watchedIndicatorOptions$pt_PT watchedIndicatorOptions = Translations$accountPreferences$watchedIndicatorOptions$pt_PT.internal(_root);
}

// Path: discover
class Translations$discover$pt_PT extends Translations$discover$pt {
	Translations$discover$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get continueWatching => 'Continuar a ver';
	@override String get nextUp => 'A seguir';
	@override String get recentlyAdded => 'Adicionados recentemente';
	@override String get overview => 'Sinopse';
	@override String get studio => 'Estúdio';
	@override String get director => 'Realizador';
	@override String get directors => 'Realizadores';
	@override String get movie => 'Filme';
	@override String get moreLikeThis => 'Títulos semelhantes';
	@override late final Translations$discover$findNext$pt_PT findNext = Translations$discover$findNext$pt_PT.internal(_root);
}

// Path: libraries
class Translations$libraries$pt_PT extends Translations$libraries$pt {
	Translations$libraries$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bibliotecas';
	@override String get scanLibrary => 'Analisar biblioteca';
	@override String get refreshMetadata => 'Atualizar metadados';
	@override String get resetFilters => 'Repor filtros';
	@override String get all => 'Todos';
	@override String get sort => 'Ordenar';
	@override String get sortBy => 'Ordenar por';
	@override String get filters => 'Filtros';
	@override String get folders => 'Pastas';
	@override late final Translations$libraries$tabs$pt_PT tabs = Translations$libraries$tabs$pt_PT.internal(_root);
	@override late final Translations$libraries$groupings$pt_PT groupings = Translations$libraries$groupings$pt_PT.internal(_root);
	@override late final Translations$libraries$filterCategories$pt_PT filterCategories = Translations$libraries$filterCategories$pt_PT.internal(_root);
	@override late final Translations$libraries$sortLabels$pt_PT sortLabels = Translations$libraries$sortLabels$pt_PT.internal(_root);
	@override late final Translations$libraries$advancedFilters$pt_PT advancedFilters = Translations$libraries$advancedFilters$pt_PT.internal(_root);
}

// Path: hubDetail
class Translations$hubDetail$pt_PT extends Translations$hubDetail$pt {
	Translations$hubDetail$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Título';
	@override String get dateAdded => 'Data de adição';
}

// Path: navigation
class Translations$navigation$pt_PT extends Translations$navigation$pt {
	Translations$navigation$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Bibliotecas';
	@override String get downloads => 'Transferências';
	@override String get liveTv => 'TV em direto';
}

// Path: explore
class Translations$explore$pt_PT extends Translations$explore$pt {
	Translations$explore$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override late final Translations$explore$status$pt_PT status = Translations$explore$status$pt_PT.internal(_root);
	@override late final Translations$explore$badge$pt_PT badge = Translations$explore$badge$pt_PT.internal(_root);
	@override late final Translations$explore$format$pt_PT format = Translations$explore$format$pt_PT.internal(_root);
	@override late final Translations$explore$sourceMaterial$pt_PT sourceMaterial = Translations$explore$sourceMaterial$pt_PT.internal(_root);
	@override late final Translations$explore$creditRole$pt_PT creditRole = Translations$explore$creditRole$pt_PT.internal(_root);
	@override late final Translations$explore$detail$pt_PT detail = Translations$explore$detail$pt_PT.internal(_root);
}

// Path: liveTv
class Translations$liveTv$pt_PT extends Translations$liveTv$pt {
	Translations$liveTv$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'TV em direto';
	@override String get guide => 'Guia TV';
	@override String get unknownHub => 'Desconhecido';
	@override String get live => 'Direto';
	@override String get premiereBadge => 'Novo';
	@override String get channelsSection => 'Canais';
	@override String get programsSection => 'Programas';
	@override String get favorites => 'Favoritos';
	@override String get record => 'Gravação';
	@override String get recordSeries => 'Gravar série';
	@override String get recordings => 'Gravações';
	@override String get manageRecording => 'Gerir gravação';
	@override String get cancelRecording => 'Cancelar gravação';
	@override String get recordingScheduled => 'Gravação agendada.';
	@override String get editRuleAction => 'Editar';
}

// Path: collections
class Translations$collections$pt_PT extends Translations$collections$pt {
	Translations$collections$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Coleções';
	@override String get collection => 'Coleção';
	@override String get deleteCollection => 'Eliminar coleção';
	@override String get removeFromCollection => 'Remover da coleção';
}

// Path: playlists
class Translations$playlists$pt_PT extends Translations$playlists$pt {
	Translations$playlists$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get delete => 'Eliminar playlist';
	@override String get removeItem => 'Remover da playlist';
}

// Path: music
class Translations$music$pt_PT extends Translations$music$pt {
	Translations$music$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get instantMix => 'Mix instantâneo';
	@override String get playNext => 'Reproduzir a seguir';
	@override String get clearQueue => 'Limpar fila';
	@override String get lyrics => 'Letras';
	@override String get stopPlayback => 'Parar reprodução';
	@override String get previousTrack => 'Faixa anterior';
	@override String get nextTrack => 'Faixa seguinte';
	@override String get repeat => 'Repetir';
	@override String get repeatAll => 'Repetir tudo';
	@override String get repeatOne => 'Repetir o item atual';
	@override late final Translations$music$discography$pt_PT discography = Translations$music$discography$pt_PT.internal(_root);
	@override String sleepTimerMinutes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minutos',
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minuto',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minutos',
	);
}

// Path: watchTogether
class Translations$watchTogether$pt_PT extends Translations$watchTogether$pt {
	Translations$watchTogether$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get removeRoom => 'Remover';
	@override String get hostBadge => 'Servidor';
	@override String get playerIdle => 'Inativo';
	@override String get remove => 'Remover';
}

// Path: downloads
class Translations$downloads$pt_PT extends Translations$downloads$pt {
	Translations$downloads$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Transferências';
	@override String get tvShows => 'Séries';
	@override String get movies => 'Filmes';
	@override String get music => 'Música';
	@override String get downloadNow => 'Transferir';
	@override String get downloadQueued => 'Transferência pendente.';
	@override String get deleteAll => 'Eliminar tudo';
	@override String get allEpisodes => 'Todos os episódios';
	@override String get syncRuleAvailable => 'Disponível';
	@override late final Translations$downloads$groupings$pt_PT groupings = Translations$downloads$groupings$pt_PT.internal(_root);
}

// Path: companionRemote
class Translations$companionRemote$pt_PT extends Translations$companionRemote$pt {
	Translations$companionRemote$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override late final Translations$companionRemote$remote$pt_PT remote = Translations$companionRemote$remote$pt_PT.internal(_root);
}

// Path: videoSettings
class Translations$videoSettings$pt_PT extends Translations$videoSettings$pt {
	Translations$videoSettings$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'Velocidade de reprodução';
	@override String get hdrToneMappingPlayer => 'Leitor';
	@override String get audioOutputStereo => 'Estéreo';
	@override String get audioEqualizerActive => 'Personalizado';
}

// Path: performanceOverlay
class Translations$performanceOverlay$pt_PT extends Translations$performanceOverlay$pt {
	Translations$performanceOverlay$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get performance => 'Desempenho';
	@override String get app => 'Aplicação';
	@override String get rotation => 'Rotação';
	@override String get sampleRate => 'Taxa de amostragem';
	@override String get player => 'Leitor';
	@override String get playMethod => 'Método de reprodução';
}

// Path: externalPlayer
class Translations$externalPlayer$pt_PT extends Translations$externalPlayer$pt {
	Translations$externalPlayer$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get off => 'Desativado';
}

// Path: metadataEdit
class Translations$metadataEdit$pt_PT extends Translations$metadataEdit$pt {
	Translations$metadataEdit$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'Editar';
	@override String get screenTitle => 'Editar metadados';
	@override String get title => 'Título';
	@override String get sortTitle => 'Título para ordenação';
	@override String get originalTitle => 'Título original';
	@override String get releaseDate => 'Data de lançamento';
	@override String get studio => 'Estúdio';
	@override String get tagline => 'Slogan';
	@override String get poster => 'Cartaz';
	@override String get logo => 'Logótipo';
	@override String get allEpisodes => 'Todos os episódios';
	@override String get never => 'Nunca';
	@override String get seasons => 'Temporadas';
	@override String get hide => 'Ocultar';
	@override String get preferredAudioLanguage => 'Idioma de áudio preferido';
	@override String get preferredSubtitleLanguage => 'Idioma preferido das legendas';
	@override String get tags => 'Etiquetas';
	@override String get genre => 'Género';
	@override String get director => 'Realizador';
	@override String get writer => 'Argumentista';
	@override String get producer => 'Produtor';
	@override String get collection => 'Coleção';
}

// Path: matchScreen
class Translations$matchScreen$pt_PT extends Translations$matchScreen$pt {
	Translations$matchScreen$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get titleHint => 'Título';
	@override String get yearHint => 'Ano';
	@override String get search => 'Pesquisar';
}

// Path: seerr
class Translations$seerr$pt_PT extends Translations$seerr$pt {
	Translations$seerr$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get seasons => 'Temporadas';
	@override String get advancedOptions => 'Definições avançadas';
	@override String get tags => 'Etiquetas';
	@override String get statusAvailable => 'Disponível';
}

// Path: services
class Translations$services$pt_PT extends Translations$services$pt {
	Translations$services$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override late final Translations$services$libraryFilter$pt_PT libraryFilter = Translations$services$libraryFilter$pt_PT.internal(_root);
}

// Path: addServer
class Translations$addServer$pt_PT extends Translations$addServer$pt {
	Translations$addServer$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get username => 'Nome de utilizador';
	@override String get password => 'Palavra-passe';
	@override String get signIn => 'Iniciar sessão';
}

// Path: watchLink
class Translations$watchLink$pt_PT extends Translations$watchLink$pt {
	Translations$watchLink$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get copy => 'Copiar';
}

// Path: homeLayout
class Translations$homeLayout$pt_PT extends Translations$homeLayout$pt {
	Translations$homeLayout$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get home => 'Página inicial';
	@override String get continueWatching => 'Continuar a ver';
	@override String get recentlyAdded => 'Adicionados recentemente';
	@override String get hide => 'Ocultar';
	@override String get remove => 'Remover';
}

// Path: fileSources
class Translations$fileSources$pt_PT extends Translations$fileSources$pt {
	Translations$fileSources$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get source => 'Fonte';
	@override String get name => 'Nome';
	@override String get username => 'Nome de utilizador';
	@override String get password => 'Palavra-passe';
	@override String get connect => 'Ligar';
	@override String get cancel => 'Cancelar';
	@override String get save => 'Guardar';
	@override String get close => 'Fechar';
	@override String get refresh => 'Atualizar';
	@override String get continueReading => 'Continuar a ler';
	@override String get continueListening => 'Continuar a ouvir';
	@override String get continueWatching => 'Continuar a ver';
	@override String get play => 'Reproduzir';
	@override String get pause => 'Pausar';
	@override String get stop => 'Parar';
	@override String get delete => 'Eliminar';
	@override String get speed => 'Velocidade de reprodução';
	@override String get sleepOff => 'Desativado';
	@override String get fontSize => 'Tamanho do texto';
	@override String get audio => 'Áudio';
	@override String get video => 'Vídeo';
	@override String get all => 'Todos';
	@override String get signIn => 'Iniciar sessão';
	@override String get none => 'Nenhum';
	@override String get fullscreen => 'Ecrã inteiro';
	@override String get audiobooks => 'Audiolivros';
	@override String get leftToRight => 'Da esquerda para a direita';
	@override String get rightToLeft => 'Da direita para a esquerda';
	@override String minutes({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minutos',
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minuto',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minutos',
	);
	@override String get googleDrive => 'Google Drive';
}

// Path: lending
class Translations$lending$pt_PT extends Translations$lending$pt {
	Translations$lending$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Cancelar';
}

// Path: sourceSetup
class Translations$sourceSetup$pt_PT extends Translations$sourceSetup$pt {
	Translations$sourceSetup$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get subtitleApplyFailed => 'Não foi possível descarregar ou aplicar esta legenda. Verifique a ligação e tente outro resultado.';
	@override String get subtitleSearching => 'A pesquisar no OpenSubtitles';
	@override String subtitleDownloading({required Object title}) => 'A descarregar a legenda: ${title}';
}

// Path: common.mediaKind
class Translations$common$mediaKind$pt_PT extends Translations$common$mediaKind$pt {
	Translations$common$mediaKind$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get movie => 'Filme';
	@override String get season => 'Temporada';
	@override String get episode => 'Episódio';
	@override String get artist => 'Artista';
	@override String get album => 'Álbum';
	@override String get track => 'Faixa';
	@override String get collection => 'Coleção';
	@override String get clip => 'Excerto';
	@override String get photo => 'Fotografia';
	@override String get folder => 'Pasta';
}

// Path: themeEditor.slots
class Translations$themeEditor$slots$pt_PT extends Translations$themeEditor$slots$pt {
	Translations$themeEditor$slots$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get text => 'Texto';
}

// Path: hotkeys.actions
class Translations$hotkeys$actions$pt_PT extends Translations$hotkeys$actions$pt {
	Translations$hotkeys$actions$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get chapterNext => 'Próximo capítulo';
	@override String get chapterPrevious => 'Capítulo anterior';
	@override String get episodeNext => 'Próximo episódio';
}

// Path: accountPreferences.watchedIndicatorOptions
class Translations$accountPreferences$watchedIndicatorOptions$pt_PT extends Translations$accountPreferences$watchedIndicatorOptions$pt {
	Translations$accountPreferences$watchedIndicatorOptions$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get none => 'Nunca';
}

// Path: discover.findNext
class Translations$discover$findNext$pt_PT extends Translations$discover$findNext$pt {
	Translations$discover$findNext$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get chooseHint => 'Abra um título, guarde-o para mais tarde ou passe ao seguinte.';
	@override String get howItWorks => 'Como funciona';
	@override String get swipeHint => 'Deslize a capa na direção de uma seta ou use os botões abaixo.';
	@override String get notNowHelp => 'Ignore este título por agora. Ele continua na sua biblioteca.';
	@override String get saveHelp => 'Guarde-o nas escolhas guardadas deste perfil neste dispositivo. Guardar não inicia uma transferência.';
	@override String get openHelp => 'Selecione a capa para ver os detalhes. Use a ação principal para reproduzir, ler ou abrir o título.';
	@override String get controlsHelp => 'Teclado ou comando: selecione um botão e prima Enter ou Selecionar. Anular restaura a sua última escolha.';
	@override String get artworkLoading => 'A carregar a imagem…';
	@override String get artworkUnavailable => 'Imagem indisponível';
	@override String get savedFeedback => 'Adicionado às escolhas guardadas';
	@override String get skippedFeedback => 'Ignorado por agora';
	@override String get releaseToConfirm => 'Solte para confirmar';
	@override String get remoteHint => 'Capa em foco: ← / → escolher · Selecionar: detalhes · ↑ / ↓ mover o foco';
}

// Path: libraries.tabs
class Translations$libraries$tabs$pt_PT extends Translations$libraries$tabs$pt {
	Translations$libraries$tabs$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get browse => 'Explorar';
	@override String get collections => 'Coleções';
}

// Path: libraries.groupings
class Translations$libraries$groupings$pt_PT extends Translations$libraries$groupings$pt {
	Translations$libraries$groupings$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get all => 'Todos';
	@override String get movies => 'Filmes';
	@override String get shows => 'Séries';
	@override String get seasons => 'Temporadas';
	@override String get episodes => 'Episódios';
	@override String get artists => 'Artistas';
	@override String get albums => 'Álbuns';
	@override String get tracks => 'Faixas';
	@override String get folders => 'Pastas';
}

// Path: libraries.filterCategories
class Translations$libraries$filterCategories$pt_PT extends Translations$libraries$filterCategories$pt {
	Translations$libraries$filterCategories$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get genre => 'Género';
	@override String get year => 'Ano';
	@override String get tag => 'Etiqueta';
	@override String get unplayed => 'Por reproduzir';
	@override String get favorites => 'Favoritos';
}

// Path: libraries.sortLabels
class Translations$libraries$sortLabels$pt_PT extends Translations$libraries$sortLabels$pt {
	Translations$libraries$sortLabels$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Título';
	@override String get dateAdded => 'Data de adição';
	@override String get releaseDate => 'Data de lançamento';
	@override String get communityRating => 'Classificação da comunidade';
	@override String get datePlayed => 'Data de reprodução';
	@override String get playCount => 'Número de reproduções';
	@override String get runtime => 'Duração';
	@override String get premiereDate => 'Data de estreia';
	@override String get airTime => 'Horário';
	@override String get studio => 'Estúdio';
	@override String get random => 'Aleatório';
	@override String get size => 'Tamanho';
}

// Path: libraries.advancedFilters
class Translations$libraries$advancedFilters$pt_PT extends Translations$libraries$advancedFilters$pt {
	Translations$libraries$advancedFilters$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get yes => 'Sim';
	@override String get no => 'Não';
}

// Path: explore.status
class Translations$explore$status$pt_PT extends Translations$explore$status$pt {
	Translations$explore$status$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get ended => 'Terminada';
	@override String get upcoming => 'Próximos';
}

// Path: explore.badge
class Translations$explore$badge$pt_PT extends Translations$explore$badge$pt {
	Translations$explore$badge$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get available => 'Disponível';
}

// Path: explore.format
class Translations$explore$format$pt_PT extends Translations$explore$format$pt {
	Translations$explore$format$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get movie => 'Filme';
	@override String get music => 'Música';
	@override String get other => 'Outro';
}

// Path: explore.sourceMaterial
class Translations$explore$sourceMaterial$pt_PT extends Translations$explore$sourceMaterial$pt {
	Translations$explore$sourceMaterial$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get novel => 'Romance';
	@override String get musicRelease => 'Música';
	@override String get otherMedia => 'Outro';
}

// Path: explore.creditRole
class Translations$explore$creditRole$pt_PT extends Translations$explore$creditRole$pt {
	Translations$explore$creditRole$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get actor => 'Ator';
	@override String get director => 'Realizador';
	@override String get writer => 'Argumentista';
	@override String get producer => 'Produtor';
	@override String get creator => 'Criador';
	@override String get composer => 'Compositor';
}

// Path: explore.detail
class Translations$explore$detail$pt_PT extends Translations$explore$detail$pt {
	Translations$explore$detail$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get originalTitle => 'Título original';
	@override String get studios => 'Estúdios';
	@override String get language => 'Idioma';
	@override String get ended => 'Terminada';
	@override String get tags => 'Etiquetas';
	@override String get schedule => 'Agendamento';
}

// Path: music.discography
class Translations$music$discography$pt_PT extends Translations$music$discography$pt {
	Translations$music$discography$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get live => 'Direto';
}

// Path: downloads.groupings
class Translations$downloads$groupings$pt_PT extends Translations$downloads$groupings$pt {
	Translations$downloads$groupings$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get collections => 'Coleções';
}

// Path: companionRemote.remote
class Translations$companionRemote$remote$pt_PT extends Translations$companionRemote$remote$pt {
	Translations$companionRemote$remote$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get tabPlay => 'Reproduzir';
	@override String get tabMore => 'Mais';
	@override String get tabLibraries => 'Bibliotecas';
	@override String get tabSearch => 'Pesquisar';
	@override String get tabDownloads => 'Transferências';
	@override String get tabSettings => 'Definições';
	@override String get previous => 'Anterior';
	@override String get next => 'Próximo';
	@override String get stop => 'Parar';
	@override String get volumeDown => 'Baixo';
	@override String get volumeUp => 'Cima';
	@override String get fullscreen => 'Ecrã inteiro';
	@override String get subtitles => 'Legendas';
	@override String get audio => 'Áudio';
}

// Path: services.libraryFilter
class Translations$services$libraryFilter$pt_PT extends Translations$services$libraryFilter$pt {
	Translations$services$libraryFilter$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get modeBlacklist => 'Lista de bloqueios';
	@override String get modeWhitelist => 'Lista de permissões';
	@override String get libraries => 'Bibliotecas';
}

// Path: sourceSetup
class Translations$sourceSetup$pt_PT extends Translations$sourceSetup$pt {
	Translations$sourceSetup$pt_PT.internal(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get subtitleApplyFailed => 'Não foi possível descarregar ou aplicar esta legenda. Verifique a ligação e tente outro resultado.';
	@override String get subtitleSearching => 'A pesquisar no OpenSubtitles';
	@override String subtitleDownloading({required Object title}) => 'A descarregar a legenda: ${title}';
}

/// The flat map containing all translations for locale <pt-PT>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsPtPt {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'cast.subtitle' => 'Legendas',
			'cast.castToDevice' => 'Transmitir para dispositivo',
			'appIcon.defaultIcon' => 'Predefinição',
			'auth.quickConnect' => 'Ligação rápida',
			'auth.useQuickConnect' => 'Utilizar Ligação rápida',
			'auth.quickConnectCancel' => 'Cancelar',
			'common.cancel' => 'Cancelar',
			'common.save' => 'Guardar',
			'common.close' => 'Fechar',
			'common.reset' => 'Repor',
			'common.submit' => 'Enviar',
			'common.retry' => 'Tentar novamente',
			'common.unknown' => 'Desconhecido',
			'common.refresh' => 'Atualizar',
			'common.yes' => 'Sim',
			'common.no' => 'Não',
			'common.delete' => 'Eliminar',
			'common.edit' => 'Editar',
			'common.shuffle' => 'Aleatório',
			'common.connect' => 'Ligar',
			'common.disconnect' => 'Desligar',
			'common.play' => 'Reproduzir',
			'common.pause' => 'Pausar',
			'common.resume' => 'Retomar',
			'common.error' => 'Erro',
			'common.search' => 'Pesquisar',
			'common.home' => 'Página inicial',
			'common.back' => 'Voltar',
			'common.settings' => 'Definições',
			'common.mute' => 'Desativar som',
			'common.off' => 'Desativado',
			'common.fullscreen' => 'Ecrã inteiro',
			'common.mediaKind.movie' => 'Filme',
			'common.mediaKind.season' => 'Temporada',
			'common.mediaKind.episode' => 'Episódio',
			'common.mediaKind.artist' => 'Artista',
			'common.mediaKind.album' => 'Álbum',
			'common.mediaKind.track' => 'Faixa',
			'common.mediaKind.collection' => 'Coleção',
			'common.mediaKind.clip' => 'Excerto',
			'common.mediaKind.photo' => 'Fotografia',
			'common.mediaKind.folder' => 'Pasta',
			'screens.subtitleStyling' => 'Estilo de legendas',
			'screens.logs' => 'Registos',
			'settings.title' => 'Definições',
			'settings.language' => 'Idioma',
			'settings.theme' => 'Tema',
			'settings.advanced' => 'Definições avançadas',
			'settings.systemTheme' => 'Sistema',
			'settings.listView' => 'Lista',
			'settings.contentScreensaverAllLibraries' => 'Todas as bibliotecas',
			'settings.rowSizeLarge' => 'Grande',
			'settings.continueWatchingPlay' => 'Reproduzir',
			'settings.episodePlay' => 'Reproduzir',
			'settings.visualEffectsAuto' => 'Automático',
			'settings.playbackBufferLarge' => 'Grande',
			'settings.playbackBufferExtraLarge' => 'Extragrande',
			'settings.musicQualityTitle' => 'Qualidade da música',
			'settings.subtitleStyling' => 'Estilo de legendas',
			'settings.cloudBackupUsername' => 'Nome de utilizador',
			'settings.cloudBackupPassword' => 'Palavra-passe',
			'settings.skipMarkerModeOff' => 'Desativado',
			'settings.downloads' => 'Transferências',
			'settings.audioChannelLimit' => 'Canais de áudio',
			'settings.audioChannelLimitStereo' => 'Estéreo',
			'settings.dvConversionAuto' => 'Automático',
			'settings.hdrSdrConversionAuto' => 'Automático',
			'settings.hdrSdrConversionDevice' => 'Dispositivo',
			'settings.hdrSdrConversionPlayer' => 'Leitor',
			'settings.deinterlaceOff' => 'Desativado',
			'settings.deinterlaceVideo' => 'Vídeo',
			'settings.general' => 'Geral',
			'settings.display' => 'Visualização',
			'settings.navigation' => 'Navegação',
			'settings.liveTv' => 'TV em direto',
			'settings.player' => 'Leitor',
			'settings.audio' => 'Áudio',
			'settings.quality' => 'Qualidade',
			'settings.subtitles' => 'Legendas',
			'settings.controls' => 'Controlos',
			'settings.scopePlaybackSpeed' => 'Velocidade de reprodução',
			'settings.scopeAspectRatio' => 'Proporção da imagem',
			'settings.secondsUnit' => ({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(seconds, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} segundos', one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} segundo', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} segundos', ), 
			'settings.minutesUnit' => ({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(minutes, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minutos', one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minuto', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minutos', ), 
			'themeEditor.custom' => 'Personalizado',
			'themeEditor.preview' => 'Antevisão',
			'themeEditor.slots.text' => 'Texto',
			'search.people' => 'Pessoas',
			'hotkeys.actions.chapterNext' => 'Próximo capítulo',
			'hotkeys.actions.chapterPrevious' => 'Capítulo anterior',
			'hotkeys.actions.episodeNext' => 'Próximo episódio',
			'fileInfo.overview' => 'Sinopse',
			'fileInfo.video' => 'Vídeo',
			'fileInfo.audio' => 'Áudio',
			'fileInfo.subtitles' => 'Legendas',
			'fileInfo.lyrics' => 'Letras',
			'fileInfo.file' => 'Ficheiro',
			'fileInfo.codecTag' => 'Etiqueta do codec',
			'fileInfo.resolution' => 'Resolução',
			'fileInfo.bitrate' => 'Taxa de bits',
			'fileInfo.rotation' => 'Rotação',
			'fileInfo.aspectRatio' => 'Proporção da imagem',
			'fileInfo.profile' => 'Perfil',
			'fileInfo.level' => 'Nível',
			'fileInfo.bitDepth' => 'Profundidade de bits',
			'fileInfo.pixelFormat' => 'Formato dos píxeis',
			'fileInfo.colorSpace' => 'Espaço de cor',
			'fileInfo.colorPrimaries' => 'Cores primárias',
			'fileInfo.colorTransfer' => 'Transferência de cor',
			'fileInfo.interlaced' => 'Entrelaçado',
			'fileInfo.anamorphic' => 'Anamórfico',
			'fileInfo.language' => 'Idioma',
			'fileInfo.channels' => 'Canais',
			'fileInfo.sampleRate' => 'Taxa de amostragem',
			'fileInfo.path' => 'Caminho',
			'fileInfo.size' => 'Tamanho',
			'fileInfo.container' => 'Contentor',
			'fileInfo.duration' => 'Duração',
			'fileInfo.protocol' => 'Protocolo',
			'fileInfo.transcoding' => 'Transcodificação',
			'fileInfo.subtitlesOff' => 'Desativado',
			'fileInfo.flagDefault' => 'Predefinição',
			'fileInfo.flagForced' => 'Forçado',
			'fileInfo.flagExternal' => 'Externo',
			'mediaMenu.deleteEpisodeConfirm' => 'Eliminar episódio',
			'mediaMenu.rate' => 'Classificar',
			'mediaMenu.playFromBeginning' => 'Reproduzir do início',
			'rateSheet.title' => 'Classificar',
			'rateSheet.server' => 'Servidor',
			'rateSheet.favorite' => 'Favorito',
			'accessibility.mediaCardWatched' => 'Visto',
			'accessibility.red' => 'Vermelho',
			'accessibility.green' => 'Verde',
			'accessibility.blue' => 'Azul',
			'videoControls.audioLabel' => 'Áudio',
			'videoControls.subtitlesLabel' => 'Legendas',
			'videoControls.stretch' => 'Esticar',
			'videoControls.playNext' => 'Reproduzir a seguir',
			'videoControls.playButton' => 'Reproduzir',
			'videoControls.pauseButton' => 'Pausar',
			'videoControls.nextButton' => 'Próximo episódio',
			'videoControls.previousChapterButton' => 'Capítulo anterior',
			'videoControls.nextChapterButton' => 'Próximo capítulo',
			'videoControls.muteButton' => 'Desativar som',
			'videoControls.unmuteButton' => 'Ativar som',
			'videoControls.versionColumnHeader' => 'Versão',
			'videoControls.qualityColumnHeader' => 'Qualidade',
			'videoControls.aspectRatioButton' => 'Proporção da imagem',
			'videoControls.language' => 'Idioma',
			'videoControls.nextEpisode' => 'Próximo episódio',
			'messages.noResultsFound' => 'Sem resultados.',
			'subtitlingStyling.text' => 'Texto',
			'subtitlingStyling.textColor' => 'Cor do texto',
			'subtitlingStyling.bold' => 'Negrito',
			'subtitlingStyling.renderResolutionScreen' => 'Resolução de ecrã',
			'subtitlingStyling.renderResolutionVideo' => 'Resolução de vídeo',
			'mpvConfig.deletePreset' => 'Eliminar',
			'profiles.delete' => 'Eliminar',
			'profiles.signOut' => 'Terminar sessão',
			'profiles.removePin' => 'Remover',
			'profiles.add' => 'Adicionar',
			'profiles.connectionDefault' => 'Predefinição',
			'profiles.removeConnection' => 'Remover',
			'accountPreferences.preferredAudioLanguage' => 'Idioma de áudio preferido',
			'accountPreferences.preferredSubtitleLanguage' => 'Idioma preferido das legendas',
			'accountPreferences.watchedIndicatorOptions.none' => 'Nunca',
			'discover.continueWatching' => 'Continuar a ver',
			'discover.nextUp' => 'A seguir',
			'discover.recentlyAdded' => 'Adicionados recentemente',
			'discover.overview' => 'Sinopse',
			'discover.studio' => 'Estúdio',
			'discover.director' => 'Realizador',
			'discover.directors' => 'Realizadores',
			'discover.movie' => 'Filme',
			'discover.moreLikeThis' => 'Títulos semelhantes',
			'discover.findNext.chooseHint' => 'Abra um título, guarde-o para mais tarde ou passe ao seguinte.',
			'discover.findNext.howItWorks' => 'Como funciona',
			'discover.findNext.swipeHint' => 'Deslize a capa na direção de uma seta ou use os botões abaixo.',
			'discover.findNext.notNowHelp' => 'Ignore este título por agora. Ele continua na sua biblioteca.',
			'discover.findNext.saveHelp' => 'Guarde-o nas escolhas guardadas deste perfil neste dispositivo. Guardar não inicia uma transferência.',
			'discover.findNext.openHelp' => 'Selecione a capa para ver os detalhes. Use a ação principal para reproduzir, ler ou abrir o título.',
			'discover.findNext.controlsHelp' => 'Teclado ou comando: selecione um botão e prima Enter ou Selecionar. Anular restaura a sua última escolha.',
			'discover.findNext.artworkLoading' => 'A carregar a imagem…',
			'discover.findNext.artworkUnavailable' => 'Imagem indisponível',
			'discover.findNext.savedFeedback' => 'Adicionado às escolhas guardadas',
			'discover.findNext.skippedFeedback' => 'Ignorado por agora',
			'discover.findNext.releaseToConfirm' => 'Solte para confirmar',
			'discover.findNext.remoteHint' => 'Capa em foco: ← / → escolher · Selecionar: detalhes · ↑ / ↓ mover o foco',
			'libraries.title' => 'Bibliotecas',
			'libraries.scanLibrary' => 'Analisar biblioteca',
			'libraries.refreshMetadata' => 'Atualizar metadados',
			'libraries.resetFilters' => 'Repor filtros',
			'libraries.all' => 'Todos',
			'libraries.sort' => 'Ordenar',
			'libraries.sortBy' => 'Ordenar por',
			'libraries.filters' => 'Filtros',
			'libraries.folders' => 'Pastas',
			'libraries.tabs.browse' => 'Explorar',
			'libraries.tabs.collections' => 'Coleções',
			'libraries.groupings.all' => 'Todos',
			'libraries.groupings.movies' => 'Filmes',
			'libraries.groupings.shows' => 'Séries',
			'libraries.groupings.seasons' => 'Temporadas',
			'libraries.groupings.episodes' => 'Episódios',
			'libraries.groupings.artists' => 'Artistas',
			'libraries.groupings.albums' => 'Álbuns',
			'libraries.groupings.tracks' => 'Faixas',
			'libraries.groupings.folders' => 'Pastas',
			'libraries.filterCategories.genre' => 'Género',
			'libraries.filterCategories.year' => 'Ano',
			'libraries.filterCategories.tag' => 'Etiqueta',
			'libraries.filterCategories.unplayed' => 'Por reproduzir',
			'libraries.filterCategories.favorites' => 'Favoritos',
			'libraries.sortLabels.title' => 'Título',
			'libraries.sortLabels.dateAdded' => 'Data de adição',
			'libraries.sortLabels.releaseDate' => 'Data de lançamento',
			'libraries.sortLabels.communityRating' => 'Classificação da comunidade',
			'libraries.sortLabels.datePlayed' => 'Data de reprodução',
			'libraries.sortLabels.playCount' => 'Número de reproduções',
			'libraries.sortLabels.runtime' => 'Duração',
			'libraries.sortLabels.premiereDate' => 'Data de estreia',
			'libraries.sortLabels.airTime' => 'Horário',
			'libraries.sortLabels.studio' => 'Estúdio',
			'libraries.sortLabels.random' => 'Aleatório',
			'libraries.sortLabels.size' => 'Tamanho',
			'libraries.advancedFilters.yes' => 'Sim',
			'libraries.advancedFilters.no' => 'Não',
			'hubDetail.title' => 'Título',
			'hubDetail.dateAdded' => 'Data de adição',
			'navigation.libraries' => 'Bibliotecas',
			'navigation.downloads' => 'Transferências',
			'navigation.liveTv' => 'TV em direto',
			'explore.status.ended' => 'Terminada',
			'explore.status.upcoming' => 'Próximos',
			'explore.badge.available' => 'Disponível',
			'explore.format.movie' => 'Filme',
			'explore.format.music' => 'Música',
			'explore.format.other' => 'Outro',
			'explore.sourceMaterial.novel' => 'Romance',
			'explore.sourceMaterial.musicRelease' => 'Música',
			'explore.sourceMaterial.otherMedia' => 'Outro',
			'explore.creditRole.actor' => 'Ator',
			'explore.creditRole.director' => 'Realizador',
			'explore.creditRole.writer' => 'Argumentista',
			'explore.creditRole.producer' => 'Produtor',
			'explore.creditRole.creator' => 'Criador',
			'explore.creditRole.composer' => 'Compositor',
			'explore.detail.originalTitle' => 'Título original',
			'explore.detail.studios' => 'Estúdios',
			'explore.detail.language' => 'Idioma',
			'explore.detail.ended' => 'Terminada',
			'explore.detail.tags' => 'Etiquetas',
			'explore.detail.schedule' => 'Agendamento',
			'liveTv.title' => 'TV em direto',
			'liveTv.guide' => 'Guia TV',
			'liveTv.unknownHub' => 'Desconhecido',
			'liveTv.live' => 'Direto',
			'liveTv.premiereBadge' => 'Novo',
			'liveTv.channelsSection' => 'Canais',
			'liveTv.programsSection' => 'Programas',
			'liveTv.favorites' => 'Favoritos',
			'liveTv.record' => 'Gravação',
			'liveTv.recordSeries' => 'Gravar série',
			'liveTv.recordings' => 'Gravações',
			'liveTv.manageRecording' => 'Gerir gravação',
			'liveTv.cancelRecording' => 'Cancelar gravação',
			'liveTv.recordingScheduled' => 'Gravação agendada.',
			'liveTv.editRuleAction' => 'Editar',
			'collections.title' => 'Coleções',
			'collections.collection' => 'Coleção',
			'collections.deleteCollection' => 'Eliminar coleção',
			'collections.removeFromCollection' => 'Remover da coleção',
			'playlists.delete' => 'Eliminar playlist',
			'playlists.removeItem' => 'Remover da playlist',
			'music.instantMix' => 'Mix instantâneo',
			'music.playNext' => 'Reproduzir a seguir',
			'music.clearQueue' => 'Limpar fila',
			'music.lyrics' => 'Letras',
			'music.stopPlayback' => 'Parar reprodução',
			'music.previousTrack' => 'Faixa anterior',
			'music.nextTrack' => 'Faixa seguinte',
			'music.repeat' => 'Repetir',
			'music.repeatAll' => 'Repetir tudo',
			'music.repeatOne' => 'Repetir o item atual',
			'music.discography.live' => 'Direto',
			'music.sleepTimerMinutes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minutos', one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minuto', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minutos', ), 
			'watchTogether.removeRoom' => 'Remover',
			'watchTogether.hostBadge' => 'Servidor',
			'watchTogether.playerIdle' => 'Inativo',
			'watchTogether.remove' => 'Remover',
			'downloads.title' => 'Transferências',
			'downloads.tvShows' => 'Séries',
			'downloads.movies' => 'Filmes',
			'downloads.music' => 'Música',
			'downloads.downloadNow' => 'Transferir',
			'downloads.downloadQueued' => 'Transferência pendente.',
			'downloads.deleteAll' => 'Eliminar tudo',
			'downloads.allEpisodes' => 'Todos os episódios',
			'downloads.syncRuleAvailable' => 'Disponível',
			'downloads.groupings.collections' => 'Coleções',
			'companionRemote.remote.tabPlay' => 'Reproduzir',
			'companionRemote.remote.tabMore' => 'Mais',
			'companionRemote.remote.tabLibraries' => 'Bibliotecas',
			'companionRemote.remote.tabSearch' => 'Pesquisar',
			'companionRemote.remote.tabDownloads' => 'Transferências',
			'companionRemote.remote.tabSettings' => 'Definições',
			'companionRemote.remote.previous' => 'Anterior',
			'companionRemote.remote.next' => 'Próximo',
			'companionRemote.remote.stop' => 'Parar',
			'companionRemote.remote.volumeDown' => 'Baixo',
			'companionRemote.remote.volumeUp' => 'Cima',
			'companionRemote.remote.fullscreen' => 'Ecrã inteiro',
			'companionRemote.remote.subtitles' => 'Legendas',
			'companionRemote.remote.audio' => 'Áudio',
			'videoSettings.playbackSpeed' => 'Velocidade de reprodução',
			'videoSettings.hdrToneMappingPlayer' => 'Leitor',
			'videoSettings.audioOutputStereo' => 'Estéreo',
			'videoSettings.audioEqualizerActive' => 'Personalizado',
			'performanceOverlay.performance' => 'Desempenho',
			'performanceOverlay.app' => 'Aplicação',
			'performanceOverlay.rotation' => 'Rotação',
			'performanceOverlay.sampleRate' => 'Taxa de amostragem',
			'performanceOverlay.player' => 'Leitor',
			'performanceOverlay.playMethod' => 'Método de reprodução',
			'externalPlayer.off' => 'Desativado',
			'metadataEdit.editMetadata' => 'Editar',
			'metadataEdit.screenTitle' => 'Editar metadados',
			'metadataEdit.title' => 'Título',
			'metadataEdit.sortTitle' => 'Título para ordenação',
			'metadataEdit.originalTitle' => 'Título original',
			'metadataEdit.releaseDate' => 'Data de lançamento',
			'metadataEdit.studio' => 'Estúdio',
			'metadataEdit.tagline' => 'Slogan',
			'metadataEdit.poster' => 'Cartaz',
			'metadataEdit.logo' => 'Logótipo',
			'metadataEdit.allEpisodes' => 'Todos os episódios',
			'metadataEdit.never' => 'Nunca',
			'metadataEdit.seasons' => 'Temporadas',
			'metadataEdit.hide' => 'Ocultar',
			'metadataEdit.preferredAudioLanguage' => 'Idioma de áudio preferido',
			'metadataEdit.preferredSubtitleLanguage' => 'Idioma preferido das legendas',
			'metadataEdit.tags' => 'Etiquetas',
			'metadataEdit.genre' => 'Género',
			'metadataEdit.director' => 'Realizador',
			'metadataEdit.writer' => 'Argumentista',
			'metadataEdit.producer' => 'Produtor',
			'metadataEdit.collection' => 'Coleção',
			'matchScreen.titleHint' => 'Título',
			'matchScreen.yearHint' => 'Ano',
			'matchScreen.search' => 'Pesquisar',
			'seerr.seasons' => 'Temporadas',
			'seerr.advancedOptions' => 'Definições avançadas',
			'seerr.tags' => 'Etiquetas',
			'seerr.statusAvailable' => 'Disponível',
			'services.libraryFilter.modeBlacklist' => 'Lista de bloqueios',
			'services.libraryFilter.modeWhitelist' => 'Lista de permissões',
			'services.libraryFilter.libraries' => 'Bibliotecas',
			'addServer.username' => 'Nome de utilizador',
			'addServer.password' => 'Palavra-passe',
			'addServer.signIn' => 'Iniciar sessão',
			'watchLink.copy' => 'Copiar',
			'homeLayout.home' => 'Página inicial',
			'homeLayout.continueWatching' => 'Continuar a ver',
			'homeLayout.recentlyAdded' => 'Adicionados recentemente',
			'homeLayout.hide' => 'Ocultar',
			'homeLayout.remove' => 'Remover',
			'fileSources.source' => 'Fonte',
			'fileSources.name' => 'Nome',
			'fileSources.username' => 'Nome de utilizador',
			'fileSources.password' => 'Palavra-passe',
			'fileSources.connect' => 'Ligar',
			'fileSources.cancel' => 'Cancelar',
			'fileSources.save' => 'Guardar',
			'fileSources.close' => 'Fechar',
			'fileSources.refresh' => 'Atualizar',
			'fileSources.continueReading' => 'Continuar a ler',
			'fileSources.continueListening' => 'Continuar a ouvir',
			'fileSources.continueWatching' => 'Continuar a ver',
			'fileSources.play' => 'Reproduzir',
			'fileSources.pause' => 'Pausar',
			'fileSources.stop' => 'Parar',
			'fileSources.delete' => 'Eliminar',
			'fileSources.speed' => 'Velocidade de reprodução',
			'fileSources.sleepOff' => 'Desativado',
			'fileSources.fontSize' => 'Tamanho do texto',
			'fileSources.audio' => 'Áudio',
			'fileSources.video' => 'Vídeo',
			'fileSources.all' => 'Todos',
			'fileSources.signIn' => 'Iniciar sessão',
			'fileSources.none' => 'Nenhum',
			'fileSources.fullscreen' => 'Ecrã inteiro',
			'fileSources.audiobooks' => 'Audiolivros',
			'fileSources.leftToRight' => 'Da esquerda para a direita',
			'fileSources.rightToLeft' => 'Da direita para a esquerda',
			'fileSources.minutes' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minutos', one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minuto', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minutos', ), 
			'fileSources.googleDrive' => 'Google Drive',
			'lending.cancel' => 'Cancelar',
			'sourceSetup.subtitleApplyFailed' => 'Não foi possível descarregar ou aplicar esta legenda. Verifique a ligação e tente outro resultado.',
			'sourceSetup.subtitleSearching' => 'A pesquisar no OpenSubtitles',
			'sourceSetup.subtitleDownloading' => ({required Object title}) => 'A descarregar a legenda: ${title}',
			_ => null,
		};
	}
}
