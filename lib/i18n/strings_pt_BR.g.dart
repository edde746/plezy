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
class TranslationsPtBr extends TranslationsPt with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsPtBr({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ptBr,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <pt-BR>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsPtBr _root = this; // ignore: unused_field

	@override 
	TranslationsPtBr $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsPtBr(meta: meta ?? this.$meta);

	// Translations
	@override late final Translations$cast$pt_BR cast = Translations$cast$pt_BR.internal(_root);
	@override late final Translations$appIcon$pt_BR appIcon = Translations$appIcon$pt_BR.internal(_root);
	@override late final Translations$auth$pt_BR auth = Translations$auth$pt_BR.internal(_root);
	@override late final Translations$common$pt_BR common = Translations$common$pt_BR.internal(_root);
	@override late final Translations$screens$pt_BR screens = Translations$screens$pt_BR.internal(_root);
	@override late final Translations$settings$pt_BR settings = Translations$settings$pt_BR.internal(_root);
	@override late final Translations$themeEditor$pt_BR themeEditor = Translations$themeEditor$pt_BR.internal(_root);
	@override late final Translations$search$pt_BR search = Translations$search$pt_BR.internal(_root);
	@override late final Translations$hotkeys$pt_BR hotkeys = Translations$hotkeys$pt_BR.internal(_root);
	@override late final Translations$fileInfo$pt_BR fileInfo = Translations$fileInfo$pt_BR.internal(_root);
	@override late final Translations$mediaMenu$pt_BR mediaMenu = Translations$mediaMenu$pt_BR.internal(_root);
	@override late final Translations$rateSheet$pt_BR rateSheet = Translations$rateSheet$pt_BR.internal(_root);
	@override late final Translations$accessibility$pt_BR accessibility = Translations$accessibility$pt_BR.internal(_root);
	@override late final Translations$videoControls$pt_BR videoControls = Translations$videoControls$pt_BR.internal(_root);
	@override late final Translations$messages$pt_BR messages = Translations$messages$pt_BR.internal(_root);
	@override late final Translations$subtitlingStyling$pt_BR subtitlingStyling = Translations$subtitlingStyling$pt_BR.internal(_root);
	@override late final Translations$mpvConfig$pt_BR mpvConfig = Translations$mpvConfig$pt_BR.internal(_root);
	@override late final Translations$profiles$pt_BR profiles = Translations$profiles$pt_BR.internal(_root);
	@override late final Translations$accountPreferences$pt_BR accountPreferences = Translations$accountPreferences$pt_BR.internal(_root);
	@override late final Translations$discover$pt_BR discover = Translations$discover$pt_BR.internal(_root);
	@override late final Translations$libraries$pt_BR libraries = Translations$libraries$pt_BR.internal(_root);
	@override late final Translations$hubDetail$pt_BR hubDetail = Translations$hubDetail$pt_BR.internal(_root);
	@override late final Translations$navigation$pt_BR navigation = Translations$navigation$pt_BR.internal(_root);
	@override late final Translations$explore$pt_BR explore = Translations$explore$pt_BR.internal(_root);
	@override late final Translations$liveTv$pt_BR liveTv = Translations$liveTv$pt_BR.internal(_root);
	@override late final Translations$collections$pt_BR collections = Translations$collections$pt_BR.internal(_root);
	@override late final Translations$playlists$pt_BR playlists = Translations$playlists$pt_BR.internal(_root);
	@override late final Translations$music$pt_BR music = Translations$music$pt_BR.internal(_root);
	@override late final Translations$watchTogether$pt_BR watchTogether = Translations$watchTogether$pt_BR.internal(_root);
	@override late final Translations$downloads$pt_BR downloads = Translations$downloads$pt_BR.internal(_root);
	@override late final Translations$companionRemote$pt_BR companionRemote = Translations$companionRemote$pt_BR.internal(_root);
	@override late final Translations$videoSettings$pt_BR videoSettings = Translations$videoSettings$pt_BR.internal(_root);
	@override late final Translations$performanceOverlay$pt_BR performanceOverlay = Translations$performanceOverlay$pt_BR.internal(_root);
	@override late final Translations$externalPlayer$pt_BR externalPlayer = Translations$externalPlayer$pt_BR.internal(_root);
	@override late final Translations$metadataEdit$pt_BR metadataEdit = Translations$metadataEdit$pt_BR.internal(_root);
	@override late final Translations$matchScreen$pt_BR matchScreen = Translations$matchScreen$pt_BR.internal(_root);
	@override late final Translations$seerr$pt_BR seerr = Translations$seerr$pt_BR.internal(_root);
	@override late final Translations$services$pt_BR services = Translations$services$pt_BR.internal(_root);
	@override late final Translations$addServer$pt_BR addServer = Translations$addServer$pt_BR.internal(_root);
	@override late final Translations$watchLink$pt_BR watchLink = Translations$watchLink$pt_BR.internal(_root);
	@override late final Translations$homeLayout$pt_BR homeLayout = Translations$homeLayout$pt_BR.internal(_root);
	@override late final Translations$fileSources$pt_BR fileSources = Translations$fileSources$pt_BR.internal(_root);
	@override late final Translations$lending$pt_BR lending = Translations$lending$pt_BR.internal(_root);
}

// Path: cast
class Translations$cast$pt_BR extends Translations$cast$pt {
	Translations$cast$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get subtitle => 'Legendas';
	@override String get castToDevice => 'Transmitir para o dispositivo';
}

// Path: appIcon
class Translations$appIcon$pt_BR extends Translations$appIcon$pt {
	Translations$appIcon$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get defaultIcon => 'Padrão';
}

// Path: auth
class Translations$auth$pt_BR extends Translations$auth$pt {
	Translations$auth$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get quickConnect => 'Conexão rápida';
	@override String get useQuickConnect => 'Usar Conexão Rápida';
	@override String get quickConnectCancel => 'Cancelar';
}

// Path: common
class Translations$common$pt_BR extends Translations$common$pt {
	Translations$common$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Cancelar';
	@override String get save => 'Salvar';
	@override String get close => 'Fechar';
	@override String get reset => 'Resetar';
	@override String get submit => 'Enviar';
	@override String get retry => 'Retentar';
	@override String get unknown => 'Desconhecido';
	@override String get refresh => 'Atualizar';
	@override String get yes => 'Sim';
	@override String get no => 'Não';
	@override String get delete => 'Excluir';
	@override String get edit => 'Editar';
	@override String get shuffle => 'Aleatório';
	@override String get connect => 'Conectar';
	@override String get disconnect => 'Desconectar';
	@override String get play => 'Reproduzir';
	@override String get pause => 'Pausar';
	@override String get resume => 'Retomar';
	@override String get error => 'Erro';
	@override String get search => 'Busca';
	@override String get home => 'Início';
	@override String get back => 'Voltar';
	@override String get settings => 'Configurações';
	@override String get mute => 'Mudo';
	@override String get off => 'Desligado';
	@override String get fullscreen => 'Tela Cheia';
	@override late final Translations$common$mediaKind$pt_BR mediaKind = Translations$common$mediaKind$pt_BR.internal(_root);
}

// Path: screens
class Translations$screens$pt_BR extends Translations$screens$pt {
	Translations$screens$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get subtitleStyling => 'Estilização da legenda';
	@override String get logs => 'Registros';
}

// Path: settings
class Translations$settings$pt_BR extends Translations$settings$pt {
	Translations$settings$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Configurações';
	@override String get language => 'Idioma';
	@override String get theme => 'Tema';
	@override String get advanced => 'Avançado';
	@override String get systemTheme => 'Sistema';
	@override String get listView => 'Lista';
	@override String get contentScreensaverAllLibraries => 'Todas as bibliotecas';
	@override String get rowSizeLarge => 'Grande';
	@override String get continueWatchingPlay => 'Reproduzir';
	@override String get episodePlay => 'Reproduzir';
	@override String get visualEffectsAuto => 'Automático';
	@override String get playbackBufferLarge => 'Grande';
	@override String get playbackBufferExtraLarge => 'Extra Grande';
	@override String get musicQualityTitle => 'Qualidade da Música';
	@override String get subtitleStyling => 'Estilização da legenda';
	@override String get cloudBackupUsername => 'Usuário';
	@override String get cloudBackupPassword => 'Senha';
	@override String get skipMarkerModeOff => 'Desligado';
	@override String get audioChannelLimit => 'Canais de áudio';
	@override String get dvConversionAuto => 'Automático';
	@override String get hdrSdrConversionAuto => 'Automático';
	@override String get hdrSdrConversionDevice => 'Dispositivo';
	@override String get hdrSdrConversionPlayer => 'Reprodutor';
	@override String get deinterlaceOff => 'Desligado';
	@override String get deinterlaceVideo => 'Vídeo';
	@override String get general => 'Geral';
	@override String get display => 'Exibição';
	@override String get navigation => 'Navegação';
	@override String get liveTv => 'TV ao Vivo';
	@override String get player => 'Reprodutor';
	@override String get audio => 'Áudio';
	@override String get quality => 'Qualidade';
	@override String get subtitles => 'Legendas';
	@override String get controls => 'Controles';
	@override String get scopePlaybackSpeed => 'Velocidade de Reprodução';
	@override String get scopeAspectRatio => 'Proporção da tela';
	@override String secondsUnit({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(seconds,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} segundo',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} segundos',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} segundos',
	);
	@override String minutesUnit({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(minutes,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minuto',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minutos',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minutos',
	);
}

// Path: themeEditor
class Translations$themeEditor$pt_BR extends Translations$themeEditor$pt {
	Translations$themeEditor$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get custom => 'Personalizado';
	@override String get preview => 'Prévia';
	@override late final Translations$themeEditor$slots$pt_BR slots = Translations$themeEditor$slots$pt_BR.internal(_root);
}

// Path: search
class Translations$search$pt_BR extends Translations$search$pt {
	Translations$search$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get people => 'Pessoas';
}

// Path: hotkeys
class Translations$hotkeys$pt_BR extends Translations$hotkeys$pt {
	Translations$hotkeys$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override late final Translations$hotkeys$actions$pt_BR actions = Translations$hotkeys$actions$pt_BR.internal(_root);
}

// Path: fileInfo
class Translations$fileInfo$pt_BR extends Translations$fileInfo$pt {
	Translations$fileInfo$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get overview => 'Sinopse';
	@override String get video => 'Vídeo';
	@override String get audio => 'Áudio';
	@override String get subtitles => 'Legendas';
	@override String get lyrics => 'Letras';
	@override String get file => 'Arquivo';
	@override String get codecTag => 'Marcador do codec';
	@override String get resolution => 'Resolução';
	@override String get rotation => 'Rotação';
	@override String get aspectRatio => 'Proporção da tela';
	@override String get profile => 'Perfil';
	@override String get level => 'Nível';
	@override String get bitDepth => 'Profundidade de bits';
	@override String get pixelFormat => 'Formato de pixel';
	@override String get colorSpace => 'Espaço de cores';
	@override String get colorPrimaries => 'Cores primárias';
	@override String get colorTransfer => 'Transferência de cor';
	@override String get interlaced => 'Entrelaçado';
	@override String get anamorphic => 'Anamórfico';
	@override String get language => 'Idioma';
	@override String get channels => 'Canais';
	@override String get sampleRate => 'Taxa da amostra';
	@override String get path => 'Local';
	@override String get size => 'Tamanho';
	@override String get container => 'Formato';
	@override String get duration => 'Duração';
	@override String get protocol => 'Protocolo';
	@override String get transcoding => 'Transcodificação';
	@override String get subtitlesOff => 'Desligado';
	@override String get flagDefault => 'Padrão';
	@override String get flagForced => 'Forçado';
	@override String get flagExternal => 'Externa';
}

// Path: mediaMenu
class Translations$mediaMenu$pt_BR extends Translations$mediaMenu$pt {
	Translations$mediaMenu$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get deleteEpisodeConfirm => 'Excluir episódio';
	@override String get rate => 'Avaliação';
	@override String get playFromBeginning => 'Reproduzir do início';
}

// Path: rateSheet
class Translations$rateSheet$pt_BR extends Translations$rateSheet$pt {
	Translations$rateSheet$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Avaliação';
	@override String get server => 'Servidor';
	@override String get favorite => 'Favorito';
}

// Path: accessibility
class Translations$accessibility$pt_BR extends Translations$accessibility$pt {
	Translations$accessibility$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get mediaCardWatched => 'Assistido';
	@override String get red => 'Vermelho';
	@override String get green => 'Verde';
	@override String get blue => 'Azul';
}

// Path: videoControls
class Translations$videoControls$pt_BR extends Translations$videoControls$pt {
	Translations$videoControls$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Áudio';
	@override String get subtitlesLabel => 'Legendas';
	@override String get stretch => 'Esticar';
	@override String get playNext => 'Reproduzir próximo';
	@override String get playButton => 'Reproduzir';
	@override String get pauseButton => 'Pausar';
	@override String get nextButton => 'Próximo episódio';
	@override String get previousChapterButton => 'Capítulo anterior';
	@override String get nextChapterButton => 'Próximo capítulo';
	@override String get muteButton => 'Mudo';
	@override String get unmuteButton => 'Sair do Mudo';
	@override String get versionColumnHeader => 'Versão';
	@override String get qualityColumnHeader => 'Qualidade';
	@override String get aspectRatioButton => 'Proporção da tela';
	@override String get language => 'Idioma';
	@override String get nextEpisode => 'Próximo episódio';
}

// Path: messages
class Translations$messages$pt_BR extends Translations$messages$pt {
	Translations$messages$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get noResultsFound => 'Nenhum resultado encontrado.';
}

// Path: subtitlingStyling
class Translations$subtitlingStyling$pt_BR extends Translations$subtitlingStyling$pt {
	Translations$subtitlingStyling$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get text => 'Texto';
	@override String get textColor => 'Cor do texto';
	@override String get bold => 'Negrito';
	@override String get renderResolutionScreen => 'Resolução de tela';
	@override String get renderResolutionVideo => 'Resolução de vídeo';
}

// Path: mpvConfig
class Translations$mpvConfig$pt_BR extends Translations$mpvConfig$pt {
	Translations$mpvConfig$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get deletePreset => 'Excluir';
}

// Path: profiles
class Translations$profiles$pt_BR extends Translations$profiles$pt {
	Translations$profiles$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get delete => 'Excluir';
	@override String get signOut => 'Sair';
	@override String get removePin => 'Remover';
	@override String get add => 'Adicionar';
	@override String get connectionDefault => 'Padrão';
	@override String get removeConnection => 'Remover';
}

// Path: accountPreferences
class Translations$accountPreferences$pt_BR extends Translations$accountPreferences$pt {
	Translations$accountPreferences$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get preferredAudioLanguage => 'Idioma preferido de áudio';
	@override String get preferredSubtitleLanguage => 'Idioma de legendas preferido';
	@override late final Translations$accountPreferences$watchedIndicatorOptions$pt_BR watchedIndicatorOptions = Translations$accountPreferences$watchedIndicatorOptions$pt_BR.internal(_root);
}

// Path: discover
class Translations$discover$pt_BR extends Translations$discover$pt {
	Translations$discover$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get continueWatching => 'Continuar assistindo';
	@override String get nextUp => 'A seguir';
	@override String get recentlyAdded => 'Recentes';
	@override String get overview => 'Sinopse';
	@override String get studio => 'Estudio';
	@override String get director => 'Diretor';
	@override String get directors => 'Diretores';
	@override String get movie => 'Filme';
	@override String get moreLikeThis => 'Mais Disso';
}

// Path: libraries
class Translations$libraries$pt_BR extends Translations$libraries$pt {
	Translations$libraries$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bibliotecas';
	@override String get scanLibrary => 'Rastrear biblioteca';
	@override String get refreshMetadata => 'Atualizar metadados';
	@override String get resetFilters => 'Redefinir filtros';
	@override String get all => 'Todos';
	@override String get sort => 'Ordenar';
	@override String get sortBy => 'Ordenar Por';
	@override String get filters => 'Filtros';
	@override String get folders => 'Pastas';
	@override late final Translations$libraries$tabs$pt_BR tabs = Translations$libraries$tabs$pt_BR.internal(_root);
	@override late final Translations$libraries$groupings$pt_BR groupings = Translations$libraries$groupings$pt_BR.internal(_root);
	@override late final Translations$libraries$filterCategories$pt_BR filterCategories = Translations$libraries$filterCategories$pt_BR.internal(_root);
	@override late final Translations$libraries$sortLabels$pt_BR sortLabels = Translations$libraries$sortLabels$pt_BR.internal(_root);
	@override late final Translations$libraries$advancedFilters$pt_BR advancedFilters = Translations$libraries$advancedFilters$pt_BR.internal(_root);
}

// Path: hubDetail
class Translations$hubDetail$pt_BR extends Translations$hubDetail$pt {
	Translations$hubDetail$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Título';
	@override String get dateAdded => 'Data de adição';
}

// Path: navigation
class Translations$navigation$pt_BR extends Translations$navigation$pt {
	Translations$navigation$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Bibliotecas';
	@override String get liveTv => 'TV ao Vivo';
}

// Path: explore
class Translations$explore$pt_BR extends Translations$explore$pt {
	Translations$explore$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override late final Translations$explore$status$pt_BR status = Translations$explore$status$pt_BR.internal(_root);
	@override late final Translations$explore$badge$pt_BR badge = Translations$explore$badge$pt_BR.internal(_root);
	@override late final Translations$explore$format$pt_BR format = Translations$explore$format$pt_BR.internal(_root);
	@override late final Translations$explore$sourceMaterial$pt_BR sourceMaterial = Translations$explore$sourceMaterial$pt_BR.internal(_root);
	@override late final Translations$explore$creditRole$pt_BR creditRole = Translations$explore$creditRole$pt_BR.internal(_root);
	@override late final Translations$explore$detail$pt_BR detail = Translations$explore$detail$pt_BR.internal(_root);
}

// Path: liveTv
class Translations$liveTv$pt_BR extends Translations$liveTv$pt {
	Translations$liveTv$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'TV ao Vivo';
	@override String get guide => 'Guia';
	@override String get unknownHub => 'Desconhecido';
	@override String get live => 'Ao vivo';
	@override String get premiereBadge => 'Novo';
	@override String get channelsSection => 'Canais';
	@override String get programsSection => 'Programas';
	@override String get favorites => 'Favoritos';
	@override String get record => 'Gravar';
	@override String get recordSeries => 'Gravar série';
	@override String get recordings => 'Gravações';
	@override String get manageRecording => 'Gerenciar gravação';
	@override String get cancelRecording => 'Cancelar gravação';
	@override String get recordingScheduled => 'Gravação agendada.';
	@override String get editRuleAction => 'Editar';
}

// Path: collections
class Translations$collections$pt_BR extends Translations$collections$pt {
	Translations$collections$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Coleções';
	@override String get collection => 'Coleção';
	@override String get deleteCollection => 'Excluir Coleção';
	@override String get removeFromCollection => 'Remover da coleção';
}

// Path: playlists
class Translations$playlists$pt_BR extends Translations$playlists$pt {
	Translations$playlists$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Listas de Reprodução';
	@override String get playlist => 'Lista de Reprodução';
	@override String get delete => 'Excluir Lista de Reprodução';
	@override String get removeItem => 'Remover da lista de reprodução';
}

// Path: music
class Translations$music$pt_BR extends Translations$music$pt {
	Translations$music$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get instantMix => 'Mix Instantâneo';
	@override String get playNext => 'Reproduzir próximo';
	@override String get clearQueue => 'Limpar fila';
	@override String get lyrics => 'Letras';
	@override String get stopPlayback => 'Parar reprodução';
	@override String get previousTrack => 'Faixa anterior';
	@override String get nextTrack => 'Próxima faixa';
	@override String get repeat => 'Repetir';
	@override String get repeatAll => 'Repetir todos';
	@override String get repeatOne => 'Repetir uma vez';
	@override late final Translations$music$discography$pt_BR discography = Translations$music$discography$pt_BR.internal(_root);
	@override String sleepTimerMinutes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minuto',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minutos',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minutos',
	);
}

// Path: watchTogether
class Translations$watchTogether$pt_BR extends Translations$watchTogether$pt {
	Translations$watchTogether$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get removeRoom => 'Remover';
	@override String get hostBadge => 'Servidor';
	@override String get playerIdle => 'Ocioso';
	@override String get remove => 'Remover';
}

// Path: downloads
class Translations$downloads$pt_BR extends Translations$downloads$pt {
	Translations$downloads$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get tvShows => 'Séries';
	@override String get movies => 'Filmes';
	@override String get music => 'Música';
	@override String get downloadQueued => 'Download enfileirado.';
	@override String get deleteAll => 'Excluir tudo';
	@override String get allEpisodes => 'Todos os episódios';
	@override String get syncRuleAvailable => 'Disponível';
	@override late final Translations$downloads$groupings$pt_BR groupings = Translations$downloads$groupings$pt_BR.internal(_root);
}

// Path: companionRemote
class Translations$companionRemote$pt_BR extends Translations$companionRemote$pt {
	Translations$companionRemote$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override late final Translations$companionRemote$remote$pt_BR remote = Translations$companionRemote$remote$pt_BR.internal(_root);
}

// Path: videoSettings
class Translations$videoSettings$pt_BR extends Translations$videoSettings$pt {
	Translations$videoSettings$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'Velocidade de Reprodução';
	@override String get zoom => 'Ampliar';
	@override String get hdrToneMappingPlayer => 'Reprodutor';
	@override String get audioEqualizerActive => 'Personalizado';
}

// Path: performanceOverlay
class Translations$performanceOverlay$pt_BR extends Translations$performanceOverlay$pt {
	Translations$performanceOverlay$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get performance => 'Rendimento';
	@override String get app => 'Aplicativo';
	@override String get rotation => 'Rotação';
	@override String get sampleRate => 'Taxa da amostra';
	@override String get player => 'Reprodutor';
	@override String get playMethod => 'Método de Reprodução';
}

// Path: externalPlayer
class Translations$externalPlayer$pt_BR extends Translations$externalPlayer$pt {
	Translations$externalPlayer$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get off => 'Desligado';
}

// Path: metadataEdit
class Translations$metadataEdit$pt_BR extends Translations$metadataEdit$pt {
	Translations$metadataEdit$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'Editar';
	@override String get screenTitle => 'Editar metadados';
	@override String get title => 'Título';
	@override String get sortTitle => 'Ordenar por título';
	@override String get originalTitle => 'Título original';
	@override String get releaseDate => 'Data do lançamento';
	@override String get studio => 'Estudio';
	@override String get tagline => 'Slogan';
	@override String get poster => 'Poster/Cartaz';
	@override String get allEpisodes => 'Todos os episódios';
	@override String get never => 'Nunca';
	@override String get seasons => 'Temporadas';
	@override String get hide => 'Ocultar';
	@override String get preferredAudioLanguage => 'Idioma preferido de áudio';
	@override String get preferredSubtitleLanguage => 'Idioma de legendas preferido';
	@override String get tags => 'Etiquetas';
	@override String get genre => 'Gênero';
	@override String get director => 'Diretor';
	@override String get writer => 'Escritor';
	@override String get producer => 'Produtor';
	@override String get collection => 'Coleção';
}

// Path: matchScreen
class Translations$matchScreen$pt_BR extends Translations$matchScreen$pt {
	Translations$matchScreen$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get titleHint => 'Título';
	@override String get yearHint => 'Ano';
	@override String get search => 'Busca';
}

// Path: seerr
class Translations$seerr$pt_BR extends Translations$seerr$pt {
	Translations$seerr$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get seasons => 'Temporadas';
	@override String get advancedOptions => 'Avançado';
	@override String get tags => 'Etiquetas';
	@override String get statusAvailable => 'Disponível';
}

// Path: services
class Translations$services$pt_BR extends Translations$services$pt {
	Translations$services$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override late final Translations$services$libraryFilter$pt_BR libraryFilter = Translations$services$libraryFilter$pt_BR.internal(_root);
}

// Path: addServer
class Translations$addServer$pt_BR extends Translations$addServer$pt {
	Translations$addServer$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get username => 'Usuário';
	@override String get password => 'Senha';
	@override String get signIn => 'Entrar';
}

// Path: watchLink
class Translations$watchLink$pt_BR extends Translations$watchLink$pt {
	Translations$watchLink$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get copy => 'cópia de';
}

// Path: homeLayout
class Translations$homeLayout$pt_BR extends Translations$homeLayout$pt {
	Translations$homeLayout$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get home => 'Início';
	@override String get continueWatching => 'Continuar assistindo';
	@override String get recentlyAdded => 'Recentes';
	@override String get hide => 'Ocultar';
	@override String get remove => 'Remover';
}

// Path: fileSources
class Translations$fileSources$pt_BR extends Translations$fileSources$pt {
	Translations$fileSources$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get source => 'Fonte';
	@override String get name => 'Nome';
	@override String get username => 'Usuário';
	@override String get password => 'Senha';
	@override String get connect => 'Conectar';
	@override String get cancel => 'Cancelar';
	@override String get save => 'Salvar';
	@override String get close => 'Fechar';
	@override String get refresh => 'Atualizar';
	@override String get continueReading => 'Continue lendo';
	@override String get continueListening => 'Continuar Escutando';
	@override String get continueWatching => 'Continuar assistindo';
	@override String get play => 'Reproduzir';
	@override String get pause => 'Pausar';
	@override String get stop => 'Parar';
	@override String get delete => 'Excluir';
	@override String get speed => 'Velocidade de Reprodução';
	@override String get sleepOff => 'Desligado';
	@override String get fontSize => 'Tamanho do texto';
	@override String get audio => 'Áudio';
	@override String get video => 'Vídeo';
	@override String get all => 'Todos';
	@override String get signIn => 'Entrar';
	@override String get none => 'Nenhum';
	@override String get fullscreen => 'Tela cheia';
	@override String get audiobooks => 'Livros de áudio';
	@override String get leftToRight => 'Esquerda para direita';
	@override String get rightToLeft => 'Direita para esquerda';
	@override String get zoom => 'Ampliar';
	@override String minutes({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minuto',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minutos',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minutos',
	);
	@override String get googleDrive => 'Google Drive';
}

// Path: lending
class Translations$lending$pt_BR extends Translations$lending$pt {
	Translations$lending$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Cancelar';
}

// Path: common.mediaKind
class Translations$common$mediaKind$pt_BR extends Translations$common$mediaKind$pt {
	Translations$common$mediaKind$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get movie => 'Filme';
	@override String get season => 'Temporada';
	@override String get episode => 'Episódio';
	@override String get artist => 'Artista';
	@override String get album => 'Álbum';
	@override String get track => 'Faixa';
	@override String get collection => 'Coleção';
	@override String get playlist => 'Lista de Reprodução';
	@override String get clip => 'Destaque';
	@override String get photo => 'Fotos';
	@override String get folder => 'Pasta';
}

// Path: themeEditor.slots
class Translations$themeEditor$slots$pt_BR extends Translations$themeEditor$slots$pt {
	Translations$themeEditor$slots$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get text => 'Texto';
}

// Path: hotkeys.actions
class Translations$hotkeys$actions$pt_BR extends Translations$hotkeys$actions$pt {
	Translations$hotkeys$actions$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get chapterNext => 'Próximo capítulo';
	@override String get chapterPrevious => 'Capítulo anterior';
	@override String get episodeNext => 'Próximo episódio';
}

// Path: accountPreferences.watchedIndicatorOptions
class Translations$accountPreferences$watchedIndicatorOptions$pt_BR extends Translations$accountPreferences$watchedIndicatorOptions$pt {
	Translations$accountPreferences$watchedIndicatorOptions$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get none => 'Nunca';
}

// Path: libraries.tabs
class Translations$libraries$tabs$pt_BR extends Translations$libraries$tabs$pt {
	Translations$libraries$tabs$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get browse => 'Navegar';
	@override String get collections => 'Coleções';
	@override String get playlists => 'Listas de Reprodução';
}

// Path: libraries.groupings
class Translations$libraries$groupings$pt_BR extends Translations$libraries$groupings$pt {
	Translations$libraries$groupings$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

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
class Translations$libraries$filterCategories$pt_BR extends Translations$libraries$filterCategories$pt {
	Translations$libraries$filterCategories$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get genre => 'Gênero';
	@override String get year => 'Ano';
	@override String get tag => 'Marcador';
	@override String get unplayed => 'Não reproduzido';
	@override String get favorites => 'Favoritos';
}

// Path: libraries.sortLabels
class Translations$libraries$sortLabels$pt_BR extends Translations$libraries$sortLabels$pt {
	Translations$libraries$sortLabels$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Título';
	@override String get dateAdded => 'Data de adição';
	@override String get releaseDate => 'Data do lançamento';
	@override String get communityRating => 'Avaliação da comunidade';
	@override String get datePlayed => 'Data de reprodução';
	@override String get playCount => 'Número de Reproduções';
	@override String get runtime => 'Duração';
	@override String get premiereDate => 'Data da Estréia';
	@override String get airTime => 'Horário da estreia';
	@override String get studio => 'Estudio';
	@override String get random => 'Aleatório';
	@override String get size => 'Tamanho';
}

// Path: libraries.advancedFilters
class Translations$libraries$advancedFilters$pt_BR extends Translations$libraries$advancedFilters$pt {
	Translations$libraries$advancedFilters$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get yes => 'Sim';
	@override String get no => 'Não';
}

// Path: explore.status
class Translations$explore$status$pt_BR extends Translations$explore$status$pt {
	Translations$explore$status$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get ended => 'Finalizada';
	@override String get upcoming => 'A seguir';
}

// Path: explore.badge
class Translations$explore$badge$pt_BR extends Translations$explore$badge$pt {
	Translations$explore$badge$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get available => 'Disponível';
}

// Path: explore.format
class Translations$explore$format$pt_BR extends Translations$explore$format$pt {
	Translations$explore$format$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get movie => 'Filme';
	@override String get music => 'Música';
	@override String get other => 'Outro';
}

// Path: explore.sourceMaterial
class Translations$explore$sourceMaterial$pt_BR extends Translations$explore$sourceMaterial$pt {
	Translations$explore$sourceMaterial$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get novel => 'Romance';
	@override String get musicRelease => 'Música';
	@override String get otherMedia => 'Outro';
}

// Path: explore.creditRole
class Translations$explore$creditRole$pt_BR extends Translations$explore$creditRole$pt {
	Translations$explore$creditRole$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get actor => 'Ator';
	@override String get director => 'Diretor';
	@override String get writer => 'Escritor';
	@override String get producer => 'Produtor';
	@override String get creator => 'Criador';
	@override String get composer => 'Compositor';
}

// Path: explore.detail
class Translations$explore$detail$pt_BR extends Translations$explore$detail$pt {
	Translations$explore$detail$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get originalTitle => 'Título original';
	@override String get studios => 'Estúdios';
	@override String get language => 'Idioma';
	@override String get ended => 'Finalizada';
	@override String get tags => 'Etiquetas';
	@override String get schedule => 'Programação';
}

// Path: music.discography
class Translations$music$discography$pt_BR extends Translations$music$discography$pt {
	Translations$music$discography$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get live => 'Ao vivo';
}

// Path: downloads.groupings
class Translations$downloads$groupings$pt_BR extends Translations$downloads$groupings$pt {
	Translations$downloads$groupings$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get collections => 'Coleções';
}

// Path: companionRemote.remote
class Translations$companionRemote$remote$pt_BR extends Translations$companionRemote$remote$pt {
	Translations$companionRemote$remote$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get tabPlay => 'Reproduzir';
	@override String get tabMore => 'Mais';
	@override String get tabLibraries => 'Bibliotecas';
	@override String get tabSearch => 'Busca';
	@override String get tabSettings => 'Configurações';
	@override String get previous => 'Anterior';
	@override String get next => 'Próximo';
	@override String get stop => 'Parar';
	@override String get volumeDown => 'Baixo';
	@override String get volumeUp => 'Para cima';
	@override String get fullscreen => 'Tela Cheia';
	@override String get subtitles => 'Legendas';
	@override String get audio => 'Áudio';
}

// Path: services.libraryFilter
class Translations$services$libraryFilter$pt_BR extends Translations$services$libraryFilter$pt {
	Translations$services$libraryFilter$pt_BR.internal(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get modeBlacklist => 'Lista negra';
	@override String get modeWhitelist => 'Lista branca';
	@override String get libraries => 'Bibliotecas';
}

/// The flat map containing all translations for locale <pt-BR>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsPtBr {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'cast.subtitle' => 'Legendas',
			'cast.castToDevice' => 'Transmitir para o dispositivo',
			'appIcon.defaultIcon' => 'Padrão',
			'auth.quickConnect' => 'Conexão rápida',
			'auth.useQuickConnect' => 'Usar Conexão Rápida',
			'auth.quickConnectCancel' => 'Cancelar',
			'common.cancel' => 'Cancelar',
			'common.save' => 'Salvar',
			'common.close' => 'Fechar',
			'common.reset' => 'Resetar',
			'common.submit' => 'Enviar',
			'common.retry' => 'Retentar',
			'common.unknown' => 'Desconhecido',
			'common.refresh' => 'Atualizar',
			'common.yes' => 'Sim',
			'common.no' => 'Não',
			'common.delete' => 'Excluir',
			'common.edit' => 'Editar',
			'common.shuffle' => 'Aleatório',
			'common.connect' => 'Conectar',
			'common.disconnect' => 'Desconectar',
			'common.play' => 'Reproduzir',
			'common.pause' => 'Pausar',
			'common.resume' => 'Retomar',
			'common.error' => 'Erro',
			'common.search' => 'Busca',
			'common.home' => 'Início',
			'common.back' => 'Voltar',
			'common.settings' => 'Configurações',
			'common.mute' => 'Mudo',
			'common.off' => 'Desligado',
			'common.fullscreen' => 'Tela Cheia',
			'common.mediaKind.movie' => 'Filme',
			'common.mediaKind.season' => 'Temporada',
			'common.mediaKind.episode' => 'Episódio',
			'common.mediaKind.artist' => 'Artista',
			'common.mediaKind.album' => 'Álbum',
			'common.mediaKind.track' => 'Faixa',
			'common.mediaKind.collection' => 'Coleção',
			'common.mediaKind.playlist' => 'Lista de Reprodução',
			'common.mediaKind.clip' => 'Destaque',
			'common.mediaKind.photo' => 'Fotos',
			'common.mediaKind.folder' => 'Pasta',
			'screens.subtitleStyling' => 'Estilização da legenda',
			'screens.logs' => 'Registros',
			'settings.title' => 'Configurações',
			'settings.language' => 'Idioma',
			'settings.theme' => 'Tema',
			'settings.advanced' => 'Avançado',
			'settings.systemTheme' => 'Sistema',
			'settings.listView' => 'Lista',
			'settings.contentScreensaverAllLibraries' => 'Todas as bibliotecas',
			'settings.rowSizeLarge' => 'Grande',
			'settings.continueWatchingPlay' => 'Reproduzir',
			'settings.episodePlay' => 'Reproduzir',
			'settings.visualEffectsAuto' => 'Automático',
			'settings.playbackBufferLarge' => 'Grande',
			'settings.playbackBufferExtraLarge' => 'Extra Grande',
			'settings.musicQualityTitle' => 'Qualidade da Música',
			'settings.subtitleStyling' => 'Estilização da legenda',
			'settings.cloudBackupUsername' => 'Usuário',
			'settings.cloudBackupPassword' => 'Senha',
			'settings.skipMarkerModeOff' => 'Desligado',
			'settings.audioChannelLimit' => 'Canais de áudio',
			'settings.dvConversionAuto' => 'Automático',
			'settings.hdrSdrConversionAuto' => 'Automático',
			'settings.hdrSdrConversionDevice' => 'Dispositivo',
			'settings.hdrSdrConversionPlayer' => 'Reprodutor',
			'settings.deinterlaceOff' => 'Desligado',
			'settings.deinterlaceVideo' => 'Vídeo',
			'settings.general' => 'Geral',
			'settings.display' => 'Exibição',
			'settings.navigation' => 'Navegação',
			'settings.liveTv' => 'TV ao Vivo',
			'settings.player' => 'Reprodutor',
			'settings.audio' => 'Áudio',
			'settings.quality' => 'Qualidade',
			'settings.subtitles' => 'Legendas',
			'settings.controls' => 'Controles',
			'settings.scopePlaybackSpeed' => 'Velocidade de Reprodução',
			'settings.scopeAspectRatio' => 'Proporção da tela',
			'settings.secondsUnit' => ({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(seconds, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} segundo', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} segundos', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} segundos', ), 
			'settings.minutesUnit' => ({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(minutes, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minuto', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minutos', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minutos', ), 
			'themeEditor.custom' => 'Personalizado',
			'themeEditor.preview' => 'Prévia',
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
			'fileInfo.file' => 'Arquivo',
			'fileInfo.codecTag' => 'Marcador do codec',
			'fileInfo.resolution' => 'Resolução',
			'fileInfo.rotation' => 'Rotação',
			'fileInfo.aspectRatio' => 'Proporção da tela',
			'fileInfo.profile' => 'Perfil',
			'fileInfo.level' => 'Nível',
			'fileInfo.bitDepth' => 'Profundidade de bits',
			'fileInfo.pixelFormat' => 'Formato de pixel',
			'fileInfo.colorSpace' => 'Espaço de cores',
			'fileInfo.colorPrimaries' => 'Cores primárias',
			'fileInfo.colorTransfer' => 'Transferência de cor',
			'fileInfo.interlaced' => 'Entrelaçado',
			'fileInfo.anamorphic' => 'Anamórfico',
			'fileInfo.language' => 'Idioma',
			'fileInfo.channels' => 'Canais',
			'fileInfo.sampleRate' => 'Taxa da amostra',
			'fileInfo.path' => 'Local',
			'fileInfo.size' => 'Tamanho',
			'fileInfo.container' => 'Formato',
			'fileInfo.duration' => 'Duração',
			'fileInfo.protocol' => 'Protocolo',
			'fileInfo.transcoding' => 'Transcodificação',
			'fileInfo.subtitlesOff' => 'Desligado',
			'fileInfo.flagDefault' => 'Padrão',
			'fileInfo.flagForced' => 'Forçado',
			'fileInfo.flagExternal' => 'Externa',
			'mediaMenu.deleteEpisodeConfirm' => 'Excluir episódio',
			'mediaMenu.rate' => 'Avaliação',
			'mediaMenu.playFromBeginning' => 'Reproduzir do início',
			'rateSheet.title' => 'Avaliação',
			'rateSheet.server' => 'Servidor',
			'rateSheet.favorite' => 'Favorito',
			'accessibility.mediaCardWatched' => 'Assistido',
			'accessibility.red' => 'Vermelho',
			'accessibility.green' => 'Verde',
			'accessibility.blue' => 'Azul',
			'videoControls.audioLabel' => 'Áudio',
			'videoControls.subtitlesLabel' => 'Legendas',
			'videoControls.stretch' => 'Esticar',
			'videoControls.playNext' => 'Reproduzir próximo',
			'videoControls.playButton' => 'Reproduzir',
			'videoControls.pauseButton' => 'Pausar',
			'videoControls.nextButton' => 'Próximo episódio',
			'videoControls.previousChapterButton' => 'Capítulo anterior',
			'videoControls.nextChapterButton' => 'Próximo capítulo',
			'videoControls.muteButton' => 'Mudo',
			'videoControls.unmuteButton' => 'Sair do Mudo',
			'videoControls.versionColumnHeader' => 'Versão',
			'videoControls.qualityColumnHeader' => 'Qualidade',
			'videoControls.aspectRatioButton' => 'Proporção da tela',
			'videoControls.language' => 'Idioma',
			'videoControls.nextEpisode' => 'Próximo episódio',
			'messages.noResultsFound' => 'Nenhum resultado encontrado.',
			'subtitlingStyling.text' => 'Texto',
			'subtitlingStyling.textColor' => 'Cor do texto',
			'subtitlingStyling.bold' => 'Negrito',
			'subtitlingStyling.renderResolutionScreen' => 'Resolução de tela',
			'subtitlingStyling.renderResolutionVideo' => 'Resolução de vídeo',
			'mpvConfig.deletePreset' => 'Excluir',
			'profiles.delete' => 'Excluir',
			'profiles.signOut' => 'Sair',
			'profiles.removePin' => 'Remover',
			'profiles.add' => 'Adicionar',
			'profiles.connectionDefault' => 'Padrão',
			'profiles.removeConnection' => 'Remover',
			'accountPreferences.preferredAudioLanguage' => 'Idioma preferido de áudio',
			'accountPreferences.preferredSubtitleLanguage' => 'Idioma de legendas preferido',
			'accountPreferences.watchedIndicatorOptions.none' => 'Nunca',
			'discover.continueWatching' => 'Continuar assistindo',
			'discover.nextUp' => 'A seguir',
			'discover.recentlyAdded' => 'Recentes',
			'discover.overview' => 'Sinopse',
			'discover.studio' => 'Estudio',
			'discover.director' => 'Diretor',
			'discover.directors' => 'Diretores',
			'discover.movie' => 'Filme',
			'discover.moreLikeThis' => 'Mais Disso',
			'libraries.title' => 'Bibliotecas',
			'libraries.scanLibrary' => 'Rastrear biblioteca',
			'libraries.refreshMetadata' => 'Atualizar metadados',
			'libraries.resetFilters' => 'Redefinir filtros',
			'libraries.all' => 'Todos',
			'libraries.sort' => 'Ordenar',
			'libraries.sortBy' => 'Ordenar Por',
			'libraries.filters' => 'Filtros',
			'libraries.folders' => 'Pastas',
			'libraries.tabs.browse' => 'Navegar',
			'libraries.tabs.collections' => 'Coleções',
			'libraries.tabs.playlists' => 'Listas de Reprodução',
			'libraries.groupings.all' => 'Todos',
			'libraries.groupings.movies' => 'Filmes',
			'libraries.groupings.shows' => 'Séries',
			'libraries.groupings.seasons' => 'Temporadas',
			'libraries.groupings.episodes' => 'Episódios',
			'libraries.groupings.artists' => 'Artistas',
			'libraries.groupings.albums' => 'Álbuns',
			'libraries.groupings.tracks' => 'Faixas',
			'libraries.groupings.folders' => 'Pastas',
			'libraries.filterCategories.genre' => 'Gênero',
			'libraries.filterCategories.year' => 'Ano',
			'libraries.filterCategories.tag' => 'Marcador',
			'libraries.filterCategories.unplayed' => 'Não reproduzido',
			'libraries.filterCategories.favorites' => 'Favoritos',
			'libraries.sortLabels.title' => 'Título',
			'libraries.sortLabels.dateAdded' => 'Data de adição',
			'libraries.sortLabels.releaseDate' => 'Data do lançamento',
			'libraries.sortLabels.communityRating' => 'Avaliação da comunidade',
			'libraries.sortLabels.datePlayed' => 'Data de reprodução',
			'libraries.sortLabels.playCount' => 'Número de Reproduções',
			'libraries.sortLabels.runtime' => 'Duração',
			'libraries.sortLabels.premiereDate' => 'Data da Estréia',
			'libraries.sortLabels.airTime' => 'Horário da estreia',
			'libraries.sortLabels.studio' => 'Estudio',
			'libraries.sortLabels.random' => 'Aleatório',
			'libraries.sortLabels.size' => 'Tamanho',
			'libraries.advancedFilters.yes' => 'Sim',
			'libraries.advancedFilters.no' => 'Não',
			'hubDetail.title' => 'Título',
			'hubDetail.dateAdded' => 'Data de adição',
			'navigation.libraries' => 'Bibliotecas',
			'navigation.liveTv' => 'TV ao Vivo',
			'explore.status.ended' => 'Finalizada',
			'explore.status.upcoming' => 'A seguir',
			'explore.badge.available' => 'Disponível',
			'explore.format.movie' => 'Filme',
			'explore.format.music' => 'Música',
			'explore.format.other' => 'Outro',
			'explore.sourceMaterial.novel' => 'Romance',
			'explore.sourceMaterial.musicRelease' => 'Música',
			'explore.sourceMaterial.otherMedia' => 'Outro',
			'explore.creditRole.actor' => 'Ator',
			'explore.creditRole.director' => 'Diretor',
			'explore.creditRole.writer' => 'Escritor',
			'explore.creditRole.producer' => 'Produtor',
			'explore.creditRole.creator' => 'Criador',
			'explore.creditRole.composer' => 'Compositor',
			'explore.detail.originalTitle' => 'Título original',
			'explore.detail.studios' => 'Estúdios',
			'explore.detail.language' => 'Idioma',
			'explore.detail.ended' => 'Finalizada',
			'explore.detail.tags' => 'Etiquetas',
			'explore.detail.schedule' => 'Programação',
			'liveTv.title' => 'TV ao Vivo',
			'liveTv.guide' => 'Guia',
			'liveTv.unknownHub' => 'Desconhecido',
			'liveTv.live' => 'Ao vivo',
			'liveTv.premiereBadge' => 'Novo',
			'liveTv.channelsSection' => 'Canais',
			'liveTv.programsSection' => 'Programas',
			'liveTv.favorites' => 'Favoritos',
			'liveTv.record' => 'Gravar',
			'liveTv.recordSeries' => 'Gravar série',
			'liveTv.recordings' => 'Gravações',
			'liveTv.manageRecording' => 'Gerenciar gravação',
			'liveTv.cancelRecording' => 'Cancelar gravação',
			'liveTv.recordingScheduled' => 'Gravação agendada.',
			'liveTv.editRuleAction' => 'Editar',
			'collections.title' => 'Coleções',
			'collections.collection' => 'Coleção',
			'collections.deleteCollection' => 'Excluir Coleção',
			'collections.removeFromCollection' => 'Remover da coleção',
			'playlists.title' => 'Listas de Reprodução',
			'playlists.playlist' => 'Lista de Reprodução',
			'playlists.delete' => 'Excluir Lista de Reprodução',
			'playlists.removeItem' => 'Remover da lista de reprodução',
			'music.instantMix' => 'Mix Instantâneo',
			'music.playNext' => 'Reproduzir próximo',
			'music.clearQueue' => 'Limpar fila',
			'music.lyrics' => 'Letras',
			'music.stopPlayback' => 'Parar reprodução',
			'music.previousTrack' => 'Faixa anterior',
			'music.nextTrack' => 'Próxima faixa',
			'music.repeat' => 'Repetir',
			'music.repeatAll' => 'Repetir todos',
			'music.repeatOne' => 'Repetir uma vez',
			'music.discography.live' => 'Ao vivo',
			'music.sleepTimerMinutes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minuto', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minutos', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minutos', ), 
			'watchTogether.removeRoom' => 'Remover',
			'watchTogether.hostBadge' => 'Servidor',
			'watchTogether.playerIdle' => 'Ocioso',
			'watchTogether.remove' => 'Remover',
			'downloads.tvShows' => 'Séries',
			'downloads.movies' => 'Filmes',
			'downloads.music' => 'Música',
			'downloads.downloadQueued' => 'Download enfileirado.',
			'downloads.deleteAll' => 'Excluir tudo',
			'downloads.allEpisodes' => 'Todos os episódios',
			'downloads.syncRuleAvailable' => 'Disponível',
			'downloads.groupings.collections' => 'Coleções',
			'companionRemote.remote.tabPlay' => 'Reproduzir',
			'companionRemote.remote.tabMore' => 'Mais',
			'companionRemote.remote.tabLibraries' => 'Bibliotecas',
			'companionRemote.remote.tabSearch' => 'Busca',
			'companionRemote.remote.tabSettings' => 'Configurações',
			'companionRemote.remote.previous' => 'Anterior',
			'companionRemote.remote.next' => 'Próximo',
			'companionRemote.remote.stop' => 'Parar',
			'companionRemote.remote.volumeDown' => 'Baixo',
			'companionRemote.remote.volumeUp' => 'Para cima',
			'companionRemote.remote.fullscreen' => 'Tela Cheia',
			'companionRemote.remote.subtitles' => 'Legendas',
			'companionRemote.remote.audio' => 'Áudio',
			'videoSettings.playbackSpeed' => 'Velocidade de Reprodução',
			'videoSettings.zoom' => 'Ampliar',
			'videoSettings.hdrToneMappingPlayer' => 'Reprodutor',
			'videoSettings.audioEqualizerActive' => 'Personalizado',
			'performanceOverlay.performance' => 'Rendimento',
			'performanceOverlay.app' => 'Aplicativo',
			'performanceOverlay.rotation' => 'Rotação',
			'performanceOverlay.sampleRate' => 'Taxa da amostra',
			'performanceOverlay.player' => 'Reprodutor',
			'performanceOverlay.playMethod' => 'Método de Reprodução',
			'externalPlayer.off' => 'Desligado',
			'metadataEdit.editMetadata' => 'Editar',
			'metadataEdit.screenTitle' => 'Editar metadados',
			'metadataEdit.title' => 'Título',
			'metadataEdit.sortTitle' => 'Ordenar por título',
			'metadataEdit.originalTitle' => 'Título original',
			'metadataEdit.releaseDate' => 'Data do lançamento',
			'metadataEdit.studio' => 'Estudio',
			'metadataEdit.tagline' => 'Slogan',
			'metadataEdit.poster' => 'Poster/Cartaz',
			'metadataEdit.allEpisodes' => 'Todos os episódios',
			'metadataEdit.never' => 'Nunca',
			'metadataEdit.seasons' => 'Temporadas',
			'metadataEdit.hide' => 'Ocultar',
			'metadataEdit.preferredAudioLanguage' => 'Idioma preferido de áudio',
			'metadataEdit.preferredSubtitleLanguage' => 'Idioma de legendas preferido',
			'metadataEdit.tags' => 'Etiquetas',
			'metadataEdit.genre' => 'Gênero',
			'metadataEdit.director' => 'Diretor',
			'metadataEdit.writer' => 'Escritor',
			'metadataEdit.producer' => 'Produtor',
			'metadataEdit.collection' => 'Coleção',
			'matchScreen.titleHint' => 'Título',
			'matchScreen.yearHint' => 'Ano',
			'matchScreen.search' => 'Busca',
			'seerr.seasons' => 'Temporadas',
			'seerr.advancedOptions' => 'Avançado',
			'seerr.tags' => 'Etiquetas',
			'seerr.statusAvailable' => 'Disponível',
			'services.libraryFilter.modeBlacklist' => 'Lista negra',
			'services.libraryFilter.modeWhitelist' => 'Lista branca',
			'services.libraryFilter.libraries' => 'Bibliotecas',
			'addServer.username' => 'Usuário',
			'addServer.password' => 'Senha',
			'addServer.signIn' => 'Entrar',
			'watchLink.copy' => 'cópia de',
			'homeLayout.home' => 'Início',
			'homeLayout.continueWatching' => 'Continuar assistindo',
			'homeLayout.recentlyAdded' => 'Recentes',
			'homeLayout.hide' => 'Ocultar',
			'homeLayout.remove' => 'Remover',
			'fileSources.source' => 'Fonte',
			'fileSources.name' => 'Nome',
			'fileSources.username' => 'Usuário',
			'fileSources.password' => 'Senha',
			'fileSources.connect' => 'Conectar',
			'fileSources.cancel' => 'Cancelar',
			'fileSources.save' => 'Salvar',
			'fileSources.close' => 'Fechar',
			'fileSources.refresh' => 'Atualizar',
			'fileSources.continueReading' => 'Continue lendo',
			'fileSources.continueListening' => 'Continuar Escutando',
			'fileSources.continueWatching' => 'Continuar assistindo',
			'fileSources.play' => 'Reproduzir',
			'fileSources.pause' => 'Pausar',
			'fileSources.stop' => 'Parar',
			'fileSources.delete' => 'Excluir',
			'fileSources.speed' => 'Velocidade de Reprodução',
			'fileSources.sleepOff' => 'Desligado',
			'fileSources.fontSize' => 'Tamanho do texto',
			'fileSources.audio' => 'Áudio',
			'fileSources.video' => 'Vídeo',
			'fileSources.all' => 'Todos',
			'fileSources.signIn' => 'Entrar',
			'fileSources.none' => 'Nenhum',
			'fileSources.fullscreen' => 'Tela cheia',
			'fileSources.audiobooks' => 'Livros de áudio',
			'fileSources.leftToRight' => 'Esquerda para direita',
			'fileSources.rightToLeft' => 'Direita para esquerda',
			'fileSources.zoom' => 'Ampliar',
			'fileSources.minutes' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minuto', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minutos', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minutos', ), 
			'fileSources.googleDrive' => 'Google Drive',
			'lending.cancel' => 'Cancelar',
			_ => null,
		};
	}
}
