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
	@override late final _Translations$app$pt_PT app = _Translations$app$pt_PT._(_root);
	@override late final _Translations$appIcon$pt_PT appIcon = _Translations$appIcon$pt_PT._(_root);
	@override late final _Translations$auth$pt_PT auth = _Translations$auth$pt_PT._(_root);
	@override late final _Translations$common$pt_PT common = _Translations$common$pt_PT._(_root);
	@override late final _Translations$screens$pt_PT screens = _Translations$screens$pt_PT._(_root);
	@override late final _Translations$update$pt_PT update = _Translations$update$pt_PT._(_root);
	@override late final _Translations$supporter$pt_PT supporter = _Translations$supporter$pt_PT._(_root);
	@override late final _Translations$settings$pt_PT settings = _Translations$settings$pt_PT._(_root);
	@override late final _Translations$themeEditor$pt_PT themeEditor = _Translations$themeEditor$pt_PT._(_root);
	@override late final _Translations$search$pt_PT search = _Translations$search$pt_PT._(_root);
	@override late final _Translations$hotkeys$pt_PT hotkeys = _Translations$hotkeys$pt_PT._(_root);
	@override late final _Translations$fileInfo$pt_PT fileInfo = _Translations$fileInfo$pt_PT._(_root);
	@override late final _Translations$mediaMenu$pt_PT mediaMenu = _Translations$mediaMenu$pt_PT._(_root);
	@override late final _Translations$rateSheet$pt_PT rateSheet = _Translations$rateSheet$pt_PT._(_root);
	@override late final _Translations$accessibility$pt_PT accessibility = _Translations$accessibility$pt_PT._(_root);
	@override late final _Translations$tooltips$pt_PT tooltips = _Translations$tooltips$pt_PT._(_root);
	@override late final _Translations$audioTracks$pt_PT audioTracks = _Translations$audioTracks$pt_PT._(_root);
	@override late final _Translations$videoControls$pt_PT videoControls = _Translations$videoControls$pt_PT._(_root);
	@override late final _Translations$messages$pt_PT messages = _Translations$messages$pt_PT._(_root);
	@override late final _Translations$subtitlingStyling$pt_PT subtitlingStyling = _Translations$subtitlingStyling$pt_PT._(_root);
	@override late final _Translations$mpvConfig$pt_PT mpvConfig = _Translations$mpvConfig$pt_PT._(_root);
	@override late final _Translations$dialog$pt_PT dialog = _Translations$dialog$pt_PT._(_root);
	@override late final _Translations$profiles$pt_PT profiles = _Translations$profiles$pt_PT._(_root);
	@override late final _Translations$connections$pt_PT connections = _Translations$connections$pt_PT._(_root);
	@override late final _Translations$accountPreferences$pt_PT accountPreferences = _Translations$accountPreferences$pt_PT._(_root);
	@override late final _Translations$discover$pt_PT discover = _Translations$discover$pt_PT._(_root);
	@override late final _Translations$errors$pt_PT errors = _Translations$errors$pt_PT._(_root);
	@override late final _Translations$libraries$pt_PT libraries = _Translations$libraries$pt_PT._(_root);
	@override late final _Translations$about$pt_PT about = _Translations$about$pt_PT._(_root);
	@override late final _Translations$serverSelection$pt_PT serverSelection = _Translations$serverSelection$pt_PT._(_root);
	@override late final _Translations$hubDetail$pt_PT hubDetail = _Translations$hubDetail$pt_PT._(_root);
	@override late final _Translations$logs$pt_PT logs = _Translations$logs$pt_PT._(_root);
	@override late final _Translations$startup$pt_PT startup = _Translations$startup$pt_PT._(_root);
	@override late final _Translations$licenses$pt_PT licenses = _Translations$licenses$pt_PT._(_root);
	@override late final _Translations$navigation$pt_PT navigation = _Translations$navigation$pt_PT._(_root);
	@override late final _Translations$explore$pt_PT explore = _Translations$explore$pt_PT._(_root);
	@override late final _Translations$liveTv$pt_PT liveTv = _Translations$liveTv$pt_PT._(_root);
	@override late final _Translations$collections$pt_PT collections = _Translations$collections$pt_PT._(_root);
	@override late final _Translations$playlists$pt_PT playlists = _Translations$playlists$pt_PT._(_root);
	@override late final _Translations$music$pt_PT music = _Translations$music$pt_PT._(_root);
	@override late final _Translations$watchTogether$pt_PT watchTogether = _Translations$watchTogether$pt_PT._(_root);
	@override late final _Translations$downloads$pt_PT downloads = _Translations$downloads$pt_PT._(_root);
	@override late final _Translations$shaders$pt_PT shaders = _Translations$shaders$pt_PT._(_root);
	@override late final _Translations$companionRemote$pt_PT companionRemote = _Translations$companionRemote$pt_PT._(_root);
	@override late final _Translations$videoSettings$pt_PT videoSettings = _Translations$videoSettings$pt_PT._(_root);
	@override late final _Translations$performanceOverlay$pt_PT performanceOverlay = _Translations$performanceOverlay$pt_PT._(_root);
	@override late final _Translations$externalPlayer$pt_PT externalPlayer = _Translations$externalPlayer$pt_PT._(_root);
	@override late final _Translations$metadataEdit$pt_PT metadataEdit = _Translations$metadataEdit$pt_PT._(_root);
	@override late final _Translations$matchScreen$pt_PT matchScreen = _Translations$matchScreen$pt_PT._(_root);
	@override late final _Translations$serverTasks$pt_PT serverTasks = _Translations$serverTasks$pt_PT._(_root);
	@override late final _Translations$trakt$pt_PT trakt = _Translations$trakt$pt_PT._(_root);
	@override late final _Translations$seerr$pt_PT seerr = _Translations$seerr$pt_PT._(_root);
	@override late final _Translations$services$pt_PT services = _Translations$services$pt_PT._(_root);
	@override late final _Translations$addServer$pt_PT addServer = _Translations$addServer$pt_PT._(_root);
	@override late final _Translations$deepLinks$pt_PT deepLinks = _Translations$deepLinks$pt_PT._(_root);
}

// Path: app
class _Translations$app$pt_PT extends Translations$app$pt {
	_Translations$app$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
}

// Path: appIcon
class _Translations$appIcon$pt_PT extends Translations$appIcon$pt {
	_Translations$appIcon$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ícone da aplicação';
	@override String get defaultIcon => 'Predefinido';
	@override String get current => 'Ícone atual';
	@override String get locked => 'Incluído no Pacote de temas e ícones';
	@override String get lockedHint => 'Os ícones alternativos estão incluídos no Pacote de temas e ícones.';
	@override String get changeFailed => 'Não foi possível alterar o ícone da aplicação';
	@override String get launcherHint => 'O novo ícone aparece no ecrã inicial assim que sair do Plezy.';
	@override String get tvLauncherHint => 'O novo banner aparece assim que sair do Plezy. O Android TV pode continuar a mostrar o antigo até a TV ser reiniciada.';
	@override late final _Translations$appIcon$names$pt_PT names = _Translations$appIcon$names$pt_PT._(_root);
}

// Path: auth
class _Translations$auth$pt_PT extends Translations$auth$pt {
	_Translations$auth$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Iniciar sessão com o Plex';
	@override String get showQRCode => 'Mostrar código QR';
	@override String get authenticate => 'Autenticar';
	@override String get authenticationTimeout => 'A autenticação expirou. Tente novamente.';
	@override String get scanQRToSignIn => 'Digitalize este código QR para iniciar sessão';
	@override String get waitingForAuth => 'A aguardar autenticação...\nInicie sessão no navegador.';
	@override String get useBrowser => 'Usar navegador';
	@override String get or => 'ou';
	@override String connectToMediaBrowser({required Object product}) => 'Ligar ao ${product}';
	@override String get quickConnect => 'Quick Connect';
	@override String get useQuickConnect => 'Usar Quick Connect';
	@override String get quickConnectInstructions => 'Abra o Quick Connect no Jellyfin e introduza este código.';
	@override String get quickConnectWaiting => 'A aguardar aprovação…';
	@override String get quickConnectCancel => 'Cancelar';
	@override String get quickConnectExpired => 'O Quick Connect expirou. Tente novamente.';
	@override String get localDataRecoveryRequired => 'O Plezy não conseguiu recuperar com segurança os dados locais de acesso e de reproduções pendentes. Inicie sessão novamente.';
	@override String get pinCheckRejected => 'A verificação do PIN do Plex foi rejeitada';
}

// Path: common
class _Translations$common$pt_PT extends Translations$common$pt {
	_Translations$common$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Cancelar';
	@override String get save => 'Guardar';
	@override String get close => 'Fechar';
	@override String get clear => 'Limpar';
	@override String get reset => 'Repor';
	@override String get later => 'Depois';
	@override String get submit => 'Enviar';
	@override String get confirm => 'Confirmar';
	@override String get retry => 'Tentar novamente';
	@override String get logout => 'Sair';
	@override String get unknown => 'Desconhecido';
	@override String get refresh => 'Atualizar';
	@override String get yes => 'Sim';
	@override String get no => 'Não';
	@override String get delete => 'Eliminar';
	@override String get edit => 'Editar';
	@override String get shuffle => 'Aleatório';
	@override String get addTo => 'Adicionar a...';
	@override String get createNew => 'Criar novo';
	@override String get connect => 'Ligar';
	@override String get disconnect => 'Desligar';
	@override String get play => 'Reproduzir';
	@override String get pause => 'Pausa';
	@override String get resume => 'Retomar';
	@override String get error => 'Erro';
	@override String get search => 'Pesquisar';
	@override String get home => 'Início';
	@override String get back => 'Voltar';
	@override String get settings => 'Definições';
	@override String get mute => 'Silenciar';
	@override String get ok => 'OK';
	@override String get off => 'Desativado';
	@override String get options => 'Opções';
	@override String seasonNumber({required Object number}) => 'Temporada ${number}';
	@override String episodeNumberTitle({required Object number, required Object title}) => 'Episódio ${number} - ${title}';
	@override String chapterNumber({required Object number}) => 'Capítulo ${number}';
	@override String get reconnect => 'Voltar a ligar';
	@override String get viewAll => 'Ver tudo';
	@override String get checkingNetwork => 'A verificar a rede...';
	@override String get loadingServers => 'A carregar servidores...';
	@override String get connectingToServers => 'A ligar aos servidores...';
	@override String get startingOfflineMode => 'A iniciar o modo offline...';
	@override String get loading => 'A carregar...';
	@override String get fullscreen => 'Ecrã inteiro';
	@override String get exitFullscreen => 'Sair do ecrã inteiro';
	@override String get pressBackAgainToExit => 'Prima Voltar novamente para sair';
	@override late final _Translations$common$ratingSource$pt_PT ratingSource = _Translations$common$ratingSource$pt_PT._(_root);
	@override String get notAvailable => 'N/D';
	@override String get url => 'URL';
	@override String get letterKeys => 'ABC';
	@override late final _Translations$common$mediaKind$pt_PT mediaKind = _Translations$common$mediaKind$pt_PT._(_root);
}

// Path: screens
class _Translations$screens$pt_PT extends Translations$screens$pt {
	_Translations$screens$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Licenças';
	@override String get switchProfile => 'Mudar de perfil';
	@override String get subtitleStyling => 'Estilo das legendas';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Registos';
}

// Path: update
class _Translations$update$pt_PT extends Translations$update$pt {
	_Translations$update$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get available => 'Atualização disponível';
	@override String versionAvailable({required Object version}) => 'A versão ${version} está disponível';
	@override String currentVersion({required Object version}) => 'Atual: ${version}';
	@override String get skipVersion => 'Saltar esta versão';
	@override String get viewRelease => 'Ver versão';
	@override String get latestVersion => 'Tem a versão mais recente';
	@override String get checkFailed => 'Falha ao verificar atualizações';
}

// Path: supporter
class _Translations$supporter$pt_PT extends Translations$supporter$pt {
	_Translations$supporter$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Pacote de temas e ícones';
	@override String get intro => 'Uma compra única e opcional que adiciona extras visuais:';
	@override String get presetThemes => 'Temas predefinidos';
	@override String get presetThemesDescription => 'Brasa, Geleira, Floresta, Ameixa e Papel';
	@override String get customTheme => 'Tema personalizado';
	@override String get customThemeDescription => 'Escolha cada cor à sua maneira';
	@override String get appIcons => 'Ícones da aplicação';
	@override String get appIconsDescription => 'Escolha um ícone alternativo do Plezy';
	@override String buy({required Object price}) => 'Comprar por ${price}';
	@override String get loadingPrice => 'A carregar preço...';
	@override String get restore => 'Restaurar compras';
	@override String get pending => 'A sua compra aguarda pagamento ou aprovação. Os extras serão desbloqueados assim que a loja a concluir.';
	@override String get thankYouTitle => 'Obrigado pela sua compra';
	@override String get thankYouBody => 'O Pacote de temas e ícones está desbloqueado.';
	@override String get tileSubtitle => 'Desbloqueie temas e ícones da aplicação com uma compra única';
	@override String get tileSubtitleThemesOnly => 'Desbloqueie temas com uma compra única';
	@override String get tileUnlocked => 'Desbloqueado — obrigado pela sua compra';
	@override late final _Translations$supporter$errors$pt_PT errors = _Translations$supporter$errors$pt_PT._(_root);
}

// Path: settings
class _Translations$settings$pt_PT extends Translations$settings$pt {
	_Translations$settings$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Definições';
	@override String get supportDeveloper => 'Apoie o Plezy';
	@override String get supportDeveloperDescription => 'Faça um donativo via Liberapay para financiar o desenvolvimento';
	@override String get language => 'Idioma';
	@override String get theme => 'Tema';
	@override String get appearance => 'Aparência';
	@override String get videoPlayback => 'Reprodução de vídeo';
	@override String get videoPlaybackDescription => 'Configurar o comportamento da reprodução';
	@override String get advanced => 'Avançado';
	@override String get episodePosterMode => 'Estilo do póster do episódio';
	@override String get seriesPoster => 'Póster da série';
	@override String get seasonPoster => 'Póster da temporada';
	@override String get episodeThumbnail => 'Miniatura';
	@override String get showHeroSectionDescription => 'Mostrar o carrossel de conteúdo em destaque no ecrã inicial';
	@override String get secondsLabel => 'Segundos';
	@override String get minutesLabel => 'Minutos';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => 'Introduza a duração (${min}-${max})';
	@override String get systemTheme => 'Sistema';
	@override String get lightTheme => 'Claro';
	@override String get darkTheme => 'Escuro';
	@override String get oledTheme => 'OLED';
	@override String get emberTheme => 'Brasa';
	@override String get glacierTheme => 'Geleira';
	@override String get forestTheme => 'Floresta';
	@override String get plumTheme => 'Ameixa';
	@override String get paperTheme => 'Papel';
	@override String get libraryDensity => 'Densidade da biblioteca';
	@override String get displayScale => 'Escala de apresentação';
	@override String get compact => 'Compacto';
	@override String get comfortable => 'Confortável';
	@override String get gridSpacing => 'Espaçamento da grelha';
	@override String get gridSpacingTight => 'Compacto';
	@override String get gridSpacingNormal => 'Normal';
	@override String get gridSpacingSpacious => 'Espaçoso';
	@override String get tvCornerSpotlightBackdrop => 'Imagem de destaque no canto';
	@override String get tvCornerSpotlightBackdropDescription => 'Mostrar a imagem de destaque no canto superior direito em vez de preencher o ecrã';
	@override String get viewMode => 'Modo de visualização';
	@override String get gridView => 'Grelha';
	@override String get listView => 'Lista';
	@override String get showHeroSection => 'Mostrar secção de destaque';
	@override String get continueWatchingAction => 'Ação da secção Continuar a ver';
	@override String get continueWatchingPlay => 'Reproduzir';
	@override String get continueWatchingDetails => 'Abrir detalhes';
	@override String get episodeAction => 'Ação do episódio';
	@override String get episodePlay => 'Reproduzir';
	@override String get episodeDetails => 'Abrir detalhes';
	@override String get useGlobalHubs => 'Usar o esquema do ecrã inicial';
	@override String get useGlobalHubsDescription => 'Mostrar hubs iniciais unificados. Caso contrário, usar recomendações da biblioteca.';
	@override String get showServerNameOnHubs => 'Mostrar nome do servidor nos hubs';
	@override String get showServerNameOnHubsDescription => 'Mostrar sempre os nomes dos servidores nos títulos dos hubs.';
	@override String get groupLibrariesByServer => 'Agrupar bibliotecas por servidor';
	@override String get groupLibrariesByServerDescription => 'Agrupar as bibliotecas da barra lateral por servidor multimédia.';
	@override String get alwaysKeepSidebarOpen => 'Manter a barra lateral sempre aberta';
	@override String get alwaysKeepSidebarOpenDescription => 'A barra lateral fica expandida e a área de conteúdo ajusta-se';
	@override String get showUnwatchedCount => 'Mostrar contagem de não vistos';
	@override String get showUnwatchedCountDescription => 'Mostrar o número de episódios não vistos em séries e temporadas';
	@override String get showWatchedIndicators => 'Mostrar indicadores de vistos';
	@override String get showWatchedIndicatorsDescription => 'Mostrar uma marca de verificação em filmes, séries e episódios vistos';
	@override String get showEpisodeNumberOnCards => 'Mostrar número do episódio nos cartões';
	@override String get showEpisodeNumberOnCardsDescription => 'Mostrar temporada e episódio nos cartões de episódio';
	@override String get showSeasonPostersOnTabs => 'Mostrar pósteres de temporada nos separadores';
	@override String get showSeasonPostersOnTabsDescription => 'Mostrar o póster de cada temporada por cima do separador';
	@override String get tvFullCardLayout => 'Cartões TV completos';
	@override String get tvFullCardLayoutDescription => 'Usar cartões de TV só com imagem e nomes dos atores sobrepostos';
	@override String get focusGlow => 'Brilho de foco';
	@override String get focusGlowDescription => 'Mostrar um brilho suave à volta do cartão em foco';
	@override String get visualEffects => 'Efeitos visuais';
	@override String get visualEffectsAuto => 'Automático';
	@override String get visualEffectsAutoDescription => 'Reduzir os efeitos automaticamente em dispositivos de baixo consumo';
	@override String get visualEffectsFull => 'Completos';
	@override String get visualEffectsReduced => 'Reduzidos';
	@override String get visualEffectsReducedDescription => 'Menos animações e imagens em menor resolução';
	@override String get hideSpoilers => 'Ocultar spoilers de episódios não vistos';
	@override String get hideSpoilersDescription => 'Desfocar miniaturas e descrições de episódios não vistos';
	@override String get playerBackend => 'Motor de reprodução';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'Descodificação por hardware';
	@override String get hardwareDecodingDescription => 'Usar aceleração por hardware quando disponível';
	@override String get playbackBuffer => 'Buffer de reprodução';
	@override String get playbackBufferAuto => 'Automático (recomendado)';
	@override String get playbackBufferLarge => 'Grande';
	@override String get playbackBufferExtraLarge => 'Extra grande';
	@override String get playbackBufferDescription => 'Guarda mais dados em buffer para ligações instáveis. Também limitado pelo tamanho do buffer.';
	@override String get defaultQualityTitle => 'Qualidade predefinida';
	@override String get cellularQualityTitle => 'Qualidade predefinida nos dados móveis';
	@override String get cellularQualitySameAsDefault => 'Igual à qualidade predefinida';
	@override String get directPlayCoveredQuality => 'Reproduzir vídeos mais pequenos na qualidade original';
	@override String get directPlayCoveredQualityDescription => 'Reproduzir diretamente os vídeos que já estão dentro do limite de qualidade em vez de transcodificá-los';
	@override String get videoCodecs => 'Codecs de vídeo';
	@override String get videoCodecsDescription => 'Codecs desmarcados são transcodificados pelo servidor';
	@override String get videoCodecsAlwaysAccepted => 'Sempre aceite';
	@override String get musicQualityTitle => 'Qualidade da música';
	@override String get subtitleStyling => 'Estilo das legendas';
	@override String get subtitleStylingDescription => 'Personalizar o aspeto das legendas';
	@override String get smallSkipDuration => 'Duração do avanço curto';
	@override String get largeSkipDuration => 'Duração do avanço longo';
	@override String get rewindOnResume => 'Rebobinar ao retomar';
	@override String secondsUnit({required Object seconds}) => '${seconds} segundos';
	@override String get defaultSleepTimer => 'Temporizador de suspensão predefinido';
	@override String minutesUnit({required Object minutes}) => '${minutes} minutos';
	@override String get rememberTrackSelections => 'Lembrar a seleção de faixas por série/filme';
	@override String get rememberTrackSelectionsDescription => 'Lembrar as escolhas de áudio e legendas por título';
	@override String get rememberTrackSelectionsBackendRule => 'O Plex guarda cada escolha no servidor por ficheiro; o Jellyfin também ativa a opção Lembrar seleções da conta; o Emby não é compatível';
	@override String get followServerTrackSelections => 'Usar a seleção de faixas do servidor por episódio';
	@override String get followServerTrackSelectionsDescription => 'Ao mudar de episódio, aplicar o áudio e as legendas selecionados no servidor em vez de manter a escolha atual';
	@override String get resumeMusicOnLaunch => 'Lembrar a sessão de música';
	@override String get resumeMusicOnLaunchDescription => 'Ao iniciar a aplicação, reabrir a última música em pausa onde parou';
	@override String get showChapterMarkersOnTimeline => 'Mostrar marcadores de capítulos na barra de reprodução';
	@override String get showChapterMarkersOnTimelineDescription => 'Segmentar a barra de reprodução nos limites dos capítulos';
	@override String get specialsOrdering => 'Especiais na ordem dos episódios';
	@override String get specialsOrderingDescription => 'Onde os especiais são reproduzidos na ordem de exibição de uma série';
	@override String get specialsOrderingServer => 'Seguir a ordem do servidor';
	@override String get specialsOrderingAirDate => 'Intercalar pela data de exibição';
	@override String get specialsOrderingLast => 'Após as temporadas regulares';
	@override String get clickVideoTogglesPlayback => 'Clicar no vídeo para alternar reprodução/pausa';
	@override String get clickVideoTogglesPlaybackDescription => 'Clicar no vídeo para reproduzir ou pausar em vez de mostrar os controlos.';
	@override String get videoPlayerControls => 'Controlos do reprodutor de vídeo';
	@override String get keyboardShortcuts => 'Atalhos de teclado';
	@override String get keyboardShortcutsDescription => 'Personalizar atalhos de teclado';
	@override String get videoPlayerNavigation => 'Navegação do reprodutor de vídeo';
	@override String get videoPlayerNavigationDescription => 'Usar as teclas de seta para navegar pelos controlos do reprodutor';
	@override String get watchTogetherRelay => 'Servidor de retransmissão do Ver juntos';
	@override String get watchTogetherRelayDescription => 'Servidores de retransmissão públicos do Open Watch Party, a menos que defina o seu';
	@override String get watchTogetherRelayHint => 'https://minha-retransmissao.exemplo.pt';
	@override String get watchTogetherRelayInvalid => 'Introduza um URL base de retransmissão HTTP ou HTTPS válido.';
	@override String get crashReporting => 'Relatórios de erros';
	@override String get crashReportingDescription => 'Enviar relatórios de erros para ajudar a melhorar a aplicação';
	@override String get debugLogging => 'Registo de depuração';
	@override String get debugLoggingDescription => 'Ativar registo detalhado para resolução de problemas';
	@override String get viewLogs => 'Ver registos';
	@override String get viewLogsDescription => 'Ver os registos da aplicação';
	@override String get clearImageCache => 'Limpar cache de imagens';
	@override String get clearImageCacheDescription => 'Limpar imagens e miniaturas em cache. As imagens podem carregar mais devagar até serem transferidas novamente.';
	@override String get clearImageCacheSuccess => 'Cache de imagens limpa com sucesso';
	@override String get resetSettings => 'Repor definições';
	@override String get resetSettingsDescription => 'Repor as definições predefinidas. Não pode ser anulado.';
	@override String get resetSettingsSuccess => 'Definições repostas com sucesso';
	@override String get backup => 'Cópia de segurança';
	@override String get exportSettings => 'Exportar definições';
	@override String get exportSettingsDescription => 'Guardar as suas preferências num ficheiro';
	@override String get exportSettingsSuccess => 'Definições exportadas';
	@override String get importSettings => 'Importar definições';
	@override String get importSettingsDescription => 'Restaurar preferências a partir de um ficheiro';
	@override String get importSettingsConfirm => 'Isto substituirá as suas definições atuais. Continuar?';
	@override String get importSettingsSuccess => 'Definições importadas';
	@override String get importSettingsInvalidFile => 'Este ficheiro não é uma exportação válida do Plezy';
	@override String get importSettingsNoUser => 'Inicie sessão antes de importar as definições';
	@override String get shortcutsReset => 'Atalhos repostos para os predefinidos';
	@override String get resetShortcutsConfirm => 'Isto substituirá os seus atalhos personalizados pelos predefinidos. Continuar?';
	@override String get about => 'Sobre';
	@override String get aboutDescription => 'Informações da aplicação e licenças';
	@override String get updates => 'Atualizações';
	@override String get updateAvailable => 'Atualização disponível';
	@override String get checkForUpdates => 'Verificar atualizações';
	@override String get autoCheckUpdatesOnStartup => 'Verificar atualizações automaticamente ao iniciar';
	@override String get autoCheckUpdatesOnStartupDescription => 'Notificar ao iniciar quando houver uma atualização disponível';
	@override String get validationErrorEnterNumber => 'Introduza um número válido';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'A duração deve estar entre ${min} e ${max} ${unit}';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Atalho já atribuído a ${action}';
	@override String shortcutUpdated({required Object action}) => 'Atalho atualizado para ${action}';
	@override String get saveFailed => 'Não foi possível guardar as alterações. Tente novamente.';
	@override String get autoPlayAndSkip => 'Reprodução automática e saltos';
	@override String get autoPlayNextEpisode => 'Reproduzir o próximo episódio automaticamente';
	@override String get autoPlayNextEpisodeDescription => 'Iniciar o próximo episódio automaticamente quando um terminar';
	@override String get shuffleStartsFromBeginning => 'A reprodução aleatória começa do início';
	@override String get shuffleStartsFromBeginningDescription => 'Iniciar cada episódio do início na reprodução aleatória em vez de retomá-lo';
	@override String get playNextCountdown => 'Contagem decrescente do próximo episódio';
	@override String get playNextCountdownImmediate => 'Reproduzir imediatamente';
	@override String get skipIntroMode => 'Saltar introdução';
	@override String get skipIntroModeOffDescription => 'Reproduzir as introduções normalmente sem botão para saltar';
	@override String get skipIntroModeButtonDescription => 'Mostrar um botão para saltar quando uma introdução começar';
	@override String get skipIntroModeAutoDescription => 'Saltar as introduções automaticamente após o atraso abaixo';
	@override String get skipCreditsMode => 'Saltar créditos';
	@override String get skipCreditsModeOffDescription => 'Reproduzir os créditos normalmente sem botão para saltar';
	@override String get skipCreditsModeButtonDescription => 'Mostrar um botão para saltar quando os créditos começarem';
	@override String get skipCreditsModeAutoDescription => 'Saltar os créditos automaticamente e reproduzir o próximo episódio';
	@override String get skipMarkerModeOff => 'Desativado';
	@override String get skipMarkerModeButton => 'Mostrar botão';
	@override String get skipMarkerModeAuto => 'Automático';
	@override String get forceSkipMarkerFallback => 'Forçar marcadores alternativos';
	@override String get forceSkipMarkerFallbackDescription => 'Usar padrões de títulos de capítulos mesmo quando o Plex tiver marcadores';
	@override String get autoSkipDelay => 'Atraso para saltar automaticamente';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Aguardar ${seconds} segundos antes de saltar automaticamente';
	@override String get introPattern => 'Padrão do marcador de introdução';
	@override String get introPatternDescription => 'Expressão regular que identifica marcadores de introdução nos títulos dos capítulos';
	@override String get creditsPattern => 'Padrão do marcador de créditos';
	@override String get creditsPatternDescription => 'Expressão regular que identifica marcadores de créditos nos títulos dos capítulos';
	@override String get invalidRegex => 'Expressão regular inválida';
	@override String get regex => 'Expressão regular';
	@override String get downloads => 'Transferências';
	@override String get downloadLocationDescription => 'Escolha onde armazenar conteúdo transferido';
	@override String get downloadLocationDefault => 'Predefinido (armazenamento da aplicação)';
	@override String get downloadLocationCustom => 'Local personalizado';
	@override String get selectFolder => 'Selecionar pasta';
	@override String get resetToDefault => 'Repor predefinição';
	@override String currentPath({required Object path}) => 'Atual: ${path}';
	@override String get downloadLocationChanged => 'Local de transferência alterado';
	@override String get downloadLocationReset => 'Local de transferência reposto para o predefinido';
	@override String get downloadLocationInvalid => 'Não é possível escrever na pasta selecionada';
	@override String get downloadLocationPickerUnavailable => 'A seleção de pasta não está disponível neste dispositivo';
	@override String get downloadOnWifiOnly => 'Transferir apenas por Wi-Fi';
	@override String get downloadOnWifiOnlyDescription => 'Impedir transferências ao usar dados móveis';
	@override String get autoRemoveWatchedDownloads => 'Remover automaticamente as transferências vistas';
	@override String get autoRemoveWatchedDownloadsDescription => 'Eliminar automaticamente as transferências já vistas';
	@override String get cellularDownloadBlocked => 'As transferências estão bloqueadas nos dados móveis. Use Wi-Fi ou altere a definição.';
	@override String get maxVolume => 'Volume máximo';
	@override String get maxVolumeDescription => 'Permitir aumentar o volume acima de 100% para conteúdos com som baixo';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Mostrar no Discord o que está a ver';
	@override String get services => 'Serviços';
	@override String get servicesDescription => 'Ligue Trakt, MyAnimeList, Seerr e mais';
	@override String get manageLibrariesDescription => 'Reordene e oculte bibliotecas';
	@override String get companionRemoteServer => 'Servidor de comando remoto';
	@override String get companionRemoteServerDescription => 'Permitir que dispositivos móveis na sua rede controlem esta aplicação';
	@override String get companionRemoteServerStartFailed => 'Não foi possível iniciar o servidor de comando remoto';
	@override String get companionRemoteServerStopFailed => 'Não foi possível parar o servidor de comando remoto';
	@override String get autoPip => 'Picture-in-picture automático';
	@override String get autoPipDescription => 'Entrar automaticamente no modo picture-in-picture ao sair da aplicação durante a reprodução';
	@override String get matchContentFrameRate => 'Ajustar à taxa de fotogramas do conteúdo';
	@override String get matchContentFrameRateDescription => 'Ajustar a taxa de atualização do ecrã ao conteúdo de vídeo';
	@override String get matchContentResolution => 'Ajustar à resolução do conteúdo';
	@override String get matchContentResolutionDescription => 'Muda o ecrã para a resolução nativa do vídeo para que a TV trate do upscaling. Os menus e as legendas também são ampliados durante a reprodução';
	@override String get matchRefreshRate => 'Ajustar à taxa de atualização';
	@override String get matchRefreshRateDescription => 'Ajustar a taxa de atualização do ecrã em ecrã inteiro';
	@override String get matchDynamicRange => 'Ajustar à gama dinâmica';
	@override String get matchDynamicRangeDescription => 'Ativar HDR para conteúdo HDR e depois voltar para SDR';
	@override String get displaySwitchDelay => 'Atraso na mudança do modo de ecrã';
	@override String get tunneledPlayback => 'Reprodução em túnel';
	@override String get tunneledPlaybackDescription => 'Usar o modo de túnel de vídeo. Desative se o vídeo ficar preto ao reproduzir em HDR ou se a imagem prender.';
	@override String get audioPassthrough => 'Passagem direta de áudio';
	@override String get audioPassthroughDescription => 'Enviar o áudio Dolby/DTS para o recetor ou para a TV sem recodificação, preservando o som surround. Desative se não houver som.';
	@override String get audioPassthroughDescriptionApple => 'Usar o descodificador Dolby nativo da Apple para Dolby Digital Plus, incluindo Atmos. DTS e TrueHD continuam a ser reproduzidos como PCM multicanal. Desative se não houver som.';
	@override String get audioPassthroughDescriptionAppleSpatial => 'Usar o descodificador Dolby nativo da Apple para Dolby Digital Plus, incluindo Atmos. No iOS, iPadOS e tvOS 26 ou posterior, TrueHD Atmos e DTS:X são reproduzidos como áudio espacial. As restantes faixas DTS e TrueHD são reproduzidas como PCM multicanal. Desative se não houver som.';
	@override String get audioPassthroughOverriddenByNormalization => 'Desativada enquanto a normalização de intensidade sonora estiver ativa';
	@override String get audioChannelLimit => 'Canais de áudio';
	@override String get audioChannelLimitDescription => 'Misturar o áudio descodificado em menos canais para altifalantes, auscultadores ou sistemas HDMI que não reproduzem todos os canais';
	@override String get audioChannelLimitOriginal => 'Original';
	@override String get audioChannelLimitOriginalDescription => 'Reproduzir todos os canais da faixa';
	@override String get audioChannelLimitSurround51 => 'Até 5.1';
	@override String get audioChannelLimitSurround51Description => 'Misturar 7.1 em 5.1 para TVs e recetores que só aceitam PCM 5.1. A passagem direta não é afetada.';
	@override String get audioChannelLimitStereo => 'Estéreo';
	@override String get audioChannelLimitStereoDescription => 'Misturar em dois canais para altifalantes estéreo ou auscultadores. Desativa a passagem direta.';
	@override String get downmixCenterBoost => 'Reforço do canal central';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'Reforço (dB)';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => 'Normalizar volume na conversão para estéreo';
	@override String get audioDownmixNormalizeDescription => 'Reduzir o volume da mistura para evitar saturação. Desative para manter o volume original, que pode distorcer em cenas muito altas.';
	@override String get dvConversionMode => 'Conversão Dolby Vision';
	@override String get dvConversionModeDescription => 'Escolha como os ficheiros Dolby Vision Profile 7 são tratados.';
	@override String get dvConversionAuto => 'Automático';
	@override String get dvConversionNative => 'Nativo / desativado';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Usar a deteção de capacidades do dispositivo e o comportamento alternativo predefinido';
	@override String get dvConversionNativeDescription => 'Forçar DV7 nativo e impedir uma nova tentativa de conversão de DV';
	@override String get dvConversionDv81Description => 'Forçar a conversão RPU integrada para Dolby Vision perfil 8.1';
	@override String get dvConversionHevcStripDescription => 'Remover as camadas RPU/EL do Dolby Vision e apresentar HEVC sem Dolby Vision';
	@override String get disableDolbyVision => 'Desativar Dolby Vision';
	@override String get disableDolbyVisionDescription => 'Reproduzir a camada HDR10 ou HLG do ficheiro em vez de Dolby Vision, quando houver';
	@override String get hdrSdrConversion => 'Conversão de HDR para SDR';
	@override String get hdrSdrConversionDescription => 'Escolha o que converte os vídeos HDR quando o ecrã não consegue mostrar HDR.';
	@override String get hdrSdrConversionAuto => 'Automático';
	@override String get hdrSdrConversionAutoDescription => 'Dispositivo no Android 9 ou posterior, reprodutor em versões anteriores';
	@override String get hdrSdrConversionDevice => 'Dispositivo';
	@override String get hdrSdrConversionDeviceDescription => 'O hardware de vídeo do dispositivo faz a conversão. Mais rápido, mas as cores dependem do dispositivo';
	@override String get hdrSdrConversionPlayer => 'Reprodutor';
	@override String get hdrSdrConversionPlayerDescription => 'O reprodutor faz a conversão. Cores consistentes, mas o 4K pode engasgar em TV boxes mais simples';
	@override String get deinterlace => 'Desentrelaçamento';
	@override String get deinterlaceDescription => 'Remover os artefactos em pente do vídeo entrelaçado (apenas no reprodutor mpv)';
	@override String get deinterlaceOff => 'Desativado';
	@override String get deinterlaceOffDescription => 'Mostrar o vídeo entrelaçado tal como é descodificado';
	@override String get deinterlaceVideo => 'Vídeo';
	@override String get deinterlaceVideoDescription => 'Transformar cada campo num fotograma completo. Para vídeos gravados para TV, como desporto, noticiários e programas de entretenimento';
	@override String get deinterlaceFilm => 'Filme';
	@override String get deinterlaceFilmDescription => 'Restaurar os fotogramas originais de filmes e animações convertidos por telecine para 29,97 fps, comum em DVDs NTSC. Os vídeos gravados para TV ficam aos soluços. A TV em direto usa Vídeo';
	@override String get requireProfileSelectionOnOpen => 'Pedir perfil ao abrir a aplicação';
	@override String get requireProfileSelectionOnOpenDescription => 'Mostrar a seleção de perfil sempre que a aplicação for aberta';
	@override String get forceTvMode => 'Forçar modo TV';
	@override String get forceTvModeDescription => 'Forçar o esquema de TV em dispositivos sem deteção automática. Requer reiniciar a aplicação.';
	@override String get startInFullscreen => 'Iniciar em ecrã inteiro';
	@override String get startInFullscreenDescription => 'Abrir o Plezy em modo de ecrã inteiro ao iniciar';
	@override String get exitFullscreenOnPlayerClose => 'Sair do ecrã inteiro ao fechar o reprodutor';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Sair automaticamente do ecrã inteiro ao fechar o reprodutor de vídeo';
	@override String get autoHidePerformanceOverlay => 'Ocultar automaticamente o painel de desempenho';
	@override String get autoHidePerformanceOverlayDescription => 'Esbater o painel de desempenho juntamente com os controlos de reprodução';
	@override String get showNavBarLabels => 'Mostrar etiquetas da barra de navegação';
	@override String get showNavBarLabelsDescription => 'Mostrar etiquetas de texto por baixo dos ícones da barra de navegação';
	@override String get startupSection => 'Secção inicial';
	@override String get showExploreTab => 'Mostrar separador Explorar';
	@override String get showExploreTabDescription => 'Mostrar o separador Explorar com conteúdo do Plex Discover e dos rastreadores ligados';
	@override String get liveTvDefaultFavorites => 'Canais favoritos por predefinição';
	@override String get liveTvDefaultFavoritesDescription => 'Mostrar apenas os canais favoritos ao abrir a TV em direto';
	@override String get general => 'Geral';
	@override String get generalDescription => 'Idioma, arranque e comportamento da janela';
	@override String get languageAndRegion => 'Idioma e região';
	@override String get startup => 'Arranque';
	@override String get display => 'Ecrã';
	@override String get libraryAndCards => 'Biblioteca e cartões';
	@override String get homeScreen => 'Ecrã inicial';
	@override String get navigation => 'Navegação';
	@override String get window => 'Janela';
	@override String get liveTv => 'TV em direto';
	@override String get player => 'Reprodutor';
	@override String get videoAndDisplay => 'Vídeo e ecrã';
	@override String get audio => 'Áudio';
	@override String get quality => 'Qualidade';
	@override String get subtitles => 'Legendas';
	@override String get seekAndTiming => 'Avanço e tempo';
	@override String get behavior => 'Comportamento';
	@override String get gestures => 'Gestos';
	@override String get gestureBrightnessSwipe => 'Deslizar para o brilho';
	@override String get gestureBrightnessSwipeDescription => 'Deslize para cima ou para baixo na margem esquerda para ajustar o brilho';
	@override String get gestureVolumeSwipe => 'Deslizar para o volume';
	@override String get gestureVolumeSwipeDescription => 'Deslize para cima ou para baixo na margem direita para ajustar o volume';
	@override String get gesturePinchToZoom => 'Beliscar para ampliar';
	@override String get gesturePinchToZoomDescription => 'Junte ou afaste os dedos no vídeo para ampliar ou reduzir';
	@override String get rememberBrightnessLevel => 'Lembrar o nível de brilho';
	@override String get rememberBrightnessLevelDescription => 'Iniciar a reprodução com o brilho definido pelo último deslize';
	@override String get controls => 'Controlos';
	@override String get rememberPlayerChanges => 'Lembrar alterações do reprodutor';
	@override String get rememberPlayerChangesDescription => 'Onde uma alteração feita durante a reprodução é guardada e reaplicada';
	@override String get scopePlaybackSpeed => 'Velocidade de reprodução';
	@override String get scopeShaderPreset => 'Predefinição de shader';
	@override String get scopeAspectRatio => 'Proporção do ecrã';
	@override String get scopeZoom => 'Zoom';
	@override String get scopeSyncOffsets => 'Sincronização de áudio e legendas';
	@override String get playerScopeOff => 'Não guardar';
	@override String get playerScopeGlobal => 'Em todo o lado';
	@override String get playerScopeLibrary => 'Por biblioteca';
	@override String get playerScopeTitle => 'Por série ou filme';
	@override String get exportDialogTitle => 'Exportar definições do Plezy';
}

// Path: themeEditor
class _Translations$themeEditor$pt_PT extends Translations$themeEditor$pt {
	_Translations$themeEditor$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get builtIn => 'Integrados';
	@override String get presets => 'Predefinidos';
	@override String get custom => 'Personalizado';
	@override String get customEmpty => 'Ainda não criado';
	@override String get editCustom => 'Editar tema personalizado';
	@override String get editCustomDescription => 'Escolha cada cor à sua maneira';
	@override String get locked => 'Desbloqueie com o Pacote de temas e ícones';
	@override String get savedLocked => 'Guardado — desbloqueia com o Pacote de temas e ícones';
	@override String get title => 'Tema personalizado';
	@override String get startFrom => 'Começar a partir de';
	@override String get startFromDescription => 'Copiar todas as cores de outro tema';
	@override String get colors => 'Cores';
	@override String get preview => 'Pré-visualização';
	@override late final _Translations$themeEditor$slots$pt_PT slots = _Translations$themeEditor$slots$pt_PT._(_root);
	@override String get opacity => 'Opacidade';
	@override String get hexHint => '#RRGGBB ou #AARRGGBB';
	@override String get fromOtherThemes => 'De outros temas';
	@override String swatchLabel({required Object color, required Object theme}) => '${color} (${theme})';
	@override late final _Translations$themeEditor$contrast$pt_PT contrast = _Translations$themeEditor$contrast$pt_PT._(_root);
	@override String lowContrast({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, abaixo dos ${minimum}:1 recomendados';
	@override String get discardTitle => 'Descartar alterações?';
	@override String get discardMessage => 'As suas alterações de cor não guardadas serão perdidas.';
	@override String get discard => 'Descartar';
	@override String previewCardTitle({required Object number}) => 'Episódio ${number}';
	@override String previewCardSubtitle({required Object minutes}) => '${minutes} min restantes';
	@override String get previewSwitch => 'Reprodução automática';
	@override String get previewMutedText => 'O texto secundário fica assim';
}

// Path: search
class _Translations$search$pt_PT extends Translations$search$pt {
	_Translations$search$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Pesquisar filmes, séries, músicas...';
	@override String get tryDifferentTerm => 'Tente um termo de pesquisa diferente';
	@override String get searchYourMedia => 'Pesquisar o seu conteúdo multimédia';
	@override String get enterTitleActorOrKeyword => 'Introduza um título, ator ou palavra-chave';
	@override String get people => 'Pessoas';
}

// Path: hotkeys
class _Translations$hotkeys$pt_PT extends Translations$hotkeys$pt {
	_Translations$hotkeys$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Definir atalho para ${actionName}';
	@override String get clearShortcut => 'Limpar atalho';
	@override String get noShortcutSet => 'Nenhum atalho definido';
	@override String get currentShortcut => 'Atalho atual:';
	@override String get pressToRecord => 'Selecionar para gravar um atalho';
	@override String get recordingShortcut => 'Prima o atalho agora';
	@override late final _Translations$hotkeys$actions$pt_PT actions = _Translations$hotkeys$actions$pt_PT._(_root);
}

// Path: fileInfo
class _Translations$fileInfo$pt_PT extends Translations$fileInfo$pt {
	_Translations$fileInfo$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Informações do ficheiro';
	@override String get overview => 'Visão geral';
	@override String get video => 'Vídeo';
	@override String get audio => 'Áudio';
	@override String get subtitles => 'Legendas';
	@override String get images => 'Imagens incorporadas';
	@override String get dataStreams => 'Fluxos de dados';
	@override String get lyrics => 'Letras';
	@override String get file => 'Ficheiro';
	@override String get attachments => 'Anexos';
	@override String get delivery => 'Entrega';
	@override String versionCounter({required Object index, required Object count}) => 'Versão ${index} de ${count}';
	@override String fileCounter({required Object index, required Object count}) => 'Ficheiro ${index} de ${count}';
	@override String get noStreams => 'O servidor não indicou fluxos para este ficheiro.';
	@override String get copyPath => 'Copiar caminho';
	@override String get pathCopied => 'Caminho do ficheiro copiado';
	@override String get codec => 'Codec';
	@override String get codecTag => 'Tag do codec';
	@override String get resolution => 'Resolução';
	@override String get codedResolution => 'Resolução codificada';
	@override String get bitrate => 'Taxa de bits';
	@override String get frameRate => 'Taxa de fotogramas';
	@override String get rotation => 'Rotação';
	@override String get comment => 'Comentário';
	@override String get audioDescription => 'Descrição de áudio';
	@override String get headerCompression => 'Compressão de cabeçalho';
	@override String get sidecarFile => 'Ficheiro sidecar';
	@override String get transportTimestamp => 'Carimbo de transporte';
	@override String get displayOffset => 'Deslocamento de apresentação';
	@override String get previewFailureCode => 'Código de falha da pré-visualização';
	@override String get previewRetries => 'Tentativas da pré-visualização';
	@override String get aspectRatio => 'Proporção';
	@override String get pixelAspectRatio => 'Proporção de aspeto de pixel';
	@override String get profile => 'Perfil';
	@override String get level => 'Nível';
	@override String get bitDepth => 'Profundidade de bits';
	@override String get pixelFormat => 'Formato de pixel';
	@override String get colorSpace => 'Espaço de cor';
	@override String get colorRange => 'Gama de cor';
	@override String get colorPrimaries => 'Primárias de cor';
	@override String get colorTransfer => 'Transferência de cor';
	@override String get chromaSubsampling => 'Subamostragem de croma';
	@override String get chromaLocation => 'Localização do croma';
	@override String get scanType => 'Tipo de varrimento';
	@override String get interlaced => 'Entrelaçado';
	@override String get anamorphic => 'Anamórfico';
	@override String get referenceFrames => 'Fotogramas de referência';
	@override String get dynamicRange => 'Gama dinâmica';
	@override String get dolbyVision => 'Dolby Vision';
	@override String get dolbyVisionLevel => 'Nível Dolby Vision';
	@override String get dolbyVisionVersion => 'Versão Dolby Vision';
	@override String get dolbyVisionLayers => 'Camadas Dolby Vision';
	@override String get baseLayerCompatibility => 'Compatibilidade da camada base';
	@override String get avcBitstream => 'Bitstream AVC';
	@override String get nalLengthSize => 'Tamanho do comprimento NAL';
	@override String get scalingMatrix => 'Matriz de dimensionamento personalizada';
	@override String get streamIdentifier => 'Identificador do fluxo';
	@override String get streamIndex => 'Índice do fluxo';
	@override String get streamId => 'ID do fluxo';
	@override String get language => 'Idioma';
	@override String get languageCode => 'Código do idioma';
	@override String get streamTitle => 'Título da faixa';
	@override String get channels => 'Canais';
	@override String get sampleRate => 'Taxa de amostragem';
	@override String get spatialAudio => 'Áudio espacial';
	@override String get textBased => 'Baseado em texto';
	@override String get subtitleFormat => 'Formato sidecar';
	@override String get provider => 'Fornecedor';
	@override String get matchScore => 'Pontuação de correspondência';
	@override String get externalDelivery => 'Pode ser servido separadamente';
	@override String get sidecarPath => 'Caminho do sidecar';
	@override String get sourceStream => 'Copiado de';
	@override String get temporary => 'Temporário';
	@override String get timeBase => 'Base de tempo';
	@override String get overallBitrate => 'Taxa de bits total';
	@override String get path => 'Caminho';
	@override String get fileName => 'Nome do ficheiro';
	@override String get size => 'Tamanho';
	@override String get totalSize => 'Tamanho total';
	@override String get container => 'Contentor';
	@override String get duration => 'Duração';
	@override String get previewThumbnails => 'Miniaturas de pré-visualização';
	@override String get previewIndex => 'Índice de pré-visualização';
	@override String get packetLength => 'Tamanho do pacote';
	@override String get filePresent => 'Ficheiro presente';
	@override String get fileReadable => 'Legível pelo servidor';
	@override String get streamPath => 'Caminho do fluxo';
	@override String get optimizedForStreaming => 'Otimizado para transmissão';
	@override String get has64bitOffsets => 'Deslocamentos de 64 bits';
	@override String get protocol => 'Protocolo';
	@override String get mediaType => 'Tipo de multimédia';
	@override String get sourceKind => 'Tipo de origem';
	@override String get optimizedVersion => 'Versão otimizada';
	@override String get optimizationTarget => 'Alvo de otimização';
	@override String get deletedAt => 'Eliminado';
	@override String get remoteSource => 'Origem remota';
	@override String get infiniteStream => 'Fluxo infinito';
	@override String get directPlay => 'Reprodução direta';
	@override String get directStream => 'Fluxo direto';
	@override String get transcoding => 'Transcodificação';
	@override String get etag => 'ETag';
	@override String get versionId => 'ID da versão';
	@override String get fileId => 'ID do ficheiro';
	@override String get defaultAudioTrack => 'Faixa de áudio predefinida';
	@override String get defaultSubtitleTrack => 'Faixa de legendas predefinida';
	@override String get subtitlesOff => 'Desativadas';
	@override String get flagDefault => 'Predefinida';
	@override String get flagForced => 'Forçada';
	@override String get flagSelected => 'Selecionada';
	@override String get flagExternal => 'Externa';
	@override String get flagHearingImpaired => 'Deficiência auditiva';
	@override String get flagDub => 'Dobrada';
	@override String get flagOriginal => 'Original';
	@override String get channelsMono => 'Mono';
	@override String dolbyVisionProfile({required Object profile}) => 'Perfil ${profile}';
}

// Path: mediaMenu
class _Translations$mediaMenu$pt_PT extends Translations$mediaMenu$pt {
	_Translations$mediaMenu$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Marcar como visto';
	@override String get markAsUnwatched => 'Marcar como não visto';
	@override String get removeFromContinueWatching => 'Remover de Continuar a ver';
	@override String get viewDetails => 'Ver detalhes';
	@override String get goToSeries => 'Ir para a série';
	@override String get shufflePlay => 'Reprodução aleatória';
	@override String get shuffleNotAvailableOffline => 'Reprodução aleatória indisponível offline';
	@override String get fileInfo => 'Informações do ficheiro';
	@override String get deleteEpisodeFromServer => 'Eliminar episódio do servidor';
	@override String get deleteSeasonFromServer => 'Eliminar temporada do servidor';
	@override String get deleteShowFromServer => 'Eliminar série do servidor';
	@override String get deleteMovieFromServer => 'Eliminar filme do servidor';
	@override String get deleteEpisodeTitle => 'Eliminar este episódio?';
	@override String get deleteSeasonTitle => 'Eliminar esta temporada?';
	@override String get deleteShowTitle => 'Eliminar esta série?';
	@override String get deleteMovieTitle => 'Eliminar este filme?';
	@override String get deleteEpisodeConfirm => 'Eliminar episódio';
	@override String get deleteSeasonConfirm => 'Eliminar temporada';
	@override String get deleteShowConfirm => 'Eliminar série';
	@override String get deleteMovieConfirm => 'Eliminar filme';
	@override String get deleteAnyway => 'Eliminar mesmo assim';
	@override String confirmDeleteTarget({required Object title}) => 'Eliminar permanentemente ${title} do seu servidor?';
	@override String get deleteMultipleWarning => 'Isto inclui todos os episódios e os respetivos ficheiros.';
	@override String deleteEpisodeCountWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: 'Isto elimina ${n} episódio e o respetivo ficheiro.',
		other: 'Isto elimina todos os ${n} episódios e os respetivos ficheiros.',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: 'Este item está armazenado como ${n} ficheiro, que será eliminado.',
		other: 'Este item está armazenado em ${n} ficheiros, e todos eles serão eliminados.',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: 'Mais ${n} episódio está armazenado no mesmo ficheiro e também será eliminado:',
		other: 'Mais ${n} episódios estão armazenados no mesmo ficheiro e também serão eliminados:',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'O Plezy não conseguiu verificar que ficheiros serão removidos, por isso pode eliminar mais do que o item acima. Cancele e tente novamente, ou elimine mesmo assim.';
	@override String get deleteScopeUnverifiedNoFileInfo => 'O seu servidor não forneceu detalhes do ficheiro para este item, por isso o Plezy não consegue verificar que ficheiros serão removidos. Pode eliminar mais do que o item acima.';
	@override String get mediaDeletedSuccessfully => 'Item multimédia eliminado com sucesso';
	@override String get mediaFailedToDelete => 'Falha ao eliminar o item multimédia';
	@override String get rate => 'Avaliar';
	@override String get playFromBeginning => 'Reproduzir do início';
	@override String get playVersion => 'Reproduzir versão...';
}

// Path: rateSheet
class _Translations$rateSheet$pt_PT extends Translations$rateSheet$pt {
	_Translations$rateSheet$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Avaliar';
	@override String get server => 'Servidor';
	@override String get favorite => 'Favorito';
	@override String get favorited => 'Adicionado aos favoritos';
	@override String get saved => 'Guardado';
	@override String get notAvailable => 'Nenhuma correspondência encontrada';
	@override String get noConnectedServices => 'Ligue um serviço nas Definições para avaliar a partir daí.';
}

// Path: accessibility
class _Translations$accessibility$pt_PT extends Translations$accessibility$pt {
	_Translations$accessibility$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, filme';
	@override String mediaCardShow({required Object title}) => '${title}, série de TV';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'visto';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent} por cento visto';
	@override String get mediaCardUnwatched => 'não visto';
	@override String get tapToPlay => 'Toque para reproduzir';
	@override String get decrease => 'Diminuir';
	@override String get increase => 'Aumentar';
	@override String decreaseValue({required Object label}) => 'Diminuir ${label}';
	@override String increaseValue({required Object label}) => 'Aumentar ${label}';
	@override String get hue => 'Matiz';
	@override String get saturation => 'Saturação';
	@override String get brightness => 'Brilho';
	@override String get hexColor => 'Cor hexadecimal';
	@override String get expandText => 'Expandir texto';
	@override String get collapseText => 'Recolher texto';
	@override String get alphabetNavigation => 'Navegação alfabética';
	@override String get alphabetScrollHint => 'Deslize para cima ou para baixo para avançar por letra';
	@override String rowColumnPosition({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Linha ${row} de ${rowCount}, coluna ${column} de ${columnCount}';
	@override String rowPosition({required Object row, required Object rowCount}) => 'Linha ${row} de ${rowCount}';
	@override String get autoScrollPlay => 'Iniciar deslocamento automático';
	@override String get autoScrollPause => 'Pausar deslocamento automático';
	@override String get hueShort => 'M';
	@override String get saturationShort => 'S';
	@override String get valueShort => 'V';
}

// Path: tooltips
class _Translations$tooltips$pt_PT extends Translations$tooltips$pt {
	_Translations$tooltips$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Reprodução aleatória';
	@override String get playTrailer => 'Reproduzir trailer';
	@override String get markAsWatched => 'Marcar como visto';
	@override String get markAsUnwatched => 'Marcar como não visto';
}

// Path: audioTracks
class _Translations$audioTracks$pt_PT extends Translations$audioTracks$pt {
	_Translations$audioTracks$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => 'Faixa de áudio ${n}';
}

// Path: videoControls
class _Translations$videoControls$pt_PT extends Translations$videoControls$pt {
	_Translations$videoControls$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Áudio';
	@override String get subtitlesLabel => 'Legendas';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String get letterbox => 'Letterbox';
	@override String get fillScreen => 'Preencher ecrã';
	@override String get stretch => 'Esticar';
	@override String get lockRotation => 'Bloquear rotação';
	@override String get unlockRotation => 'Desbloquear rotação';
	@override String get timerActive => 'Temporizador ativo';
	@override String playbackWillPauseIn({required Object duration}) => 'A reprodução será pausada dentro de ${duration}';
	@override String get sleepTimerEndOfVideo => 'Fim do vídeo atual';
	@override String get sleepTimerStopAtHeader => 'Parar em';
	@override String get sleepTimerDurationHeader => 'Temporizador';
	@override String get playbackWillPauseAtEnd => 'A reprodução será pausada no final deste vídeo';
	@override String get stillWatching => 'Ainda está a ver?';
	@override String pausingIn({required Object seconds}) => 'A pausar dentro de ${seconds}s';
	@override String get continueWatching => 'Continuar';
	@override String get autoPlayNext => 'Reproduzir o próximo automaticamente';
	@override String get playNext => 'Reproduzir o próximo';
	@override String get playButton => 'Reproduzir';
	@override String get pauseButton => 'Pausa';
	@override String get playbackPaused => 'Em pausa';
	@override String get playbackResumed => 'A reproduzir';
	@override String get loadingVideo => 'A carregar o vídeo';
	@override String get showPlaybackControls => 'Mostrar controlos de reprodução';
	@override String get hidePlaybackControls => 'Ocultar controlos de reprodução';
	@override String seekBackwardButton({required Object seconds}) => 'Retroceder ${seconds} segundos';
	@override String seekForwardButton({required Object seconds}) => 'Avançar ${seconds} segundos';
	@override String get previousButton => 'Episódio anterior';
	@override String get nextButton => 'Próximo episódio';
	@override String get previousChapterButton => 'Capítulo anterior';
	@override String get nextChapterButton => 'Próximo capítulo';
	@override String get muteButton => 'Silenciar';
	@override String get unmuteButton => 'Ativar som';
	@override String get settingsButton => 'Definições de reprodução';
	@override String get tracksButton => 'Áudio e legendas';
	@override String get chaptersButton => 'Capítulos';
	@override String get versionQualityButton => 'Versão e qualidade';
	@override String get versionColumnHeader => 'Versão';
	@override String get qualityColumnHeader => 'Qualidade';
	@override String get qualityOriginal => 'Original';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => 'Transcodificação indisponível — a reproduzir na qualidade original';
	@override String get subtitleUnavailableFallback => 'Não foi possível carregar as legendas selecionadas — a reprodução continuará sem legendas';
	@override String get pipButton => 'Modo Picture-in-Picture';
	@override String get aspectRatioButton => 'Proporção';
	@override String get ambientLighting => 'Iluminação ambiente';
	@override String get fullscreenButton => 'Entrar em ecrã inteiro';
	@override String get exitFullscreenButton => 'Sair do ecrã inteiro';
	@override String get alwaysOnTopButton => 'Sempre no topo';
	@override String get rotationLockButton => 'Bloquear rotação';
	@override String get lockScreen => 'Bloquear ecrã';
	@override String get screenLockButton => 'Bloquear ecrã';
	@override String get tapToUnlock => 'Toque para desbloquear';
	@override String get tapAgainToUnlock => 'Toque novamente para desbloquear';
	@override String get timelineSlider => 'Linha do tempo do vídeo';
	@override String get volumeSlider => 'Nível de volume';
	@override String endsAt({required Object time}) => 'Termina às ${time}';
	@override String get pipActive => 'A reproduzir em Picture-in-Picture';
	@override String get pipFailed => 'Falha ao iniciar picture-in-picture';
	@override String get screenshotSaved => 'Captura de ecrã guardada';
	@override String get screenshotFailed => 'Não foi possível fazer a captura de ecrã';
	@override String zoomPercent({required Object percent}) => 'Zoom ${percent}%';
	@override String volumePercent({required Object percent}) => 'Volume ${percent}%';
	@override late final _Translations$videoControls$pipErrors$pt_PT pipErrors = _Translations$videoControls$pipErrors$pt_PT._(_root);
	@override String get chapters => 'Capítulos';
	@override String get noChaptersAvailable => 'Nenhum capítulo disponível';
	@override String get queue => 'Fila';
	@override String get noQueueItems => 'Nenhum item na fila';
	@override String get noAudioDevicesAvailable => 'Nenhum dispositivo de áudio disponível';
	@override String get searchSubtitles => 'Pesquisar legendas';
	@override String get language => 'Idioma';
	@override String get noSubtitlesFound => 'Nenhuma legenda encontrada';
	@override String get subtitleDownloaded => 'Legenda transferida';
	@override String get subtitleDownloadedNotApplied => 'A legenda foi transferida, mas não foi possível selecioná-la';
	@override String get subtitleDownloadFailed => 'Falha ao transferir a legenda';
	@override String get subtitleDownloadTimedOut => 'A legenda não apareceu a tempo. A transferência pode ter falhado';
	@override String get searchLanguages => 'Pesquisar idiomas...';
	@override String get skipIntro => 'Saltar introdução';
	@override String get skipCredits => 'Saltar créditos';
	@override String get nextEpisode => 'Próximo episódio';
	@override String subtitleTrack({required Object n}) => 'Faixa ${n}';
	@override String subtitleFile({required Object name}) => 'Legenda ${name}';
	@override String forcedTrack({required Object label}) => '${label} (Forçada)';
	@override String get osdSubtitlesOff => 'Legendas: desativadas';
	@override String osdSubtitles({required Object track}) => 'Legendas: ${track}';
	@override String osdAudio({required Object track}) => 'Áudio: ${track}';
}

// Path: messages
class _Translations$messages$pt_PT extends Translations$messages$pt {
	_Translations$messages$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Marcado como visto';
	@override String get markedAsUnwatched => 'Marcado como não visto';
	@override String get markedAsWatchedOffline => 'Marcado como visto (será sincronizado quando online)';
	@override String get markedAsUnwatchedOffline => 'Marcado como não visto (será sincronizado quando online)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'Removido automaticamente: ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: 'Removida automaticamente ${n} transferência vista',
		other: 'Removidas automaticamente ${n} transferências vistas',
	);
	@override String get removedFromContinueWatching => 'Removido de Continuar a ver';
	@override String errorLoading({required Object error}) => 'Erro: ${error}';
	@override String get searchPartialResults => 'Não foi possível pesquisar alguns servidores multimédia. A mostrar os resultados disponíveis.';
	@override String get streamInterrupted => 'A transmissão foi interrompida. Prima reproduzir ou avance para tentar novamente.';
	@override String get liveStreamInterrupted => 'A transmissão em direto foi interrompida. Prima reproduzir para tentar novamente.';
	@override String get fileInfoNotAvailable => 'Informações do ficheiro não disponíveis';
	@override String get playbackAuthenticationRequired => 'Inicie sessão novamente no servidor multimédia para reproduzir este item.';
	@override String get playbackServerUnavailable => 'O servidor multimédia está indisponível. Tente novamente mais tarde.';
	@override String get playbackDataInvalid => 'O servidor devolveu informações de reprodução inválidas.';
	@override String get playbackCancelled => 'A reprodução foi cancelada.';
	@override String get playbackFailed => 'Não foi possível iniciar a reprodução.';
	@override String playbackFailedDetail({required Object error}) => 'Não foi possível iniciar a reprodução: ${error}';
	@override String get audioOutputFailed => 'A saída de áudio deixou de responder. Verifique a ligação de áudio da TV ou do recetor; se outras aplicações também estiverem sem som, reinicie o dispositivo.';
	@override String get mediaUnavailable => 'Este conteúdo já não está disponível.';
	@override String errorLoadingFileInfo({required Object error}) => 'Erro ao carregar as informações do ficheiro: ${error}';
	@override String get errorLoadingSeries => 'Erro ao carregar a série';
	@override String get musicNotSupported => 'A reprodução de música ainda não é suportada';
	@override String get noDescriptionAvailable => 'Nenhuma descrição disponível';
	@override String get noProfilesAvailable => 'Nenhum perfil disponível';
	@override String get contactAdminForProfiles => 'Contacte o administrador do servidor para adicionar perfis';
	@override String get unableToDetermineLibrarySection => 'Não foi possível determinar a secção da biblioteca deste item';
	@override String get logsCleared => 'Registos limpos';
	@override String get logsCopied => 'Registos copiados para a área de transferência';
	@override String get noLogsAvailable => 'Nenhum registo disponível';
	@override String libraryScanning({required Object title}) => 'A examinar "${title}"...';
	@override String libraryScanStarted({required Object title}) => 'Exame da biblioteca iniciado para "${title}"';
	@override String libraryScanFailed({required Object error}) => 'Falha ao examinar a biblioteca: ${error}';
	@override String metadataRefreshing({required Object title}) => 'A atualizar metadados de "${title}"...';
	@override String metadataRefreshStarted({required Object title}) => 'Atualização de metadados iniciada para "${title}"';
	@override String metadataRefreshFailed({required Object error}) => 'Falha ao atualizar os metadados: ${error}';
	@override String get logoutConfirm => 'Tem a certeza de que pretende sair?';
	@override String get noSeasonsFound => 'Nenhuma temporada encontrada';
	@override String get seasonsLoadFailed => 'Não foi possível carregar as temporadas';
	@override String get noEpisodesFound => 'Nenhum episódio encontrado na primeira temporada';
	@override String get noEpisodesFoundGeneral => 'Nenhum episódio encontrado';
	@override String get episodesLoadFailed => 'Não foi possível carregar os episódios';
	@override String get noResultsFound => 'Nenhum resultado encontrado';
	@override String sleepTimerSet({required Object label}) => 'Temporizador de suspensão definido como ${label}';
	@override String get noItemsAvailable => 'Nenhum item disponível';
	@override String get failedToCreatePlayQueueNoItems => 'Falha ao criar a fila de reprodução — nenhum item';
	@override String failedPlayback({required Object action, required Object error}) => 'Falha ao ${action}: ${error}';
	@override String get switchingToCompatiblePlayer => 'A alternar para um reprodutor compatível...';
	@override String get serverLimitTitle => 'Falha na reprodução';
	@override String get serverLimitBody => 'Erro do servidor (HTTP 500). Um limite de largura de banda ou de transcodificação terá provavelmente rejeitado esta sessão. Peça ao proprietário do servidor para o ajustar.';
	@override String get serverLimitTranscode => 'Experimentar transcodificar';
	@override String get mediaUnreadableTitle => 'Ficheiro indisponível';
	@override String get mediaUnreadableBody => 'O servidor encontrou este item, mas não conseguiu ler o ficheiro (HTTP 404). O ficheiro foi provavelmente movido, eliminado ou o armazenamento está offline. Peça ao responsável pelo servidor para verificar o ficheiro e voltar a examinar a biblioteca.';
	@override String get serverBusyTitle => 'Transmissão indisponível';
	@override String get serverBusyBody => 'O servidor continuou a recusar-se a transmitir este ficheiro (HTTP 503). Pode estar a reiniciar ou ocupado, ou o armazenamento do ficheiro pode estar offline. Tente novamente daqui a pouco — se continuar a acontecer, peça ao proprietário do servidor para verificar o servidor e o armazenamento do ficheiro.';
	@override String get playbackNotAllowedTitle => 'Reprodução não permitida';
	@override String get playbackNotAllowedBody => 'O servidor recusou-se a transmitir este item (HTTP 403). A sua conta pode não ter permissão para o reproduzir, ou o servidor pode permitir a reprodução apenas na própria rede local.';
	@override String get logsUploaded => 'Registos enviados';
	@override String get logsUploadFailed => 'Falha ao enviar os registos';
	@override String get logId => 'ID do registo';
	@override String get burnedSubtitlesUseMenu => 'As legendas estão incorporadas nesta transmissão. Altere-as no menu de legendas.';
	@override String get noVideoUrl => 'Nenhum URL de vídeo disponível';
	@override String get playbackNoMediaSources => 'O servidor não devolveu nenhuma origem multimédia reproduzível';
	@override String get playbackDataNotPrepared => 'A reprodução foi iniciada antes de os dados estarem prontos';
	@override String get streamSelectionUnavailable => 'A seleção de fluxos não está disponível para esta origem';
	@override String get streamSelectionFailed => 'Não foi possível aplicar os fluxos selecionados';
	@override String get trackSelectionNotRemembered => 'Esta escolha de faixa aplica-se apenas à reprodução atual.';
	@override String get serverUnavailableForProfile => 'Nenhum servidor está disponível para o perfil ativo';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$pt_PT extends Translations$subtitlingStyling$pt {
	_Translations$subtitlingStyling$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get text => 'Texto';
	@override String get border => 'Contorno';
	@override String get background => 'Fundo';
	@override String get fontSize => 'Tamanho da letra';
	@override String get textColor => 'Cor do texto';
	@override String get borderSize => 'Tamanho do contorno';
	@override String get borderColor => 'Cor do contorno';
	@override String get backgroundOpacity => 'Opacidade do fundo';
	@override String get backgroundColor => 'Cor do fundo';
	@override String get position => 'Posição';
	@override String get assOverride => 'Substituição ASS';
	@override String get overrideScale => 'Dimensionar';
	@override String get overrideForce => 'Forçar';
	@override String get overrideStrip => 'Remover estilo';
	@override String get positionTop => 'Superior';
	@override String get positionBottom => 'Inferior';
	@override String get useMargins => 'Usar margens';
	@override String get useMarginsDescription => 'Permitir legendas de texto no espaço fora do vídeo. Legendas estilizadas podem manter a sua posição original.';
	@override String get anchorToScreen => 'Ancorar ao ecrã';
	@override String get anchorToScreenDescription => 'Mostrar as legendas de texto nas barras pretas por baixo de vídeos em formato panorâmico';
	@override String get bold => 'Negrito';
	@override String get italic => 'Itálico';
	@override String get renderResolution => 'Resolução de renderização';
	@override String get renderResolutionScreen => 'Resolução do ecrã';
	@override String get renderResolutionVideo => 'Resolução do vídeo';
}

// Path: mpvConfig
class _Translations$mpvConfig$pt_PT extends Translations$mpvConfig$pt {
	_Translations$mpvConfig$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => 'Definições avançadas do reprodutor de vídeo';
	@override String get presets => 'Predefinições';
	@override String get noPresets => 'Nenhuma predefinição guardada';
	@override String get saveAsPreset => 'Guardar como predefinição...';
	@override String get presetName => 'Nome da predefinição';
	@override String get presetNameHint => 'Introduza um nome para esta predefinição';
	@override String get loadPreset => 'Carregar';
	@override String get deletePreset => 'Eliminar';
	@override String get presetSaved => 'Predefinição guardada';
	@override String get presetLoaded => 'Predefinição carregada';
	@override String get presetDeleted => 'Predefinição eliminada';
	@override String get confirmDeletePreset => 'Tem a certeza de que pretende eliminar esta predefinição?';
	@override String get configPlaceholder => 'gpu-api=vulkan\nhwdec=auto\n# comment';
	@override String get lineHint => 'option=value';
	@override String get addLine => 'Adicionar linha';
	@override String get removeLine => 'Remover linha';
	@override String get embeddedVoHint => 'vo, gpu-context e gpu-api são ignorados no Linux: o vídeo incorporado é sempre renderizado via vo=libmpv no plano de vídeo, e gpu-next (necessário para shaders de computação como ArtCNN) não pode ser executado incorporado.';
}

// Path: dialog
class _Translations$dialog$pt_PT extends Translations$dialog$pt {
	_Translations$dialog$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Confirmar ação';
}

// Path: profiles
class _Translations$profiles$pt_PT extends Translations$profiles$pt {
	_Translations$profiles$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'Adicionar perfil Plezy';
	@override String get switchingProfile => 'A mudar de perfil…';
	@override String get deleteThisProfileTitle => 'Eliminar este perfil?';
	@override String deleteThisProfileMessage({required Object displayName}) => 'Remover ${displayName}. As ligações não serão afetadas.';
	@override String get active => 'Ativo';
	@override String get manage => 'Gerir';
	@override String get delete => 'Eliminar';
	@override String get signOut => 'Terminar sessão';
	@override String get signOutPlexTitle => 'Terminar sessão no Plex?';
	@override String signOutPlexMessage({required Object displayName}) => 'Remover ${displayName} e todos os utilizadores do Plex Home? Pode voltar a iniciar sessão quando quiser.';
	@override String get signOutPlexDeleteDownloads => 'Eliminar também as transferências';
	@override String get signOutPlexDeleteDownloadsDescription => 'Caso contrário, ficam neste dispositivo e voltam quando iniciar novamente sessão nesta conta.';
	@override String get signedOutPlex => 'Sessão terminada no Plex.';
	@override String get signOutFailed => 'Falha ao terminar sessão.';
	@override String get sectionTitle => 'Perfis';
	@override String get summarySingle => 'Adicione perfis para combinar utilizadores geridos e identidades locais';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} perfis · ativo: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} perfis';
	@override String get removeConnectionTitle => 'Remover ligação?';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => 'Remover o acesso de ${displayName} a ${connectionLabel}. Os outros perfis mantêm o acesso.';
	@override String get deleteProfileTitle => 'Eliminar perfil?';
	@override String deleteProfileMessage({required Object displayName}) => 'Remover ${displayName} e as suas ligações. Os servidores continuam disponíveis.';
	@override String get profileNameLabel => 'Nome do perfil';
	@override String get pinProtectionLabel => 'Proteção por PIN';
	@override String get pinManagedByPlex => 'PIN gerido pelo Plex. Edite em plex.tv.';
	@override String get noPinSetEditOnPlex => 'Nenhum PIN definido. Para exigir um, edite o utilizador do Plex Home em plex.tv.';
	@override String get setPin => 'Definir PIN';
	@override String get setPinTitle => 'Definir PIN';
	@override String get confirmPinTitle => 'Confirmar PIN';
	@override String get pinSet => 'PIN definido';
	@override String get changePin => 'Alterar';
	@override String get removePin => 'Remover';
	@override String get connectionsLabel => 'Ligações';
	@override String get add => 'Adicionar';
	@override String get deleteProfileButton => 'Eliminar perfil';
	@override String get noConnectionsHint => 'Sem ligações — adicione uma para usar este perfil.';
	@override String get noConnections => 'Sem ligações';
	@override String get plexHomeAccount => 'Conta Plex Home';
	@override String plexAccountChip({required Object account}) => 'Conta Plex: ${account}';
	@override String plexAccountUserChip({required Object user, required Object account}) => '${user} via ${account}';
	@override String get connectionDefault => 'Predefinida';
	@override String connectionAs({required Object displayName}) => 'como ${displayName}';
	@override String get makeDefault => 'Definir como predefinida';
	@override String get removeConnection => 'Remover';
	@override String get profileRenamed => 'Perfil renomeado.';
	@override String borrowAddTo({required Object displayName}) => 'Adicionar a ${displayName}';
	@override String get borrowExplain => 'Use a ligação de outro perfil. Os perfis protegidos por PIN exigem o PIN.';
	@override String get borrowEmpty => 'Nenhuma ligação disponível ainda.';
	@override String get borrowEmptySubtitle => 'Primeiro, ligue o Plex, o Jellyfin ou o Emby a outro perfil.';
	@override String get borrowLoadFailed => 'Não foi possível carregar as ligações disponíveis. Tente novamente.';
	@override String borrowFromProfile({required Object displayName}) => 'De ${displayName}';
	@override String get borrowConnectionBorrowed => 'Ligação adicionada ao perfil.';
	@override String get borrowFailed => 'Não foi possível adicionar a ligação.';
	@override String get incorrectPin => 'PIN incorreto.';
	@override String get incorrectPinTryAgain => 'PIN incorreto. Tente novamente.';
	@override String get sourceProfileMissingParentAccount => 'O perfil de origem não tem a conta principal.';
	@override String get failedToLoadHomeUsers => 'Não foi possível carregar os utilizadores do Plex Home. Verifique a sua ligação e tente novamente.';
	@override String get failedToVerifyPin => 'Não foi possível verificar o PIN.';
	@override String get newProfile => 'Novo perfil';
	@override String get profileNameHint => 'Ex.: Visitas, Crianças, Sala';
	@override String get pinProtectionOptional => 'Proteção por PIN (opcional)';
	@override String get pinExplain => 'PIN de 4 dígitos necessário para mudar de perfil.';
	@override String get continueButton => 'Continuar';
	@override String get pinsDontMatch => 'Os PINs não correspondem';
	@override String get tokenIdentityMismatch => 'O token do perfil do Plex foi associado a um servidor inesperado';
}

// Path: connections
class _Translations$connections$pt_PT extends Translations$connections$pt {
	_Translations$connections$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Ligações';
	@override String get addConnection => 'Adicionar ligação';
	@override String get addConnectionSubtitleNoProfile => 'Inicie sessão no Plex ou ligue um servidor Jellyfin ou Emby';
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'Adicionar a ${displayName}: Plex, Jellyfin, Emby ou outra ligação de perfil';
	@override String sessionExpiredOne({required Object name}) => 'Sessão de ${name} expirada';
	@override String sessionExpiredMany({required Object count}) => 'Sessões expiradas em ${count} servidores';
	@override String accessDeniedOne({required Object name}) => '${name} negou o acesso a esta conta';
	@override String accessDeniedMany({required Object count}) => '${count} servidores negaram o acesso a esta conta';
	@override String get signInAgain => 'Iniciar sessão novamente';
	@override String editMediaBrowserTitle({required Object product}) => 'Editar ligação do ${product}';
	@override String editMediaBrowserIntro({required Object serverName}) => 'Adicione ou remova URLs para ${serverName}. O Plezy usará o URL acessível com menor latência.';
}

// Path: accountPreferences
class _Translations$accountPreferences$pt_PT extends Translations$accountPreferences$pt {
	_Translations$accountPreferences$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Preferências da conta';
	@override String hubSubtitleSingle({required Object account}) => 'Opções de áudio, legendas e biblioteca guardadas em ${account}';
	@override String hubSubtitleMultiple({required Object count}) => 'Opções de áudio, legendas e biblioteca guardadas em ${count} contas';
	@override String get pickAccount => 'Cada conta guarda as suas próprias preferências. Escolha a que pretende editar.';
	@override String get storedOnAccount => 'Estas opções são guardadas na própria conta, por isso todas as aplicações ligadas a ela as utilizam — incluindo o Plezy nos seus outros dispositivos.';
	@override String get noAccounts => 'Nenhuma conta para configurar';
	@override String get noAccountsHint => 'Inicie sessão no Plex ou ligue um servidor Jellyfin ou Emby, e as preferências guardadas nessa conta aparecerão aqui.';
	@override String get unavailable => 'Não foi possível aceder a esta conta';
	@override String get loadFailed => 'Não foi possível carregar estas preferências';
	@override String get noPreference => 'Sem preferência';
	@override String get notSet => 'Não definido';
	@override late final _Translations$accountPreferences$groups$pt_PT groups = _Translations$accountPreferences$groups$pt_PT._(_root);
	@override String get preferredAudioLanguage => 'Idioma de áudio preferido';
	@override String get autoSelectAudio => 'Escolher áudio pelo idioma';
	@override String get autoSelectAudioDescription => 'Desativado mantém a faixa de áudio que o ficheiro marca como predefinida.';
	@override String get preferredSubtitleLanguage => 'Idioma de legenda preferido';
	@override String get subtitleMode => 'Ativar legendas';
	@override late final _Translations$accountPreferences$subtitleModes$pt_PT subtitleModes = _Translations$accountPreferences$subtitleModes$pt_PT._(_root);
	@override String get subtitleAccessibility => 'Legendas SDH';
	@override late final _Translations$accountPreferences$subtitleAccessibilityOptions$pt_PT subtitleAccessibilityOptions = _Translations$accountPreferences$subtitleAccessibilityOptions$pt_PT._(_root);
	@override String get forcedSubtitles => 'Legendas forçadas';
	@override late final _Translations$accountPreferences$forcedSubtitleOptions$pt_PT forcedSubtitleOptions = _Translations$accountPreferences$forcedSubtitleOptions$pt_PT._(_root);
	@override String get displayMissingEpisodes => 'Mostrar episódios em falta';
	@override String get displayMissingEpisodesDescription => 'Listar episódios que o servidor conhece, mas para os quais não há ficheiro.';
	@override String get hidePlayedInLatest => 'Ocultar itens vistos em Recentes';
	@override String get hidePlayedInLatestDescription => 'Manter fora das linhas Recentes do servidor os itens que já viu.';
	@override String get displayCollectionsView => 'Mostrar a vista de Coleções';
	@override String get displayCollectionsViewDescription => 'Oferecer a vista de Coleções do servidor juntamente com as suas bibliotecas.';
	@override String get rewatchingInNextUp => 'Manter em A seguir as séries que está a rever';
	@override String get rewatchingInNextUpDescription => 'Ao terminar uma série, comece a vê-la de novo e A seguir acompanha a nova visualização em vez de remover a série.';
	@override String get watchedIndicator => 'Indicadores de visto';
	@override late final _Translations$accountPreferences$watchedIndicatorOptions$pt_PT watchedIndicatorOptions = _Translations$accountPreferences$watchedIndicatorOptions$pt_PT._(_root);
	@override String get mediaReviewsVisibility => 'Avaliações e críticas';
	@override late final _Translations$accountPreferences$mediaReviewsOptions$pt_PT mediaReviewsOptions = _Translations$accountPreferences$mediaReviewsOptions$pt_PT._(_root);
}

// Path: discover
class _Translations$discover$pt_PT extends Translations$discover$pt {
	_Translations$discover$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Descobrir';
	@override String get noContentAvailable => 'Nenhum conteúdo disponível';
	@override String get addMediaToLibraries => 'Adicione conteúdos multimédia às suas bibliotecas';
	@override String get continueWatching => 'Continuar a ver';
	@override String continueWatchingIn({required Object library}) => 'Continuar a ver em ${library}';
	@override String get selectVersion => 'Selecionar versão';
	@override String get nextUp => 'A seguir';
	@override String nextUpIn({required Object library}) => 'A seguir em ${library}';
	@override String get recentlyAdded => 'Adicionados recentemente';
	@override String recentlyAddedIn({required Object library}) => 'Adicionados recentemente em ${library}';
	@override String latestAlbumsIn({required Object library}) => 'Álbuns mais recentes em ${library}';
	@override String recentlyPlayedIn({required Object library}) => 'Reproduzidos recentemente em ${library}';
	@override String mostPlayedIn({required Object library}) => 'Mais reproduzidos em ${library}';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get overview => 'Sinopse';
	@override String get cast => 'Elenco';
	@override String get extras => 'Trailers e extras';
	@override String get studio => 'Estúdio';
	@override String get rating => 'Avaliação';
	@override String get director => 'Realizador';
	@override String get directors => 'Realizadores';
	@override String get movie => 'Filme';
	@override String get tvShow => 'Série de TV';
	@override String minutesLeft({required Object minutes}) => '${minutes} min restantes';
	@override String get moreLikeThis => 'Títulos semelhantes';
	@override String titleCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '${n} título',
		other: '${n} títulos',
	);
	@override late final _Translations$discover$person$pt_PT person = _Translations$discover$person$pt_PT._(_root);
}

// Path: errors
class _Translations$errors$pt_PT extends Translations$errors$pt {
	_Translations$errors$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Falha na pesquisa: ${error}';
	@override String get searchUnavailable => 'A pesquisa não conseguiu chegar a nenhum servidor multimédia.';
	@override String connectionTimeout({required Object context}) => 'Tempo de ligação esgotado ao carregar ${context}';
	@override String get connectionFailed => 'Não foi possível ligar ao servidor multimédia';
	@override String unableToLoad({required Object context}) => 'Não foi possível carregar ${context}. Tente novamente.';
	@override String get noClientAvailable => 'Nenhum cliente disponível';
	@override String get pleaseEnterToken => 'Introduza um token';
	@override String get invalidToken => 'Token inválido';
	@override String failedToVerifyToken({required Object error}) => 'Falha ao verificar o token: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Falha ao mudar para ${displayName}';
	@override String failedToDeleteProfile({required Object displayName}) => 'Falha ao eliminar ${displayName}';
	@override String get failedToRate => 'Não foi possível atualizar a classificação';
	@override String get reasonTimedOut => 'o tempo de ligação esgotou-se';
	@override String get reasonUnreachable => 'não foi possível contactar o servidor';
	@override String get reasonRefused => 'o servidor recusou o pedido';
	@override String get reasonNotFound => 'o item já não está no servidor';
	@override String get reasonServerError => 'o servidor indicou um erro';
	@override String get reasonCancelled => 'o pedido foi cancelado';
	@override String get reasonUnexpected => 'ocorreu um erro inesperado';
}

// Path: libraries
class _Translations$libraries$pt_PT extends Translations$libraries$pt {
	_Translations$libraries$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bibliotecas';
	@override String get fallbackTitle => 'Biblioteca';
	@override String get scanLibraryFiles => 'Examinar ficheiros da biblioteca';
	@override String get scanLibrary => 'Examinar biblioteca';
	@override String get analyze => 'Analisar';
	@override String get analyzeLibrary => 'Analisar biblioteca';
	@override String get refreshMetadata => 'Atualizar metadados';
	@override String get emptyTrash => 'Esvaziar lixo';
	@override String emptyingTrash({required Object title}) => 'A esvaziar o lixo de "${title}"...';
	@override String trashEmptied({required Object title}) => 'Lixo de "${title}" esvaziado';
	@override String failedToEmptyTrash({required Object error}) => 'Falha ao esvaziar o lixo: ${error}';
	@override String analyzing({required Object title}) => 'A analisar "${title}"...';
	@override String analysisStarted({required Object title}) => 'Análise iniciada para "${title}"';
	@override String failedToAnalyze({required Object error}) => 'Falha ao analisar a biblioteca: ${error}';
	@override String get noLibrariesFound => 'Nenhuma biblioteca encontrada';
	@override String get allLibrariesHidden => 'Todas as bibliotecas estão ocultas';
	@override String hiddenLibrariesCount({required Object count}) => 'Bibliotecas ocultas (${count})';
	@override String get thisLibraryIsEmpty => 'Esta biblioteca está vazia';
	@override String get noItemsMatchFilters => 'Nenhum item corresponde aos filtros ativos';
	@override String get resetFilters => 'Repor filtros';
	@override String get all => 'Todos';
	@override String get clearAll => 'Limpar tudo';
	@override String scanLibraryConfirm({required Object title}) => 'Tem a certeza de que pretende examinar "${title}"?';
	@override String analyzeLibraryConfirm({required Object title}) => 'Tem a certeza de que pretende analisar "${title}"?';
	@override String refreshMetadataConfirm({required Object title}) => 'Tem a certeza de que pretende atualizar os metadados de "${title}"?';
	@override String emptyTrashConfirm({required Object title}) => 'Tem a certeza de que pretende esvaziar o lixo de "${title}"?';
	@override String get manageLibraries => 'Gerir bibliotecas';
	@override String get sort => 'Ordenar';
	@override String get sortBy => 'Ordenar por';
	@override String get filters => 'Filtros';
	@override String get confirmActionMessage => 'Tem a certeza de que pretende realizar esta ação?';
	@override String get showLibrary => 'Mostrar biblioteca';
	@override String get hideLibrary => 'Ocultar biblioteca';
	@override String get libraryOptions => 'Opções da biblioteca';
	@override String get shuffleLibrary => 'Reprodução aleatória da biblioteca';
	@override String get content => 'conteúdo da biblioteca';
	@override String get selectLibrary => 'Selecionar biblioteca';
	@override String filtersWithCount({required Object count}) => 'Filtros (${count})';
	@override String get noRecommendations => 'Nenhuma recomendação disponível';
	@override String get noCollections => 'Nenhuma coleção nesta biblioteca';
	@override String get noGenres => 'Nenhum género nesta biblioteca';
	@override String get noFoldersFound => 'Nenhuma pasta encontrada';
	@override String get folders => 'pastas';
	@override late final _Translations$libraries$tabs$pt_PT tabs = _Translations$libraries$tabs$pt_PT._(_root);
	@override late final _Translations$libraries$groupings$pt_PT groupings = _Translations$libraries$groupings$pt_PT._(_root);
	@override late final _Translations$libraries$filterCategories$pt_PT filterCategories = _Translations$libraries$filterCategories$pt_PT._(_root);
	@override late final _Translations$libraries$sortLabels$pt_PT sortLabels = _Translations$libraries$sortLabels$pt_PT._(_root);
	@override late final _Translations$libraries$advancedFilters$pt_PT advancedFilters = _Translations$libraries$advancedFilters$pt_PT._(_root);
}

// Path: about
class _Translations$about$pt_PT extends Translations$about$pt {
	_Translations$about$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Sobre';
	@override String get openSourceLicenses => 'Licenças de código aberto';
	@override String versionLabel({required Object version}) => 'Versão ${version}';
	@override String get appDescription => 'Um belo cliente de Plex, Jellyfin e Emby feito com Flutter';
	@override String get viewLicensesDescription => 'Ver as licenças de bibliotecas de terceiros';
}

// Path: serverSelection
class _Translations$serverSelection$pt_PT extends Translations$serverSelection$pt {
	_Translations$serverSelection$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Nenhum servidor encontrado para ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Falha ao carregar servidores: ${error}';
	@override String get noValidServers => 'Nenhum servidor utilizável foi encontrado nesta conta';
}

// Path: hubDetail
class _Translations$hubDetail$pt_PT extends Translations$hubDetail$pt {
	_Translations$hubDetail$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Título';
	@override String get releaseYear => 'Ano de lançamento';
	@override String get dateAdded => 'Data de adição';
	@override String get rating => 'Avaliação';
	@override String get noItemsFound => 'Nenhum item encontrado';
}

// Path: logs
class _Translations$logs$pt_PT extends Translations$logs$pt {
	_Translations$logs$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Limpar registos';
	@override String get copyLogs => 'Copiar registos';
	@override String get uploadLogs => 'Enviar registos';
}

// Path: startup
class _Translations$startup$pt_PT extends Translations$startup$pt {
	_Translations$startup$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'O Plezy não conseguiu iniciar';
	@override String get failedBody => 'Algo correu mal durante o arranque. Os detalhes abaixo identificam o que falhou.';
	@override String get failedBodyRepairable => 'O ficheiro de definições guardado do Plezy está danificado e tem de ser reconstruído antes de o Plezy poder iniciar. Tentar novamente não vai ajudar — escolha Reparar armazenamento.';
	@override String get phaseLabel => 'Fase';
	@override String get showDetails => 'Mostrar detalhes';
	@override String get hideDetails => 'Ocultar detalhes';
	@override String get copyDetails => 'Copiar detalhes';
	@override String get detailsCopied => 'Detalhes copiados para a área de transferência';
	@override String get uploadDetails => 'Enviar detalhes';
	@override String get repairStorage => 'Reparar armazenamento';
	@override String get repairTitle => 'Reparar dados armazenados?';
	@override String get repairBodyCommon => 'O ficheiro de definições do Plezy está danificado e não pode ser lido. Reparar repõe todas as definições predefinidas.';
	@override String get repairBodyOneCredential => 'Um início de sessão guardado está danificado e não pode ser lido. Reparar remove apenas esse início de sessão; as suas outras definições permanecem intactas.';
	@override String get repairBodySignInsKept => 'Os seus servidores e perfis devem permanecer ligados.';
	@override String get repairBodySignInsLost => 'A chave que protege os seus inícios de sessão guardados não pode ser recuperada deste ficheiro, por isso terá de iniciar sessão novamente em todos os servidores e perfis. Nada no seu servidor multimédia é afetado.';
	@override String get repairBodySessionsUncertain => 'Os rastreadores (MAL, AniList, Simkl, Trakt) e o Seerr são guardados separadamente e podem ou não ser preservados. O Plezy indicará exatamente o que foi mantido.';
	@override String get repairConfirm => 'Reparar';
	@override String get repairSucceeded => 'Armazenamento reparado';
	@override String get repairNeedsRestart => 'Armazenamento reparado — reinício necessário';
	@override String get restartRequiredBody => 'Os seus dados foram reparados, mas o Plezy tem de iniciar do zero antes de os usar. Feche o Plezy e abra-o novamente.';
	@override String get quitPlezy => 'Sair do Plezy';
	@override String get repairFailed => 'Falha na reparação';
	@override String get repairKeptSignIns => 'Os seus servidores e perfis ainda estão ligados.';
	@override String get repairLostSignIns => 'A chave que protege os seus inícios de sessão guardados não pôde ser recuperada. Terá de iniciar sessão novamente em todos os servidores e perfis.';
	@override String get repairLostSessions => 'Pelo menos uma ligação de rastreador ou do Seerr foi perdida e tem de ser ligada novamente.';
	@override String get backupTitle => 'Uma cópia do ficheiro danificado foi mantida';
	@override String get backupWarning => 'Contém as suas credenciais de início de sessão. Não a envie nem partilhe.';
	@override String get deleteBackup => 'Eliminar cópia';
	@override String get backupDeleted => 'Cópia eliminada.';
	@override String get previousFailureTitle => 'O Plezy não conseguiu iniciar da última vez';
}

// Path: licenses
class _Translations$licenses$pt_PT extends Translations$licenses$pt {
	_Translations$licenses$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Pacotes relacionados';
	@override String get license => 'Licença';
	@override String licenseNumber({required Object number}) => 'Licença ${number}';
	@override String licensesCount({required Object count}) => '${count} licenças';
}

// Path: navigation
class _Translations$navigation$pt_PT extends Translations$navigation$pt {
	_Translations$navigation$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Bibliotecas';
	@override String get downloads => 'Transferências';
	@override String get liveTv => 'TV em direto';
	@override String get explore => 'Explorar';
}

// Path: explore
class _Translations$explore$pt_PT extends Translations$explore$pt {
	_Translations$explore$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Explorar';
	@override String get selectSource => 'Selecionar origem';
	@override late final _Translations$explore$rows$pt_PT rows = _Translations$explore$rows$pt_PT._(_root);
	@override late final _Translations$explore$status$pt_PT status = _Translations$explore$status$pt_PT._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '${n} episódio',
		other: '${n} episódios',
	);
	@override String get cast => 'Elenco';
	@override String get characters => 'Personagens';
	@override String get addToWatchlist => 'Adicionar à lista para ver';
	@override String get removeFromWatchlist => 'Remover da lista para ver';
	@override String get addedToWatchlist => 'Adicionado à lista para ver';
	@override String get removedFromWatchlist => 'Removido da lista para ver';
	@override String get watchlistUpdateFailed => 'Não foi possível atualizar a lista para ver';
	@override String get watchlistNoMatch => 'Não foi possível associar este item a uma lista para ver';
	@override String get notInLibrary => 'Não está na sua biblioteca';
	@override String get inTheseLibraries => 'Nestas bibliotecas';
	@override String get checkingLibrary => 'A verificar a sua biblioteca...';
	@override String libraryCheckFailed({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: 'Não foi possível verificar ${n} servidor',
		other: 'Não foi possível verificar ${n} servidores',
	);
	@override String get emptyTitle => 'Ainda não há nada aqui';
	@override String emptyMessage({required Object source}) => 'As linhas de ${source} aparecerão aqui quando tiverem conteúdo.';
	@override String searchHint({required Object source}) => 'Pesquisar em ${source}';
	@override String searchEmpty({required Object query}) => 'Nenhum resultado para "${query}"';
	@override String searchPrompt({required Object source}) => 'Pesquise filmes e séries em ${source}.';
	@override String get searchFailed => 'Falha na pesquisa. Verifique a sua ligação e tente novamente.';
	@override late final _Translations$explore$badge$pt_PT badge = _Translations$explore$badge$pt_PT._(_root);
	@override late final _Translations$explore$stats$pt_PT stats = _Translations$explore$stats$pt_PT._(_root);
	@override late final _Translations$explore$season$pt_PT season = _Translations$explore$season$pt_PT._(_root);
	@override late final _Translations$explore$format$pt_PT format = _Translations$explore$format$pt_PT._(_root);
	@override late final _Translations$explore$sourceMaterial$pt_PT sourceMaterial = _Translations$explore$sourceMaterial$pt_PT._(_root);
	@override late final _Translations$explore$creditRole$pt_PT creditRole = _Translations$explore$creditRole$pt_PT._(_root);
	@override late final _Translations$explore$relation$pt_PT relation = _Translations$explore$relation$pt_PT._(_root);
	@override String broadcast({required Object day, required Object time}) => 'Exibido ${day} às ${time}';
	@override String broadcastWithZone({required Object day, required Object time, required Object timezone}) => 'Exibido ${day} às ${time} ${timezone}';
	@override late final _Translations$explore$detail$pt_PT detail = _Translations$explore$detail$pt_PT._(_root);
	@override String totalResults({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '${n} resultado',
		other: '${n} resultados',
	);
}

// Path: liveTv
class _Translations$liveTv$pt_PT extends Translations$liveTv$pt {
	_Translations$liveTv$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'TV em direto';
	@override String get guide => 'Guia';
	@override String get noChannels => 'Nenhum canal disponível';
	@override String get noDvr => 'Nenhum DVR configurado em nenhum servidor';
	@override String get serverUnavailable => 'O servidor de TV em direto não está disponível.';
	@override String get serverNotConnected => 'O servidor de TV em direto não está ligado.';
	@override String get noPrograms => 'Nenhum dado de programação disponível';
	@override String get liveStreamFailed => 'Falha na transmissão em direto';
	@override String get unknownProgram => 'Programa desconhecido';
	@override String get unknownHub => 'Desconhecido';
	@override String get unknownError => 'Erro desconhecido';
	@override String channelNumber({required Object number}) => 'Canal ${number}';
	@override String get unknownChannel => 'Canal desconhecido';
	@override String get live => 'EM DIRETO';
	@override String get premiereBadge => 'NOVO';
	@override String get reloadGuide => 'Recarregar guia';
	@override String get searchGuide => 'Pesquisar no guia';
	@override String get searchHint => 'Pesquisar canais e programas';
	@override String searchNoResults({required Object query}) => 'Nenhuma correspondência para "${query}"';
	@override String get channelsSection => 'Canais';
	@override String get programsSection => 'Programas';
	@override String get now => 'Agora';
	@override String get today => 'Hoje';
	@override String get tomorrow => 'Amanhã';
	@override String get midnight => 'Meia-noite';
	@override String get overnight => 'Madrugada';
	@override String get morning => 'Manhã';
	@override String get daytime => 'Dia';
	@override String get evening => 'Noite';
	@override String get lateNight => 'Madrugada';
	@override String get whatsOn => 'O que está a passar';
	@override String get watchChannel => 'Ver o canal';
	@override String get favorites => 'Favoritos';
	@override String get reorderFavorites => 'Reordenar favoritos';
	@override String get noFavoriteChannels => 'Nenhum canal favorito';
	@override String get noFavoriteChannelsHint => 'Mostre todos os canais e mantenha um canal premido para o adicionar aos favoritos.';
	@override String get showAllChannels => 'Mostrar todos os canais';
	@override String get favoritesLoadFailed => 'Não foi possível carregar os favoritos. Verifique a sua ligação e tente novamente.';
	@override String get favoritesUpdateFailed => 'Não foi possível atualizar os favoritos. Verifique a sua ligação e tente novamente.';
	@override String get joinSession => 'Entrar na sessão em curso';
	@override String watchFromStart({required Object minutes}) => 'Ver do início (há ${minutes} min)';
	@override String get watchLive => 'Ver em direto';
	@override String get goToLive => 'Ir para o ponto em direto';
	@override String get record => 'Gravar';
	@override String get recordEpisode => 'Gravar episódio';
	@override String get recordSeries => 'Gravar série';
	@override String get recordOptions => 'Opções de gravação';
	@override String get saveTo => 'Guardar em';
	@override String get recordings => 'Gravações';
	@override String get scheduledRecordings => 'Agendadas';
	@override String get recordingRules => 'Regras de gravação';
	@override String get noScheduledRecordings => 'Sem gravações agendadas';
	@override String get manageRecording => 'Gerir gravação';
	@override String get cancelRecording => 'Cancelar gravação';
	@override String get cancelRecordingTitle => 'Cancelar esta gravação?';
	@override String cancelRecordingMessage({required Object title}) => '${title} já não será gravado.';
	@override String get deleteRule => 'Eliminar regra';
	@override String get deleteRuleTitle => 'Eliminar regra de gravação?';
	@override String deleteRuleMessage({required Object title}) => 'Os episódios futuros de ${title} não serão gravados.';
	@override String get recordingScheduled => 'Gravação agendada';
	@override String get alreadyScheduled => 'Este programa já está agendado';
	@override String get dvrAdminRequired => 'As definições de DVR exigem uma conta de administrador';
	@override String get recordingFailed => 'Não foi possível agendar a gravação';
	@override String get recordingTargetMissing => 'Não foi possível determinar a biblioteca de gravação';
	@override String get recordNotAvailable => 'Gravação indisponível para este programa';
	@override String get recordingCancelled => 'Gravação cancelada';
	@override String get recordingRuleDeleted => 'Regra de gravação eliminada';
	@override String get processRecordingRules => 'Reavaliar regras';
	@override String get recordingInProgress => 'A gravar agora';
	@override String recordingsCount({required Object count}) => '${count} agendadas';
	@override String get editRule => 'Editar regra';
	@override String get editRuleAction => 'Editar';
	@override String get recordingRuleUpdated => 'Regra de gravação atualizada';
	@override String get guideReloadRequested => 'Atualização do guia pedida';
	@override String get guideReloadFailed => 'Não foi possível atualizar o guia';
	@override String get rulesProcessRequested => 'Reavaliação de regras pedida';
	@override String get rulesProcessFailed => 'Não foi possível reavaliar as regras de gravação';
	@override String get recordShow => 'Gravar programa';
	@override late final _Translations$liveTv$recordSettings$pt_PT recordSettings = _Translations$liveTv$recordSettings$pt_PT._(_root);
	@override String startingInMinutes({required Object minutes}) => 'Começa dentro de ${minutes} min';
	@override String dayAtTime({required Object day, required Object time}) => '${day} às ${time}';
	@override String invalidPlaybackData({required Object product}) => '${product} devolveu dados de reprodução de TV em direto inválidos';
	@override String get failedToStartChannel => 'Não foi possível iniciar o canal em direto';
	@override String get failedToBuildStreamUrl => 'Não foi possível gerar o URL da transmissão';
	@override String playbackStartFailed({required Object reason}) => 'Não foi possível iniciar o canal: ${reason}';
	@override String channelSwitchFailed({required Object reason}) => 'Não foi possível mudar de canal: ${reason}';
}

// Path: collections
class _Translations$collections$pt_PT extends Translations$collections$pt {
	_Translations$collections$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Coleções';
	@override String get collection => 'Coleção';
	@override String get empty => 'A coleção está vazia';
	@override String get deleteCollection => 'Eliminar coleção';
	@override String deleteConfirm({required Object title}) => 'Eliminar "${title}"? Não pode ser anulado.';
	@override String get deleted => 'Coleção eliminada';
	@override String get deleteFailed => 'Falha ao eliminar a coleção';
	@override String deleteFailedWithError({required Object error}) => 'Falha ao eliminar a coleção: ${error}';
	@override String get selectCollection => 'Selecionar coleção';
	@override String get collectionName => 'Nome da coleção';
	@override String get enterCollectionName => 'Introduza o nome da coleção';
	@override String get addedToCollection => 'Adicionado à coleção';
	@override String get errorAddingToCollection => 'Falha ao adicionar à coleção';
	@override String get created => 'Coleção criada';
	@override String get removeFromCollection => 'Remover da coleção';
	@override String removeFromCollectionConfirm({required Object title}) => 'Remover "${title}" desta coleção?';
	@override String get removedFromCollection => 'Removido da coleção';
	@override String get removeFromCollectionFailed => 'Falha ao remover da coleção';
	@override String removeFromCollectionError({required Object error}) => 'Erro ao remover da coleção: ${error}';
	@override String get searchCollections => 'Pesquisar coleções...';
}

// Path: playlists
class _Translations$playlists$pt_PT extends Translations$playlists$pt {
	_Translations$playlists$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Playlists';
	@override String get playlist => 'Playlist';
	@override String get noPlaylists => 'Nenhuma playlist encontrada';
	@override String get create => 'Criar playlist';
	@override String get playlistName => 'Nome da playlist';
	@override String get enterPlaylistName => 'Introduza o nome da playlist';
	@override String get delete => 'Eliminar playlist';
	@override String get removeItem => 'Remover da playlist';
	@override String get smartPlaylist => 'Playlist inteligente';
	@override String itemCount({required Object count}) => '${count} itens';
	@override String get oneItem => '1 item';
	@override String get emptyPlaylist => 'Esta playlist está vazia';
	@override String get deleteConfirm => 'Eliminar playlist?';
	@override String deleteMessage({required Object name}) => 'Tem a certeza de que pretende eliminar "${name}"?';
	@override String get created => 'Playlist criada';
	@override String get deleted => 'Playlist eliminada';
	@override String get itemAdded => 'Adicionado à playlist';
	@override String get itemRemoved => 'Removido da playlist';
	@override String get selectPlaylist => 'Selecionar playlist';
	@override String get searchPlaylists => 'Pesquisar playlists...';
	@override String get errorCreating => 'Falha ao criar a playlist';
	@override String get errorDeleting => 'Falha ao eliminar a playlist';
	@override String get errorLoading => 'Falha ao carregar playlists';
	@override String get errorAdding => 'Falha ao adicionar à playlist';
	@override String get errorReordering => 'Falha ao reordenar o item da playlist';
	@override String get errorRemoving => 'Falha ao remover da playlist';
}

// Path: music
class _Translations$music$pt_PT extends Translations$music$pt {
	_Translations$music$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => 'Ir para o álbum';
	@override String get goToArtist => 'Ir para o artista';
	@override String get instantMix => 'Mix instantâneo';
	@override String get playNext => 'Reproduzir a seguir';
	@override String get addToQueue => 'Adicionar à fila';
	@override String discNumber({required Object n}) => 'Disco ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '${n} faixa',
		other: '${n} faixas',
	);
	@override String get nowPlaying => 'A reproduzir agora';
	@override String playingFrom({required Object title}) => 'A reproduzir de ${title}';
	@override String get queue => 'Fila';
	@override String get clearQueue => 'Limpar fila';
	@override String get lyrics => 'Letra';
	@override String get noLyrics => 'Nenhuma letra disponível';
	@override String get sleepTimer => 'Temporizador de suspensão';
	@override String get sleepTimerEndOfTrack => 'Fim da faixa';
	@override String sleepTimerMinutes({required Object n}) => '${n} minutos';
	@override String get stopPlayback => 'Parar a reprodução';
	@override String get previousTrack => 'Faixa anterior';
	@override String get nextTrack => 'Próxima faixa';
	@override String get repeat => 'Repetir';
	@override String get repeatAll => 'Repetir tudo';
	@override String get repeatOne => 'Repetir uma faixa';
	@override String get instantMixNoServer => 'Nenhum servidor disponível para um mix instantâneo';
	@override String get instantMixFailed => 'Falha ao carregar o mix instantâneo';
	@override String get instantMixEmpty => 'O mix instantâneo não devolveu nenhuma faixa';
	@override String noAudioUrl({required Object track}) => 'Nenhum URL de áudio disponível para ${track}';
	@override late final _Translations$music$discography$pt_PT discography = _Translations$music$discography$pt_PT._(_root);
}

// Path: watchTogether
class _Translations$watchTogether$pt_PT extends Translations$watchTogether$pt {
	_Translations$watchTogether$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ver juntos';
	@override String get description => 'Veja conteúdos em sincronia com amigos e família';
	@override String get createRoom => 'Criar sala';
	@override String get creatingRoom => 'A criar sala...';
	@override String get joinRoom => 'Entrar na sala';
	@override String get joiningRoom => 'A entrar na sala...';
	@override String get connecting => 'A ligar...';
	@override String get relayPublic => 'As salas usam os servidores de retransmissão públicos do Open Watch Party.';
	@override String relayCustom({required Object url}) => 'As salas usam o seu servidor de retransmissão em ${url}.';
	@override String get recentRooms => 'Salas recentes';
	@override String get roomActions => 'Ações da sala';
	@override String get renameRoom => 'Renomear sala';
	@override String get removeRoom => 'Remover';
	@override String get enterRoomCode => 'Introduza o código de 6 caracteres do anfitrião.';
	@override String get roomCode => 'Código da sala';
	@override String get paste => 'Colar';
	@override String get noCodeInClipboard => 'A área de transferência não contém um código de sala';
	@override String get copyCode => 'Copiar código';
	@override String get codeCopied => 'Código da sala copiado';
	@override String get shareInvite => 'Partilhar convite';
	@override String get inviteCopied => 'Convite copiado. Cole-o numa mensagem.';
	@override String inviteMessage({required Object code}) => 'Entra na minha sala do Ver juntos no Plezy: abre "Ver juntos", escolhe "Entrar na sala" e introduz ${code}.';
	@override String get openSessionControls => 'Abrir os controlos da sessão Ver juntos';
	@override String get reconnecting => 'A voltar a ligar...';
	@override String get reconnectingDescription => 'A ligação caiu. Vai voltar à sala automaticamente.';
	@override String get connected => 'Ligado';
	@override String get disconnected => 'Desligado';
	@override String get youAreHost => 'É o anfitrião';
	@override String hostedBy({required Object name}) => 'Anfitrião: ${name}';
	@override String get hostControlsPlayback => 'O anfitrião controla a reprodução';
	@override String get anyoneCanControl => 'Qualquer pessoa pode controlar a reprodução';
	@override String get roomLocked => 'Sala bloqueada';
	@override String get nowPlaying => 'A reproduzir agora';
	@override String get nothingPlaying => 'Nada em reprodução';
	@override String get nothingPlayingHost => 'Reproduza algo de qualquer biblioteca para partilhar com a sala.';
	@override String get nothingPlayingGuest => 'Quando o anfitrião reproduzir algo, o conteúdo será aberto aqui.';
	@override String get notShareable => 'Este vídeo não corresponde a nenhum item do catálogo, por isso só as pessoas com acesso ao mesmo servidor o podem reproduzir.';
	@override String get searching => 'A procurar este vídeo nas suas bibliotecas...';
	@override String get yourCopy => 'A sua cópia';
	@override String get sharingYourCopy => 'Está a partilhar a sua cópia';
	@override String playingOtherLength({required Object difference}) => 'A reproduzir a sua cópia, ${difference}';
	@override String get mismatchTitle => 'A sua cópia tem outra duração';
	@override String mismatchDescription({required Object difference}) => 'A sua cópia mais próxima é ${difference} que o vídeo da sala. Pode ser outro corte ou outra versão.';
	@override String get playAnyway => 'Reproduzir mesmo assim';
	@override String get chooseAnotherCopy => 'Escolher outra cópia';
	@override String get dontPlay => 'Não reproduzir';
	@override String get unavailableTitle => 'Não tem este vídeo';
	@override String get unavailableDescription => 'O Plezy não o encontrou nas suas bibliotecas. Escolha uma cópia manualmente ou pesquise novamente.';
	@override String get chooseCopy => 'Escolher uma cópia';
	@override String get searchAgain => 'Pesquisar novamente';
	@override String get noCandidates => 'Nenhuma cópia encontrada nas suas bibliotecas.';
	@override String get choiceFailed => 'Não foi possível reproduzir esta cópia para a sala';
	@override String lengthLonger({required Object duration}) => '${duration} mais longa';
	@override String lengthShorter({required Object duration}) => '${duration} mais curta';
	@override String get lengthSame => 'Mesma duração';
	@override String get lengthUnknown => 'Duração desconhecida';
	@override String get joinCurrentPlayback => 'Entrar na reprodução atual';
	@override String get joinCurrentPlaybackDescription => 'Voltar ao conteúdo que o anfitrião está a ver agora';
	@override String get stopMedia => 'Parar o vídeo para todos';
	@override String get syncOffset => 'Ajuste de sincronização';
	@override String get syncOffsetDescription => 'Ajuste o seu vídeo se estiver adiantado ou atrasado em relação à sala.';
	@override String offsetHint({required Object difference}) => 'A sua cópia é ${difference} que o vídeo da sala.';
	@override String applyDifference({required Object offset}) => 'Usar ${offset}';
	@override String get offsetMinusSecond => '-1 s';
	@override String get offsetMinusTenth => '-100 ms';
	@override String get offsetPlusTenth => '+100 ms';
	@override String get offsetPlusSecond => '+1 s';
	@override String get participants => 'Participantes';
	@override String participantCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '${n} participante',
		other: '${n} participantes',
	);
	@override String get hostBadge => 'ANFITRIÃO';
	@override String nameYou({required Object name}) => '${name} (você)';
	@override String get playerIdle => 'Inativo';
	@override String get playerLoading => 'A carregar';
	@override String get playerReady => 'Pronto';
	@override String get playerBuffering => 'Em buffer';
	@override String get matchSearching => 'A procurar';
	@override String get matchMatched => 'Tem o vídeo';
	@override String get matchMismatched => 'Duração diferente';
	@override String get matchUnavailable => 'Não tem o vídeo';
	@override String participantOffset({required Object offset}) => 'Ajuste ${offset}';
	@override String get makeHost => 'Tornar anfitrião';
	@override String get makeHostQuestion => 'Transferir o papel de anfitrião?';
	@override String makeHostConfirm({required Object name}) => '${name} controlará a reprodução e conduzirá a sessão para todos.';
	@override String get transfer => 'Transferir';
	@override String get removeParticipant => 'Remover da sala';
	@override String removeParticipantQuestion({required Object name}) => 'Remover ${name}?';
	@override String removeParticipantConfirm({required Object name}) => '${name} sairá da sala. A pessoa poderá voltar a entrar com o código, a menos que bloqueie a sala.';
	@override String get remove => 'Remover';
	@override String get roomSettings => 'Definições da sala';
	@override String get letEveryoneControl => 'Permitir que todos controlem a reprodução';
	@override String get lockRoom => 'Bloquear sala';
	@override String get lockRoomDescription => 'Ninguém novo pode entrar';
	@override String get leaveRoom => 'Sair da sala';
	@override String get leaveRoomQuestion => 'Sair da sala?';
	@override String get leaveRoomConfirm => 'Pode voltar a entrar com o código da sala.';
	@override String get leave => 'Sair';
	@override String get endRoom => 'Encerrar sala';
	@override String get endRoomQuestion => 'Encerrar sala?';
	@override String get endRoomConfirm => 'Isto encerra a sala para todos.';
	@override String get end => 'Encerrar';
	@override String get playBlockedTitle => 'A reprodução não começou';
	@override String get playBlockedDescription => 'Prima reproduzir para começar a ver com a sala.';
	@override late final _Translations$watchTogether$notices$pt_PT notices = _Translations$watchTogether$notices$pt_PT._(_root);
	@override late final _Translations$watchTogether$ended$pt_PT ended = _Translations$watchTogether$ended$pt_PT._(_root);
	@override late final _Translations$watchTogether$errors$pt_PT errors = _Translations$watchTogether$errors$pt_PT._(_root);
	@override String untitledEpisode({required Object number}) => 'Episódio ${number}';
}

// Path: downloads
class _Translations$downloads$pt_PT extends Translations$downloads$pt {
	_Translations$downloads$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Transferências';
	@override String get manage => 'Gerir';
	@override String get tvShows => 'Séries de TV';
	@override String get movies => 'Filmes';
	@override String get music => 'Música';
	@override String tracksQueued({required Object count}) => '${count} faixas na fila para transferência';
	@override String get noDownloads => 'Ainda não há transferências';
	@override String get noDownloadsDescription => 'O conteúdo transferido aparecerá aqui para ver offline';
	@override String get downloadNow => 'Transferir';
	@override String get deleteDownload => 'Eliminar transferência';
	@override String get retryDownload => 'Tentar transferência novamente';
	@override String get downloadQueued => 'Transferência na fila';
	@override String get downloadResumed => 'Transferência retomada';
	@override String get serverErrorBitrate => 'Erro do servidor: o ficheiro pode exceder o limite remoto de taxa de bits';
	@override String get storageFull => 'As transferências foram interrompidas para proteger o espaço disponível. Liberte espaço ou escolha outro local de transferência e tente novamente.';
	@override String get storageUnavailable => 'As transferências foram interrompidas porque não foi possível verificar o armazenamento disponível. Verifique o local de transferência e tente novamente.';
	@override String episodesQueued({required Object count}) => '${count} episódios na fila de transferência';
	@override String get downloadDeleted => 'Transferência eliminada';
	@override String deleteConfirm({required Object title}) => 'Eliminar "${title}" deste dispositivo?';
	@override String get deleteCollectionDownloads => 'Eliminar transferências';
	@override String deleteCollectionDownloadsConfirm({required Object title}) => 'Eliminar todas as transferências de "${title}" deste dispositivo?';
	@override String get collectionDownloadsDeleted => 'Transferências eliminadas';
	@override String get cancelledDownloadTitle => 'Transferência cancelada';
	@override String get cancelledDownloadMessage => 'Esta transferência foi cancelada. O que pretende fazer?';
	@override String get allEpisodesAlreadyDownloaded => 'Todos os episódios já foram transferidos';
	@override String get resumeDownload => 'Retomar transferência';
	@override String get cancelledDownload => 'Transferência cancelada';
	@override String syncingFile({required Object file, required Object status}) => '${file} (a sincronizar ${status})';
	@override String downloadedFileClickToComplete({required Object file}) => '${file} transferido — clique para concluir';
	@override String get partialDownloadClickToComplete => 'Parcialmente transferido — clique para concluir';
	@override String get deleting => 'A eliminar...';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'A eliminar ${title}... (${current} de ${total})';
	@override String get queuedTooltip => 'Na fila';
	@override String queuedFilesTooltip({required Object files}) => 'Na fila: ${files}';
	@override String get downloadingTooltip => 'A transferir...';
	@override String downloadingFilesTooltip({required Object files}) => 'A transferir ${files}';
	@override String get noDownloadsTree => 'Nenhuma transferência';
	@override String get pauseAll => 'Pausar todas';
	@override String get resumeAll => 'Retomar todas';
	@override String get retryAll => 'Tentar todas novamente';
	@override String get retryFailed => 'Tentar novamente as transferências com falha';
	@override String get deleteAll => 'Eliminar todas';
	@override String get selectVersion => 'Selecionar versão';
	@override String get allEpisodes => 'Todos os episódios';
	@override String get unwatchedOnly => 'Apenas não vistos';
	@override String nextNUnwatched({required Object count}) => 'Próximos ${count} episódios não vistos';
	@override String get customAmount => 'Quantidade personalizada...';
	@override String get includeSpecials => 'Incluir especiais';
	@override String get howManyEpisodes => 'Quantos episódios?';
	@override String get invalidEpisodeCount => 'Introduza um número de episódios válido.';
	@override String get keepSynced => 'Manter sincronizado';
	@override String get downloadOnce => 'Transferir uma vez';
	@override String keepNUnwatched({required Object count}) => 'Manter ${count} episódios não vistos';
	@override String get editSyncRule => 'Editar regra de sincronização';
	@override String get removeSyncRule => 'Remover regra de sincronização';
	@override String removeSyncRuleConfirm({required Object title}) => 'Parar de sincronizar "${title}"? Os episódios transferidos serão mantidos.';
	@override String removeListSyncRuleConfirm({required Object title}) => 'Parar a sincronização de "${title}"?';
	@override String get deleteSyncRuleDownloads => 'Eliminar também as transferências associadas';
	@override String get deleteSyncRuleDownloadsDescription => 'As transferências usadas por outra regra de sincronização ou perfil serão mantidas.';
	@override String syncRuleCreated({required Object count}) => 'Regra de sincronização criada — a manter ${count} episódios não vistos';
	@override String get syncRuleUpdated => 'Regra de sincronização atualizada';
	@override String get syncRuleRemoved => 'Regra de sincronização removida';
	@override String get syncRuleAndDownloadsRemoved => 'Regra de sincronização e transferências associadas removidas';
	@override String get syncRuleCleanupBusy => 'As regras de sincronização estão a ser atualizadas. Tente novamente daqui a pouco.';
	@override String get syncRuleCleanupUnavailable => 'Não foi possível identificar com segurança as transferências associadas. Volte a ligar o servidor e tente novamente, ou remova a regra sem eliminar as transferências.';
	@override String syncedNewEpisodes({required Object count, required Object title}) => '${count} novos episódios sincronizados para ${title}';
	@override String get activeSyncRules => 'Regras de sincronização';
	@override String get noSyncRules => 'Nenhuma regra de sincronização';
	@override String get manageSyncRule => 'Gerir sincronização';
	@override String get editEpisodeCount => 'Número de episódios';
	@override String get editSyncFilter => 'Filtro de sincronização';
	@override String get syncAllItems => 'A sincronizar todos os itens';
	@override String get syncUnwatchedItems => 'A sincronizar itens não vistos';
	@override String syncRuleServerContext({required Object server, required Object status}) => 'Servidor: ${server} • ${status}';
	@override String get syncRuleAvailable => 'Disponível';
	@override String get syncRuleOffline => 'Offline';
	@override String get syncRuleSignInRequired => 'É necessário iniciar sessão';
	@override String get syncRuleAccessDenied => 'Acesso negado';
	@override String get syncRuleNotAvailableForProfile => 'Indisponível para o perfil atual';
	@override String get syncRuleUnknownServer => 'Servidor desconhecido';
	@override String get syncRuleListCreated => 'Regra de sincronização criada';
	@override late final _Translations$downloads$backgroundWarning$pt_PT backgroundWarning = _Translations$downloads$backgroundWarning$pt_PT._(_root);
	@override String get options => 'Opções de transferências';
	@override late final _Translations$downloads$groupings$pt_PT groupings = _Translations$downloads$groupings$pt_PT._(_root);
	@override String get unknownLibrary => 'Biblioteca desconhecida';
	@override String get unknownShow => 'Série desconhecida';
	@override String get unknownSeason => 'Temporada desconhecida';
	@override String get unknownAlbum => 'Álbum desconhecido';
	@override String completedOfTotal({required Object completed, required Object total}) => '${completed}/${total} concluídas';
	@override String get errorFileNotFound => 'Ficheiro não encontrado (404)';
	@override String get errorDownloadNotAllowed => 'Transferência não permitida pelo servidor (403)';
	@override String get errorDownloadFailed => 'Falha na transferência';
	@override String errorDownloadFailedWithReason({required Object reason}) => 'Falha na transferência: ${reason}';
	@override String errorHttpStatus({required Object status}) => 'Falha na transferência (HTTP ${status})';
	@override String errorPostProcessing({required Object reason}) => 'Falha no pós-processamento: ${reason}';
	@override String get reasonFileNotSaved => 'não foi possível guardar o ficheiro neste dispositivo';
	@override String get reasonCannotResume => 'não foi possível retomar a transferência parcial';
	@override String get reasonDeviceStorageFull => 'este dispositivo está sem espaço de armazenamento';
	@override String get notificationDownloading => 'A transferir...';
	@override String get notificationComplete => 'Transferência concluída';
	@override String get notificationPaused => 'Transferência em pausa';
}

// Path: shaders
class _Translations$shaders$pt_PT extends Translations$shaders$pt {
	_Translations$shaders$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Shaders';
	@override String get noShaderDescription => 'Sem melhoramento de vídeo';
	@override String get nvscalerDescription => 'Dimensionamento de imagem da NVIDIA para vídeos mais nítidos';
	@override String get artcnnVariantNeutral => 'Neutro';
	@override String get artcnnVariantDenoise => 'Redução de ruído';
	@override String get artcnnVariantDenoiseSharpen => 'Redução de ruído + nitidez';
	@override String get qualityFast => 'Rápido';
	@override String get qualityHQ => 'Alta qualidade';
	@override String get mode => 'Modo';
	@override String get importShader => 'Importar shader';
	@override String get customShaderDescription => 'Shader GLSL personalizado';
	@override String get shaderImported => 'Shader importado';
	@override String get shaderImportFailed => 'Falha ao importar o shader';
	@override String get deleteShader => 'Eliminar shader';
	@override String deleteShaderConfirm({required Object name}) => 'Eliminar "${name}"?';
}

// Path: companionRemote
class _Translations$companionRemote$pt_PT extends Translations$companionRemote$pt {
	_Translations$companionRemote$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Comando remoto';
	@override String connectedTo({required Object name}) => 'Ligado a ${name}';
	@override String get unknownDevice => 'Dispositivo desconhecido';
	@override late final _Translations$companionRemote$session$pt_PT session = _Translations$companionRemote$session$pt_PT._(_root);
	@override late final _Translations$companionRemote$pairing$pt_PT pairing = _Translations$companionRemote$pairing$pt_PT._(_root);
	@override late final _Translations$companionRemote$remote$pt_PT remote = _Translations$companionRemote$remote$pt_PT._(_root);
	@override late final _Translations$companionRemote$errors$pt_PT errors = _Translations$companionRemote$errors$pt_PT._(_root);
	@override String get closedBeforeAuth => 'A ligação foi encerrada antes da autenticação';
}

// Path: videoSettings
class _Translations$videoSettings$pt_PT extends Translations$videoSettings$pt {
	_Translations$videoSettings$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'Velocidade de reprodução';
	@override String get normalSpeed => 'Normal';
	@override String sleepTimerActive({required Object duration}) => 'Ativo (${duration})';
	@override String get zoom => 'Zoom';
	@override String get sleepTimer => 'Temporizador de suspensão';
	@override String get audioSync => 'Sincronização do áudio';
	@override String get subtitleSync => 'Sincronização das legendas';
	@override String get hdr => 'HDR';
	@override String get hdrUnsupported => 'O HDR não está disponível aqui — o compositor do ambiente de trabalho ou a saída de vídeo não o suporta.';
	@override String get hdrToneMapping => 'Mapeamento de tons HDR';
	@override String get hdrToneMappingCompositor => 'Compositor';
	@override String get hdrToneMappingCompositorDescription => 'Passar os metadados HDR da origem e deixar que o compositor do ambiente de trabalho faça o mapeamento.';
	@override String get hdrToneMappingPlayer => 'Reprodutor';
	@override String get hdrToneMappingPlayerDescription => 'Mapear para o brilho máximo do ecrã no reprodutor e comunicar o resultado ao compositor.';
	@override String get hdrToneMappingFailed => 'Não foi possível alterar o mapeamento de tons HDR — o modo anterior continua ativo.';
	@override String get audioOutput => 'Saída de áudio';
	@override String get performanceOverlay => 'Painel de desempenho';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'Surround';
	@override String get audioOutputSpatial => 'Áudio espacial';
	@override String get audioOutputStereo => 'Estéreo';
	@override String get audioNormalization => 'Normalizar intensidade sonora';
	@override String get audioNormalizationDisablesPassthrough => 'Descodifica o áudio para PCM; a passagem direta fica desativada enquanto esta opção estiver ativa';
}

// Path: performanceOverlay
class _Translations$performanceOverlay$pt_PT extends Translations$performanceOverlay$pt {
	_Translations$performanceOverlay$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get color => 'Cor';
	@override String get performance => 'Desempenho';
	@override String get buffer => 'Buffer';
	@override String get app => 'Aplicação';
	@override String get decoder => 'Descodificador';
	@override String get rawDecoder => 'Descodificador bruto';
	@override String get tunneling => 'Túnel';
	@override String get passthrough => 'Passagem direta';
	@override String get aspect => 'Aspeto';
	@override String get rotation => 'Rotação';
	@override String get dvSource => 'Origem DV';
	@override String get dvPath => 'Caminho DV';
	@override String get dvRouteDecoder => 'Descodificador Dolby Vision';
	@override String get dvRouteDecoderP81 => 'Descodificador Dolby Vision (P7→8.1)';
	@override String get dvRouteBaseLayer => 'Camada base';
	@override String get dvRouteBaseLayerHdr10 => 'Camada base HDR10';
	@override String get dvRouteBaseLayerHlg => 'Camada base HLG';
	@override String get dvRouteBaseLayerSdr => 'Camada base SDR';
	@override String get dvRouteReshaped => 'Remodelagem RPU (gpu-next)';
	@override String get p7Conversion => 'Conv. P7';
	@override String get sampleRate => 'Taxa de amostragem';
	@override String get pixelFormat => 'Formato de pixel';
	@override String get hwFormat => 'Formato HW';
	@override String get matrix => 'Matriz';
	@override String get primaries => 'Primárias';
	@override String get transfer => 'Transferência';
	@override String get renderFps => 'FPS de renderização';
	@override String get displayFps => 'FPS do ecrã';
	@override String get avSync => 'Sincronização A/V';
	@override String get dropped => 'Descartados';
	@override String get dvRpus => 'DV RPUs';
	@override String get dvRpuAverage => 'Média DV RPU';
	@override String get dvSampleAverage => 'Média amostra DV';
	@override String get maxLuma => 'Luma máx.';
	@override String get minLuma => 'Luma mín.';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => 'Cache usada';
	@override String get cacheLimit => 'Limite da cache';
	@override String get speed => 'Velocidade';
	@override String get player => 'Reprodutor';
	@override String get playMethod => 'Método de reprodução';
	@override String get memory => 'Memória';
	@override String get uiFps => 'UI FPS';
	@override String get fps => 'FPS';
	@override String get decoderAndroidHw => 'Android HW';
	@override String get decoderNvidiaHw => 'NVIDIA HW';
	@override String get decoderQualcommHw => 'Qualcomm HW';
	@override String get decoderMediatekHw => 'MediaTek HW';
	@override String get decoderExynosHw => 'Exynos HW';
	@override String get decoderSoftware => 'Software';
	@override String get decoderHardware => 'Hardware';
	@override String get tunnelingActive => 'Ativo';
	@override String dvRpuFailed({required Object converted, required Object failures}) => '${converted} (${failures} com falha)';
}

// Path: externalPlayer
class _Translations$externalPlayer$pt_PT extends Translations$externalPlayer$pt {
	_Translations$externalPlayer$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Reprodutor externo';
	@override String get useExternalPlayer => 'Usar reprodutor externo';
	@override String get useExternalPlayerDescription => 'Abrir vídeos noutra aplicação';
	@override String get selectPlayer => 'Selecionar reprodutor';
	@override String get customPlayers => 'Reprodutores personalizados';
	@override String get systemDefault => 'Predefinição do sistema';
	@override String get addCustomPlayer => 'Adicionar reprodutor personalizado';
	@override String get playerName => 'Nome do reprodutor';
	@override String get playerNameHint => 'O meu reprodutor';
	@override String get playerCommand => 'Comando';
	@override String get playerPackage => 'Nome do pacote';
	@override String get playerUrlScheme => 'Esquema de URL';
	@override String get off => 'Desativado';
	@override String get launchFailed => 'Falha ao abrir o reprodutor externo';
	@override String appNotInstalled({required Object name}) => '${name} não está instalado';
	@override String get playInExternalPlayer => 'Reproduzir no reprodutor externo';
}

// Path: metadataEdit
class _Translations$metadataEdit$pt_PT extends Translations$metadataEdit$pt {
	_Translations$metadataEdit$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'Editar...';
	@override String get screenTitle => 'Editar metadados';
	@override String get basicInfo => 'Informações básicas';
	@override String get artwork => 'Imagens';
	@override String get advancedSettings => 'Definições avançadas';
	@override String get title => 'Título';
	@override String get sortTitle => 'Título para ordenação';
	@override String get originalTitle => 'Título original';
	@override String get releaseDate => 'Data de lançamento';
	@override String get contentRating => 'Classificação etária';
	@override String get studio => 'Estúdio';
	@override String get tagline => 'Slogan';
	@override String get summary => 'Sinopse';
	@override String get poster => 'Póster';
	@override String get background => 'Imagem de fundo';
	@override String get logo => 'Logótipo';
	@override String get squareArt => 'Imagem quadrada';
	@override String get selectPoster => 'Selecionar póster';
	@override String get selectBackground => 'Selecionar imagem de fundo';
	@override String get selectLogo => 'Selecionar logótipo';
	@override String get selectSquareArt => 'Selecionar imagem quadrada';
	@override String get fromUrl => 'A partir de URL';
	@override String get uploadFile => 'Carregar ficheiro';
	@override String get enterImageUrl => 'Introduza o URL da imagem';
	@override String get imageUrl => 'URL da imagem';
	@override String get metadataUpdated => 'Metadados atualizados';
	@override String get metadataUpdateFailed => 'Falha ao atualizar os metadados';
	@override String get artworkUpdated => 'Imagem atualizada';
	@override String get artworkUpdateFailed => 'Falha ao atualizar a imagem';
	@override String get noArtworkAvailable => 'Nenhuma imagem disponível';
	@override String artworkOption({required Object index}) => 'Opção de imagem ${index}';
	@override String selectedArtworkOption({required Object index}) => 'Opção de imagem ${index}, selecionada';
	@override String get notSet => 'Não definido';
	@override String get libraryDefault => 'Predefinição da biblioteca';
	@override String get accountDefault => 'Predefinição da conta';
	@override String get seriesDefault => 'Predefinição da série';
	@override String get episodeSorting => 'Ordenação de episódios';
	@override String get oldestFirst => 'Mais antigos primeiro';
	@override String get newestFirst => 'Mais recentes primeiro';
	@override String get keep => 'Manter';
	@override String get allEpisodes => 'Todos os episódios';
	@override String latestEpisodes({required Object count}) => '${count} episódios mais recentes';
	@override String get latestEpisode => 'Episódio mais recente';
	@override String episodesAddedPastDays({required Object count}) => 'Episódios adicionados nos últimos ${count} dias';
	@override String get deleteAfterPlaying => 'Eliminar episódios após reproduzir';
	@override String get never => 'Nunca';
	@override String get afterADay => 'Após um dia';
	@override String get afterAWeek => 'Após uma semana';
	@override String get afterAMonth => 'Após um mês';
	@override String get onNextRefresh => 'Na próxima atualização';
	@override String get seasons => 'Temporadas';
	@override String get show => 'Mostrar';
	@override String get hide => 'Ocultar';
	@override String get episodeOrdering => 'Ordem dos episódios';
	@override String get tmdbAiring => 'The Movie Database (Exibição)';
	@override String get tvdbAiring => 'TheTVDB (Exibição)';
	@override String get tvdbAbsolute => 'TheTVDB (Absoluto)';
	@override String get metadataLanguage => 'Idioma dos metadados';
	@override String get useOriginalTitle => 'Usar título original';
	@override String get preferredAudioLanguage => 'Idioma de áudio preferido';
	@override String get preferredSubtitleLanguage => 'Idioma de legendas preferido';
	@override String get subtitleMode => 'Modo de seleção automática de legendas';
	@override String get manuallySelected => 'Seleção manual';
	@override String get shownWithForeignAudio => 'Mostrar com áudio estrangeiro';
	@override String get alwaysEnabled => 'Sempre ativado';
	@override String get tags => 'Tags';
	@override String get addTag => 'Adicionar tag';
	@override String get genre => 'Género';
	@override String get director => 'Realizador';
	@override String get writer => 'Argumentista';
	@override String get producer => 'Produtor';
	@override String get country => 'País';
	@override String get collection => 'Coleção';
	@override String get label => 'Etiqueta';
	@override String get quickTag => 'Tag rápida...';
}

// Path: matchScreen
class _Translations$matchScreen$pt_PT extends Translations$matchScreen$pt {
	_Translations$matchScreen$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get match => 'Associar...';
	@override String get fixMatch => 'Corrigir correspondência...';
	@override String get unmatch => 'Desassociar';
	@override String get unmatchConfirm => 'Limpar esta correspondência? O Plex tratará o item como sem correspondência até voltar a ser associado.';
	@override String get unmatchSuccess => 'Item desassociado';
	@override String get unmatchFailed => 'Falha ao desassociar o item';
	@override String get matchApplied => 'Correspondência aplicada';
	@override String get matchFailed => 'Falha ao aplicar a correspondência';
	@override String get titleHint => 'Título';
	@override String get yearHint => 'Ano';
	@override String get search => 'Pesquisar';
	@override String get noMatchesFound => 'Nenhuma correspondência encontrada';
}

// Path: serverTasks
class _Translations$serverTasks$pt_PT extends Translations$serverTasks$pt {
	_Translations$serverTasks$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tarefas do servidor';
	@override String get failedToLoad => 'Falha ao carregar as tarefas';
	@override String get noTasks => 'Nenhuma tarefa em execução';
}

// Path: trakt
class _Translations$trakt$pt_PT extends Translations$trakt$pt {
	_Translations$trakt$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'Ligado';
	@override String connectedAs({required Object username}) => 'Ligado como @${username}';
	@override String get disconnectConfirm => 'Desligar a conta do Trakt?';
	@override String get disconnectConfirmBody => 'O Plezy deixará de enviar eventos para o Trakt. Pode voltar a ligar quando quiser.';
	@override String get scrobble => 'Scrobbling em tempo real';
	@override String get scrobbleDescription => 'Envia eventos de reprodução, pausa e paragem para o Trakt durante a visualização.';
	@override String get watchedSync => 'Sincronizar estado de visto';
	@override String get watchedSyncDescription => 'Ao marcar itens como vistos no Plezy, também serão marcados no Trakt.';
}

// Path: seerr
class _Translations$seerr$pt_PT extends Translations$seerr$pt {
	_Translations$seerr$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => 'Ligar ao Seerr';
	@override String get serverUrl => 'URL do servidor';
	@override String get serverUrlHelper => 'O endereço da sua instância do Seerr';
	@override String get checkServer => 'Continuar';
	@override String get signInWithJellyfin => 'Iniciar sessão com o Jellyfin';
	@override String get signInWithEmby => 'Iniciar sessão com o Emby';
	@override String get signInWithLocal => 'Usar uma conta local';
	@override String get email => 'E-mail';
	@override String get noSignInMethods => 'Esta instância do Seerr não oferece nenhum método de acesso compatível com o Plezy.';
	@override String get instance => 'Instância';
	@override String get disconnectConfirm => 'Desligar o Seerr?';
	@override String get disconnectConfirmBody => 'O Plezy esquecerá esta instância do Seerr. Volte a ligar quando quiser.';
	@override String get request => 'Pedir';
	@override String get request4k => 'Pedir em 4K';
	@override String get seasons => 'Temporadas';
	@override String get allSeasons => 'Todas as temporadas';
	@override String get advancedOptions => 'Avançado';
	@override String get destinationServer => 'Servidor de destino';
	@override String get qualityProfile => 'Perfil de qualidade';
	@override String get rootFolder => 'Pasta raiz';
	@override String get languageProfile => 'Perfil de idioma';
	@override String get tags => 'Etiquetas';
	@override String get noTags => 'Sem etiquetas';
	@override String defaultOption({required Object name}) => '${name} (predefinido)';
	@override String get animeNote => 'Esta série é um anime.';
	@override String get requestSubmitted => 'Pedido enviado';
	@override String requestFailed({required Object error}) => 'Falha no pedido: ${error}';
	@override String get requestsLoadFailed => 'Não foi possível carregar as opções de pedido';
	@override String get nothingToRequest => 'Tudo já está disponível ou foi pedido.';
	@override String get statusAvailable => 'Disponível';
	@override String get statusPartiallyAvailable => 'Parcialmente disponível';
	@override String get statusRequested => 'Pedido';
	@override String get statusProcessing => 'A processar';
	@override String get statusBlocklisted => 'Na lista de bloqueio';
	@override String couldNotReach({required Object url, required Object error}) => 'Não foi possível contactar ${url}: ${error}';
	@override String noInstanceAtUrl({required Object url, required Object status}) => 'Nenhuma instância do Seerr em ${url} (HTTP ${status})';
	@override String get behindAuthProxy => 'Um proxy inverso com autenticação (SSO ou autenticação HTTP) respondeu em vez do Seerr. O Plezy não consegue iniciar sessão através dele: permita que o caminho /api/v1 do Seerr ignore o proxy para esta aplicação, ou use um endereço que chegue diretamente ao Seerr.';
	@override String get invalidUrl => 'Introduza um endereço de servidor como https://seerr.example.com';
	@override String get quickConnectUnsupported => 'Esta instância do Seerr não suporta o Quick Connect. É necessário o Seerr 3.4 ou mais recente.';
	@override String get notInitialized => 'Esta instância do Seerr não concluiu a configuração inicial';
	@override String get noPlexTokenForReauth => 'Nenhum token do Plex disponível para voltar a iniciar sessão';
	@override String get noStoredCredentials => 'Nenhuma credencial guardada disponível para voltar a iniciar sessão';
	@override String get signInRejected => 'O início de sessão foi rejeitado';
	@override String get noSessionCookie => 'O Seerr não forneceu um cookie de sessão';
	@override String get freshCookieRejected => 'O Seerr rejeitou o novo cookie de sessão';
	@override String get noUserInformation => 'O Seerr não devolveu informações do utilizador';
	@override String get sessionRejectedAfterReauth => 'A sessão foi rejeitada depois de voltar a iniciar sessão';
	@override String get permissionDenied => 'O Seerr negou esta ação: a sua conta já não tem a permissão necessária';
	@override String get permissionRevoked => 'Já não tem permissão para pedir isto';
}

// Path: services
class _Translations$services$pt_PT extends Translations$services$pt {
	_Translations$services$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Serviços';
	@override String get hubSubtitle => 'Sincronize o progresso de visualização e peça novos títulos.';
	@override String get integrations => 'Integrações';
	@override String get notConnected => 'Não ligado';
	@override String connectedAs({required Object username}) => 'Ligado como @${username}';
	@override String get scrobble => 'Registar progresso automaticamente';
	@override String get scrobbleDescription => 'Atualiza a sua lista quando termina um episódio ou filme.';
	@override String disconnectConfirm({required Object service}) => 'Desligar ${service}?';
	@override String disconnectConfirmBody({required Object service}) => 'O Plezy deixará de atualizar ${service}. Volte a ligar quando quiser.';
	@override String connectFailed({required Object service}) => 'Não foi possível ligar ao ${service}. Tente novamente.';
	@override late final _Translations$services$names$pt_PT names = _Translations$services$names$pt_PT._(_root);
	@override late final _Translations$services$simklReconnect$pt_PT simklReconnect = _Translations$services$simklReconnect$pt_PT._(_root);
	@override late final _Translations$services$deviceCode$pt_PT deviceCode = _Translations$services$deviceCode$pt_PT._(_root);
	@override late final _Translations$services$oauthProxy$pt_PT oauthProxy = _Translations$services$oauthProxy$pt_PT._(_root);
	@override late final _Translations$services$pendingAuth$pt_PT pendingAuth = _Translations$services$pendingAuth$pt_PT._(_root);
	@override late final _Translations$services$libraryFilter$pt_PT libraryFilter = _Translations$services$libraryFilter$pt_PT._(_root);
}

// Path: addServer
class _Translations$addServer$pt_PT extends Translations$addServer$pt {
	_Translations$addServer$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String addMediaBrowserTitle({required Object product}) => 'Adicionar servidor ${product}';
	@override String get serverUrls => 'URLs do servidor';
	@override String get serverUrlsHelper => 'São permitidos vários URLs, separados por vírgulas.';
	@override String get findServer => 'Encontrar servidor';
	@override String searchingLocalMediaBrowserServers({required Object product}) => 'A procurar servidores ${product} locais...';
	@override String localMediaBrowserServers({required Object product}) => 'Servidores ${product} locais';
	@override String get username => 'Utilizador';
	@override String get password => 'Palavra-passe';
	@override String get signIn => 'Iniciar sessão';
	@override String get change => 'Alterar';
	@override String get required => 'Obrigatório';
	@override String couldNotReachServer({required Object error}) => 'Não foi possível ligar ao servidor: ${error}';
	@override String signInFailed({required Object error}) => 'Falha ao iniciar sessão: ${error}';
	@override String quickConnectFailed({required Object error}) => 'O Quick Connect falhou: ${error}';
	@override String get addPlexTitle => 'Iniciar sessão com o Plex';
	@override String get pinExpired => 'O PIN expirou antes de iniciar sessão. Tente novamente.';
	@override String failedToRegisterAccount({required Object error}) => 'Falha ao registar a conta: ${error}';
	@override String enterMediaBrowserUrlError({required Object product}) => 'Introduza o URL do seu servidor ${product}';
	@override String get addConnectionTitle => 'Adicionar ligação';
	@override String addConnectionTitleScoped({required Object name}) => 'Adicionar a ${name}';
	@override String get signInWithPlexCard => 'Iniciar sessão com o Plex';
	@override String get signInWithPlexCardSubtitle => 'Autorize este dispositivo. Os servidores partilhados são adicionados.';
	@override String get signInWithPlexCardSubtitleScoped => 'Autorize uma conta Plex. Os utilizadores do Plex Home tornam-se perfis.';
	@override String connectToMediaBrowserCard({required Object product}) => 'Ligar ao ${product}';
	@override String get connectToMediaBrowserCardSubtitle => 'Introduza o URL do servidor, o nome de utilizador e a palavra-passe.';
	@override String connectToMediaBrowserCardSubtitleScoped({required Object product, required Object name}) => 'Inicie sessão no seu servidor ${product}. Associado a ${name}.';
	@override String get borrowFromAnotherProfile => 'Usar a ligação de outro perfil';
	@override String get borrowFromAnotherProfileSubtitle => 'Reutilize a ligação de outro perfil. Os perfis protegidos por PIN exigem o PIN.';
	@override String get invalidCredentials => 'Utilizador ou palavra-passe inválidos';
	@override String get authResponseNotJson => 'A resposta de autenticação não era um JSON válido';
	@override String get authResponseIncomplete => 'A resposta de início de sessão do servidor estava incompleta';
	@override String get quickConnectRejected => 'O Quick Connect foi rejeitado pelo servidor';
	@override String get quickConnectNotJson => 'A resposta do Quick Connect não era um JSON válido';
	@override String get quickConnectMissingFields => 'A resposta do Quick Connect não contém um código ou segredo';
	@override String get quickConnectPollRejected => 'A consulta do Quick Connect foi rejeitada pelo servidor';
	@override String get serverTimedOut => 'O servidor não respondeu a tempo';
	@override String get responseNotJson => 'A resposta do servidor não era um JSON válido';
	@override String responseMissingIdentity({required Object product}) => 'A resposta não contém um ID ou nome de servidor — este é um servidor ${product}?';
	@override String probeFailed({required Object error}) => 'Não foi possível ligar ao servidor: ${error}';
	@override String enterAtLeastOneUrl({required Object product}) => 'Introduza pelo menos um URL de servidor ${product}';
	@override String noReachableServer({required Object product}) => 'Nenhum servidor ${product} acessível foi encontrado';
	@override String urlsPointToDifferentServers({required Object product}) => 'Estes URLs apontam para servidores ${product} diferentes';
	@override String urlDoesNotMatchServer({required Object product}) => 'Este URL não corresponde ao servidor ${product}';
	@override String get redirectUnsupported => 'O servidor redirecionou para um URL não suportado';
	@override String redirectDifferentHost({required Object product}) => 'O servidor redirecionou para outro anfitrião. Introduza diretamente o URL final do ${product}.';
	@override String get redirectInsecure => 'O servidor redirecionou de HTTPS para um URL inseguro';
	@override String redirectUnsupportedEnterFinal({required Object product}) => 'O servidor redirecionou para um URL não suportado. Introduza diretamente o URL final do ${product}.';
}

// Path: deepLinks
class _Translations$deepLinks$pt_PT extends Translations$deepLinks$en {
	_Translations$deepLinks$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get invalid => 'Este link do Plezy não é válido.';
	@override String profileNotFound({required Object profile}) => 'Nenhum perfil corresponde a "${profile}".';
	@override String get serverUnavailable => 'Não foi possível contactar o servidor deste link.';
	@override String get notFound => 'Não foi possível encontrar este título nas suas bibliotecas.';
	@override String get unsupportedItem => 'Este link não pode ser reproduzido.';
	@override String get noLiveTv => 'Nenhum servidor de TV em direto está disponível para este link.';
	@override String channelNotFound({required Object channel}) => 'Não foi possível encontrar o canal "${channel}".';
	@override String get showLink => 'Mostrar link';
	@override String get showProfileLink => 'Mostrar link do perfil';
	@override String get dialogTitle => 'Link';
	@override String get showHint => 'Abrir este link reproduz o próximo episódio. Adicione &mode=shuffle para reproduzir a série em modo aleatório.';
	@override String get movieHint => 'Abrir este link reproduz o filme.';
	@override String get episodeHint => 'Abrir este link reproduz este episódio.';
	@override String get profileHint => 'Abrir este link muda para este perfil.';
	@override String openAsProfile({required Object name}) => 'Abrir como ${name}';
	@override String get copy => 'Copiar';
	@override String get copied => 'Link copiado';
}

// Path: appIcon.names
class _Translations$appIcon$names$pt_PT extends Translations$appIcon$names$pt {
	_Translations$appIcon$names$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get midnight => 'Meia-noite';
	@override String get ember => 'Brasa';
	@override String get paper => 'Papel';
	@override String get oled => 'OLED';
	@override String get line => 'Traço';
	@override String get ocean => 'Oceano';
	@override String get ultraviolet => 'Ultravioleta';
	@override String get matcha => 'Matcha';
	@override String get sunset => 'Pôr do sol';
	@override String get gold => 'Dourado';
	@override String get titanium => 'Titânio';
	@override String get glass => 'Vidro';
	@override String get crt => 'CRT';
	@override String get vhs => 'VHS';
	@override String get synthwave => 'Synthwave';
	@override String get pixel => 'Pixel';
	@override String get neon => 'Neon';
	@override String get sticker => 'Autocolante';
	@override String get ticket => 'Bilhete';
	@override String get pop => 'Pop';
	@override String get strata => 'Estratos';
	@override String get facet => 'Faceta';
	@override String get tilde => 'Til';
}

// Path: common.ratingSource
class _Translations$common$ratingSource$pt_PT extends Translations$common$ratingSource$pt {
	_Translations$common$ratingSource$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get critic => 'Críticos';
	@override String get audience => 'Público';
	@override String get imdb => 'IMDb';
	@override String get tmdb => 'TMDB';
	@override String get rottenTomatoes => 'Rotten Tomatoes';
	@override String get simkl => 'Simkl';
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get trakt => 'Trakt';
	@override String get rottenTomatoesCritic => 'Críticos do Rotten Tomatoes';
	@override String get rottenTomatoesAudience => 'Público do Rotten Tomatoes';
	@override String get metacritic => 'Metacritic';
	@override String get letterboxd => 'Letterboxd';
}

// Path: common.mediaKind
class _Translations$common$mediaKind$pt_PT extends Translations$common$mediaKind$pt {
	_Translations$common$mediaKind$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get movie => 'Filme';
	@override String get show => 'Série';
	@override String get season => 'Temporada';
	@override String get episode => 'Episódio';
	@override String get artist => 'Artista';
	@override String get album => 'Álbum';
	@override String get track => 'Faixa';
	@override String get collection => 'Coleção';
	@override String get playlist => 'Playlist';
	@override String get clip => 'Clip';
	@override String get photo => 'Foto';
	@override String get folder => 'Pasta';
}

// Path: supporter.errors
class _Translations$supporter$errors$pt_PT extends Translations$supporter$errors$pt {
	_Translations$supporter$errors$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get storeUnavailable => 'As compras não estão disponíveis. Verifique se iniciou sessão na sua conta da loja e se as compras são permitidas neste dispositivo.';
	@override String get productNotFound => 'O Pacote de temas e ícones não está disponível na sua loja de momento.';
	@override String get productQueryFailed => 'Não foi possível carregar o preço. Verifique a sua ligação e tente novamente.';
	@override String get purchaseFailed => 'A compra não foi concluída. Tente novamente.';
	@override String get restoreFailed => 'Não foi possível aceder à loja para restaurar a sua compra. Tente novamente.';
	@override String get nothingToRestore => 'Nenhuma compra do Pacote de temas e ícones foi encontrada para esta conta da loja.';
}

// Path: themeEditor.slots
class _Translations$themeEditor$slots$pt_PT extends Translations$themeEditor$slots$pt {
	_Translations$themeEditor$slots$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get bg => 'Fundo';
	@override String get surface => 'Superfície';
	@override String get outline => 'Contorno';
	@override String get text => 'Texto';
	@override String get textMuted => 'Texto secundário';
	@override String get accent => 'Destaque';
}

// Path: themeEditor.contrast
class _Translations$themeEditor$contrast$pt_PT extends Translations$themeEditor$contrast$pt {
	_Translations$themeEditor$contrast$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get textOnBg => 'Texto sobre o fundo';
	@override String get textOnSurface => 'Texto sobre a superfície';
	@override String get textMutedOnBg => 'Texto secundário sobre o fundo';
	@override String get textMutedOnSurface => 'Texto secundário sobre a superfície';
	@override String get accentOnBg => 'Destaque sobre o fundo';
	@override String get accentOnSurface => 'Destaque sobre a superfície';
	@override String get labelOnAccent => 'Rótulo do botão sobre o destaque';
}

// Path: hotkeys.actions
class _Translations$hotkeys$actions$pt_PT extends Translations$hotkeys$actions$pt {
	_Translations$hotkeys$actions$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'Reproduzir/Pausar';
	@override String get volumeUp => 'Aumentar Volume';
	@override String get volumeDown => 'Diminuir Volume';
	@override String seekForward({required Object seconds}) => 'Avançar (${seconds}s)';
	@override String seekBackward({required Object seconds}) => 'Retroceder (${seconds}s)';
	@override String get fullscreenToggle => 'Alternar ecrã inteiro';
	@override String get muteToggle => 'Alternar Silêncio';
	@override String get subtitleToggle => 'Alternar Legendas';
	@override String get audioTrackNext => 'Próxima Faixa de Áudio';
	@override String get subtitleTrackNext => 'Próxima Faixa de Legenda';
	@override String get chapterNext => 'Próximo Capítulo';
	@override String get chapterPrevious => 'Capítulo Anterior';
	@override String get episodeNext => 'Próximo Episódio';
	@override String get episodePrevious => 'Episódio Anterior';
	@override String get speedIncrease => 'Aumentar Velocidade';
	@override String get speedDecrease => 'Diminuir Velocidade';
	@override String get speedReset => 'Repor velocidade';
	@override String get zoomIn => 'Aumentar zoom';
	@override String get zoomOut => 'Diminuir zoom';
	@override String get zoomReset => 'Repor zoom';
	@override String get subSeekNext => 'Ir para a próxima legenda';
	@override String get subSeekPrev => 'Ir para a legenda anterior';
	@override String get shaderToggle => 'Alternar Shaders';
	@override String get skipMarker => 'Saltar introdução/créditos';
	@override String get screenshot => 'Capturar ecrã';
}

// Path: videoControls.pipErrors
class _Translations$videoControls$pipErrors$pt_PT extends Translations$videoControls$pipErrors$pt {
	_Translations$videoControls$pipErrors$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Requer Android 8.0 ou superior';
	@override String get iosVersion => 'Requer iOS 15.0 ou superior';
	@override String get permissionDisabled => 'O picture-in-picture está desativado. Ative-o nas definições do sistema.';
	@override String get notSupported => 'O dispositivo não suporta o modo picture-in-picture';
	@override String get voSwitchFailed => 'Falha ao mudar a saída de vídeo para picture-in-picture';
	@override String get failed => 'Falha ao iniciar picture-in-picture';
	@override String get prepareFailed => 'Não foi possível preparar o picture-in-picture';
	@override String unknown({required Object error}) => 'Ocorreu um erro: ${error}';
}

// Path: accountPreferences.groups
class _Translations$accountPreferences$groups$pt_PT extends Translations$accountPreferences$groups$pt {
	_Translations$accountPreferences$groups$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get audioAndSubtitles => 'Áudio e legendas';
	@override String get libraryDisplay => 'Biblioteca';
	@override String get personalMedia => 'Multimédia pessoal';
}

// Path: accountPreferences.subtitleModes
class _Translations$accountPreferences$subtitleModes$pt_PT extends Translations$accountPreferences$subtitleModes$pt {
	_Translations$accountPreferences$subtitleModes$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get none => 'Seleção manual';
	@override String get noneDescription => 'Nunca ativar legendas automaticamente.';
	@override String get defaultMode => 'Seguir as marcações da faixa';
	@override String get defaultModeDescription => 'Usar as marcações de predefinida e forçada guardadas em cada faixa de legendas.';
	@override String get always => 'Sempre ativado';
	@override String get alwaysDescription => 'Ativar uma faixa de legendas no idioma preferido sempre que houver uma.';
	@override String get onlyForced => 'Apenas legendas forçadas';
	@override String get onlyForcedDescription => 'Carregar apenas as faixas marcadas como forçadas.';
	@override String get smart => 'Mostrar com áudio estrangeiro';
	@override String get smartDescription => 'Ativar legendas apenas quando o áudio estiver noutro idioma.';
}

// Path: accountPreferences.subtitleAccessibilityOptions
class _Translations$accountPreferences$subtitleAccessibilityOptions$pt_PT extends Translations$accountPreferences$subtitleAccessibilityOptions$pt {
	_Translations$accountPreferences$subtitleAccessibilityOptions$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get preferNonSdh => 'Preferir legendas não SDH';
	@override String get preferSdh => 'Preferir legendas SDH';
	@override String get onlySdh => 'Apenas legendas SDH';
	@override String get onlyNonSdh => 'Apenas legendas não SDH';
}

// Path: accountPreferences.forcedSubtitleOptions
class _Translations$accountPreferences$forcedSubtitleOptions$pt_PT extends Translations$accountPreferences$forcedSubtitleOptions$pt {
	_Translations$accountPreferences$forcedSubtitleOptions$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get preferNonForced => 'Preferir legendas não forçadas';
	@override String get preferForced => 'Preferir legendas forçadas';
	@override String get onlyForced => 'Apenas legendas forçadas';
	@override String get onlyNonForced => 'Apenas legendas não forçadas';
}

// Path: accountPreferences.watchedIndicatorOptions
class _Translations$accountPreferences$watchedIndicatorOptions$pt_PT extends Translations$accountPreferences$watchedIndicatorOptions$pt {
	_Translations$accountPreferences$watchedIndicatorOptions$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get none => 'Nunca';
	@override String get moviesAndShows => 'Filmes e séries de TV';
	@override String get movies => 'Apenas filmes';
	@override String get shows => 'Apenas séries de TV';
}

// Path: accountPreferences.mediaReviewsOptions
class _Translations$accountPreferences$mediaReviewsOptions$pt_PT extends Translations$accountPreferences$mediaReviewsOptions$pt {
	_Translations$accountPreferences$mediaReviewsOptions$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get usersAndCritics => 'Utilizadores e críticos';
	@override String get usersOnly => 'Apenas utilizadores';
	@override String get criticsOnly => 'Apenas críticos';
	@override String get nobody => 'Oculto';
}

// Path: discover.person
class _Translations$discover$person$pt_PT extends Translations$discover$person$pt {
	_Translations$discover$person$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get born => 'Nascimento';
	@override String get died => 'Falecimento';
	@override String get birthplace => 'Local de nascimento';
	@override String dateWithAge({required Object date, required Object age}) => '${date} (${age} anos)';
	@override String dateWithAgeAtDeath({required Object date, required Object age}) => '${date} (aos ${age} anos)';
}

// Path: libraries.tabs
class _Translations$libraries$tabs$pt_PT extends Translations$libraries$tabs$pt {
	_Translations$libraries$tabs$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Recomendados';
	@override String get browse => 'Navegar';
	@override String get collections => 'Coleções';
	@override String get genres => 'Géneros';
	@override String get playlists => 'Playlists';
}

// Path: libraries.groupings
class _Translations$libraries$groupings$pt_PT extends Translations$libraries$groupings$pt {
	_Translations$libraries$groupings$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Agrupamento';
	@override String get all => 'Todos';
	@override String get movies => 'Filmes';
	@override String get shows => 'Séries de TV';
	@override String get seasons => 'Temporadas';
	@override String get episodes => 'Episódios';
	@override String get artists => 'Artistas';
	@override String get albums => 'Álbuns';
	@override String get tracks => 'Faixas';
	@override String get folders => 'Pastas';
}

// Path: libraries.filterCategories
class _Translations$libraries$filterCategories$pt_PT extends Translations$libraries$filterCategories$pt {
	_Translations$libraries$filterCategories$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get genre => 'Género';
	@override String get year => 'Ano';
	@override String get contentRating => 'Classificação etária';
	@override String get tag => 'Tag';
	@override String get unwatched => 'Não vistos';
	@override String get unplayed => 'Não reproduzidos';
	@override String get favorites => 'Favoritos';
	@override String get filePath => 'Caminho do ficheiro';
}

// Path: libraries.sortLabels
class _Translations$libraries$sortLabels$pt_PT extends Translations$libraries$sortLabels$pt {
	_Translations$libraries$sortLabels$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Título';
	@override String get dateAdded => 'Data de adição';
	@override String get releaseDate => 'Data de lançamento';
	@override String get rating => 'Avaliação';
	@override String get communityRating => 'Avaliação da comunidade';
	@override String get criticRating => 'Avaliação da crítica';
	@override String get userRating => 'Avaliação do utilizador';
	@override String get datePlayed => 'Data de reprodução';
	@override String get playCount => 'Reproduções';
	@override String get productionYear => 'Ano de produção';
	@override String get runtime => 'Duração';
	@override String get officialRating => 'Classificação oficial';
	@override String get premiereDate => 'Data de estreia';
	@override String get startDate => 'Data de início';
	@override String get airTime => 'Horário de exibição';
	@override String get studio => 'Estúdio';
	@override String get random => 'Aleatório';
	@override String get dateShared => 'Data de partilha';
	@override String get latestEpisodeAirDate => 'Última data de exibição do episódio';
	@override String get lastEpisodeDateAdded => 'Data de adição do último episódio';
	@override String get dateDownloaded => 'Data de transferência';
	@override String get size => 'Tamanho';
	@override String get library => 'Biblioteca';
}

// Path: libraries.advancedFilters
class _Translations$libraries$advancedFilters$pt_PT extends Translations$libraries$advancedFilters$pt {
	_Translations$libraries$advancedFilters$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get include => 'Incluir';
	@override String get exclude => 'Excluir';
	@override String get any => 'Qualquer';
	@override String get yes => 'Sim';
	@override String get no => 'Não';
	@override String not({required Object value}) => 'Exceto ${value}';
	@override String valueCount({required Object count}) => '${count} selecionados';
	@override String valueCountExcluded({required Object count}) => '${count} excluídos';
	@override String get searchValues => 'Pesquisar valores';
	@override String get noValues => 'Nenhum valor';
	@override String get matchContains => 'Contém';
	@override String get matchNotContains => 'Não contém';
	@override String get matchIs => 'É';
	@override String get matchIsNot => 'Não é';
	@override String get matchBeginsWith => 'Começa com';
	@override String get matchEndsWith => 'Termina com';
	@override String get textHint => 'Escreva para filtrar';
	@override String get from => 'De';
	@override String get to => 'Até';
	@override String range({required Object from, required Object to}) => '${from} a ${to}';
	@override String atLeast({required Object value}) => '${value} ou mais';
	@override String atMost({required Object value}) => 'Até ${value}';
	@override String dateLastDays({required Object count}) => 'Últimos ${count} dias';
	@override String get dateLastYear => 'Último ano';
	@override String dateOlderThanDays({required Object count}) => 'Há mais de ${count} dias';
	@override String get dateOlderThanYear => 'Há mais de um ano';
}

// Path: explore.rows
class _Translations$explore$rows$pt_PT extends Translations$explore$rows$pt {
	_Translations$explore$rows$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'Lista para ver';
	@override String get recommendedMovies => 'Filmes recomendados';
	@override String get recommendedShows => 'Séries recomendadas';
	@override String get trendingMovies => 'Filmes em tendência';
	@override String get trendingShows => 'Séries em tendência';
	@override String get popularMovies => 'Filmes populares';
	@override String get popularShows => 'Séries populares';
	@override String get trendingAnime => 'Anime em tendência';
	@override String get suggestedAnime => 'Anime sugerido';
	@override String get airingAnime => 'Melhores animes em exibição';
	@override String get popularAnime => 'Anime mais popular';
	@override String get trending => 'Em tendência';
	@override String get upcomingMovies => 'Próximos filmes';
	@override String get upcomingShows => 'Próximas séries';
}

// Path: explore.status
class _Translations$explore$status$pt_PT extends Translations$explore$status$pt {
	_Translations$explore$status$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get airing => 'Em exibição';
	@override String get ended => 'Terminada';
	@override String get canceled => 'Cancelada';
	@override String get upcoming => 'Em breve';
}

// Path: explore.badge
class _Translations$explore$badge$pt_PT extends Translations$explore$badge$pt {
	_Translations$explore$badge$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String rankPopular({required Object n}) => '#${n} popular';
	@override String rankAiring({required Object n}) => '#${n} em exibição';
	@override String rankRated({required Object n}) => '#${n} mais bem avaliado';
	@override String rankTrending({required Object n}) => '#${n} em tendência';
	@override String rankSeasonal({required Object n, required Object season}) => '#${n} em ${season}';
	@override String watchingNow({required Object n}) => '${n} a ver';
	@override String get available => 'Disponível';
	@override String get partiallyAvailable => 'Parcialmente disponível';
	@override String get availableIn4k => '4K disponível';
	@override String get requested => 'Pedido';
	@override String get pendingApproval => 'A aguardar aprovação';
	@override String get processing => 'A processar';
	@override String get declined => 'Recusado';
	@override String get requestFailed => 'Falha no pedido';
	@override String get requested4k => '4K pedido';
	@override String seasonsAvailable({required Object available, required Object total}) => '${available}/${total} temporadas';
	@override String nextEpisodeIn({required Object episode, required Object duration}) => 'Ep ${episode} dentro de ${duration}';
	@override String nextAiringIn({required Object duration}) => 'Próximo dentro de ${duration}';
	@override String episodesShort({required Object n}) => '${n} eps';
	@override String minutesPerEpisode({required Object n}) => '${n} min/ep';
	@override String get adult => '18+';
}

// Path: explore.stats
class _Translations$explore$stats$pt_PT extends Translations$explore$stats$pt {
	_Translations$explore$stats$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String listed({required Object n}) => '${n} listados';
	@override String viewersDay({required Object n}) => '${n} viram hoje';
	@override String viewersWeek({required Object n}) => '${n} viram esta semana';
	@override String viewersMonth({required Object n}) => '${n} viram este mês';
	@override String viewersYear({required Object n}) => '${n} viram este ano';
	@override String viewersAllTime({required Object n}) => '${n} espectadores';
	@override String planning({required Object n}) => '${n} pretendem ver';
	@override String favorited({required Object n}) => '${n} favoritos';
	@override String dropRate({required Object percent}) => '${percent} abandonaram';
	@override String comments({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '${n} comentário',
		other: '${n} comentários',
	);
	@override String votes({required Object n}) => '${n} votos';
	@override String watching({required Object n}) => '${n} a ver';
	@override String completed({required Object n}) => '${n} concluíram';
	@override String onHold({required Object n}) => '${n} em pausa';
	@override String dropped({required Object n}) => '${n} abandonaram';
}

// Path: explore.season
class _Translations$explore$season$pt_PT extends Translations$explore$season$pt {
	_Translations$explore$season$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get winter => 'Inverno';
	@override String get spring => 'Primavera';
	@override String get summer => 'Verão';
	@override String get fall => 'Outono';
	@override String withYear({required Object season, required Object year}) => '${season} ${year}';
}

// Path: explore.format
class _Translations$explore$format$pt_PT extends Translations$explore$format$pt {
	_Translations$explore$format$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get tv => 'TV';
	@override String get tvShort => 'Curta de TV';
	@override String get movie => 'Filme';
	@override String get special => 'Especial';
	@override String get ova => 'OVA';
	@override String get ona => 'ONA';
	@override String get music => 'Música';
	@override String get other => 'Outro';
}

// Path: explore.sourceMaterial
class _Translations$explore$sourceMaterial$pt_PT extends Translations$explore$sourceMaterial$pt {
	_Translations$explore$sourceMaterial$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get original => 'Original';
	@override String get manga => 'Manga';
	@override String get lightNovel => 'Light novel';
	@override String get novel => 'Romance';
	@override String get visualNovel => 'Visual novel';
	@override String get game => 'Jogo';
	@override String get webComic => 'Webcomic';
	@override String get musicRelease => 'Música';
	@override String get otherMedia => 'Outro';
}

// Path: explore.creditRole
class _Translations$explore$creditRole$pt_PT extends Translations$explore$creditRole$pt {
	_Translations$explore$creditRole$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get actor => 'Ator';
	@override String get director => 'Realizador';
	@override String get writer => 'Argumentista';
	@override String get producer => 'Produtor';
	@override String get creator => 'Criador';
	@override String get composer => 'Compositor';
}

// Path: explore.relation
class _Translations$explore$relation$pt_PT extends Translations$explore$relation$pt {
	_Translations$explore$relation$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get prequel => 'Prequela';
	@override String get sequel => 'Sequela';
	@override String get sideStory => 'História paralela';
	@override String get spinOff => 'Spin-off';
	@override String get alternativeVersion => 'Versão alternativa';
	@override String get summary => 'Resumo';
	@override String get parentStory => 'História principal';
	@override String get adaptation => 'Adaptação';
	@override String get other => 'Relacionado';
}

// Path: explore.detail
class _Translations$explore$detail$pt_PT extends Translations$explore$detail$pt {
	_Translations$explore$detail$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get originalTitle => 'Título original';
	@override String get alsoKnownAs => 'Também conhecido como';
	@override String get studios => 'Estúdios';
	@override String get country => 'País';
	@override String get language => 'Idioma';
	@override String get released => 'Lançado';
	@override String get physicalRelease => 'Em disco';
	@override String get ended => 'Terminado';
	@override String addedOn({required Object date}) => 'Adicionado em ${date}';
	@override String get yourRating => 'A sua avaliação';
	@override String get budget => 'Orçamento';
	@override String get revenue => 'Bilheteira';
	@override String get contentAdvisory => 'Classificação etária';
	@override String get tags => 'Tags';
	@override String get revealSpoilerTags => 'Mostrar tags de spoiler';
	@override String get links => 'Links';
	@override String get watchOn => 'Ver em';
	@override String get watchTrailer => 'Ver trailer';
	@override String openOn({required Object site}) => 'Abrir em ${site}';
	@override String get trailerUnavailable => 'Não foi possível abrir o trailer neste dispositivo';
	@override String get linkUnavailable => 'Não foi possível abrir o link neste dispositivo';
	@override String get crew => 'Equipa';
	@override String get ratings => 'Avaliações';
	@override String get schedule => 'Programação';
	@override String recommendedByUsers({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: 'Recomendado por ${n} utilizador',
		other: 'Recomendado por ${n} utilizadores',
	);
	@override String recommendedBy({required Object who}) => 'Recomendado por ${who}';
	@override String favoritedBy({required Object who}) => 'Adicionado aos favoritos por ${who}';
	@override String unairedEpisodes({required Object n}) => '${n} ainda não exibidos';
	@override String recommendedByPercent({required Object percent}) => 'Recomendado por ${percent} dos espectadores';
	@override String get relatedTitles => 'Títulos relacionados';
	@override String get background => 'Contexto';
}

// Path: liveTv.recordSettings
class _Translations$liveTv$recordSettings$pt_PT extends Translations$liveTv$recordSettings$pt {
	_Translations$liveTv$recordSettings$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get startEarly => 'Começar antes (segundos)';
	@override String get endLate => 'Terminar depois (segundos)';
	@override String get newOnly => 'Apenas episódios novos';
	@override String get anyChannel => 'Gravar em qualquer canal';
	@override String get anyTime => 'Gravar a qualquer hora';
	@override String get skipInLibrary => 'Ignorar episódios que já estão na biblioteca';
	@override String get keepUpTo => 'Episódios a manter';
	@override String get keepUpToHint => '0 mantém todos os episódios';
}

// Path: music.discography
class _Translations$music$discography$pt_PT extends Translations$music$discography$pt {
	_Translations$music$discography$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get singlesAndEps => 'Singles e EPs';
	@override String get live => 'Em direto';
	@override String get compilations => 'Compilações';
}

// Path: watchTogether.notices
class _Translations$watchTogether$notices$pt_PT extends Translations$watchTogether$notices$pt {
	_Translations$watchTogether$notices$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String pressedPlay({required Object name}) => '${name} iniciou a reprodução';
	@override String get playbackStarted => 'Reprodução iniciada';
	@override String paused({required Object name}) => '${name} colocou em pausa';
	@override String get playbackPaused => 'Reprodução pausada';
	@override String jumpedTo({required Object name, required Object position}) => '${name} saltou para ${position}';
	@override String roomJumpedTo({required Object position}) => 'Saltou para ${position}';
	@override String changedSpeed({required Object name, required Object speed}) => '${name} definiu a velocidade para ${speed}';
	@override String speedChanged({required Object speed}) => 'Velocidade definida para ${speed}';
	@override String startedMedia({required Object name, required Object title}) => '${name} iniciou ${title}';
	@override String mediaStarted({required Object title}) => 'A reproduzir agora: ${title}';
	@override String stoppedMedia({required Object name}) => '${name} parou o vídeo';
	@override String get mediaStopped => 'O vídeo parou';
	@override String waitingFor({required Object name}) => 'A aguardar ${name}...';
	@override String get waitingForSomeone => 'A aguardar que alguém sincronize...';
	@override String get finished => 'Concluído';
	@override String hostChangedTo({required Object name}) => '${name} é agora o anfitrião';
	@override String get youAreNowHost => 'Agora é o anfitrião';
	@override String joined({required Object name}) => '${name} entrou';
	@override String left({required Object name}) => '${name} saiu';
	@override String get controlRefused => 'Apenas o anfitrião pode controlar a reprodução';
	@override String get searchFailed => 'Não foi possível pesquisar o vídeo da sala em alguns servidores';
	@override String get playBlocked => 'Prima reproduzir para começar';
	@override String get shareFailed => 'Não foi possível partilhar este vídeo com a sala';
	@override String get downloadNotShared => 'As transferências não são partilhadas com a sala enquanto o servidor de origem estiver offline';
	@override String get openFailed => 'Não foi possível abrir o vídeo da sala';
}

// Path: watchTogether.ended
class _Translations$watchTogether$ended$pt_PT extends Translations$watchTogether$ended$pt {
	_Translations$watchTogether$ended$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get ended => 'O anfitrião encerrou a sala';
	@override String get kicked => 'Foi removido da sala';
	@override String get expired => 'A sala expirou';
	@override String get replaced => 'Entrou nesta sala noutro dispositivo';
	@override String get lost => 'A ligação com a sala foi perdida';
}

// Path: watchTogether.errors
class _Translations$watchTogether$errors$pt_PT extends Translations$watchTogether$errors$pt {
	_Translations$watchTogether$errors$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get invalidCode => 'Isto não é um código de sala. Os códigos têm 6 letras e números, sem 0, 1, I, L ou O.';
	@override String get roomNotFound => 'Nenhuma sala tem esse código. Pode ter sido encerrada.';
	@override String get roomFull => 'Esta sala está cheia.';
	@override String get roomLocked => 'O anfitrião bloqueou esta sala.';
	@override String get relayFull => 'O Ver juntos está sobrecarregado de momento. Tente novamente mais tarde.';
	@override String get unreachable => 'Não foi possível contactar o servidor de retransmissão do Ver juntos. Verifique a sua ligação.';
	@override String get rateLimited => 'Demasiadas tentativas. Aguarde um momento e tente novamente.';
	@override String get clientBlocked => 'Esta versão do Plezy não pode usar o servidor de retransmissão. Atualize a aplicação.';
	@override String get forbidden => 'Apenas o anfitrião pode fazer isto.';
	@override String get notInRoom => 'Não está numa sala.';
	@override String get alreadyInRoom => 'Já está numa sala.';
	@override String get resumeFailed => 'Não foi possível voltar à sala.';
	@override String get unsupported => 'O servidor de retransmissão não suporta isto.';
	@override String get generic => 'Algo correu mal. Tente novamente.';
}

// Path: downloads.backgroundWarning
class _Translations$downloads$backgroundWarning$pt_PT extends Translations$downloads$backgroundWarning$pt {
	_Translations$downloads$backgroundWarning$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get bannerBlocked => 'As transferências serão interrompidas ao sair da aplicação';
	@override String get bannerDegraded => 'As transferências em segundo plano podem estar limitadas';
	@override String get bannerAction => 'Detalhes';
	@override String get sheetTitle => 'As transferências em segundo plano estão bloqueadas';
	@override String get sheetTitleDegraded => 'As transferências em segundo plano podem estar limitadas';
	@override String get sheetIntro => 'O Android está a impedir que o Plezy faça transferências de forma fiável em segundo plano.';
	@override String get sheetIntroDegraded => 'O seu dispositivo está a limitar quando o Plezy pode fazer transferências em segundo plano.';
	@override String get reasonBackgroundRestricted => 'A utilização em segundo plano do Plezy está restrita. Defina a utilização da bateria ou a utilização em segundo plano como "Sem restrições".';
	@override String get reasonStandbyRestricted => 'O Android colocou o Plezy num modo de espera restrito. Defina a utilização da bateria como "Sem restrições".';
	@override String get reasonDownloadChannelBlocked => 'As notificações de transferência estão desativadas; por isso, o progresso e os controlos podem ficar indisponíveis.';
	@override String get reasonNotificationsDisabled => 'As notificações estão desativadas. No Android 13 ou mais recente, são necessárias para transferências longas em segundo plano.';
	@override String get reasonDataSaver => 'A Poupança de dados está ativada e bloqueia as transferências em segundo plano com dados móveis. As transferências devem continuar a funcionar por Wi-Fi.';
	@override String get reasonOemUnknown => 'As transferências foram interrompidas várias vezes enquanto o Plezy estava em segundo plano. Verifique as definições de bateria ou de utilização em segundo plano do Plezy.';
	@override String get openSettings => 'Abrir definições';
	@override String get stillNotWorking => 'Ajuda específica para o dispositivo';
	@override String get stillNotWorkingDescription => 'Veja as instruções para o seu dispositivo ou, se o problema persistir, envie um registo em Definições › Ver registos.';
	@override String get dialogTitle => 'As transferências podem não ser concluídas';
	@override String get dialogDownloadAnyway => 'Transferir mesmo assim';
	@override String get dialogFixFirst => 'Corrigir primeiro';
	@override String get statusTile => 'Transferências em segundo plano';
	@override String get statusOk => 'Execução em segundo plano permitida';
	@override String get statusBlocked => 'Bloqueado pelas definições do sistema';
	@override String get statusDegraded => 'Limitado pelas definições do sistema';
	@override String get statusUnknown => 'Ainda não verificado';
	@override String get settingsUnavailable => 'Não foi possível abrir as definições do sistema neste dispositivo';
	@override String get linkUnavailable => 'Não foi possível abrir dontkillmyapp.com neste dispositivo';
}

// Path: downloads.groupings
class _Translations$downloads$groupings$pt_PT extends Translations$downloads$groupings$pt {
	_Translations$downloads$groupings$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get library => 'Biblioteca';
	@override String get collections => 'Coleções';
}

// Path: companionRemote.session
class _Translations$companionRemote$session$pt_PT extends Translations$companionRemote$session$pt {
	_Translations$companionRemote$session$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'A iniciar o servidor remoto...';
	@override String get hostAddress => 'Endereço do anfitrião';
	@override String get connected => 'Ligado';
	@override String get serverRunning => 'Servidor remoto ativo';
	@override String get serverStopped => 'Servidor remoto parado';
	@override String get serverRunningDescription => 'Os dispositivos móveis na sua rede podem ligar-se a esta aplicação';
	@override String get serverStoppedDescription => 'Inicie o servidor para permitir que os dispositivos móveis se liguem';
	@override String get usePhoneToControl => 'Use o seu dispositivo móvel para controlar esta aplicação';
	@override String get startServer => 'Iniciar servidor';
	@override String get stopServer => 'Parar servidor';
	@override String get minimize => 'Minimizar';
	@override String get manualAddressHint => 'Endereço de ligação manual:';
}

// Path: companionRemote.pairing
class _Translations$companionRemote$pairing$pt_PT extends Translations$companionRemote$pairing$pt {
	_Translations$companionRemote$pairing$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'Dispositivos Plezy com a mesma conta Plex aparecem aqui';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'A ligar...';
	@override String get searchingForDevices => 'A procurar dispositivos...';
	@override String get noDevicesFound => 'Nenhum dispositivo encontrado na sua rede';
	@override String get noDevicesHint => 'Abra o Plezy no computador e use a mesma rede Wi-Fi';
	@override String get availableDevices => 'Dispositivos disponíveis';
	@override String get manualConnection => 'Ligação manual';
	@override String get cryptoInitFailed => 'Não foi possível iniciar a ligação segura. Inicie sessão no Plex primeiro.';
	@override String get validationHostRequired => 'Introduza o endereço do anfitrião';
	@override String get validationHostFormat => 'O formato deve ser IP:porta (ex.: 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'A ligação atingiu o tempo limite. Use a mesma rede nos dois dispositivos.';
	@override String get sessionNotFound => 'Dispositivo não encontrado. Verifique se o Plezy está em execução no anfitrião.';
	@override String get authFailed => 'Falha na autenticação. Ambos os dispositivos têm de usar a mesma conta Plex.';
	@override String failedToConnect({required Object error}) => 'Falha ao ligar: ${error}';
}

// Path: companionRemote.remote
class _Translations$companionRemote$remote$pt_PT extends Translations$companionRemote$remote$pt {
	_Translations$companionRemote$remote$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'Pretende desligar-se da sessão remota?';
	@override String get reconnecting => 'A voltar a ligar...';
	@override String attemptOf({required Object current}) => 'Tentativa ${current} de 5';
	@override String get retryNow => 'Tentar agora';
	@override String get tabRemote => 'Remoto';
	@override String get tabPlay => 'Reproduzir';
	@override String get tabMore => 'Mais';
	@override String get menu => 'Menu';
	@override String get tabNavigation => 'Navegação por separadores';
	@override String get tabDiscover => 'Descobrir';
	@override String get tabLibraries => 'Bibliotecas';
	@override String get tabSearch => 'Pesquisar';
	@override String get tabDownloads => 'Transferências';
	@override String get tabSettings => 'Definições';
	@override String get previous => 'Anterior';
	@override String get playPause => 'Reproduzir/Pausar';
	@override String get next => 'Próximo';
	@override String get seekBack => 'Retroceder';
	@override String get stop => 'Parar';
	@override String get seekForward => 'Avançar';
	@override String get volume => 'Volume';
	@override String get volumeDown => 'Diminuir';
	@override String get volumeUp => 'Aumentar';
	@override String get fullscreen => 'Ecrã inteiro';
	@override String get subtitles => 'Legendas';
	@override String get audio => 'Áudio';
	@override String get searchHint => 'Pesquisar no computador...';
}

// Path: companionRemote.errors
class _Translations$companionRemote$errors$pt_PT extends Translations$companionRemote$errors$pt {
	_Translations$companionRemote$errors$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => 'Nenhuma interface de rede encontrada';
	@override String get authenticationFailed => 'Falha na autenticação';
	@override String serverStartFailed({required Object error}) => 'Falha ao iniciar o servidor remoto: ${error}';
	@override String commandFailed({required Object error}) => 'Falha ao enviar o comando remoto: ${error}';
	@override String get joinTimedOut => 'Tempo esgotado ao entrar na sessão';
	@override String get failedToConnectAnyAddress => 'Falha ao ligar a qualquer endereço';
	@override String connectionLostAfterAttempts({required Object attempts}) => 'Ligação perdida após ${attempts} tentativas';
	@override String get connectionLost => 'Ligação perdida';
}

// Path: services.names
class _Translations$services$names$pt_PT extends Translations$services$names$pt {
	_Translations$services$names$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
	@override String get mdblist => 'MDBList';
}

// Path: services.simklReconnect
class _Translations$services$simklReconnect$pt_PT extends Translations$services$simklReconnect$pt {
	_Translations$services$simklReconnect$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Voltar a ligar o Simkl';
	@override String get subtitle => 'O Simkl está a desativar o método de acesso usado por esta ligação. Ao voltar a ligar, o simkl.com será aberto para aprovar o Plezy — o Plezy nunca vê a sua palavra-passe. O seu histórico de visualização continua no Simkl.';
}

// Path: services.deviceCode
class _Translations$services$deviceCode$pt_PT extends Translations$services$deviceCode$pt {
	_Translations$services$deviceCode$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Ativar o Plezy no ${service}';
	@override String get instructions => 'Digitalize o código QR ou aceda ao endereço abaixo e introduza este código:';
	@override String openToActivate({required Object service}) => 'Abrir ${service} para ativar';
	@override String get copyCode => 'Copiar código de ativação';
	@override String get waitingForAuthorization => 'A aguardar autorização…';
	@override String get codeCopied => 'Código copiado';
}

// Path: services.oauthProxy
class _Translations$services$oauthProxy$pt_PT extends Translations$services$oauthProxy$pt {
	_Translations$services$oauthProxy$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Iniciar sessão no ${service}';
	@override String get body => 'Digitalize este código QR ou abra o URL em qualquer dispositivo.';
	@override String openToSignIn({required Object service}) => 'Abrir ${service} para iniciar sessão';
}

// Path: services.pendingAuth
class _Translations$services$pendingAuth$pt_PT extends Translations$services$pendingAuth$pt {
	_Translations$services$pendingAuth$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get copyUrl => 'Copiar URL de acesso';
	@override String get urlCopied => 'URL copiado';
}

// Path: services.libraryFilter
class _Translations$services$libraryFilter$pt_PT extends Translations$services$libraryFilter$pt {
	_Translations$services$libraryFilter$pt_PT._(TranslationsPtPt root) : this._root = root, super.internal(root);

	final TranslationsPtPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Filtro de bibliotecas';
	@override String get subtitleAllSyncing => 'A sincronizar todas as bibliotecas';
	@override String get subtitleNoneSyncing => 'Nada a sincronizar';
	@override String subtitleBlocked({required Object count}) => '${count} bloqueadas';
	@override String subtitleAllowed({required Object count}) => '${count} permitidas';
	@override String get mode => 'Modo de filtro';
	@override String get modeBlacklist => 'Lista de bloqueio';
	@override String get modeWhitelist => 'Lista de permissões';
	@override String get modeHintBlacklist => 'Sincronizar todas as bibliotecas, exceto as marcadas abaixo.';
	@override String get modeHintWhitelist => 'Sincronizar apenas as bibliotecas marcadas abaixo.';
	@override String get libraries => 'Bibliotecas';
	@override String get noLibraries => 'Nenhuma biblioteca disponível';
}

/// The flat map containing all translations for locale <pt-PT>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsPtPt {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Plezy',
			'appIcon.title' => 'Ícone da aplicação',
			'appIcon.defaultIcon' => 'Predefinido',
			'appIcon.current' => 'Ícone atual',
			'appIcon.locked' => 'Incluído no Pacote de temas e ícones',
			'appIcon.lockedHint' => 'Os ícones alternativos estão incluídos no Pacote de temas e ícones.',
			'appIcon.changeFailed' => 'Não foi possível alterar o ícone da aplicação',
			'appIcon.launcherHint' => 'O novo ícone aparece no ecrã inicial assim que sair do Plezy.',
			'appIcon.tvLauncherHint' => 'O novo banner aparece assim que sair do Plezy. O Android TV pode continuar a mostrar o antigo até a TV ser reiniciada.',
			'appIcon.names.midnight' => 'Meia-noite',
			'appIcon.names.ember' => 'Brasa',
			'appIcon.names.paper' => 'Papel',
			'appIcon.names.oled' => 'OLED',
			'appIcon.names.line' => 'Traço',
			'appIcon.names.ocean' => 'Oceano',
			'appIcon.names.ultraviolet' => 'Ultravioleta',
			'appIcon.names.matcha' => 'Matcha',
			'appIcon.names.sunset' => 'Pôr do sol',
			'appIcon.names.gold' => 'Dourado',
			'appIcon.names.titanium' => 'Titânio',
			'appIcon.names.glass' => 'Vidro',
			'appIcon.names.crt' => 'CRT',
			'appIcon.names.vhs' => 'VHS',
			'appIcon.names.synthwave' => 'Synthwave',
			'appIcon.names.pixel' => 'Pixel',
			'appIcon.names.neon' => 'Neon',
			'appIcon.names.sticker' => 'Autocolante',
			'appIcon.names.ticket' => 'Bilhete',
			'appIcon.names.pop' => 'Pop',
			'appIcon.names.strata' => 'Estratos',
			'appIcon.names.facet' => 'Faceta',
			'appIcon.names.tilde' => 'Til',
			'auth.signInWithPlex' => 'Iniciar sessão com o Plex',
			'auth.showQRCode' => 'Mostrar código QR',
			'auth.authenticate' => 'Autenticar',
			'auth.authenticationTimeout' => 'A autenticação expirou. Tente novamente.',
			'auth.scanQRToSignIn' => 'Digitalize este código QR para iniciar sessão',
			'auth.waitingForAuth' => 'A aguardar autenticação...\nInicie sessão no navegador.',
			'auth.useBrowser' => 'Usar navegador',
			'auth.or' => 'ou',
			'auth.connectToMediaBrowser' => ({required Object product}) => 'Ligar ao ${product}',
			'auth.quickConnect' => 'Quick Connect',
			'auth.useQuickConnect' => 'Usar Quick Connect',
			'auth.quickConnectInstructions' => 'Abra o Quick Connect no Jellyfin e introduza este código.',
			'auth.quickConnectWaiting' => 'A aguardar aprovação…',
			'auth.quickConnectCancel' => 'Cancelar',
			'auth.quickConnectExpired' => 'O Quick Connect expirou. Tente novamente.',
			'auth.localDataRecoveryRequired' => 'O Plezy não conseguiu recuperar com segurança os dados locais de acesso e de reproduções pendentes. Inicie sessão novamente.',
			'auth.pinCheckRejected' => 'A verificação do PIN do Plex foi rejeitada',
			'common.cancel' => 'Cancelar',
			'common.save' => 'Guardar',
			'common.close' => 'Fechar',
			'common.clear' => 'Limpar',
			'common.reset' => 'Repor',
			'common.later' => 'Depois',
			'common.submit' => 'Enviar',
			'common.confirm' => 'Confirmar',
			'common.retry' => 'Tentar novamente',
			'common.logout' => 'Sair',
			'common.unknown' => 'Desconhecido',
			'common.refresh' => 'Atualizar',
			'common.yes' => 'Sim',
			'common.no' => 'Não',
			'common.delete' => 'Eliminar',
			'common.edit' => 'Editar',
			'common.shuffle' => 'Aleatório',
			'common.addTo' => 'Adicionar a...',
			'common.createNew' => 'Criar novo',
			'common.connect' => 'Ligar',
			'common.disconnect' => 'Desligar',
			'common.play' => 'Reproduzir',
			'common.pause' => 'Pausa',
			'common.resume' => 'Retomar',
			'common.error' => 'Erro',
			'common.search' => 'Pesquisar',
			'common.home' => 'Início',
			'common.back' => 'Voltar',
			'common.settings' => 'Definições',
			'common.mute' => 'Silenciar',
			'common.ok' => 'OK',
			'common.off' => 'Desativado',
			'common.options' => 'Opções',
			'common.seasonNumber' => ({required Object number}) => 'Temporada ${number}',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => 'Episódio ${number} - ${title}',
			'common.chapterNumber' => ({required Object number}) => 'Capítulo ${number}',
			'common.reconnect' => 'Voltar a ligar',
			'common.viewAll' => 'Ver tudo',
			'common.checkingNetwork' => 'A verificar a rede...',
			'common.loadingServers' => 'A carregar servidores...',
			'common.connectingToServers' => 'A ligar aos servidores...',
			'common.startingOfflineMode' => 'A iniciar o modo offline...',
			'common.loading' => 'A carregar...',
			'common.fullscreen' => 'Ecrã inteiro',
			'common.exitFullscreen' => 'Sair do ecrã inteiro',
			'common.pressBackAgainToExit' => 'Prima Voltar novamente para sair',
			'common.ratingSource.critic' => 'Críticos',
			'common.ratingSource.audience' => 'Público',
			'common.ratingSource.imdb' => 'IMDb',
			'common.ratingSource.tmdb' => 'TMDB',
			'common.ratingSource.rottenTomatoes' => 'Rotten Tomatoes',
			'common.ratingSource.simkl' => 'Simkl',
			'common.ratingSource.mal' => 'MyAnimeList',
			'common.ratingSource.anilist' => 'AniList',
			'common.ratingSource.trakt' => 'Trakt',
			'common.ratingSource.rottenTomatoesCritic' => 'Críticos do Rotten Tomatoes',
			'common.ratingSource.rottenTomatoesAudience' => 'Público do Rotten Tomatoes',
			'common.ratingSource.metacritic' => 'Metacritic',
			'common.ratingSource.letterboxd' => 'Letterboxd',
			'common.notAvailable' => 'N/D',
			'common.url' => 'URL',
			'common.letterKeys' => 'ABC',
			'common.mediaKind.movie' => 'Filme',
			'common.mediaKind.show' => 'Série',
			'common.mediaKind.season' => 'Temporada',
			'common.mediaKind.episode' => 'Episódio',
			'common.mediaKind.artist' => 'Artista',
			'common.mediaKind.album' => 'Álbum',
			'common.mediaKind.track' => 'Faixa',
			'common.mediaKind.collection' => 'Coleção',
			'common.mediaKind.playlist' => 'Playlist',
			'common.mediaKind.clip' => 'Clip',
			'common.mediaKind.photo' => 'Foto',
			'common.mediaKind.folder' => 'Pasta',
			'screens.licenses' => 'Licenças',
			'screens.switchProfile' => 'Mudar de perfil',
			'screens.subtitleStyling' => 'Estilo das legendas',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'Registos',
			'update.available' => 'Atualização disponível',
			'update.versionAvailable' => ({required Object version}) => 'A versão ${version} está disponível',
			'update.currentVersion' => ({required Object version}) => 'Atual: ${version}',
			'update.skipVersion' => 'Saltar esta versão',
			'update.viewRelease' => 'Ver versão',
			'update.latestVersion' => 'Tem a versão mais recente',
			'update.checkFailed' => 'Falha ao verificar atualizações',
			'supporter.title' => 'Pacote de temas e ícones',
			'supporter.intro' => 'Uma compra única e opcional que adiciona extras visuais:',
			'supporter.presetThemes' => 'Temas predefinidos',
			'supporter.presetThemesDescription' => 'Brasa, Geleira, Floresta, Ameixa e Papel',
			'supporter.customTheme' => 'Tema personalizado',
			'supporter.customThemeDescription' => 'Escolha cada cor à sua maneira',
			'supporter.appIcons' => 'Ícones da aplicação',
			'supporter.appIconsDescription' => 'Escolha um ícone alternativo do Plezy',
			'supporter.buy' => ({required Object price}) => 'Comprar por ${price}',
			'supporter.loadingPrice' => 'A carregar preço...',
			'supporter.restore' => 'Restaurar compras',
			'supporter.pending' => 'A sua compra aguarda pagamento ou aprovação. Os extras serão desbloqueados assim que a loja a concluir.',
			'supporter.thankYouTitle' => 'Obrigado pela sua compra',
			'supporter.thankYouBody' => 'O Pacote de temas e ícones está desbloqueado.',
			'supporter.tileSubtitle' => 'Desbloqueie temas e ícones da aplicação com uma compra única',
			'supporter.tileSubtitleThemesOnly' => 'Desbloqueie temas com uma compra única',
			'supporter.tileUnlocked' => 'Desbloqueado — obrigado pela sua compra',
			'supporter.errors.storeUnavailable' => 'As compras não estão disponíveis. Verifique se iniciou sessão na sua conta da loja e se as compras são permitidas neste dispositivo.',
			'supporter.errors.productNotFound' => 'O Pacote de temas e ícones não está disponível na sua loja de momento.',
			'supporter.errors.productQueryFailed' => 'Não foi possível carregar o preço. Verifique a sua ligação e tente novamente.',
			'supporter.errors.purchaseFailed' => 'A compra não foi concluída. Tente novamente.',
			'supporter.errors.restoreFailed' => 'Não foi possível aceder à loja para restaurar a sua compra. Tente novamente.',
			'supporter.errors.nothingToRestore' => 'Nenhuma compra do Pacote de temas e ícones foi encontrada para esta conta da loja.',
			'settings.title' => 'Definições',
			'settings.supportDeveloper' => 'Apoie o Plezy',
			'settings.supportDeveloperDescription' => 'Faça um donativo via Liberapay para financiar o desenvolvimento',
			'settings.language' => 'Idioma',
			'settings.theme' => 'Tema',
			'settings.appearance' => 'Aparência',
			'settings.videoPlayback' => 'Reprodução de vídeo',
			'settings.videoPlaybackDescription' => 'Configurar o comportamento da reprodução',
			'settings.advanced' => 'Avançado',
			'settings.episodePosterMode' => 'Estilo do póster do episódio',
			'settings.seriesPoster' => 'Póster da série',
			'settings.seasonPoster' => 'Póster da temporada',
			'settings.episodeThumbnail' => 'Miniatura',
			'settings.showHeroSectionDescription' => 'Mostrar o carrossel de conteúdo em destaque no ecrã inicial',
			'settings.secondsLabel' => 'Segundos',
			'settings.minutesLabel' => 'Minutos',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'm',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Introduza a duração (${min}-${max})',
			'settings.systemTheme' => 'Sistema',
			'settings.lightTheme' => 'Claro',
			'settings.darkTheme' => 'Escuro',
			'settings.oledTheme' => 'OLED',
			'settings.emberTheme' => 'Brasa',
			'settings.glacierTheme' => 'Geleira',
			'settings.forestTheme' => 'Floresta',
			'settings.plumTheme' => 'Ameixa',
			'settings.paperTheme' => 'Papel',
			'settings.libraryDensity' => 'Densidade da biblioteca',
			'settings.displayScale' => 'Escala de apresentação',
			'settings.compact' => 'Compacto',
			'settings.comfortable' => 'Confortável',
			'settings.gridSpacing' => 'Espaçamento da grelha',
			'settings.gridSpacingTight' => 'Compacto',
			'settings.gridSpacingNormal' => 'Normal',
			'settings.gridSpacingSpacious' => 'Espaçoso',
			'settings.tvCornerSpotlightBackdrop' => 'Imagem de destaque no canto',
			'settings.tvCornerSpotlightBackdropDescription' => 'Mostrar a imagem de destaque no canto superior direito em vez de preencher o ecrã',
			'settings.viewMode' => 'Modo de visualização',
			'settings.gridView' => 'Grelha',
			'settings.listView' => 'Lista',
			'settings.showHeroSection' => 'Mostrar secção de destaque',
			'settings.continueWatchingAction' => 'Ação da secção Continuar a ver',
			'settings.continueWatchingPlay' => 'Reproduzir',
			'settings.continueWatchingDetails' => 'Abrir detalhes',
			'settings.episodeAction' => 'Ação do episódio',
			'settings.episodePlay' => 'Reproduzir',
			'settings.episodeDetails' => 'Abrir detalhes',
			'settings.useGlobalHubs' => 'Usar o esquema do ecrã inicial',
			'settings.useGlobalHubsDescription' => 'Mostrar hubs iniciais unificados. Caso contrário, usar recomendações da biblioteca.',
			'settings.showServerNameOnHubs' => 'Mostrar nome do servidor nos hubs',
			'settings.showServerNameOnHubsDescription' => 'Mostrar sempre os nomes dos servidores nos títulos dos hubs.',
			'settings.groupLibrariesByServer' => 'Agrupar bibliotecas por servidor',
			'settings.groupLibrariesByServerDescription' => 'Agrupar as bibliotecas da barra lateral por servidor multimédia.',
			'settings.alwaysKeepSidebarOpen' => 'Manter a barra lateral sempre aberta',
			'settings.alwaysKeepSidebarOpenDescription' => 'A barra lateral fica expandida e a área de conteúdo ajusta-se',
			'settings.showUnwatchedCount' => 'Mostrar contagem de não vistos',
			'settings.showUnwatchedCountDescription' => 'Mostrar o número de episódios não vistos em séries e temporadas',
			'settings.showWatchedIndicators' => 'Mostrar indicadores de vistos',
			'settings.showWatchedIndicatorsDescription' => 'Mostrar uma marca de verificação em filmes, séries e episódios vistos',
			'settings.showEpisodeNumberOnCards' => 'Mostrar número do episódio nos cartões',
			'settings.showEpisodeNumberOnCardsDescription' => 'Mostrar temporada e episódio nos cartões de episódio',
			'settings.showSeasonPostersOnTabs' => 'Mostrar pósteres de temporada nos separadores',
			'settings.showSeasonPostersOnTabsDescription' => 'Mostrar o póster de cada temporada por cima do separador',
			'settings.tvFullCardLayout' => 'Cartões TV completos',
			'settings.tvFullCardLayoutDescription' => 'Usar cartões de TV só com imagem e nomes dos atores sobrepostos',
			'settings.focusGlow' => 'Brilho de foco',
			'settings.focusGlowDescription' => 'Mostrar um brilho suave à volta do cartão em foco',
			'settings.visualEffects' => 'Efeitos visuais',
			'settings.visualEffectsAuto' => 'Automático',
			'settings.visualEffectsAutoDescription' => 'Reduzir os efeitos automaticamente em dispositivos de baixo consumo',
			'settings.visualEffectsFull' => 'Completos',
			'settings.visualEffectsReduced' => 'Reduzidos',
			'settings.visualEffectsReducedDescription' => 'Menos animações e imagens em menor resolução',
			'settings.hideSpoilers' => 'Ocultar spoilers de episódios não vistos',
			'settings.hideSpoilersDescription' => 'Desfocar miniaturas e descrições de episódios não vistos',
			'settings.playerBackend' => 'Motor de reprodução',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'Descodificação por hardware',
			'settings.hardwareDecodingDescription' => 'Usar aceleração por hardware quando disponível',
			'settings.playbackBuffer' => 'Buffer de reprodução',
			'settings.playbackBufferAuto' => 'Automático (recomendado)',
			'settings.playbackBufferLarge' => 'Grande',
			'settings.playbackBufferExtraLarge' => 'Extra grande',
			'settings.playbackBufferDescription' => 'Guarda mais dados em buffer para ligações instáveis. Também limitado pelo tamanho do buffer.',
			'settings.defaultQualityTitle' => 'Qualidade predefinida',
			'settings.cellularQualityTitle' => 'Qualidade predefinida nos dados móveis',
			'settings.cellularQualitySameAsDefault' => 'Igual à qualidade predefinida',
			'settings.directPlayCoveredQuality' => 'Reproduzir vídeos mais pequenos na qualidade original',
			'settings.directPlayCoveredQualityDescription' => 'Reproduzir diretamente os vídeos que já estão dentro do limite de qualidade em vez de transcodificá-los',
			'settings.videoCodecs' => 'Codecs de vídeo',
			'settings.videoCodecsDescription' => 'Codecs desmarcados são transcodificados pelo servidor',
			'settings.videoCodecsAlwaysAccepted' => 'Sempre aceite',
			'settings.musicQualityTitle' => 'Qualidade da música',
			'settings.subtitleStyling' => 'Estilo das legendas',
			'settings.subtitleStylingDescription' => 'Personalizar o aspeto das legendas',
			'settings.smallSkipDuration' => 'Duração do avanço curto',
			'settings.largeSkipDuration' => 'Duração do avanço longo',
			'settings.rewindOnResume' => 'Rebobinar ao retomar',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} segundos',
			'settings.defaultSleepTimer' => 'Temporizador de suspensão predefinido',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} minutos',
			'settings.rememberTrackSelections' => 'Lembrar a seleção de faixas por série/filme',
			'settings.rememberTrackSelectionsDescription' => 'Lembrar as escolhas de áudio e legendas por título',
			'settings.rememberTrackSelectionsBackendRule' => 'O Plex guarda cada escolha no servidor por ficheiro; o Jellyfin também ativa a opção Lembrar seleções da conta; o Emby não é compatível',
			'settings.followServerTrackSelections' => 'Usar a seleção de faixas do servidor por episódio',
			'settings.followServerTrackSelectionsDescription' => 'Ao mudar de episódio, aplicar o áudio e as legendas selecionados no servidor em vez de manter a escolha atual',
			'settings.resumeMusicOnLaunch' => 'Lembrar a sessão de música',
			'settings.resumeMusicOnLaunchDescription' => 'Ao iniciar a aplicação, reabrir a última música em pausa onde parou',
			'settings.showChapterMarkersOnTimeline' => 'Mostrar marcadores de capítulos na barra de reprodução',
			'settings.showChapterMarkersOnTimelineDescription' => 'Segmentar a barra de reprodução nos limites dos capítulos',
			'settings.specialsOrdering' => 'Especiais na ordem dos episódios',
			'settings.specialsOrderingDescription' => 'Onde os especiais são reproduzidos na ordem de exibição de uma série',
			'settings.specialsOrderingServer' => 'Seguir a ordem do servidor',
			'settings.specialsOrderingAirDate' => 'Intercalar pela data de exibição',
			'settings.specialsOrderingLast' => 'Após as temporadas regulares',
			'settings.clickVideoTogglesPlayback' => 'Clicar no vídeo para alternar reprodução/pausa',
			'settings.clickVideoTogglesPlaybackDescription' => 'Clicar no vídeo para reproduzir ou pausar em vez de mostrar os controlos.',
			'settings.videoPlayerControls' => 'Controlos do reprodutor de vídeo',
			'settings.keyboardShortcuts' => 'Atalhos de teclado',
			'settings.keyboardShortcutsDescription' => 'Personalizar atalhos de teclado',
			'settings.videoPlayerNavigation' => 'Navegação do reprodutor de vídeo',
			'settings.videoPlayerNavigationDescription' => 'Usar as teclas de seta para navegar pelos controlos do reprodutor',
			'settings.watchTogetherRelay' => 'Servidor de retransmissão do Ver juntos',
			'settings.watchTogetherRelayDescription' => 'Servidores de retransmissão públicos do Open Watch Party, a menos que defina o seu',
			'settings.watchTogetherRelayHint' => 'https://minha-retransmissao.exemplo.pt',
			'settings.watchTogetherRelayInvalid' => 'Introduza um URL base de retransmissão HTTP ou HTTPS válido.',
			'settings.crashReporting' => 'Relatórios de erros',
			'settings.crashReportingDescription' => 'Enviar relatórios de erros para ajudar a melhorar a aplicação',
			'settings.debugLogging' => 'Registo de depuração',
			'settings.debugLoggingDescription' => 'Ativar registo detalhado para resolução de problemas',
			'settings.viewLogs' => 'Ver registos',
			'settings.viewLogsDescription' => 'Ver os registos da aplicação',
			'settings.clearImageCache' => 'Limpar cache de imagens',
			'settings.clearImageCacheDescription' => 'Limpar imagens e miniaturas em cache. As imagens podem carregar mais devagar até serem transferidas novamente.',
			'settings.clearImageCacheSuccess' => 'Cache de imagens limpa com sucesso',
			'settings.resetSettings' => 'Repor definições',
			'settings.resetSettingsDescription' => 'Repor as definições predefinidas. Não pode ser anulado.',
			'settings.resetSettingsSuccess' => 'Definições repostas com sucesso',
			'settings.backup' => 'Cópia de segurança',
			'settings.exportSettings' => 'Exportar definições',
			'settings.exportSettingsDescription' => 'Guardar as suas preferências num ficheiro',
			'settings.exportSettingsSuccess' => 'Definições exportadas',
			'settings.importSettings' => 'Importar definições',
			'settings.importSettingsDescription' => 'Restaurar preferências a partir de um ficheiro',
			'settings.importSettingsConfirm' => 'Isto substituirá as suas definições atuais. Continuar?',
			'settings.importSettingsSuccess' => 'Definições importadas',
			'settings.importSettingsInvalidFile' => 'Este ficheiro não é uma exportação válida do Plezy',
			'settings.importSettingsNoUser' => 'Inicie sessão antes de importar as definições',
			'settings.shortcutsReset' => 'Atalhos repostos para os predefinidos',
			'settings.resetShortcutsConfirm' => 'Isto substituirá os seus atalhos personalizados pelos predefinidos. Continuar?',
			'settings.about' => 'Sobre',
			'settings.aboutDescription' => 'Informações da aplicação e licenças',
			'settings.updates' => 'Atualizações',
			'settings.updateAvailable' => 'Atualização disponível',
			'settings.checkForUpdates' => 'Verificar atualizações',
			'settings.autoCheckUpdatesOnStartup' => 'Verificar atualizações automaticamente ao iniciar',
			'settings.autoCheckUpdatesOnStartupDescription' => 'Notificar ao iniciar quando houver uma atualização disponível',
			'settings.validationErrorEnterNumber' => 'Introduza um número válido',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'A duração deve estar entre ${min} e ${max} ${unit}',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Atalho já atribuído a ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Atalho atualizado para ${action}',
			'settings.saveFailed' => 'Não foi possível guardar as alterações. Tente novamente.',
			'settings.autoPlayAndSkip' => 'Reprodução automática e saltos',
			'settings.autoPlayNextEpisode' => 'Reproduzir o próximo episódio automaticamente',
			'settings.autoPlayNextEpisodeDescription' => 'Iniciar o próximo episódio automaticamente quando um terminar',
			'settings.shuffleStartsFromBeginning' => 'A reprodução aleatória começa do início',
			'settings.shuffleStartsFromBeginningDescription' => 'Iniciar cada episódio do início na reprodução aleatória em vez de retomá-lo',
			'settings.playNextCountdown' => 'Contagem decrescente do próximo episódio',
			'settings.playNextCountdownImmediate' => 'Reproduzir imediatamente',
			'settings.skipIntroMode' => 'Saltar introdução',
			'settings.skipIntroModeOffDescription' => 'Reproduzir as introduções normalmente sem botão para saltar',
			'settings.skipIntroModeButtonDescription' => 'Mostrar um botão para saltar quando uma introdução começar',
			'settings.skipIntroModeAutoDescription' => 'Saltar as introduções automaticamente após o atraso abaixo',
			'settings.skipCreditsMode' => 'Saltar créditos',
			'settings.skipCreditsModeOffDescription' => 'Reproduzir os créditos normalmente sem botão para saltar',
			'settings.skipCreditsModeButtonDescription' => 'Mostrar um botão para saltar quando os créditos começarem',
			'settings.skipCreditsModeAutoDescription' => 'Saltar os créditos automaticamente e reproduzir o próximo episódio',
			'settings.skipMarkerModeOff' => 'Desativado',
			'settings.skipMarkerModeButton' => 'Mostrar botão',
			'settings.skipMarkerModeAuto' => 'Automático',
			'settings.forceSkipMarkerFallback' => 'Forçar marcadores alternativos',
			'settings.forceSkipMarkerFallbackDescription' => 'Usar padrões de títulos de capítulos mesmo quando o Plex tiver marcadores',
			'settings.autoSkipDelay' => 'Atraso para saltar automaticamente',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Aguardar ${seconds} segundos antes de saltar automaticamente',
			'settings.introPattern' => 'Padrão do marcador de introdução',
			'settings.introPatternDescription' => 'Expressão regular que identifica marcadores de introdução nos títulos dos capítulos',
			'settings.creditsPattern' => 'Padrão do marcador de créditos',
			'settings.creditsPatternDescription' => 'Expressão regular que identifica marcadores de créditos nos títulos dos capítulos',
			'settings.invalidRegex' => 'Expressão regular inválida',
			'settings.regex' => 'Expressão regular',
			'settings.downloads' => 'Transferências',
			'settings.downloadLocationDescription' => 'Escolha onde armazenar conteúdo transferido',
			'settings.downloadLocationDefault' => 'Predefinido (armazenamento da aplicação)',
			'settings.downloadLocationCustom' => 'Local personalizado',
			'settings.selectFolder' => 'Selecionar pasta',
			'settings.resetToDefault' => 'Repor predefinição',
			'settings.currentPath' => ({required Object path}) => 'Atual: ${path}',
			'settings.downloadLocationChanged' => 'Local de transferência alterado',
			'settings.downloadLocationReset' => 'Local de transferência reposto para o predefinido',
			'settings.downloadLocationInvalid' => 'Não é possível escrever na pasta selecionada',
			'settings.downloadLocationPickerUnavailable' => 'A seleção de pasta não está disponível neste dispositivo',
			'settings.downloadOnWifiOnly' => 'Transferir apenas por Wi-Fi',
			'settings.downloadOnWifiOnlyDescription' => 'Impedir transferências ao usar dados móveis',
			'settings.autoRemoveWatchedDownloads' => 'Remover automaticamente as transferências vistas',
			'settings.autoRemoveWatchedDownloadsDescription' => 'Eliminar automaticamente as transferências já vistas',
			'settings.cellularDownloadBlocked' => 'As transferências estão bloqueadas nos dados móveis. Use Wi-Fi ou altere a definição.',
			'settings.maxVolume' => 'Volume máximo',
			'settings.maxVolumeDescription' => 'Permitir aumentar o volume acima de 100% para conteúdos com som baixo',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Mostrar no Discord o que está a ver',
			'settings.services' => 'Serviços',
			'settings.servicesDescription' => 'Ligue Trakt, MyAnimeList, Seerr e mais',
			'settings.manageLibrariesDescription' => 'Reordene e oculte bibliotecas',
			'settings.companionRemoteServer' => 'Servidor de comando remoto',
			'settings.companionRemoteServerDescription' => 'Permitir que dispositivos móveis na sua rede controlem esta aplicação',
			'settings.companionRemoteServerStartFailed' => 'Não foi possível iniciar o servidor de comando remoto',
			'settings.companionRemoteServerStopFailed' => 'Não foi possível parar o servidor de comando remoto',
			'settings.autoPip' => 'Picture-in-picture automático',
			'settings.autoPipDescription' => 'Entrar automaticamente no modo picture-in-picture ao sair da aplicação durante a reprodução',
			'settings.matchContentFrameRate' => 'Ajustar à taxa de fotogramas do conteúdo',
			'settings.matchContentFrameRateDescription' => 'Ajustar a taxa de atualização do ecrã ao conteúdo de vídeo',
			'settings.matchContentResolution' => 'Ajustar à resolução do conteúdo',
			'settings.matchContentResolutionDescription' => 'Muda o ecrã para a resolução nativa do vídeo para que a TV trate do upscaling. Os menus e as legendas também são ampliados durante a reprodução',
			'settings.matchRefreshRate' => 'Ajustar à taxa de atualização',
			'settings.matchRefreshRateDescription' => 'Ajustar a taxa de atualização do ecrã em ecrã inteiro',
			'settings.matchDynamicRange' => 'Ajustar à gama dinâmica',
			'settings.matchDynamicRangeDescription' => 'Ativar HDR para conteúdo HDR e depois voltar para SDR',
			'settings.displaySwitchDelay' => 'Atraso na mudança do modo de ecrã',
			'settings.tunneledPlayback' => 'Reprodução em túnel',
			'settings.tunneledPlaybackDescription' => 'Usar o modo de túnel de vídeo. Desative se o vídeo ficar preto ao reproduzir em HDR ou se a imagem prender.',
			'settings.audioPassthrough' => 'Passagem direta de áudio',
			'settings.audioPassthroughDescription' => 'Enviar o áudio Dolby/DTS para o recetor ou para a TV sem recodificação, preservando o som surround. Desative se não houver som.',
			'settings.audioPassthroughDescriptionApple' => 'Usar o descodificador Dolby nativo da Apple para Dolby Digital Plus, incluindo Atmos. DTS e TrueHD continuam a ser reproduzidos como PCM multicanal. Desative se não houver som.',
			'settings.audioPassthroughDescriptionAppleSpatial' => 'Usar o descodificador Dolby nativo da Apple para Dolby Digital Plus, incluindo Atmos. No iOS, iPadOS e tvOS 26 ou posterior, TrueHD Atmos e DTS:X são reproduzidos como áudio espacial. As restantes faixas DTS e TrueHD são reproduzidas como PCM multicanal. Desative se não houver som.',
			'settings.audioPassthroughOverriddenByNormalization' => 'Desativada enquanto a normalização de intensidade sonora estiver ativa',
			'settings.audioChannelLimit' => 'Canais de áudio',
			'settings.audioChannelLimitDescription' => 'Misturar o áudio descodificado em menos canais para altifalantes, auscultadores ou sistemas HDMI que não reproduzem todos os canais',
			'settings.audioChannelLimitOriginal' => 'Original',
			'settings.audioChannelLimitOriginalDescription' => 'Reproduzir todos os canais da faixa',
			'settings.audioChannelLimitSurround51' => 'Até 5.1',
			'settings.audioChannelLimitSurround51Description' => 'Misturar 7.1 em 5.1 para TVs e recetores que só aceitam PCM 5.1. A passagem direta não é afetada.',
			'settings.audioChannelLimitStereo' => 'Estéreo',
			'settings.audioChannelLimitStereoDescription' => 'Misturar em dois canais para altifalantes estéreo ou auscultadores. Desativa a passagem direta.',
			'settings.downmixCenterBoost' => 'Reforço do canal central',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'Reforço (dB)',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => 'Normalizar volume na conversão para estéreo',
			'settings.audioDownmixNormalizeDescription' => 'Reduzir o volume da mistura para evitar saturação. Desative para manter o volume original, que pode distorcer em cenas muito altas.',
			'settings.dvConversionMode' => 'Conversão Dolby Vision',
			'settings.dvConversionModeDescription' => 'Escolha como os ficheiros Dolby Vision Profile 7 são tratados.',
			'settings.dvConversionAuto' => 'Automático',
			'settings.dvConversionNative' => 'Nativo / desativado',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Usar a deteção de capacidades do dispositivo e o comportamento alternativo predefinido',
			'settings.dvConversionNativeDescription' => 'Forçar DV7 nativo e impedir uma nova tentativa de conversão de DV',
			'settings.dvConversionDv81Description' => 'Forçar a conversão RPU integrada para Dolby Vision perfil 8.1',
			'settings.dvConversionHevcStripDescription' => 'Remover as camadas RPU/EL do Dolby Vision e apresentar HEVC sem Dolby Vision',
			'settings.disableDolbyVision' => 'Desativar Dolby Vision',
			'settings.disableDolbyVisionDescription' => 'Reproduzir a camada HDR10 ou HLG do ficheiro em vez de Dolby Vision, quando houver',
			'settings.hdrSdrConversion' => 'Conversão de HDR para SDR',
			'settings.hdrSdrConversionDescription' => 'Escolha o que converte os vídeos HDR quando o ecrã não consegue mostrar HDR.',
			'settings.hdrSdrConversionAuto' => 'Automático',
			'settings.hdrSdrConversionAutoDescription' => 'Dispositivo no Android 9 ou posterior, reprodutor em versões anteriores',
			'settings.hdrSdrConversionDevice' => 'Dispositivo',
			'settings.hdrSdrConversionDeviceDescription' => 'O hardware de vídeo do dispositivo faz a conversão. Mais rápido, mas as cores dependem do dispositivo',
			'settings.hdrSdrConversionPlayer' => 'Reprodutor',
			'settings.hdrSdrConversionPlayerDescription' => 'O reprodutor faz a conversão. Cores consistentes, mas o 4K pode engasgar em TV boxes mais simples',
			'settings.deinterlace' => 'Desentrelaçamento',
			'settings.deinterlaceDescription' => 'Remover os artefactos em pente do vídeo entrelaçado (apenas no reprodutor mpv)',
			'settings.deinterlaceOff' => 'Desativado',
			'settings.deinterlaceOffDescription' => 'Mostrar o vídeo entrelaçado tal como é descodificado',
			'settings.deinterlaceVideo' => 'Vídeo',
			'settings.deinterlaceVideoDescription' => 'Transformar cada campo num fotograma completo. Para vídeos gravados para TV, como desporto, noticiários e programas de entretenimento',
			'settings.deinterlaceFilm' => 'Filme',
			'settings.deinterlaceFilmDescription' => 'Restaurar os fotogramas originais de filmes e animações convertidos por telecine para 29,97 fps, comum em DVDs NTSC. Os vídeos gravados para TV ficam aos soluços. A TV em direto usa Vídeo',
			'settings.requireProfileSelectionOnOpen' => 'Pedir perfil ao abrir a aplicação',
			'settings.requireProfileSelectionOnOpenDescription' => 'Mostrar a seleção de perfil sempre que a aplicação for aberta',
			'settings.forceTvMode' => 'Forçar modo TV',
			'settings.forceTvModeDescription' => 'Forçar o esquema de TV em dispositivos sem deteção automática. Requer reiniciar a aplicação.',
			'settings.startInFullscreen' => 'Iniciar em ecrã inteiro',
			'settings.startInFullscreenDescription' => 'Abrir o Plezy em modo de ecrã inteiro ao iniciar',
			'settings.exitFullscreenOnPlayerClose' => 'Sair do ecrã inteiro ao fechar o reprodutor',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Sair automaticamente do ecrã inteiro ao fechar o reprodutor de vídeo',
			'settings.autoHidePerformanceOverlay' => 'Ocultar automaticamente o painel de desempenho',
			'settings.autoHidePerformanceOverlayDescription' => 'Esbater o painel de desempenho juntamente com os controlos de reprodução',
			'settings.showNavBarLabels' => 'Mostrar etiquetas da barra de navegação',
			'settings.showNavBarLabelsDescription' => 'Mostrar etiquetas de texto por baixo dos ícones da barra de navegação',
			'settings.startupSection' => 'Secção inicial',
			'settings.showExploreTab' => 'Mostrar separador Explorar',
			'settings.showExploreTabDescription' => 'Mostrar o separador Explorar com conteúdo do Plex Discover e dos rastreadores ligados',
			'settings.liveTvDefaultFavorites' => 'Canais favoritos por predefinição',
			'settings.liveTvDefaultFavoritesDescription' => 'Mostrar apenas os canais favoritos ao abrir a TV em direto',
			'settings.general' => 'Geral',
			'settings.generalDescription' => 'Idioma, arranque e comportamento da janela',
			'settings.languageAndRegion' => 'Idioma e região',
			'settings.startup' => 'Arranque',
			'settings.display' => 'Ecrã',
			'settings.libraryAndCards' => 'Biblioteca e cartões',
			'settings.homeScreen' => 'Ecrã inicial',
			'settings.navigation' => 'Navegação',
			'settings.window' => 'Janela',
			'settings.liveTv' => 'TV em direto',
			'settings.player' => 'Reprodutor',
			'settings.videoAndDisplay' => 'Vídeo e ecrã',
			'settings.audio' => 'Áudio',
			'settings.quality' => 'Qualidade',
			'settings.subtitles' => 'Legendas',
			'settings.seekAndTiming' => 'Avanço e tempo',
			'settings.behavior' => 'Comportamento',
			'settings.gestures' => 'Gestos',
			'settings.gestureBrightnessSwipe' => 'Deslizar para o brilho',
			'settings.gestureBrightnessSwipeDescription' => 'Deslize para cima ou para baixo na margem esquerda para ajustar o brilho',
			'settings.gestureVolumeSwipe' => 'Deslizar para o volume',
			'settings.gestureVolumeSwipeDescription' => 'Deslize para cima ou para baixo na margem direita para ajustar o volume',
			'settings.gesturePinchToZoom' => 'Beliscar para ampliar',
			'settings.gesturePinchToZoomDescription' => 'Junte ou afaste os dedos no vídeo para ampliar ou reduzir',
			'settings.rememberBrightnessLevel' => 'Lembrar o nível de brilho',
			'settings.rememberBrightnessLevelDescription' => 'Iniciar a reprodução com o brilho definido pelo último deslize',
			'settings.controls' => 'Controlos',
			'settings.rememberPlayerChanges' => 'Lembrar alterações do reprodutor',
			'settings.rememberPlayerChangesDescription' => 'Onde uma alteração feita durante a reprodução é guardada e reaplicada',
			'settings.scopePlaybackSpeed' => 'Velocidade de reprodução',
			'settings.scopeShaderPreset' => 'Predefinição de shader',
			'settings.scopeAspectRatio' => 'Proporção do ecrã',
			'settings.scopeZoom' => 'Zoom',
			'settings.scopeSyncOffsets' => 'Sincronização de áudio e legendas',
			'settings.playerScopeOff' => 'Não guardar',
			'settings.playerScopeGlobal' => 'Em todo o lado',
			'settings.playerScopeLibrary' => 'Por biblioteca',
			'settings.playerScopeTitle' => 'Por série ou filme',
			'settings.exportDialogTitle' => 'Exportar definições do Plezy',
			'themeEditor.builtIn' => 'Integrados',
			'themeEditor.presets' => 'Predefinidos',
			'themeEditor.custom' => 'Personalizado',
			'themeEditor.customEmpty' => 'Ainda não criado',
			'themeEditor.editCustom' => 'Editar tema personalizado',
			'themeEditor.editCustomDescription' => 'Escolha cada cor à sua maneira',
			'themeEditor.locked' => 'Desbloqueie com o Pacote de temas e ícones',
			'themeEditor.savedLocked' => 'Guardado — desbloqueia com o Pacote de temas e ícones',
			'themeEditor.title' => 'Tema personalizado',
			'themeEditor.startFrom' => 'Começar a partir de',
			'themeEditor.startFromDescription' => 'Copiar todas as cores de outro tema',
			'themeEditor.colors' => 'Cores',
			'themeEditor.preview' => 'Pré-visualização',
			'themeEditor.slots.bg' => 'Fundo',
			'themeEditor.slots.surface' => 'Superfície',
			'themeEditor.slots.outline' => 'Contorno',
			'themeEditor.slots.text' => 'Texto',
			'themeEditor.slots.textMuted' => 'Texto secundário',
			_ => null,
		} ?? switch (path) {
			'themeEditor.slots.accent' => 'Destaque',
			'themeEditor.opacity' => 'Opacidade',
			'themeEditor.hexHint' => '#RRGGBB ou #AARRGGBB',
			'themeEditor.fromOtherThemes' => 'De outros temas',
			'themeEditor.swatchLabel' => ({required Object color, required Object theme}) => '${color} (${theme})',
			'themeEditor.contrast.textOnBg' => 'Texto sobre o fundo',
			'themeEditor.contrast.textOnSurface' => 'Texto sobre a superfície',
			'themeEditor.contrast.textMutedOnBg' => 'Texto secundário sobre o fundo',
			'themeEditor.contrast.textMutedOnSurface' => 'Texto secundário sobre a superfície',
			'themeEditor.contrast.accentOnBg' => 'Destaque sobre o fundo',
			'themeEditor.contrast.accentOnSurface' => 'Destaque sobre a superfície',
			'themeEditor.contrast.labelOnAccent' => 'Rótulo do botão sobre o destaque',
			'themeEditor.lowContrast' => ({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, abaixo dos ${minimum}:1 recomendados',
			'themeEditor.discardTitle' => 'Descartar alterações?',
			'themeEditor.discardMessage' => 'As suas alterações de cor não guardadas serão perdidas.',
			'themeEditor.discard' => 'Descartar',
			'themeEditor.previewCardTitle' => ({required Object number}) => 'Episódio ${number}',
			'themeEditor.previewCardSubtitle' => ({required Object minutes}) => '${minutes} min restantes',
			'themeEditor.previewSwitch' => 'Reprodução automática',
			'themeEditor.previewMutedText' => 'O texto secundário fica assim',
			'search.hint' => 'Pesquisar filmes, séries, músicas...',
			'search.tryDifferentTerm' => 'Tente um termo de pesquisa diferente',
			'search.searchYourMedia' => 'Pesquisar o seu conteúdo multimédia',
			'search.enterTitleActorOrKeyword' => 'Introduza um título, ator ou palavra-chave',
			'search.people' => 'Pessoas',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'Definir atalho para ${actionName}',
			'hotkeys.clearShortcut' => 'Limpar atalho',
			'hotkeys.noShortcutSet' => 'Nenhum atalho definido',
			'hotkeys.currentShortcut' => 'Atalho atual:',
			'hotkeys.pressToRecord' => 'Selecionar para gravar um atalho',
			'hotkeys.recordingShortcut' => 'Prima o atalho agora',
			'hotkeys.actions.playPause' => 'Reproduzir/Pausar',
			'hotkeys.actions.volumeUp' => 'Aumentar Volume',
			'hotkeys.actions.volumeDown' => 'Diminuir Volume',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'Avançar (${seconds}s)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'Retroceder (${seconds}s)',
			'hotkeys.actions.fullscreenToggle' => 'Alternar ecrã inteiro',
			'hotkeys.actions.muteToggle' => 'Alternar Silêncio',
			'hotkeys.actions.subtitleToggle' => 'Alternar Legendas',
			'hotkeys.actions.audioTrackNext' => 'Próxima Faixa de Áudio',
			'hotkeys.actions.subtitleTrackNext' => 'Próxima Faixa de Legenda',
			'hotkeys.actions.chapterNext' => 'Próximo Capítulo',
			'hotkeys.actions.chapterPrevious' => 'Capítulo Anterior',
			'hotkeys.actions.episodeNext' => 'Próximo Episódio',
			'hotkeys.actions.episodePrevious' => 'Episódio Anterior',
			'hotkeys.actions.speedIncrease' => 'Aumentar Velocidade',
			'hotkeys.actions.speedDecrease' => 'Diminuir Velocidade',
			'hotkeys.actions.speedReset' => 'Repor velocidade',
			'hotkeys.actions.zoomIn' => 'Aumentar zoom',
			'hotkeys.actions.zoomOut' => 'Diminuir zoom',
			'hotkeys.actions.zoomReset' => 'Repor zoom',
			'hotkeys.actions.subSeekNext' => 'Ir para a próxima legenda',
			'hotkeys.actions.subSeekPrev' => 'Ir para a legenda anterior',
			'hotkeys.actions.shaderToggle' => 'Alternar Shaders',
			'hotkeys.actions.skipMarker' => 'Saltar introdução/créditos',
			'hotkeys.actions.screenshot' => 'Capturar ecrã',
			'fileInfo.title' => 'Informações do ficheiro',
			'fileInfo.overview' => 'Visão geral',
			'fileInfo.video' => 'Vídeo',
			'fileInfo.audio' => 'Áudio',
			'fileInfo.subtitles' => 'Legendas',
			'fileInfo.images' => 'Imagens incorporadas',
			'fileInfo.dataStreams' => 'Fluxos de dados',
			'fileInfo.lyrics' => 'Letras',
			'fileInfo.file' => 'Ficheiro',
			'fileInfo.attachments' => 'Anexos',
			'fileInfo.delivery' => 'Entrega',
			'fileInfo.versionCounter' => ({required Object index, required Object count}) => 'Versão ${index} de ${count}',
			'fileInfo.fileCounter' => ({required Object index, required Object count}) => 'Ficheiro ${index} de ${count}',
			'fileInfo.noStreams' => 'O servidor não indicou fluxos para este ficheiro.',
			'fileInfo.copyPath' => 'Copiar caminho',
			'fileInfo.pathCopied' => 'Caminho do ficheiro copiado',
			'fileInfo.codec' => 'Codec',
			'fileInfo.codecTag' => 'Tag do codec',
			'fileInfo.resolution' => 'Resolução',
			'fileInfo.codedResolution' => 'Resolução codificada',
			'fileInfo.bitrate' => 'Taxa de bits',
			'fileInfo.frameRate' => 'Taxa de fotogramas',
			'fileInfo.rotation' => 'Rotação',
			'fileInfo.comment' => 'Comentário',
			'fileInfo.audioDescription' => 'Descrição de áudio',
			'fileInfo.headerCompression' => 'Compressão de cabeçalho',
			'fileInfo.sidecarFile' => 'Ficheiro sidecar',
			'fileInfo.transportTimestamp' => 'Carimbo de transporte',
			'fileInfo.displayOffset' => 'Deslocamento de apresentação',
			'fileInfo.previewFailureCode' => 'Código de falha da pré-visualização',
			'fileInfo.previewRetries' => 'Tentativas da pré-visualização',
			'fileInfo.aspectRatio' => 'Proporção',
			'fileInfo.pixelAspectRatio' => 'Proporção de aspeto de pixel',
			'fileInfo.profile' => 'Perfil',
			'fileInfo.level' => 'Nível',
			'fileInfo.bitDepth' => 'Profundidade de bits',
			'fileInfo.pixelFormat' => 'Formato de pixel',
			'fileInfo.colorSpace' => 'Espaço de cor',
			'fileInfo.colorRange' => 'Gama de cor',
			'fileInfo.colorPrimaries' => 'Primárias de cor',
			'fileInfo.colorTransfer' => 'Transferência de cor',
			'fileInfo.chromaSubsampling' => 'Subamostragem de croma',
			'fileInfo.chromaLocation' => 'Localização do croma',
			'fileInfo.scanType' => 'Tipo de varrimento',
			'fileInfo.interlaced' => 'Entrelaçado',
			'fileInfo.anamorphic' => 'Anamórfico',
			'fileInfo.referenceFrames' => 'Fotogramas de referência',
			'fileInfo.dynamicRange' => 'Gama dinâmica',
			'fileInfo.dolbyVision' => 'Dolby Vision',
			'fileInfo.dolbyVisionLevel' => 'Nível Dolby Vision',
			'fileInfo.dolbyVisionVersion' => 'Versão Dolby Vision',
			'fileInfo.dolbyVisionLayers' => 'Camadas Dolby Vision',
			'fileInfo.baseLayerCompatibility' => 'Compatibilidade da camada base',
			'fileInfo.avcBitstream' => 'Bitstream AVC',
			'fileInfo.nalLengthSize' => 'Tamanho do comprimento NAL',
			'fileInfo.scalingMatrix' => 'Matriz de dimensionamento personalizada',
			'fileInfo.streamIdentifier' => 'Identificador do fluxo',
			'fileInfo.streamIndex' => 'Índice do fluxo',
			'fileInfo.streamId' => 'ID do fluxo',
			'fileInfo.language' => 'Idioma',
			'fileInfo.languageCode' => 'Código do idioma',
			'fileInfo.streamTitle' => 'Título da faixa',
			'fileInfo.channels' => 'Canais',
			'fileInfo.sampleRate' => 'Taxa de amostragem',
			'fileInfo.spatialAudio' => 'Áudio espacial',
			'fileInfo.textBased' => 'Baseado em texto',
			'fileInfo.subtitleFormat' => 'Formato sidecar',
			'fileInfo.provider' => 'Fornecedor',
			'fileInfo.matchScore' => 'Pontuação de correspondência',
			'fileInfo.externalDelivery' => 'Pode ser servido separadamente',
			'fileInfo.sidecarPath' => 'Caminho do sidecar',
			'fileInfo.sourceStream' => 'Copiado de',
			'fileInfo.temporary' => 'Temporário',
			'fileInfo.timeBase' => 'Base de tempo',
			'fileInfo.overallBitrate' => 'Taxa de bits total',
			'fileInfo.path' => 'Caminho',
			'fileInfo.fileName' => 'Nome do ficheiro',
			'fileInfo.size' => 'Tamanho',
			'fileInfo.totalSize' => 'Tamanho total',
			'fileInfo.container' => 'Contentor',
			'fileInfo.duration' => 'Duração',
			'fileInfo.previewThumbnails' => 'Miniaturas de pré-visualização',
			'fileInfo.previewIndex' => 'Índice de pré-visualização',
			'fileInfo.packetLength' => 'Tamanho do pacote',
			'fileInfo.filePresent' => 'Ficheiro presente',
			'fileInfo.fileReadable' => 'Legível pelo servidor',
			'fileInfo.streamPath' => 'Caminho do fluxo',
			'fileInfo.optimizedForStreaming' => 'Otimizado para transmissão',
			'fileInfo.has64bitOffsets' => 'Deslocamentos de 64 bits',
			'fileInfo.protocol' => 'Protocolo',
			'fileInfo.mediaType' => 'Tipo de multimédia',
			'fileInfo.sourceKind' => 'Tipo de origem',
			'fileInfo.optimizedVersion' => 'Versão otimizada',
			'fileInfo.optimizationTarget' => 'Alvo de otimização',
			'fileInfo.deletedAt' => 'Eliminado',
			'fileInfo.remoteSource' => 'Origem remota',
			'fileInfo.infiniteStream' => 'Fluxo infinito',
			'fileInfo.directPlay' => 'Reprodução direta',
			'fileInfo.directStream' => 'Fluxo direto',
			'fileInfo.transcoding' => 'Transcodificação',
			'fileInfo.etag' => 'ETag',
			'fileInfo.versionId' => 'ID da versão',
			'fileInfo.fileId' => 'ID do ficheiro',
			'fileInfo.defaultAudioTrack' => 'Faixa de áudio predefinida',
			'fileInfo.defaultSubtitleTrack' => 'Faixa de legendas predefinida',
			'fileInfo.subtitlesOff' => 'Desativadas',
			'fileInfo.flagDefault' => 'Predefinida',
			'fileInfo.flagForced' => 'Forçada',
			'fileInfo.flagSelected' => 'Selecionada',
			'fileInfo.flagExternal' => 'Externa',
			'fileInfo.flagHearingImpaired' => 'Deficiência auditiva',
			'fileInfo.flagDub' => 'Dobrada',
			'fileInfo.flagOriginal' => 'Original',
			'fileInfo.channelsMono' => 'Mono',
			'fileInfo.dolbyVisionProfile' => ({required Object profile}) => 'Perfil ${profile}',
			'mediaMenu.markAsWatched' => 'Marcar como visto',
			'mediaMenu.markAsUnwatched' => 'Marcar como não visto',
			'mediaMenu.removeFromContinueWatching' => 'Remover de Continuar a ver',
			'mediaMenu.viewDetails' => 'Ver detalhes',
			'mediaMenu.goToSeries' => 'Ir para a série',
			'mediaMenu.shufflePlay' => 'Reprodução aleatória',
			'mediaMenu.shuffleNotAvailableOffline' => 'Reprodução aleatória indisponível offline',
			'mediaMenu.fileInfo' => 'Informações do ficheiro',
			'mediaMenu.deleteEpisodeFromServer' => 'Eliminar episódio do servidor',
			'mediaMenu.deleteSeasonFromServer' => 'Eliminar temporada do servidor',
			'mediaMenu.deleteShowFromServer' => 'Eliminar série do servidor',
			'mediaMenu.deleteMovieFromServer' => 'Eliminar filme do servidor',
			'mediaMenu.deleteEpisodeTitle' => 'Eliminar este episódio?',
			'mediaMenu.deleteSeasonTitle' => 'Eliminar esta temporada?',
			'mediaMenu.deleteShowTitle' => 'Eliminar esta série?',
			'mediaMenu.deleteMovieTitle' => 'Eliminar este filme?',
			'mediaMenu.deleteEpisodeConfirm' => 'Eliminar episódio',
			'mediaMenu.deleteSeasonConfirm' => 'Eliminar temporada',
			'mediaMenu.deleteShowConfirm' => 'Eliminar série',
			'mediaMenu.deleteMovieConfirm' => 'Eliminar filme',
			'mediaMenu.deleteAnyway' => 'Eliminar mesmo assim',
			'mediaMenu.confirmDeleteTarget' => ({required Object title}) => 'Eliminar permanentemente ${title} do seu servidor?',
			'mediaMenu.deleteMultipleWarning' => 'Isto inclui todos os episódios e os respetivos ficheiros.',
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: 'Isto elimina ${n} episódio e o respetivo ficheiro.', other: 'Isto elimina todos os ${n} episódios e os respetivos ficheiros.', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: 'Este item está armazenado como ${n} ficheiro, que será eliminado.', other: 'Este item está armazenado em ${n} ficheiros, e todos eles serão eliminados.', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: 'Mais ${n} episódio está armazenado no mesmo ficheiro e também será eliminado:', other: 'Mais ${n} episódios estão armazenados no mesmo ficheiro e também serão eliminados:', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'O Plezy não conseguiu verificar que ficheiros serão removidos, por isso pode eliminar mais do que o item acima. Cancele e tente novamente, ou elimine mesmo assim.',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'O seu servidor não forneceu detalhes do ficheiro para este item, por isso o Plezy não consegue verificar que ficheiros serão removidos. Pode eliminar mais do que o item acima.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Item multimédia eliminado com sucesso',
			'mediaMenu.mediaFailedToDelete' => 'Falha ao eliminar o item multimédia',
			'mediaMenu.rate' => 'Avaliar',
			'mediaMenu.playFromBeginning' => 'Reproduzir do início',
			'mediaMenu.playVersion' => 'Reproduzir versão...',
			'rateSheet.title' => 'Avaliar',
			'rateSheet.server' => 'Servidor',
			'rateSheet.favorite' => 'Favorito',
			'rateSheet.favorited' => 'Adicionado aos favoritos',
			'rateSheet.saved' => 'Guardado',
			'rateSheet.notAvailable' => 'Nenhuma correspondência encontrada',
			'rateSheet.noConnectedServices' => 'Ligue um serviço nas Definições para avaliar a partir daí.',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, filme',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, série de TV',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'visto',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} por cento visto',
			'accessibility.mediaCardUnwatched' => 'não visto',
			'accessibility.tapToPlay' => 'Toque para reproduzir',
			'accessibility.decrease' => 'Diminuir',
			'accessibility.increase' => 'Aumentar',
			'accessibility.decreaseValue' => ({required Object label}) => 'Diminuir ${label}',
			'accessibility.increaseValue' => ({required Object label}) => 'Aumentar ${label}',
			'accessibility.hue' => 'Matiz',
			'accessibility.saturation' => 'Saturação',
			'accessibility.brightness' => 'Brilho',
			'accessibility.hexColor' => 'Cor hexadecimal',
			'accessibility.expandText' => 'Expandir texto',
			'accessibility.collapseText' => 'Recolher texto',
			'accessibility.alphabetNavigation' => 'Navegação alfabética',
			'accessibility.alphabetScrollHint' => 'Deslize para cima ou para baixo para avançar por letra',
			'accessibility.rowColumnPosition' => ({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Linha ${row} de ${rowCount}, coluna ${column} de ${columnCount}',
			'accessibility.rowPosition' => ({required Object row, required Object rowCount}) => 'Linha ${row} de ${rowCount}',
			'accessibility.autoScrollPlay' => 'Iniciar deslocamento automático',
			'accessibility.autoScrollPause' => 'Pausar deslocamento automático',
			'accessibility.hueShort' => 'M',
			'accessibility.saturationShort' => 'S',
			'accessibility.valueShort' => 'V',
			'tooltips.shufflePlay' => 'Reprodução aleatória',
			'tooltips.playTrailer' => 'Reproduzir trailer',
			'tooltips.markAsWatched' => 'Marcar como visto',
			'tooltips.markAsUnwatched' => 'Marcar como não visto',
			'audioTracks.track' => ({required Object n}) => 'Faixa de áudio ${n}',
			'videoControls.audioLabel' => 'Áudio',
			'videoControls.subtitlesLabel' => 'Legendas',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.letterbox' => 'Letterbox',
			'videoControls.fillScreen' => 'Preencher ecrã',
			'videoControls.stretch' => 'Esticar',
			'videoControls.lockRotation' => 'Bloquear rotação',
			'videoControls.unlockRotation' => 'Desbloquear rotação',
			'videoControls.timerActive' => 'Temporizador ativo',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'A reprodução será pausada dentro de ${duration}',
			'videoControls.sleepTimerEndOfVideo' => 'Fim do vídeo atual',
			'videoControls.sleepTimerStopAtHeader' => 'Parar em',
			'videoControls.sleepTimerDurationHeader' => 'Temporizador',
			'videoControls.playbackWillPauseAtEnd' => 'A reprodução será pausada no final deste vídeo',
			'videoControls.stillWatching' => 'Ainda está a ver?',
			'videoControls.pausingIn' => ({required Object seconds}) => 'A pausar dentro de ${seconds}s',
			'videoControls.continueWatching' => 'Continuar',
			'videoControls.autoPlayNext' => 'Reproduzir o próximo automaticamente',
			'videoControls.playNext' => 'Reproduzir o próximo',
			'videoControls.playButton' => 'Reproduzir',
			'videoControls.pauseButton' => 'Pausa',
			'videoControls.playbackPaused' => 'Em pausa',
			'videoControls.playbackResumed' => 'A reproduzir',
			'videoControls.loadingVideo' => 'A carregar o vídeo',
			'videoControls.showPlaybackControls' => 'Mostrar controlos de reprodução',
			'videoControls.hidePlaybackControls' => 'Ocultar controlos de reprodução',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'Retroceder ${seconds} segundos',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'Avançar ${seconds} segundos',
			'videoControls.previousButton' => 'Episódio anterior',
			'videoControls.nextButton' => 'Próximo episódio',
			'videoControls.previousChapterButton' => 'Capítulo anterior',
			'videoControls.nextChapterButton' => 'Próximo capítulo',
			'videoControls.muteButton' => 'Silenciar',
			'videoControls.unmuteButton' => 'Ativar som',
			'videoControls.settingsButton' => 'Definições de reprodução',
			'videoControls.tracksButton' => 'Áudio e legendas',
			'videoControls.chaptersButton' => 'Capítulos',
			'videoControls.versionQualityButton' => 'Versão e qualidade',
			'videoControls.versionColumnHeader' => 'Versão',
			'videoControls.qualityColumnHeader' => 'Qualidade',
			'videoControls.qualityOriginal' => 'Original',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => 'Transcodificação indisponível — a reproduzir na qualidade original',
			'videoControls.subtitleUnavailableFallback' => 'Não foi possível carregar as legendas selecionadas — a reprodução continuará sem legendas',
			'videoControls.pipButton' => 'Modo Picture-in-Picture',
			'videoControls.aspectRatioButton' => 'Proporção',
			'videoControls.ambientLighting' => 'Iluminação ambiente',
			'videoControls.fullscreenButton' => 'Entrar em ecrã inteiro',
			'videoControls.exitFullscreenButton' => 'Sair do ecrã inteiro',
			'videoControls.alwaysOnTopButton' => 'Sempre no topo',
			'videoControls.rotationLockButton' => 'Bloquear rotação',
			'videoControls.lockScreen' => 'Bloquear ecrã',
			'videoControls.screenLockButton' => 'Bloquear ecrã',
			'videoControls.tapToUnlock' => 'Toque para desbloquear',
			'videoControls.tapAgainToUnlock' => 'Toque novamente para desbloquear',
			'videoControls.timelineSlider' => 'Linha do tempo do vídeo',
			'videoControls.volumeSlider' => 'Nível de volume',
			'videoControls.endsAt' => ({required Object time}) => 'Termina às ${time}',
			'videoControls.pipActive' => 'A reproduzir em Picture-in-Picture',
			'videoControls.pipFailed' => 'Falha ao iniciar picture-in-picture',
			'videoControls.screenshotSaved' => 'Captura de ecrã guardada',
			'videoControls.screenshotFailed' => 'Não foi possível fazer a captura de ecrã',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Zoom ${percent}%',
			'videoControls.volumePercent' => ({required Object percent}) => 'Volume ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'Requer Android 8.0 ou superior',
			'videoControls.pipErrors.iosVersion' => 'Requer iOS 15.0 ou superior',
			'videoControls.pipErrors.permissionDisabled' => 'O picture-in-picture está desativado. Ative-o nas definições do sistema.',
			'videoControls.pipErrors.notSupported' => 'O dispositivo não suporta o modo picture-in-picture',
			'videoControls.pipErrors.voSwitchFailed' => 'Falha ao mudar a saída de vídeo para picture-in-picture',
			'videoControls.pipErrors.failed' => 'Falha ao iniciar picture-in-picture',
			'videoControls.pipErrors.prepareFailed' => 'Não foi possível preparar o picture-in-picture',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Ocorreu um erro: ${error}',
			'videoControls.chapters' => 'Capítulos',
			'videoControls.noChaptersAvailable' => 'Nenhum capítulo disponível',
			'videoControls.queue' => 'Fila',
			'videoControls.noQueueItems' => 'Nenhum item na fila',
			'videoControls.noAudioDevicesAvailable' => 'Nenhum dispositivo de áudio disponível',
			'videoControls.searchSubtitles' => 'Pesquisar legendas',
			'videoControls.language' => 'Idioma',
			'videoControls.noSubtitlesFound' => 'Nenhuma legenda encontrada',
			'videoControls.subtitleDownloaded' => 'Legenda transferida',
			'videoControls.subtitleDownloadedNotApplied' => 'A legenda foi transferida, mas não foi possível selecioná-la',
			'videoControls.subtitleDownloadFailed' => 'Falha ao transferir a legenda',
			'videoControls.subtitleDownloadTimedOut' => 'A legenda não apareceu a tempo. A transferência pode ter falhado',
			'videoControls.searchLanguages' => 'Pesquisar idiomas...',
			'videoControls.skipIntro' => 'Saltar introdução',
			'videoControls.skipCredits' => 'Saltar créditos',
			'videoControls.nextEpisode' => 'Próximo episódio',
			'videoControls.subtitleTrack' => ({required Object n}) => 'Faixa ${n}',
			'videoControls.subtitleFile' => ({required Object name}) => 'Legenda ${name}',
			'videoControls.forcedTrack' => ({required Object label}) => '${label} (Forçada)',
			'videoControls.osdSubtitlesOff' => 'Legendas: desativadas',
			'videoControls.osdSubtitles' => ({required Object track}) => 'Legendas: ${track}',
			'videoControls.osdAudio' => ({required Object track}) => 'Áudio: ${track}',
			'messages.markedAsWatched' => 'Marcado como visto',
			'messages.markedAsUnwatched' => 'Marcado como não visto',
			'messages.markedAsWatchedOffline' => 'Marcado como visto (será sincronizado quando online)',
			'messages.markedAsUnwatchedOffline' => 'Marcado como não visto (será sincronizado quando online)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Removido automaticamente: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: 'Removida automaticamente ${n} transferência vista', other: 'Removidas automaticamente ${n} transferências vistas', ), 
			'messages.removedFromContinueWatching' => 'Removido de Continuar a ver',
			'messages.errorLoading' => ({required Object error}) => 'Erro: ${error}',
			'messages.searchPartialResults' => 'Não foi possível pesquisar alguns servidores multimédia. A mostrar os resultados disponíveis.',
			'messages.streamInterrupted' => 'A transmissão foi interrompida. Prima reproduzir ou avance para tentar novamente.',
			'messages.liveStreamInterrupted' => 'A transmissão em direto foi interrompida. Prima reproduzir para tentar novamente.',
			'messages.fileInfoNotAvailable' => 'Informações do ficheiro não disponíveis',
			'messages.playbackAuthenticationRequired' => 'Inicie sessão novamente no servidor multimédia para reproduzir este item.',
			'messages.playbackServerUnavailable' => 'O servidor multimédia está indisponível. Tente novamente mais tarde.',
			'messages.playbackDataInvalid' => 'O servidor devolveu informações de reprodução inválidas.',
			'messages.playbackCancelled' => 'A reprodução foi cancelada.',
			'messages.playbackFailed' => 'Não foi possível iniciar a reprodução.',
			'messages.playbackFailedDetail' => ({required Object error}) => 'Não foi possível iniciar a reprodução: ${error}',
			'messages.audioOutputFailed' => 'A saída de áudio deixou de responder. Verifique a ligação de áudio da TV ou do recetor; se outras aplicações também estiverem sem som, reinicie o dispositivo.',
			'messages.mediaUnavailable' => 'Este conteúdo já não está disponível.',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Erro ao carregar as informações do ficheiro: ${error}',
			'messages.errorLoadingSeries' => 'Erro ao carregar a série',
			'messages.musicNotSupported' => 'A reprodução de música ainda não é suportada',
			'messages.noDescriptionAvailable' => 'Nenhuma descrição disponível',
			'messages.noProfilesAvailable' => 'Nenhum perfil disponível',
			'messages.contactAdminForProfiles' => 'Contacte o administrador do servidor para adicionar perfis',
			'messages.unableToDetermineLibrarySection' => 'Não foi possível determinar a secção da biblioteca deste item',
			'messages.logsCleared' => 'Registos limpos',
			'messages.logsCopied' => 'Registos copiados para a área de transferência',
			'messages.noLogsAvailable' => 'Nenhum registo disponível',
			'messages.libraryScanning' => ({required Object title}) => 'A examinar "${title}"...',
			'messages.libraryScanStarted' => ({required Object title}) => 'Exame da biblioteca iniciado para "${title}"',
			'messages.libraryScanFailed' => ({required Object error}) => 'Falha ao examinar a biblioteca: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => 'A atualizar metadados de "${title}"...',
			'messages.metadataRefreshStarted' => ({required Object title}) => 'Atualização de metadados iniciada para "${title}"',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'Falha ao atualizar os metadados: ${error}',
			'messages.logoutConfirm' => 'Tem a certeza de que pretende sair?',
			'messages.noSeasonsFound' => 'Nenhuma temporada encontrada',
			'messages.seasonsLoadFailed' => 'Não foi possível carregar as temporadas',
			'messages.noEpisodesFound' => 'Nenhum episódio encontrado na primeira temporada',
			'messages.noEpisodesFoundGeneral' => 'Nenhum episódio encontrado',
			'messages.episodesLoadFailed' => 'Não foi possível carregar os episódios',
			'messages.noResultsFound' => 'Nenhum resultado encontrado',
			'messages.sleepTimerSet' => ({required Object label}) => 'Temporizador de suspensão definido como ${label}',
			'messages.noItemsAvailable' => 'Nenhum item disponível',
			'messages.failedToCreatePlayQueueNoItems' => 'Falha ao criar a fila de reprodução — nenhum item',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Falha ao ${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => 'A alternar para um reprodutor compatível...',
			'messages.serverLimitTitle' => 'Falha na reprodução',
			'messages.serverLimitBody' => 'Erro do servidor (HTTP 500). Um limite de largura de banda ou de transcodificação terá provavelmente rejeitado esta sessão. Peça ao proprietário do servidor para o ajustar.',
			'messages.serverLimitTranscode' => 'Experimentar transcodificar',
			'messages.mediaUnreadableTitle' => 'Ficheiro indisponível',
			'messages.mediaUnreadableBody' => 'O servidor encontrou este item, mas não conseguiu ler o ficheiro (HTTP 404). O ficheiro foi provavelmente movido, eliminado ou o armazenamento está offline. Peça ao responsável pelo servidor para verificar o ficheiro e voltar a examinar a biblioteca.',
			'messages.serverBusyTitle' => 'Transmissão indisponível',
			'messages.serverBusyBody' => 'O servidor continuou a recusar-se a transmitir este ficheiro (HTTP 503). Pode estar a reiniciar ou ocupado, ou o armazenamento do ficheiro pode estar offline. Tente novamente daqui a pouco — se continuar a acontecer, peça ao proprietário do servidor para verificar o servidor e o armazenamento do ficheiro.',
			'messages.playbackNotAllowedTitle' => 'Reprodução não permitida',
			'messages.playbackNotAllowedBody' => 'O servidor recusou-se a transmitir este item (HTTP 403). A sua conta pode não ter permissão para o reproduzir, ou o servidor pode permitir a reprodução apenas na própria rede local.',
			'messages.logsUploaded' => 'Registos enviados',
			'messages.logsUploadFailed' => 'Falha ao enviar os registos',
			'messages.logId' => 'ID do registo',
			'messages.burnedSubtitlesUseMenu' => 'As legendas estão incorporadas nesta transmissão. Altere-as no menu de legendas.',
			'messages.noVideoUrl' => 'Nenhum URL de vídeo disponível',
			'messages.playbackNoMediaSources' => 'O servidor não devolveu nenhuma origem multimédia reproduzível',
			'messages.playbackDataNotPrepared' => 'A reprodução foi iniciada antes de os dados estarem prontos',
			'messages.streamSelectionUnavailable' => 'A seleção de fluxos não está disponível para esta origem',
			'messages.streamSelectionFailed' => 'Não foi possível aplicar os fluxos selecionados',
			'messages.trackSelectionNotRemembered' => 'Esta escolha de faixa aplica-se apenas à reprodução atual.',
			'messages.serverUnavailableForProfile' => 'Nenhum servidor está disponível para o perfil ativo',
			'subtitlingStyling.text' => 'Texto',
			'subtitlingStyling.border' => 'Contorno',
			'subtitlingStyling.background' => 'Fundo',
			'subtitlingStyling.fontSize' => 'Tamanho da letra',
			'subtitlingStyling.textColor' => 'Cor do texto',
			'subtitlingStyling.borderSize' => 'Tamanho do contorno',
			'subtitlingStyling.borderColor' => 'Cor do contorno',
			'subtitlingStyling.backgroundOpacity' => 'Opacidade do fundo',
			'subtitlingStyling.backgroundColor' => 'Cor do fundo',
			'subtitlingStyling.position' => 'Posição',
			'subtitlingStyling.assOverride' => 'Substituição ASS',
			'subtitlingStyling.overrideScale' => 'Dimensionar',
			'subtitlingStyling.overrideForce' => 'Forçar',
			'subtitlingStyling.overrideStrip' => 'Remover estilo',
			'subtitlingStyling.positionTop' => 'Superior',
			'subtitlingStyling.positionBottom' => 'Inferior',
			'subtitlingStyling.useMargins' => 'Usar margens',
			'subtitlingStyling.useMarginsDescription' => 'Permitir legendas de texto no espaço fora do vídeo. Legendas estilizadas podem manter a sua posição original.',
			'subtitlingStyling.anchorToScreen' => 'Ancorar ao ecrã',
			'subtitlingStyling.anchorToScreenDescription' => 'Mostrar as legendas de texto nas barras pretas por baixo de vídeos em formato panorâmico',
			'subtitlingStyling.bold' => 'Negrito',
			'subtitlingStyling.italic' => 'Itálico',
			'subtitlingStyling.renderResolution' => 'Resolução de renderização',
			'subtitlingStyling.renderResolutionScreen' => 'Resolução do ecrã',
			'subtitlingStyling.renderResolutionVideo' => 'Resolução do vídeo',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => 'Definições avançadas do reprodutor de vídeo',
			'mpvConfig.presets' => 'Predefinições',
			'mpvConfig.noPresets' => 'Nenhuma predefinição guardada',
			'mpvConfig.saveAsPreset' => 'Guardar como predefinição...',
			'mpvConfig.presetName' => 'Nome da predefinição',
			'mpvConfig.presetNameHint' => 'Introduza um nome para esta predefinição',
			'mpvConfig.loadPreset' => 'Carregar',
			'mpvConfig.deletePreset' => 'Eliminar',
			'mpvConfig.presetSaved' => 'Predefinição guardada',
			'mpvConfig.presetLoaded' => 'Predefinição carregada',
			'mpvConfig.presetDeleted' => 'Predefinição eliminada',
			'mpvConfig.confirmDeletePreset' => 'Tem a certeza de que pretende eliminar esta predefinição?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan\nhwdec=auto\n# comment',
			'mpvConfig.lineHint' => 'option=value',
			'mpvConfig.addLine' => 'Adicionar linha',
			'mpvConfig.removeLine' => 'Remover linha',
			'mpvConfig.embeddedVoHint' => 'vo, gpu-context e gpu-api são ignorados no Linux: o vídeo incorporado é sempre renderizado via vo=libmpv no plano de vídeo, e gpu-next (necessário para shaders de computação como ArtCNN) não pode ser executado incorporado.',
			'dialog.confirmAction' => 'Confirmar ação',
			'profiles.addPlezyProfile' => 'Adicionar perfil Plezy',
			'profiles.switchingProfile' => 'A mudar de perfil…',
			'profiles.deleteThisProfileTitle' => 'Eliminar este perfil?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => 'Remover ${displayName}. As ligações não serão afetadas.',
			'profiles.active' => 'Ativo',
			'profiles.manage' => 'Gerir',
			'profiles.delete' => 'Eliminar',
			'profiles.signOut' => 'Terminar sessão',
			'profiles.signOutPlexTitle' => 'Terminar sessão no Plex?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => 'Remover ${displayName} e todos os utilizadores do Plex Home? Pode voltar a iniciar sessão quando quiser.',
			'profiles.signOutPlexDeleteDownloads' => 'Eliminar também as transferências',
			'profiles.signOutPlexDeleteDownloadsDescription' => 'Caso contrário, ficam neste dispositivo e voltam quando iniciar novamente sessão nesta conta.',
			'profiles.signedOutPlex' => 'Sessão terminada no Plex.',
			'profiles.signOutFailed' => 'Falha ao terminar sessão.',
			'profiles.sectionTitle' => 'Perfis',
			'profiles.summarySingle' => 'Adicione perfis para combinar utilizadores geridos e identidades locais',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} perfis · ativo: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} perfis',
			'profiles.removeConnectionTitle' => 'Remover ligação?',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => 'Remover o acesso de ${displayName} a ${connectionLabel}. Os outros perfis mantêm o acesso.',
			'profiles.deleteProfileTitle' => 'Eliminar perfil?',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => 'Remover ${displayName} e as suas ligações. Os servidores continuam disponíveis.',
			'profiles.profileNameLabel' => 'Nome do perfil',
			'profiles.pinProtectionLabel' => 'Proteção por PIN',
			'profiles.pinManagedByPlex' => 'PIN gerido pelo Plex. Edite em plex.tv.',
			'profiles.noPinSetEditOnPlex' => 'Nenhum PIN definido. Para exigir um, edite o utilizador do Plex Home em plex.tv.',
			'profiles.setPin' => 'Definir PIN',
			'profiles.setPinTitle' => 'Definir PIN',
			'profiles.confirmPinTitle' => 'Confirmar PIN',
			'profiles.pinSet' => 'PIN definido',
			'profiles.changePin' => 'Alterar',
			'profiles.removePin' => 'Remover',
			'profiles.connectionsLabel' => 'Ligações',
			'profiles.add' => 'Adicionar',
			'profiles.deleteProfileButton' => 'Eliminar perfil',
			'profiles.noConnectionsHint' => 'Sem ligações — adicione uma para usar este perfil.',
			'profiles.noConnections' => 'Sem ligações',
			'profiles.plexHomeAccount' => 'Conta Plex Home',
			'profiles.plexAccountChip' => ({required Object account}) => 'Conta Plex: ${account}',
			'profiles.plexAccountUserChip' => ({required Object user, required Object account}) => '${user} via ${account}',
			'profiles.connectionDefault' => 'Predefinida',
			'profiles.connectionAs' => ({required Object displayName}) => 'como ${displayName}',
			'profiles.makeDefault' => 'Definir como predefinida',
			'profiles.removeConnection' => 'Remover',
			'profiles.profileRenamed' => 'Perfil renomeado.',
			'profiles.borrowAddTo' => ({required Object displayName}) => 'Adicionar a ${displayName}',
			'profiles.borrowExplain' => 'Use a ligação de outro perfil. Os perfis protegidos por PIN exigem o PIN.',
			'profiles.borrowEmpty' => 'Nenhuma ligação disponível ainda.',
			'profiles.borrowEmptySubtitle' => 'Primeiro, ligue o Plex, o Jellyfin ou o Emby a outro perfil.',
			'profiles.borrowLoadFailed' => 'Não foi possível carregar as ligações disponíveis. Tente novamente.',
			'profiles.borrowFromProfile' => ({required Object displayName}) => 'De ${displayName}',
			'profiles.borrowConnectionBorrowed' => 'Ligação adicionada ao perfil.',
			'profiles.borrowFailed' => 'Não foi possível adicionar a ligação.',
			'profiles.incorrectPin' => 'PIN incorreto.',
			'profiles.incorrectPinTryAgain' => 'PIN incorreto. Tente novamente.',
			'profiles.sourceProfileMissingParentAccount' => 'O perfil de origem não tem a conta principal.',
			'profiles.failedToLoadHomeUsers' => 'Não foi possível carregar os utilizadores do Plex Home. Verifique a sua ligação e tente novamente.',
			'profiles.failedToVerifyPin' => 'Não foi possível verificar o PIN.',
			'profiles.newProfile' => 'Novo perfil',
			'profiles.profileNameHint' => 'Ex.: Visitas, Crianças, Sala',
			'profiles.pinProtectionOptional' => 'Proteção por PIN (opcional)',
			'profiles.pinExplain' => 'PIN de 4 dígitos necessário para mudar de perfil.',
			'profiles.continueButton' => 'Continuar',
			_ => null,
		} ?? switch (path) {
			'profiles.pinsDontMatch' => 'Os PINs não correspondem',
			'profiles.tokenIdentityMismatch' => 'O token do perfil do Plex foi associado a um servidor inesperado',
			'connections.sectionTitle' => 'Ligações',
			'connections.addConnection' => 'Adicionar ligação',
			'connections.addConnectionSubtitleNoProfile' => 'Inicie sessão no Plex ou ligue um servidor Jellyfin ou Emby',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'Adicionar a ${displayName}: Plex, Jellyfin, Emby ou outra ligação de perfil',
			'connections.sessionExpiredOne' => ({required Object name}) => 'Sessão de ${name} expirada',
			'connections.sessionExpiredMany' => ({required Object count}) => 'Sessões expiradas em ${count} servidores',
			'connections.accessDeniedOne' => ({required Object name}) => '${name} negou o acesso a esta conta',
			'connections.accessDeniedMany' => ({required Object count}) => '${count} servidores negaram o acesso a esta conta',
			'connections.signInAgain' => 'Iniciar sessão novamente',
			'connections.editMediaBrowserTitle' => ({required Object product}) => 'Editar ligação do ${product}',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => 'Adicione ou remova URLs para ${serverName}. O Plezy usará o URL acessível com menor latência.',
			'accountPreferences.sectionTitle' => 'Preferências da conta',
			'accountPreferences.hubSubtitleSingle' => ({required Object account}) => 'Opções de áudio, legendas e biblioteca guardadas em ${account}',
			'accountPreferences.hubSubtitleMultiple' => ({required Object count}) => 'Opções de áudio, legendas e biblioteca guardadas em ${count} contas',
			'accountPreferences.pickAccount' => 'Cada conta guarda as suas próprias preferências. Escolha a que pretende editar.',
			'accountPreferences.storedOnAccount' => 'Estas opções são guardadas na própria conta, por isso todas as aplicações ligadas a ela as utilizam — incluindo o Plezy nos seus outros dispositivos.',
			'accountPreferences.noAccounts' => 'Nenhuma conta para configurar',
			'accountPreferences.noAccountsHint' => 'Inicie sessão no Plex ou ligue um servidor Jellyfin ou Emby, e as preferências guardadas nessa conta aparecerão aqui.',
			'accountPreferences.unavailable' => 'Não foi possível aceder a esta conta',
			'accountPreferences.loadFailed' => 'Não foi possível carregar estas preferências',
			'accountPreferences.noPreference' => 'Sem preferência',
			'accountPreferences.notSet' => 'Não definido',
			'accountPreferences.groups.audioAndSubtitles' => 'Áudio e legendas',
			'accountPreferences.groups.libraryDisplay' => 'Biblioteca',
			'accountPreferences.groups.personalMedia' => 'Multimédia pessoal',
			'accountPreferences.preferredAudioLanguage' => 'Idioma de áudio preferido',
			'accountPreferences.autoSelectAudio' => 'Escolher áudio pelo idioma',
			'accountPreferences.autoSelectAudioDescription' => 'Desativado mantém a faixa de áudio que o ficheiro marca como predefinida.',
			'accountPreferences.preferredSubtitleLanguage' => 'Idioma de legenda preferido',
			'accountPreferences.subtitleMode' => 'Ativar legendas',
			'accountPreferences.subtitleModes.none' => 'Seleção manual',
			'accountPreferences.subtitleModes.noneDescription' => 'Nunca ativar legendas automaticamente.',
			'accountPreferences.subtitleModes.defaultMode' => 'Seguir as marcações da faixa',
			'accountPreferences.subtitleModes.defaultModeDescription' => 'Usar as marcações de predefinida e forçada guardadas em cada faixa de legendas.',
			'accountPreferences.subtitleModes.always' => 'Sempre ativado',
			'accountPreferences.subtitleModes.alwaysDescription' => 'Ativar uma faixa de legendas no idioma preferido sempre que houver uma.',
			'accountPreferences.subtitleModes.onlyForced' => 'Apenas legendas forçadas',
			'accountPreferences.subtitleModes.onlyForcedDescription' => 'Carregar apenas as faixas marcadas como forçadas.',
			'accountPreferences.subtitleModes.smart' => 'Mostrar com áudio estrangeiro',
			'accountPreferences.subtitleModes.smartDescription' => 'Ativar legendas apenas quando o áudio estiver noutro idioma.',
			'accountPreferences.subtitleAccessibility' => 'Legendas SDH',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdh' => 'Preferir legendas não SDH',
			'accountPreferences.subtitleAccessibilityOptions.preferSdh' => 'Preferir legendas SDH',
			'accountPreferences.subtitleAccessibilityOptions.onlySdh' => 'Apenas legendas SDH',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdh' => 'Apenas legendas não SDH',
			'accountPreferences.forcedSubtitles' => 'Legendas forçadas',
			'accountPreferences.forcedSubtitleOptions.preferNonForced' => 'Preferir legendas não forçadas',
			'accountPreferences.forcedSubtitleOptions.preferForced' => 'Preferir legendas forçadas',
			'accountPreferences.forcedSubtitleOptions.onlyForced' => 'Apenas legendas forçadas',
			'accountPreferences.forcedSubtitleOptions.onlyNonForced' => 'Apenas legendas não forçadas',
			'accountPreferences.displayMissingEpisodes' => 'Mostrar episódios em falta',
			'accountPreferences.displayMissingEpisodesDescription' => 'Listar episódios que o servidor conhece, mas para os quais não há ficheiro.',
			'accountPreferences.hidePlayedInLatest' => 'Ocultar itens vistos em Recentes',
			'accountPreferences.hidePlayedInLatestDescription' => 'Manter fora das linhas Recentes do servidor os itens que já viu.',
			'accountPreferences.displayCollectionsView' => 'Mostrar a vista de Coleções',
			'accountPreferences.displayCollectionsViewDescription' => 'Oferecer a vista de Coleções do servidor juntamente com as suas bibliotecas.',
			'accountPreferences.rewatchingInNextUp' => 'Manter em A seguir as séries que está a rever',
			'accountPreferences.rewatchingInNextUpDescription' => 'Ao terminar uma série, comece a vê-la de novo e A seguir acompanha a nova visualização em vez de remover a série.',
			'accountPreferences.watchedIndicator' => 'Indicadores de visto',
			'accountPreferences.watchedIndicatorOptions.none' => 'Nunca',
			'accountPreferences.watchedIndicatorOptions.moviesAndShows' => 'Filmes e séries de TV',
			'accountPreferences.watchedIndicatorOptions.movies' => 'Apenas filmes',
			'accountPreferences.watchedIndicatorOptions.shows' => 'Apenas séries de TV',
			'accountPreferences.mediaReviewsVisibility' => 'Avaliações e críticas',
			'accountPreferences.mediaReviewsOptions.usersAndCritics' => 'Utilizadores e críticos',
			'accountPreferences.mediaReviewsOptions.usersOnly' => 'Apenas utilizadores',
			'accountPreferences.mediaReviewsOptions.criticsOnly' => 'Apenas críticos',
			'accountPreferences.mediaReviewsOptions.nobody' => 'Oculto',
			'discover.title' => 'Descobrir',
			'discover.noContentAvailable' => 'Nenhum conteúdo disponível',
			'discover.addMediaToLibraries' => 'Adicione conteúdos multimédia às suas bibliotecas',
			'discover.continueWatching' => 'Continuar a ver',
			'discover.continueWatchingIn' => ({required Object library}) => 'Continuar a ver em ${library}',
			'discover.selectVersion' => 'Selecionar versão',
			'discover.nextUp' => 'A seguir',
			'discover.nextUpIn' => ({required Object library}) => 'A seguir em ${library}',
			'discover.recentlyAdded' => 'Adicionados recentemente',
			'discover.recentlyAddedIn' => ({required Object library}) => 'Adicionados recentemente em ${library}',
			'discover.latestAlbumsIn' => ({required Object library}) => 'Álbuns mais recentes em ${library}',
			'discover.recentlyPlayedIn' => ({required Object library}) => 'Reproduzidos recentemente em ${library}',
			'discover.mostPlayedIn' => ({required Object library}) => 'Mais reproduzidos em ${library}',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.overview' => 'Sinopse',
			'discover.cast' => 'Elenco',
			'discover.extras' => 'Trailers e extras',
			'discover.studio' => 'Estúdio',
			'discover.rating' => 'Avaliação',
			'discover.director' => 'Realizador',
			'discover.directors' => 'Realizadores',
			'discover.movie' => 'Filme',
			'discover.tvShow' => 'Série de TV',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} min restantes',
			'discover.moreLikeThis' => 'Títulos semelhantes',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '${n} título', other: '${n} títulos', ), 
			'discover.person.born' => 'Nascimento',
			'discover.person.died' => 'Falecimento',
			'discover.person.birthplace' => 'Local de nascimento',
			'discover.person.dateWithAge' => ({required Object date, required Object age}) => '${date} (${age} anos)',
			'discover.person.dateWithAgeAtDeath' => ({required Object date, required Object age}) => '${date} (aos ${age} anos)',
			'errors.searchFailed' => ({required Object error}) => 'Falha na pesquisa: ${error}',
			'errors.searchUnavailable' => 'A pesquisa não conseguiu chegar a nenhum servidor multimédia.',
			'errors.connectionTimeout' => ({required Object context}) => 'Tempo de ligação esgotado ao carregar ${context}',
			'errors.connectionFailed' => 'Não foi possível ligar ao servidor multimédia',
			'errors.unableToLoad' => ({required Object context}) => 'Não foi possível carregar ${context}. Tente novamente.',
			'errors.noClientAvailable' => 'Nenhum cliente disponível',
			'errors.pleaseEnterToken' => 'Introduza um token',
			'errors.invalidToken' => 'Token inválido',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Falha ao verificar o token: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Falha ao mudar para ${displayName}',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => 'Falha ao eliminar ${displayName}',
			'errors.failedToRate' => 'Não foi possível atualizar a classificação',
			'errors.reasonTimedOut' => 'o tempo de ligação esgotou-se',
			'errors.reasonUnreachable' => 'não foi possível contactar o servidor',
			'errors.reasonRefused' => 'o servidor recusou o pedido',
			'errors.reasonNotFound' => 'o item já não está no servidor',
			'errors.reasonServerError' => 'o servidor indicou um erro',
			'errors.reasonCancelled' => 'o pedido foi cancelado',
			'errors.reasonUnexpected' => 'ocorreu um erro inesperado',
			'libraries.title' => 'Bibliotecas',
			'libraries.fallbackTitle' => 'Biblioteca',
			'libraries.scanLibraryFiles' => 'Examinar ficheiros da biblioteca',
			'libraries.scanLibrary' => 'Examinar biblioteca',
			'libraries.analyze' => 'Analisar',
			'libraries.analyzeLibrary' => 'Analisar biblioteca',
			'libraries.refreshMetadata' => 'Atualizar metadados',
			'libraries.emptyTrash' => 'Esvaziar lixo',
			'libraries.emptyingTrash' => ({required Object title}) => 'A esvaziar o lixo de "${title}"...',
			'libraries.trashEmptied' => ({required Object title}) => 'Lixo de "${title}" esvaziado',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'Falha ao esvaziar o lixo: ${error}',
			'libraries.analyzing' => ({required Object title}) => 'A analisar "${title}"...',
			'libraries.analysisStarted' => ({required Object title}) => 'Análise iniciada para "${title}"',
			'libraries.failedToAnalyze' => ({required Object error}) => 'Falha ao analisar a biblioteca: ${error}',
			'libraries.noLibrariesFound' => 'Nenhuma biblioteca encontrada',
			'libraries.allLibrariesHidden' => 'Todas as bibliotecas estão ocultas',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'Bibliotecas ocultas (${count})',
			'libraries.thisLibraryIsEmpty' => 'Esta biblioteca está vazia',
			'libraries.noItemsMatchFilters' => 'Nenhum item corresponde aos filtros ativos',
			'libraries.resetFilters' => 'Repor filtros',
			'libraries.all' => 'Todos',
			'libraries.clearAll' => 'Limpar tudo',
			'libraries.scanLibraryConfirm' => ({required Object title}) => 'Tem a certeza de que pretende examinar "${title}"?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => 'Tem a certeza de que pretende analisar "${title}"?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => 'Tem a certeza de que pretende atualizar os metadados de "${title}"?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => 'Tem a certeza de que pretende esvaziar o lixo de "${title}"?',
			'libraries.manageLibraries' => 'Gerir bibliotecas',
			'libraries.sort' => 'Ordenar',
			'libraries.sortBy' => 'Ordenar por',
			'libraries.filters' => 'Filtros',
			'libraries.confirmActionMessage' => 'Tem a certeza de que pretende realizar esta ação?',
			'libraries.showLibrary' => 'Mostrar biblioteca',
			'libraries.hideLibrary' => 'Ocultar biblioteca',
			'libraries.libraryOptions' => 'Opções da biblioteca',
			'libraries.shuffleLibrary' => 'Reprodução aleatória da biblioteca',
			'libraries.content' => 'conteúdo da biblioteca',
			'libraries.selectLibrary' => 'Selecionar biblioteca',
			'libraries.filtersWithCount' => ({required Object count}) => 'Filtros (${count})',
			'libraries.noRecommendations' => 'Nenhuma recomendação disponível',
			'libraries.noCollections' => 'Nenhuma coleção nesta biblioteca',
			'libraries.noGenres' => 'Nenhum género nesta biblioteca',
			'libraries.noFoldersFound' => 'Nenhuma pasta encontrada',
			'libraries.folders' => 'pastas',
			'libraries.tabs.recommended' => 'Recomendados',
			'libraries.tabs.browse' => 'Navegar',
			'libraries.tabs.collections' => 'Coleções',
			'libraries.tabs.genres' => 'Géneros',
			'libraries.tabs.playlists' => 'Playlists',
			'libraries.groupings.title' => 'Agrupamento',
			'libraries.groupings.all' => 'Todos',
			'libraries.groupings.movies' => 'Filmes',
			'libraries.groupings.shows' => 'Séries de TV',
			'libraries.groupings.seasons' => 'Temporadas',
			'libraries.groupings.episodes' => 'Episódios',
			'libraries.groupings.artists' => 'Artistas',
			'libraries.groupings.albums' => 'Álbuns',
			'libraries.groupings.tracks' => 'Faixas',
			'libraries.groupings.folders' => 'Pastas',
			'libraries.filterCategories.genre' => 'Género',
			'libraries.filterCategories.year' => 'Ano',
			'libraries.filterCategories.contentRating' => 'Classificação etária',
			'libraries.filterCategories.tag' => 'Tag',
			'libraries.filterCategories.unwatched' => 'Não vistos',
			'libraries.filterCategories.unplayed' => 'Não reproduzidos',
			'libraries.filterCategories.favorites' => 'Favoritos',
			'libraries.filterCategories.filePath' => 'Caminho do ficheiro',
			'libraries.sortLabels.title' => 'Título',
			'libraries.sortLabels.dateAdded' => 'Data de adição',
			'libraries.sortLabels.releaseDate' => 'Data de lançamento',
			'libraries.sortLabels.rating' => 'Avaliação',
			'libraries.sortLabels.communityRating' => 'Avaliação da comunidade',
			'libraries.sortLabels.criticRating' => 'Avaliação da crítica',
			'libraries.sortLabels.userRating' => 'Avaliação do utilizador',
			'libraries.sortLabels.datePlayed' => 'Data de reprodução',
			'libraries.sortLabels.playCount' => 'Reproduções',
			'libraries.sortLabels.productionYear' => 'Ano de produção',
			'libraries.sortLabels.runtime' => 'Duração',
			'libraries.sortLabels.officialRating' => 'Classificação oficial',
			'libraries.sortLabels.premiereDate' => 'Data de estreia',
			'libraries.sortLabels.startDate' => 'Data de início',
			'libraries.sortLabels.airTime' => 'Horário de exibição',
			'libraries.sortLabels.studio' => 'Estúdio',
			'libraries.sortLabels.random' => 'Aleatório',
			'libraries.sortLabels.dateShared' => 'Data de partilha',
			'libraries.sortLabels.latestEpisodeAirDate' => 'Última data de exibição do episódio',
			'libraries.sortLabels.lastEpisodeDateAdded' => 'Data de adição do último episódio',
			'libraries.sortLabels.dateDownloaded' => 'Data de transferência',
			'libraries.sortLabels.size' => 'Tamanho',
			'libraries.sortLabels.library' => 'Biblioteca',
			'libraries.advancedFilters.include' => 'Incluir',
			'libraries.advancedFilters.exclude' => 'Excluir',
			'libraries.advancedFilters.any' => 'Qualquer',
			'libraries.advancedFilters.yes' => 'Sim',
			'libraries.advancedFilters.no' => 'Não',
			'libraries.advancedFilters.not' => ({required Object value}) => 'Exceto ${value}',
			'libraries.advancedFilters.valueCount' => ({required Object count}) => '${count} selecionados',
			'libraries.advancedFilters.valueCountExcluded' => ({required Object count}) => '${count} excluídos',
			'libraries.advancedFilters.searchValues' => 'Pesquisar valores',
			'libraries.advancedFilters.noValues' => 'Nenhum valor',
			'libraries.advancedFilters.matchContains' => 'Contém',
			'libraries.advancedFilters.matchNotContains' => 'Não contém',
			'libraries.advancedFilters.matchIs' => 'É',
			'libraries.advancedFilters.matchIsNot' => 'Não é',
			'libraries.advancedFilters.matchBeginsWith' => 'Começa com',
			'libraries.advancedFilters.matchEndsWith' => 'Termina com',
			'libraries.advancedFilters.textHint' => 'Escreva para filtrar',
			'libraries.advancedFilters.from' => 'De',
			'libraries.advancedFilters.to' => 'Até',
			'libraries.advancedFilters.range' => ({required Object from, required Object to}) => '${from} a ${to}',
			'libraries.advancedFilters.atLeast' => ({required Object value}) => '${value} ou mais',
			'libraries.advancedFilters.atMost' => ({required Object value}) => 'Até ${value}',
			'libraries.advancedFilters.dateLastDays' => ({required Object count}) => 'Últimos ${count} dias',
			'libraries.advancedFilters.dateLastYear' => 'Último ano',
			'libraries.advancedFilters.dateOlderThanDays' => ({required Object count}) => 'Há mais de ${count} dias',
			'libraries.advancedFilters.dateOlderThanYear' => 'Há mais de um ano',
			'about.title' => 'Sobre',
			'about.openSourceLicenses' => 'Licenças de código aberto',
			'about.versionLabel' => ({required Object version}) => 'Versão ${version}',
			'about.appDescription' => 'Um belo cliente de Plex, Jellyfin e Emby feito com Flutter',
			'about.viewLicensesDescription' => 'Ver as licenças de bibliotecas de terceiros',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'Nenhum servidor encontrado para ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Falha ao carregar servidores: ${error}',
			'serverSelection.noValidServers' => 'Nenhum servidor utilizável foi encontrado nesta conta',
			'hubDetail.title' => 'Título',
			'hubDetail.releaseYear' => 'Ano de lançamento',
			'hubDetail.dateAdded' => 'Data de adição',
			'hubDetail.rating' => 'Avaliação',
			'hubDetail.noItemsFound' => 'Nenhum item encontrado',
			'logs.clearLogs' => 'Limpar registos',
			'logs.copyLogs' => 'Copiar registos',
			'logs.uploadLogs' => 'Enviar registos',
			'startup.failedTitle' => 'O Plezy não conseguiu iniciar',
			'startup.failedBody' => 'Algo correu mal durante o arranque. Os detalhes abaixo identificam o que falhou.',
			'startup.failedBodyRepairable' => 'O ficheiro de definições guardado do Plezy está danificado e tem de ser reconstruído antes de o Plezy poder iniciar. Tentar novamente não vai ajudar — escolha Reparar armazenamento.',
			'startup.phaseLabel' => 'Fase',
			'startup.showDetails' => 'Mostrar detalhes',
			'startup.hideDetails' => 'Ocultar detalhes',
			'startup.copyDetails' => 'Copiar detalhes',
			'startup.detailsCopied' => 'Detalhes copiados para a área de transferência',
			'startup.uploadDetails' => 'Enviar detalhes',
			'startup.repairStorage' => 'Reparar armazenamento',
			'startup.repairTitle' => 'Reparar dados armazenados?',
			'startup.repairBodyCommon' => 'O ficheiro de definições do Plezy está danificado e não pode ser lido. Reparar repõe todas as definições predefinidas.',
			'startup.repairBodyOneCredential' => 'Um início de sessão guardado está danificado e não pode ser lido. Reparar remove apenas esse início de sessão; as suas outras definições permanecem intactas.',
			'startup.repairBodySignInsKept' => 'Os seus servidores e perfis devem permanecer ligados.',
			'startup.repairBodySignInsLost' => 'A chave que protege os seus inícios de sessão guardados não pode ser recuperada deste ficheiro, por isso terá de iniciar sessão novamente em todos os servidores e perfis. Nada no seu servidor multimédia é afetado.',
			'startup.repairBodySessionsUncertain' => 'Os rastreadores (MAL, AniList, Simkl, Trakt) e o Seerr são guardados separadamente e podem ou não ser preservados. O Plezy indicará exatamente o que foi mantido.',
			'startup.repairConfirm' => 'Reparar',
			'startup.repairSucceeded' => 'Armazenamento reparado',
			'startup.repairNeedsRestart' => 'Armazenamento reparado — reinício necessário',
			'startup.restartRequiredBody' => 'Os seus dados foram reparados, mas o Plezy tem de iniciar do zero antes de os usar. Feche o Plezy e abra-o novamente.',
			'startup.quitPlezy' => 'Sair do Plezy',
			'startup.repairFailed' => 'Falha na reparação',
			'startup.repairKeptSignIns' => 'Os seus servidores e perfis ainda estão ligados.',
			'startup.repairLostSignIns' => 'A chave que protege os seus inícios de sessão guardados não pôde ser recuperada. Terá de iniciar sessão novamente em todos os servidores e perfis.',
			'startup.repairLostSessions' => 'Pelo menos uma ligação de rastreador ou do Seerr foi perdida e tem de ser ligada novamente.',
			'startup.backupTitle' => 'Uma cópia do ficheiro danificado foi mantida',
			'startup.backupWarning' => 'Contém as suas credenciais de início de sessão. Não a envie nem partilhe.',
			'startup.deleteBackup' => 'Eliminar cópia',
			'startup.backupDeleted' => 'Cópia eliminada.',
			'startup.previousFailureTitle' => 'O Plezy não conseguiu iniciar da última vez',
			'licenses.relatedPackages' => 'Pacotes relacionados',
			'licenses.license' => 'Licença',
			'licenses.licenseNumber' => ({required Object number}) => 'Licença ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} licenças',
			'navigation.libraries' => 'Bibliotecas',
			'navigation.downloads' => 'Transferências',
			'navigation.liveTv' => 'TV em direto',
			'navigation.explore' => 'Explorar',
			'explore.title' => 'Explorar',
			'explore.selectSource' => 'Selecionar origem',
			'explore.rows.watchlist' => 'Lista para ver',
			'explore.rows.recommendedMovies' => 'Filmes recomendados',
			'explore.rows.recommendedShows' => 'Séries recomendadas',
			'explore.rows.trendingMovies' => 'Filmes em tendência',
			'explore.rows.trendingShows' => 'Séries em tendência',
			'explore.rows.popularMovies' => 'Filmes populares',
			'explore.rows.popularShows' => 'Séries populares',
			'explore.rows.trendingAnime' => 'Anime em tendência',
			'explore.rows.suggestedAnime' => 'Anime sugerido',
			'explore.rows.airingAnime' => 'Melhores animes em exibição',
			'explore.rows.popularAnime' => 'Anime mais popular',
			'explore.rows.trending' => 'Em tendência',
			'explore.rows.upcomingMovies' => 'Próximos filmes',
			'explore.rows.upcomingShows' => 'Próximas séries',
			'explore.status.airing' => 'Em exibição',
			'explore.status.ended' => 'Terminada',
			'explore.status.canceled' => 'Cancelada',
			'explore.status.upcoming' => 'Em breve',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '${n} episódio', other: '${n} episódios', ), 
			'explore.cast' => 'Elenco',
			'explore.characters' => 'Personagens',
			'explore.addToWatchlist' => 'Adicionar à lista para ver',
			'explore.removeFromWatchlist' => 'Remover da lista para ver',
			'explore.addedToWatchlist' => 'Adicionado à lista para ver',
			'explore.removedFromWatchlist' => 'Removido da lista para ver',
			'explore.watchlistUpdateFailed' => 'Não foi possível atualizar a lista para ver',
			'explore.watchlistNoMatch' => 'Não foi possível associar este item a uma lista para ver',
			'explore.notInLibrary' => 'Não está na sua biblioteca',
			'explore.inTheseLibraries' => 'Nestas bibliotecas',
			'explore.checkingLibrary' => 'A verificar a sua biblioteca...',
			'explore.libraryCheckFailed' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: 'Não foi possível verificar ${n} servidor', other: 'Não foi possível verificar ${n} servidores', ), 
			'explore.emptyTitle' => 'Ainda não há nada aqui',
			'explore.emptyMessage' => ({required Object source}) => 'As linhas de ${source} aparecerão aqui quando tiverem conteúdo.',
			'explore.searchHint' => ({required Object source}) => 'Pesquisar em ${source}',
			'explore.searchEmpty' => ({required Object query}) => 'Nenhum resultado para "${query}"',
			'explore.searchPrompt' => ({required Object source}) => 'Pesquise filmes e séries em ${source}.',
			'explore.searchFailed' => 'Falha na pesquisa. Verifique a sua ligação e tente novamente.',
			'explore.badge.rankPopular' => ({required Object n}) => '#${n} popular',
			'explore.badge.rankAiring' => ({required Object n}) => '#${n} em exibição',
			'explore.badge.rankRated' => ({required Object n}) => '#${n} mais bem avaliado',
			'explore.badge.rankTrending' => ({required Object n}) => '#${n} em tendência',
			'explore.badge.rankSeasonal' => ({required Object n, required Object season}) => '#${n} em ${season}',
			'explore.badge.watchingNow' => ({required Object n}) => '${n} a ver',
			'explore.badge.available' => 'Disponível',
			'explore.badge.partiallyAvailable' => 'Parcialmente disponível',
			'explore.badge.availableIn4k' => '4K disponível',
			'explore.badge.requested' => 'Pedido',
			'explore.badge.pendingApproval' => 'A aguardar aprovação',
			'explore.badge.processing' => 'A processar',
			'explore.badge.declined' => 'Recusado',
			'explore.badge.requestFailed' => 'Falha no pedido',
			'explore.badge.requested4k' => '4K pedido',
			'explore.badge.seasonsAvailable' => ({required Object available, required Object total}) => '${available}/${total} temporadas',
			'explore.badge.nextEpisodeIn' => ({required Object episode, required Object duration}) => 'Ep ${episode} dentro de ${duration}',
			'explore.badge.nextAiringIn' => ({required Object duration}) => 'Próximo dentro de ${duration}',
			'explore.badge.episodesShort' => ({required Object n}) => '${n} eps',
			'explore.badge.minutesPerEpisode' => ({required Object n}) => '${n} min/ep',
			'explore.badge.adult' => '18+',
			'explore.stats.listed' => ({required Object n}) => '${n} listados',
			'explore.stats.viewersDay' => ({required Object n}) => '${n} viram hoje',
			'explore.stats.viewersWeek' => ({required Object n}) => '${n} viram esta semana',
			'explore.stats.viewersMonth' => ({required Object n}) => '${n} viram este mês',
			'explore.stats.viewersYear' => ({required Object n}) => '${n} viram este ano',
			'explore.stats.viewersAllTime' => ({required Object n}) => '${n} espectadores',
			'explore.stats.planning' => ({required Object n}) => '${n} pretendem ver',
			'explore.stats.favorited' => ({required Object n}) => '${n} favoritos',
			'explore.stats.dropRate' => ({required Object percent}) => '${percent} abandonaram',
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '${n} comentário', other: '${n} comentários', ), 
			'explore.stats.votes' => ({required Object n}) => '${n} votos',
			'explore.stats.watching' => ({required Object n}) => '${n} a ver',
			'explore.stats.completed' => ({required Object n}) => '${n} concluíram',
			'explore.stats.onHold' => ({required Object n}) => '${n} em pausa',
			'explore.stats.dropped' => ({required Object n}) => '${n} abandonaram',
			'explore.season.winter' => 'Inverno',
			'explore.season.spring' => 'Primavera',
			'explore.season.summer' => 'Verão',
			'explore.season.fall' => 'Outono',
			'explore.season.withYear' => ({required Object season, required Object year}) => '${season} ${year}',
			'explore.format.tv' => 'TV',
			'explore.format.tvShort' => 'Curta de TV',
			'explore.format.movie' => 'Filme',
			'explore.format.special' => 'Especial',
			'explore.format.ova' => 'OVA',
			'explore.format.ona' => 'ONA',
			'explore.format.music' => 'Música',
			'explore.format.other' => 'Outro',
			'explore.sourceMaterial.original' => 'Original',
			'explore.sourceMaterial.manga' => 'Manga',
			'explore.sourceMaterial.lightNovel' => 'Light novel',
			'explore.sourceMaterial.novel' => 'Romance',
			'explore.sourceMaterial.visualNovel' => 'Visual novel',
			'explore.sourceMaterial.game' => 'Jogo',
			'explore.sourceMaterial.webComic' => 'Webcomic',
			'explore.sourceMaterial.musicRelease' => 'Música',
			'explore.sourceMaterial.otherMedia' => 'Outro',
			'explore.creditRole.actor' => 'Ator',
			'explore.creditRole.director' => 'Realizador',
			'explore.creditRole.writer' => 'Argumentista',
			'explore.creditRole.producer' => 'Produtor',
			'explore.creditRole.creator' => 'Criador',
			'explore.creditRole.composer' => 'Compositor',
			'explore.relation.prequel' => 'Prequela',
			'explore.relation.sequel' => 'Sequela',
			'explore.relation.sideStory' => 'História paralela',
			'explore.relation.spinOff' => 'Spin-off',
			'explore.relation.alternativeVersion' => 'Versão alternativa',
			'explore.relation.summary' => 'Resumo',
			'explore.relation.parentStory' => 'História principal',
			'explore.relation.adaptation' => 'Adaptação',
			'explore.relation.other' => 'Relacionado',
			'explore.broadcast' => ({required Object day, required Object time}) => 'Exibido ${day} às ${time}',
			'explore.broadcastWithZone' => ({required Object day, required Object time, required Object timezone}) => 'Exibido ${day} às ${time} ${timezone}',
			'explore.detail.originalTitle' => 'Título original',
			'explore.detail.alsoKnownAs' => 'Também conhecido como',
			'explore.detail.studios' => 'Estúdios',
			'explore.detail.country' => 'País',
			'explore.detail.language' => 'Idioma',
			'explore.detail.released' => 'Lançado',
			'explore.detail.physicalRelease' => 'Em disco',
			'explore.detail.ended' => 'Terminado',
			'explore.detail.addedOn' => ({required Object date}) => 'Adicionado em ${date}',
			'explore.detail.yourRating' => 'A sua avaliação',
			'explore.detail.budget' => 'Orçamento',
			'explore.detail.revenue' => 'Bilheteira',
			'explore.detail.contentAdvisory' => 'Classificação etária',
			'explore.detail.tags' => 'Tags',
			'explore.detail.revealSpoilerTags' => 'Mostrar tags de spoiler',
			'explore.detail.links' => 'Links',
			'explore.detail.watchOn' => 'Ver em',
			'explore.detail.watchTrailer' => 'Ver trailer',
			'explore.detail.openOn' => ({required Object site}) => 'Abrir em ${site}',
			'explore.detail.trailerUnavailable' => 'Não foi possível abrir o trailer neste dispositivo',
			'explore.detail.linkUnavailable' => 'Não foi possível abrir o link neste dispositivo',
			'explore.detail.crew' => 'Equipa',
			'explore.detail.ratings' => 'Avaliações',
			'explore.detail.schedule' => 'Programação',
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: 'Recomendado por ${n} utilizador', other: 'Recomendado por ${n} utilizadores', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => 'Recomendado por ${who}',
			'explore.detail.favoritedBy' => ({required Object who}) => 'Adicionado aos favoritos por ${who}',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '${n} ainda não exibidos',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => 'Recomendado por ${percent} dos espectadores',
			'explore.detail.relatedTitles' => 'Títulos relacionados',
			'explore.detail.background' => 'Contexto',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '${n} resultado', other: '${n} resultados', ), 
			'liveTv.title' => 'TV em direto',
			'liveTv.guide' => 'Guia',
			'liveTv.noChannels' => 'Nenhum canal disponível',
			'liveTv.noDvr' => 'Nenhum DVR configurado em nenhum servidor',
			'liveTv.serverUnavailable' => 'O servidor de TV em direto não está disponível.',
			'liveTv.serverNotConnected' => 'O servidor de TV em direto não está ligado.',
			'liveTv.noPrograms' => 'Nenhum dado de programação disponível',
			'liveTv.liveStreamFailed' => 'Falha na transmissão em direto',
			'liveTv.unknownProgram' => 'Programa desconhecido',
			'liveTv.unknownHub' => 'Desconhecido',
			'liveTv.unknownError' => 'Erro desconhecido',
			'liveTv.channelNumber' => ({required Object number}) => 'Canal ${number}',
			'liveTv.unknownChannel' => 'Canal desconhecido',
			'liveTv.live' => 'EM DIRETO',
			'liveTv.premiereBadge' => 'NOVO',
			'liveTv.reloadGuide' => 'Recarregar guia',
			'liveTv.searchGuide' => 'Pesquisar no guia',
			'liveTv.searchHint' => 'Pesquisar canais e programas',
			'liveTv.searchNoResults' => ({required Object query}) => 'Nenhuma correspondência para "${query}"',
			'liveTv.channelsSection' => 'Canais',
			'liveTv.programsSection' => 'Programas',
			'liveTv.now' => 'Agora',
			'liveTv.today' => 'Hoje',
			'liveTv.tomorrow' => 'Amanhã',
			'liveTv.midnight' => 'Meia-noite',
			'liveTv.overnight' => 'Madrugada',
			'liveTv.morning' => 'Manhã',
			'liveTv.daytime' => 'Dia',
			'liveTv.evening' => 'Noite',
			'liveTv.lateNight' => 'Madrugada',
			'liveTv.whatsOn' => 'O que está a passar',
			'liveTv.watchChannel' => 'Ver o canal',
			'liveTv.favorites' => 'Favoritos',
			'liveTv.reorderFavorites' => 'Reordenar favoritos',
			'liveTv.noFavoriteChannels' => 'Nenhum canal favorito',
			'liveTv.noFavoriteChannelsHint' => 'Mostre todos os canais e mantenha um canal premido para o adicionar aos favoritos.',
			'liveTv.showAllChannels' => 'Mostrar todos os canais',
			'liveTv.favoritesLoadFailed' => 'Não foi possível carregar os favoritos. Verifique a sua ligação e tente novamente.',
			'liveTv.favoritesUpdateFailed' => 'Não foi possível atualizar os favoritos. Verifique a sua ligação e tente novamente.',
			'liveTv.joinSession' => 'Entrar na sessão em curso',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'Ver do início (há ${minutes} min)',
			'liveTv.watchLive' => 'Ver em direto',
			'liveTv.goToLive' => 'Ir para o ponto em direto',
			'liveTv.record' => 'Gravar',
			'liveTv.recordEpisode' => 'Gravar episódio',
			'liveTv.recordSeries' => 'Gravar série',
			'liveTv.recordOptions' => 'Opções de gravação',
			'liveTv.saveTo' => 'Guardar em',
			'liveTv.recordings' => 'Gravações',
			'liveTv.scheduledRecordings' => 'Agendadas',
			'liveTv.recordingRules' => 'Regras de gravação',
			'liveTv.noScheduledRecordings' => 'Sem gravações agendadas',
			'liveTv.manageRecording' => 'Gerir gravação',
			'liveTv.cancelRecording' => 'Cancelar gravação',
			'liveTv.cancelRecordingTitle' => 'Cancelar esta gravação?',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '${title} já não será gravado.',
			'liveTv.deleteRule' => 'Eliminar regra',
			'liveTv.deleteRuleTitle' => 'Eliminar regra de gravação?',
			'liveTv.deleteRuleMessage' => ({required Object title}) => 'Os episódios futuros de ${title} não serão gravados.',
			'liveTv.recordingScheduled' => 'Gravação agendada',
			'liveTv.alreadyScheduled' => 'Este programa já está agendado',
			'liveTv.dvrAdminRequired' => 'As definições de DVR exigem uma conta de administrador',
			'liveTv.recordingFailed' => 'Não foi possível agendar a gravação',
			'liveTv.recordingTargetMissing' => 'Não foi possível determinar a biblioteca de gravação',
			'liveTv.recordNotAvailable' => 'Gravação indisponível para este programa',
			'liveTv.recordingCancelled' => 'Gravação cancelada',
			'liveTv.recordingRuleDeleted' => 'Regra de gravação eliminada',
			'liveTv.processRecordingRules' => 'Reavaliar regras',
			'liveTv.recordingInProgress' => 'A gravar agora',
			'liveTv.recordingsCount' => ({required Object count}) => '${count} agendadas',
			'liveTv.editRule' => 'Editar regra',
			'liveTv.editRuleAction' => 'Editar',
			'liveTv.recordingRuleUpdated' => 'Regra de gravação atualizada',
			'liveTv.guideReloadRequested' => 'Atualização do guia pedida',
			'liveTv.guideReloadFailed' => 'Não foi possível atualizar o guia',
			'liveTv.rulesProcessRequested' => 'Reavaliação de regras pedida',
			'liveTv.rulesProcessFailed' => 'Não foi possível reavaliar as regras de gravação',
			_ => null,
		} ?? switch (path) {
			'liveTv.recordShow' => 'Gravar programa',
			'liveTv.recordSettings.startEarly' => 'Começar antes (segundos)',
			'liveTv.recordSettings.endLate' => 'Terminar depois (segundos)',
			'liveTv.recordSettings.newOnly' => 'Apenas episódios novos',
			'liveTv.recordSettings.anyChannel' => 'Gravar em qualquer canal',
			'liveTv.recordSettings.anyTime' => 'Gravar a qualquer hora',
			'liveTv.recordSettings.skipInLibrary' => 'Ignorar episódios que já estão na biblioteca',
			'liveTv.recordSettings.keepUpTo' => 'Episódios a manter',
			'liveTv.recordSettings.keepUpToHint' => '0 mantém todos os episódios',
			'liveTv.startingInMinutes' => ({required Object minutes}) => 'Começa dentro de ${minutes} min',
			'liveTv.dayAtTime' => ({required Object day, required Object time}) => '${day} às ${time}',
			'liveTv.invalidPlaybackData' => ({required Object product}) => '${product} devolveu dados de reprodução de TV em direto inválidos',
			'liveTv.failedToStartChannel' => 'Não foi possível iniciar o canal em direto',
			'liveTv.failedToBuildStreamUrl' => 'Não foi possível gerar o URL da transmissão',
			'liveTv.playbackStartFailed' => ({required Object reason}) => 'Não foi possível iniciar o canal: ${reason}',
			'liveTv.channelSwitchFailed' => ({required Object reason}) => 'Não foi possível mudar de canal: ${reason}',
			'collections.title' => 'Coleções',
			'collections.collection' => 'Coleção',
			'collections.empty' => 'A coleção está vazia',
			'collections.deleteCollection' => 'Eliminar coleção',
			'collections.deleteConfirm' => ({required Object title}) => 'Eliminar "${title}"? Não pode ser anulado.',
			'collections.deleted' => 'Coleção eliminada',
			'collections.deleteFailed' => 'Falha ao eliminar a coleção',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Falha ao eliminar a coleção: ${error}',
			'collections.selectCollection' => 'Selecionar coleção',
			'collections.collectionName' => 'Nome da coleção',
			'collections.enterCollectionName' => 'Introduza o nome da coleção',
			'collections.addedToCollection' => 'Adicionado à coleção',
			'collections.errorAddingToCollection' => 'Falha ao adicionar à coleção',
			'collections.created' => 'Coleção criada',
			'collections.removeFromCollection' => 'Remover da coleção',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => 'Remover "${title}" desta coleção?',
			'collections.removedFromCollection' => 'Removido da coleção',
			'collections.removeFromCollectionFailed' => 'Falha ao remover da coleção',
			'collections.removeFromCollectionError' => ({required Object error}) => 'Erro ao remover da coleção: ${error}',
			'collections.searchCollections' => 'Pesquisar coleções...',
			'playlists.title' => 'Playlists',
			'playlists.playlist' => 'Playlist',
			'playlists.noPlaylists' => 'Nenhuma playlist encontrada',
			'playlists.create' => 'Criar playlist',
			'playlists.playlistName' => 'Nome da playlist',
			'playlists.enterPlaylistName' => 'Introduza o nome da playlist',
			'playlists.delete' => 'Eliminar playlist',
			'playlists.removeItem' => 'Remover da playlist',
			'playlists.smartPlaylist' => 'Playlist inteligente',
			'playlists.itemCount' => ({required Object count}) => '${count} itens',
			'playlists.oneItem' => '1 item',
			'playlists.emptyPlaylist' => 'Esta playlist está vazia',
			'playlists.deleteConfirm' => 'Eliminar playlist?',
			'playlists.deleteMessage' => ({required Object name}) => 'Tem a certeza de que pretende eliminar "${name}"?',
			'playlists.created' => 'Playlist criada',
			'playlists.deleted' => 'Playlist eliminada',
			'playlists.itemAdded' => 'Adicionado à playlist',
			'playlists.itemRemoved' => 'Removido da playlist',
			'playlists.selectPlaylist' => 'Selecionar playlist',
			'playlists.searchPlaylists' => 'Pesquisar playlists...',
			'playlists.errorCreating' => 'Falha ao criar a playlist',
			'playlists.errorDeleting' => 'Falha ao eliminar a playlist',
			'playlists.errorLoading' => 'Falha ao carregar playlists',
			'playlists.errorAdding' => 'Falha ao adicionar à playlist',
			'playlists.errorReordering' => 'Falha ao reordenar o item da playlist',
			'playlists.errorRemoving' => 'Falha ao remover da playlist',
			'music.goToAlbum' => 'Ir para o álbum',
			'music.goToArtist' => 'Ir para o artista',
			'music.instantMix' => 'Mix instantâneo',
			'music.playNext' => 'Reproduzir a seguir',
			'music.addToQueue' => 'Adicionar à fila',
			'music.discNumber' => ({required Object n}) => 'Disco ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '${n} faixa', other: '${n} faixas', ), 
			'music.nowPlaying' => 'A reproduzir agora',
			'music.playingFrom' => ({required Object title}) => 'A reproduzir de ${title}',
			'music.queue' => 'Fila',
			'music.clearQueue' => 'Limpar fila',
			'music.lyrics' => 'Letra',
			'music.noLyrics' => 'Nenhuma letra disponível',
			'music.sleepTimer' => 'Temporizador de suspensão',
			'music.sleepTimerEndOfTrack' => 'Fim da faixa',
			'music.sleepTimerMinutes' => ({required Object n}) => '${n} minutos',
			'music.stopPlayback' => 'Parar a reprodução',
			'music.previousTrack' => 'Faixa anterior',
			'music.nextTrack' => 'Próxima faixa',
			'music.repeat' => 'Repetir',
			'music.repeatAll' => 'Repetir tudo',
			'music.repeatOne' => 'Repetir uma faixa',
			'music.instantMixNoServer' => 'Nenhum servidor disponível para um mix instantâneo',
			'music.instantMixFailed' => 'Falha ao carregar o mix instantâneo',
			'music.instantMixEmpty' => 'O mix instantâneo não devolveu nenhuma faixa',
			'music.noAudioUrl' => ({required Object track}) => 'Nenhum URL de áudio disponível para ${track}',
			'music.discography.singlesAndEps' => 'Singles e EPs',
			'music.discography.live' => 'Em direto',
			'music.discography.compilations' => 'Compilações',
			'watchTogether.title' => 'Ver juntos',
			'watchTogether.description' => 'Veja conteúdos em sincronia com amigos e família',
			'watchTogether.createRoom' => 'Criar sala',
			'watchTogether.creatingRoom' => 'A criar sala...',
			'watchTogether.joinRoom' => 'Entrar na sala',
			'watchTogether.joiningRoom' => 'A entrar na sala...',
			'watchTogether.connecting' => 'A ligar...',
			'watchTogether.relayPublic' => 'As salas usam os servidores de retransmissão públicos do Open Watch Party.',
			'watchTogether.relayCustom' => ({required Object url}) => 'As salas usam o seu servidor de retransmissão em ${url}.',
			'watchTogether.recentRooms' => 'Salas recentes',
			'watchTogether.roomActions' => 'Ações da sala',
			'watchTogether.renameRoom' => 'Renomear sala',
			'watchTogether.removeRoom' => 'Remover',
			'watchTogether.enterRoomCode' => 'Introduza o código de 6 caracteres do anfitrião.',
			'watchTogether.roomCode' => 'Código da sala',
			'watchTogether.paste' => 'Colar',
			'watchTogether.noCodeInClipboard' => 'A área de transferência não contém um código de sala',
			'watchTogether.copyCode' => 'Copiar código',
			'watchTogether.codeCopied' => 'Código da sala copiado',
			'watchTogether.shareInvite' => 'Partilhar convite',
			'watchTogether.inviteCopied' => 'Convite copiado. Cole-o numa mensagem.',
			'watchTogether.inviteMessage' => ({required Object code}) => 'Entra na minha sala do Ver juntos no Plezy: abre "Ver juntos", escolhe "Entrar na sala" e introduz ${code}.',
			'watchTogether.openSessionControls' => 'Abrir os controlos da sessão Ver juntos',
			'watchTogether.reconnecting' => 'A voltar a ligar...',
			'watchTogether.reconnectingDescription' => 'A ligação caiu. Vai voltar à sala automaticamente.',
			'watchTogether.connected' => 'Ligado',
			'watchTogether.disconnected' => 'Desligado',
			'watchTogether.youAreHost' => 'É o anfitrião',
			'watchTogether.hostedBy' => ({required Object name}) => 'Anfitrião: ${name}',
			'watchTogether.hostControlsPlayback' => 'O anfitrião controla a reprodução',
			'watchTogether.anyoneCanControl' => 'Qualquer pessoa pode controlar a reprodução',
			'watchTogether.roomLocked' => 'Sala bloqueada',
			'watchTogether.nowPlaying' => 'A reproduzir agora',
			'watchTogether.nothingPlaying' => 'Nada em reprodução',
			'watchTogether.nothingPlayingHost' => 'Reproduza algo de qualquer biblioteca para partilhar com a sala.',
			'watchTogether.nothingPlayingGuest' => 'Quando o anfitrião reproduzir algo, o conteúdo será aberto aqui.',
			'watchTogether.notShareable' => 'Este vídeo não corresponde a nenhum item do catálogo, por isso só as pessoas com acesso ao mesmo servidor o podem reproduzir.',
			'watchTogether.searching' => 'A procurar este vídeo nas suas bibliotecas...',
			'watchTogether.yourCopy' => 'A sua cópia',
			'watchTogether.sharingYourCopy' => 'Está a partilhar a sua cópia',
			'watchTogether.playingOtherLength' => ({required Object difference}) => 'A reproduzir a sua cópia, ${difference}',
			'watchTogether.mismatchTitle' => 'A sua cópia tem outra duração',
			'watchTogether.mismatchDescription' => ({required Object difference}) => 'A sua cópia mais próxima é ${difference} que o vídeo da sala. Pode ser outro corte ou outra versão.',
			'watchTogether.playAnyway' => 'Reproduzir mesmo assim',
			'watchTogether.chooseAnotherCopy' => 'Escolher outra cópia',
			'watchTogether.dontPlay' => 'Não reproduzir',
			'watchTogether.unavailableTitle' => 'Não tem este vídeo',
			'watchTogether.unavailableDescription' => 'O Plezy não o encontrou nas suas bibliotecas. Escolha uma cópia manualmente ou pesquise novamente.',
			'watchTogether.chooseCopy' => 'Escolher uma cópia',
			'watchTogether.searchAgain' => 'Pesquisar novamente',
			'watchTogether.noCandidates' => 'Nenhuma cópia encontrada nas suas bibliotecas.',
			'watchTogether.choiceFailed' => 'Não foi possível reproduzir esta cópia para a sala',
			'watchTogether.lengthLonger' => ({required Object duration}) => '${duration} mais longa',
			'watchTogether.lengthShorter' => ({required Object duration}) => '${duration} mais curta',
			'watchTogether.lengthSame' => 'Mesma duração',
			'watchTogether.lengthUnknown' => 'Duração desconhecida',
			'watchTogether.joinCurrentPlayback' => 'Entrar na reprodução atual',
			'watchTogether.joinCurrentPlaybackDescription' => 'Voltar ao conteúdo que o anfitrião está a ver agora',
			'watchTogether.stopMedia' => 'Parar o vídeo para todos',
			'watchTogether.syncOffset' => 'Ajuste de sincronização',
			'watchTogether.syncOffsetDescription' => 'Ajuste o seu vídeo se estiver adiantado ou atrasado em relação à sala.',
			'watchTogether.offsetHint' => ({required Object difference}) => 'A sua cópia é ${difference} que o vídeo da sala.',
			'watchTogether.applyDifference' => ({required Object offset}) => 'Usar ${offset}',
			'watchTogether.offsetMinusSecond' => '-1 s',
			'watchTogether.offsetMinusTenth' => '-100 ms',
			'watchTogether.offsetPlusTenth' => '+100 ms',
			'watchTogether.offsetPlusSecond' => '+1 s',
			'watchTogether.participants' => 'Participantes',
			'watchTogether.participantCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '${n} participante', other: '${n} participantes', ), 
			'watchTogether.hostBadge' => 'ANFITRIÃO',
			'watchTogether.nameYou' => ({required Object name}) => '${name} (você)',
			'watchTogether.playerIdle' => 'Inativo',
			'watchTogether.playerLoading' => 'A carregar',
			'watchTogether.playerReady' => 'Pronto',
			'watchTogether.playerBuffering' => 'Em buffer',
			'watchTogether.matchSearching' => 'A procurar',
			'watchTogether.matchMatched' => 'Tem o vídeo',
			'watchTogether.matchMismatched' => 'Duração diferente',
			'watchTogether.matchUnavailable' => 'Não tem o vídeo',
			'watchTogether.participantOffset' => ({required Object offset}) => 'Ajuste ${offset}',
			'watchTogether.makeHost' => 'Tornar anfitrião',
			'watchTogether.makeHostQuestion' => 'Transferir o papel de anfitrião?',
			'watchTogether.makeHostConfirm' => ({required Object name}) => '${name} controlará a reprodução e conduzirá a sessão para todos.',
			'watchTogether.transfer' => 'Transferir',
			'watchTogether.removeParticipant' => 'Remover da sala',
			'watchTogether.removeParticipantQuestion' => ({required Object name}) => 'Remover ${name}?',
			'watchTogether.removeParticipantConfirm' => ({required Object name}) => '${name} sairá da sala. A pessoa poderá voltar a entrar com o código, a menos que bloqueie a sala.',
			'watchTogether.remove' => 'Remover',
			'watchTogether.roomSettings' => 'Definições da sala',
			'watchTogether.letEveryoneControl' => 'Permitir que todos controlem a reprodução',
			'watchTogether.lockRoom' => 'Bloquear sala',
			'watchTogether.lockRoomDescription' => 'Ninguém novo pode entrar',
			'watchTogether.leaveRoom' => 'Sair da sala',
			'watchTogether.leaveRoomQuestion' => 'Sair da sala?',
			'watchTogether.leaveRoomConfirm' => 'Pode voltar a entrar com o código da sala.',
			'watchTogether.leave' => 'Sair',
			'watchTogether.endRoom' => 'Encerrar sala',
			'watchTogether.endRoomQuestion' => 'Encerrar sala?',
			'watchTogether.endRoomConfirm' => 'Isto encerra a sala para todos.',
			'watchTogether.end' => 'Encerrar',
			'watchTogether.playBlockedTitle' => 'A reprodução não começou',
			'watchTogether.playBlockedDescription' => 'Prima reproduzir para começar a ver com a sala.',
			'watchTogether.notices.pressedPlay' => ({required Object name}) => '${name} iniciou a reprodução',
			'watchTogether.notices.playbackStarted' => 'Reprodução iniciada',
			'watchTogether.notices.paused' => ({required Object name}) => '${name} colocou em pausa',
			'watchTogether.notices.playbackPaused' => 'Reprodução pausada',
			'watchTogether.notices.jumpedTo' => ({required Object name, required Object position}) => '${name} saltou para ${position}',
			'watchTogether.notices.roomJumpedTo' => ({required Object position}) => 'Saltou para ${position}',
			'watchTogether.notices.changedSpeed' => ({required Object name, required Object speed}) => '${name} definiu a velocidade para ${speed}',
			'watchTogether.notices.speedChanged' => ({required Object speed}) => 'Velocidade definida para ${speed}',
			'watchTogether.notices.startedMedia' => ({required Object name, required Object title}) => '${name} iniciou ${title}',
			'watchTogether.notices.mediaStarted' => ({required Object title}) => 'A reproduzir agora: ${title}',
			'watchTogether.notices.stoppedMedia' => ({required Object name}) => '${name} parou o vídeo',
			'watchTogether.notices.mediaStopped' => 'O vídeo parou',
			'watchTogether.notices.waitingFor' => ({required Object name}) => 'A aguardar ${name}...',
			'watchTogether.notices.waitingForSomeone' => 'A aguardar que alguém sincronize...',
			'watchTogether.notices.finished' => 'Concluído',
			'watchTogether.notices.hostChangedTo' => ({required Object name}) => '${name} é agora o anfitrião',
			'watchTogether.notices.youAreNowHost' => 'Agora é o anfitrião',
			'watchTogether.notices.joined' => ({required Object name}) => '${name} entrou',
			'watchTogether.notices.left' => ({required Object name}) => '${name} saiu',
			'watchTogether.notices.controlRefused' => 'Apenas o anfitrião pode controlar a reprodução',
			'watchTogether.notices.searchFailed' => 'Não foi possível pesquisar o vídeo da sala em alguns servidores',
			'watchTogether.notices.playBlocked' => 'Prima reproduzir para começar',
			'watchTogether.notices.shareFailed' => 'Não foi possível partilhar este vídeo com a sala',
			'watchTogether.notices.downloadNotShared' => 'As transferências não são partilhadas com a sala enquanto o servidor de origem estiver offline',
			'watchTogether.notices.openFailed' => 'Não foi possível abrir o vídeo da sala',
			'watchTogether.ended.ended' => 'O anfitrião encerrou a sala',
			'watchTogether.ended.kicked' => 'Foi removido da sala',
			'watchTogether.ended.expired' => 'A sala expirou',
			'watchTogether.ended.replaced' => 'Entrou nesta sala noutro dispositivo',
			'watchTogether.ended.lost' => 'A ligação com a sala foi perdida',
			'watchTogether.errors.invalidCode' => 'Isto não é um código de sala. Os códigos têm 6 letras e números, sem 0, 1, I, L ou O.',
			'watchTogether.errors.roomNotFound' => 'Nenhuma sala tem esse código. Pode ter sido encerrada.',
			'watchTogether.errors.roomFull' => 'Esta sala está cheia.',
			'watchTogether.errors.roomLocked' => 'O anfitrião bloqueou esta sala.',
			'watchTogether.errors.relayFull' => 'O Ver juntos está sobrecarregado de momento. Tente novamente mais tarde.',
			'watchTogether.errors.unreachable' => 'Não foi possível contactar o servidor de retransmissão do Ver juntos. Verifique a sua ligação.',
			'watchTogether.errors.rateLimited' => 'Demasiadas tentativas. Aguarde um momento e tente novamente.',
			'watchTogether.errors.clientBlocked' => 'Esta versão do Plezy não pode usar o servidor de retransmissão. Atualize a aplicação.',
			'watchTogether.errors.forbidden' => 'Apenas o anfitrião pode fazer isto.',
			'watchTogether.errors.notInRoom' => 'Não está numa sala.',
			'watchTogether.errors.alreadyInRoom' => 'Já está numa sala.',
			'watchTogether.errors.resumeFailed' => 'Não foi possível voltar à sala.',
			'watchTogether.errors.unsupported' => 'O servidor de retransmissão não suporta isto.',
			'watchTogether.errors.generic' => 'Algo correu mal. Tente novamente.',
			'watchTogether.untitledEpisode' => ({required Object number}) => 'Episódio ${number}',
			'downloads.title' => 'Transferências',
			'downloads.manage' => 'Gerir',
			'downloads.tvShows' => 'Séries de TV',
			'downloads.movies' => 'Filmes',
			'downloads.music' => 'Música',
			'downloads.tracksQueued' => ({required Object count}) => '${count} faixas na fila para transferência',
			'downloads.noDownloads' => 'Ainda não há transferências',
			'downloads.noDownloadsDescription' => 'O conteúdo transferido aparecerá aqui para ver offline',
			'downloads.downloadNow' => 'Transferir',
			'downloads.deleteDownload' => 'Eliminar transferência',
			'downloads.retryDownload' => 'Tentar transferência novamente',
			'downloads.downloadQueued' => 'Transferência na fila',
			'downloads.downloadResumed' => 'Transferência retomada',
			'downloads.serverErrorBitrate' => 'Erro do servidor: o ficheiro pode exceder o limite remoto de taxa de bits',
			'downloads.storageFull' => 'As transferências foram interrompidas para proteger o espaço disponível. Liberte espaço ou escolha outro local de transferência e tente novamente.',
			'downloads.storageUnavailable' => 'As transferências foram interrompidas porque não foi possível verificar o armazenamento disponível. Verifique o local de transferência e tente novamente.',
			'downloads.episodesQueued' => ({required Object count}) => '${count} episódios na fila de transferência',
			'downloads.downloadDeleted' => 'Transferência eliminada',
			'downloads.deleteConfirm' => ({required Object title}) => 'Eliminar "${title}" deste dispositivo?',
			'downloads.deleteCollectionDownloads' => 'Eliminar transferências',
			'downloads.deleteCollectionDownloadsConfirm' => ({required Object title}) => 'Eliminar todas as transferências de "${title}" deste dispositivo?',
			'downloads.collectionDownloadsDeleted' => 'Transferências eliminadas',
			'downloads.cancelledDownloadTitle' => 'Transferência cancelada',
			'downloads.cancelledDownloadMessage' => 'Esta transferência foi cancelada. O que pretende fazer?',
			'downloads.allEpisodesAlreadyDownloaded' => 'Todos os episódios já foram transferidos',
			'downloads.resumeDownload' => 'Retomar transferência',
			'downloads.cancelledDownload' => 'Transferência cancelada',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file} (a sincronizar ${status})',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => '${file} transferido — clique para concluir',
			'downloads.partialDownloadClickToComplete' => 'Parcialmente transferido — clique para concluir',
			'downloads.deleting' => 'A eliminar...',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'A eliminar ${title}... (${current} de ${total})',
			'downloads.queuedTooltip' => 'Na fila',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'Na fila: ${files}',
			'downloads.downloadingTooltip' => 'A transferir...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => 'A transferir ${files}',
			'downloads.noDownloadsTree' => 'Nenhuma transferência',
			'downloads.pauseAll' => 'Pausar todas',
			'downloads.resumeAll' => 'Retomar todas',
			'downloads.retryAll' => 'Tentar todas novamente',
			'downloads.retryFailed' => 'Tentar novamente as transferências com falha',
			'downloads.deleteAll' => 'Eliminar todas',
			'downloads.selectVersion' => 'Selecionar versão',
			'downloads.allEpisodes' => 'Todos os episódios',
			'downloads.unwatchedOnly' => 'Apenas não vistos',
			'downloads.nextNUnwatched' => ({required Object count}) => 'Próximos ${count} episódios não vistos',
			'downloads.customAmount' => 'Quantidade personalizada...',
			'downloads.includeSpecials' => 'Incluir especiais',
			'downloads.howManyEpisodes' => 'Quantos episódios?',
			'downloads.invalidEpisodeCount' => 'Introduza um número de episódios válido.',
			'downloads.keepSynced' => 'Manter sincronizado',
			'downloads.downloadOnce' => 'Transferir uma vez',
			'downloads.keepNUnwatched' => ({required Object count}) => 'Manter ${count} episódios não vistos',
			'downloads.editSyncRule' => 'Editar regra de sincronização',
			'downloads.removeSyncRule' => 'Remover regra de sincronização',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => 'Parar de sincronizar "${title}"? Os episódios transferidos serão mantidos.',
			'downloads.removeListSyncRuleConfirm' => ({required Object title}) => 'Parar a sincronização de "${title}"?',
			'downloads.deleteSyncRuleDownloads' => 'Eliminar também as transferências associadas',
			'downloads.deleteSyncRuleDownloadsDescription' => 'As transferências usadas por outra regra de sincronização ou perfil serão mantidas.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'Regra de sincronização criada — a manter ${count} episódios não vistos',
			'downloads.syncRuleUpdated' => 'Regra de sincronização atualizada',
			'downloads.syncRuleRemoved' => 'Regra de sincronização removida',
			'downloads.syncRuleAndDownloadsRemoved' => 'Regra de sincronização e transferências associadas removidas',
			'downloads.syncRuleCleanupBusy' => 'As regras de sincronização estão a ser atualizadas. Tente novamente daqui a pouco.',
			'downloads.syncRuleCleanupUnavailable' => 'Não foi possível identificar com segurança as transferências associadas. Volte a ligar o servidor e tente novamente, ou remova a regra sem eliminar as transferências.',
			'downloads.syncedNewEpisodes' => ({required Object count, required Object title}) => '${count} novos episódios sincronizados para ${title}',
			'downloads.activeSyncRules' => 'Regras de sincronização',
			'downloads.noSyncRules' => 'Nenhuma regra de sincronização',
			'downloads.manageSyncRule' => 'Gerir sincronização',
			'downloads.editEpisodeCount' => 'Número de episódios',
			'downloads.editSyncFilter' => 'Filtro de sincronização',
			'downloads.syncAllItems' => 'A sincronizar todos os itens',
			'downloads.syncUnwatchedItems' => 'A sincronizar itens não vistos',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'Servidor: ${server} • ${status}',
			'downloads.syncRuleAvailable' => 'Disponível',
			'downloads.syncRuleOffline' => 'Offline',
			'downloads.syncRuleSignInRequired' => 'É necessário iniciar sessão',
			'downloads.syncRuleAccessDenied' => 'Acesso negado',
			'downloads.syncRuleNotAvailableForProfile' => 'Indisponível para o perfil atual',
			'downloads.syncRuleUnknownServer' => 'Servidor desconhecido',
			'downloads.syncRuleListCreated' => 'Regra de sincronização criada',
			'downloads.backgroundWarning.bannerBlocked' => 'As transferências serão interrompidas ao sair da aplicação',
			'downloads.backgroundWarning.bannerDegraded' => 'As transferências em segundo plano podem estar limitadas',
			'downloads.backgroundWarning.bannerAction' => 'Detalhes',
			'downloads.backgroundWarning.sheetTitle' => 'As transferências em segundo plano estão bloqueadas',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'As transferências em segundo plano podem estar limitadas',
			'downloads.backgroundWarning.sheetIntro' => 'O Android está a impedir que o Plezy faça transferências de forma fiável em segundo plano.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'O seu dispositivo está a limitar quando o Plezy pode fazer transferências em segundo plano.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'A utilização em segundo plano do Plezy está restrita. Defina a utilização da bateria ou a utilização em segundo plano como "Sem restrições".',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'O Android colocou o Plezy num modo de espera restrito. Defina a utilização da bateria como "Sem restrições".',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'As notificações de transferência estão desativadas; por isso, o progresso e os controlos podem ficar indisponíveis.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'As notificações estão desativadas. No Android 13 ou mais recente, são necessárias para transferências longas em segundo plano.',
			'downloads.backgroundWarning.reasonDataSaver' => 'A Poupança de dados está ativada e bloqueia as transferências em segundo plano com dados móveis. As transferências devem continuar a funcionar por Wi-Fi.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'As transferências foram interrompidas várias vezes enquanto o Plezy estava em segundo plano. Verifique as definições de bateria ou de utilização em segundo plano do Plezy.',
			'downloads.backgroundWarning.openSettings' => 'Abrir definições',
			'downloads.backgroundWarning.stillNotWorking' => 'Ajuda específica para o dispositivo',
			'downloads.backgroundWarning.stillNotWorkingDescription' => 'Veja as instruções para o seu dispositivo ou, se o problema persistir, envie um registo em Definições › Ver registos.',
			'downloads.backgroundWarning.dialogTitle' => 'As transferências podem não ser concluídas',
			'downloads.backgroundWarning.dialogDownloadAnyway' => 'Transferir mesmo assim',
			'downloads.backgroundWarning.dialogFixFirst' => 'Corrigir primeiro',
			'downloads.backgroundWarning.statusTile' => 'Transferências em segundo plano',
			'downloads.backgroundWarning.statusOk' => 'Execução em segundo plano permitida',
			'downloads.backgroundWarning.statusBlocked' => 'Bloqueado pelas definições do sistema',
			'downloads.backgroundWarning.statusDegraded' => 'Limitado pelas definições do sistema',
			'downloads.backgroundWarning.statusUnknown' => 'Ainda não verificado',
			'downloads.backgroundWarning.settingsUnavailable' => 'Não foi possível abrir as definições do sistema neste dispositivo',
			'downloads.backgroundWarning.linkUnavailable' => 'Não foi possível abrir dontkillmyapp.com neste dispositivo',
			'downloads.options' => 'Opções de transferências',
			'downloads.groupings.library' => 'Biblioteca',
			'downloads.groupings.collections' => 'Coleções',
			'downloads.unknownLibrary' => 'Biblioteca desconhecida',
			'downloads.unknownShow' => 'Série desconhecida',
			'downloads.unknownSeason' => 'Temporada desconhecida',
			'downloads.unknownAlbum' => 'Álbum desconhecido',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '${completed}/${total} concluídas',
			'downloads.errorFileNotFound' => 'Ficheiro não encontrado (404)',
			'downloads.errorDownloadNotAllowed' => 'Transferência não permitida pelo servidor (403)',
			'downloads.errorDownloadFailed' => 'Falha na transferência',
			'downloads.errorDownloadFailedWithReason' => ({required Object reason}) => 'Falha na transferência: ${reason}',
			'downloads.errorHttpStatus' => ({required Object status}) => 'Falha na transferência (HTTP ${status})',
			'downloads.errorPostProcessing' => ({required Object reason}) => 'Falha no pós-processamento: ${reason}',
			'downloads.reasonFileNotSaved' => 'não foi possível guardar o ficheiro neste dispositivo',
			'downloads.reasonCannotResume' => 'não foi possível retomar a transferência parcial',
			'downloads.reasonDeviceStorageFull' => 'este dispositivo está sem espaço de armazenamento',
			'downloads.notificationDownloading' => 'A transferir...',
			'downloads.notificationComplete' => 'Transferência concluída',
			'downloads.notificationPaused' => 'Transferência em pausa',
			'shaders.title' => 'Shaders',
			'shaders.noShaderDescription' => 'Sem melhoramento de vídeo',
			'shaders.nvscalerDescription' => 'Dimensionamento de imagem da NVIDIA para vídeos mais nítidos',
			'shaders.artcnnVariantNeutral' => 'Neutro',
			'shaders.artcnnVariantDenoise' => 'Redução de ruído',
			'shaders.artcnnVariantDenoiseSharpen' => 'Redução de ruído + nitidez',
			'shaders.qualityFast' => 'Rápido',
			'shaders.qualityHQ' => 'Alta qualidade',
			'shaders.mode' => 'Modo',
			'shaders.importShader' => 'Importar shader',
			'shaders.customShaderDescription' => 'Shader GLSL personalizado',
			'shaders.shaderImported' => 'Shader importado',
			'shaders.shaderImportFailed' => 'Falha ao importar o shader',
			'shaders.deleteShader' => 'Eliminar shader',
			'shaders.deleteShaderConfirm' => ({required Object name}) => 'Eliminar "${name}"?',
			'companionRemote.title' => 'Comando remoto',
			'companionRemote.connectedTo' => ({required Object name}) => 'Ligado a ${name}',
			'companionRemote.unknownDevice' => 'Dispositivo desconhecido',
			'companionRemote.session.startingServer' => 'A iniciar o servidor remoto...',
			'companionRemote.session.hostAddress' => 'Endereço do anfitrião',
			'companionRemote.session.connected' => 'Ligado',
			'companionRemote.session.serverRunning' => 'Servidor remoto ativo',
			'companionRemote.session.serverStopped' => 'Servidor remoto parado',
			'companionRemote.session.serverRunningDescription' => 'Os dispositivos móveis na sua rede podem ligar-se a esta aplicação',
			'companionRemote.session.serverStoppedDescription' => 'Inicie o servidor para permitir que os dispositivos móveis se liguem',
			'companionRemote.session.usePhoneToControl' => 'Use o seu dispositivo móvel para controlar esta aplicação',
			'companionRemote.session.startServer' => 'Iniciar servidor',
			'companionRemote.session.stopServer' => 'Parar servidor',
			'companionRemote.session.minimize' => 'Minimizar',
			'companionRemote.session.manualAddressHint' => 'Endereço de ligação manual:',
			'companionRemote.pairing.discoveryDescription' => 'Dispositivos Plezy com a mesma conta Plex aparecem aqui',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'A ligar...',
			'companionRemote.pairing.searchingForDevices' => 'A procurar dispositivos...',
			'companionRemote.pairing.noDevicesFound' => 'Nenhum dispositivo encontrado na sua rede',
			'companionRemote.pairing.noDevicesHint' => 'Abra o Plezy no computador e use a mesma rede Wi-Fi',
			'companionRemote.pairing.availableDevices' => 'Dispositivos disponíveis',
			'companionRemote.pairing.manualConnection' => 'Ligação manual',
			'companionRemote.pairing.cryptoInitFailed' => 'Não foi possível iniciar a ligação segura. Inicie sessão no Plex primeiro.',
			'companionRemote.pairing.validationHostRequired' => 'Introduza o endereço do anfitrião',
			'companionRemote.pairing.validationHostFormat' => 'O formato deve ser IP:porta (ex.: 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'A ligação atingiu o tempo limite. Use a mesma rede nos dois dispositivos.',
			'companionRemote.pairing.sessionNotFound' => 'Dispositivo não encontrado. Verifique se o Plezy está em execução no anfitrião.',
			'companionRemote.pairing.authFailed' => 'Falha na autenticação. Ambos os dispositivos têm de usar a mesma conta Plex.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Falha ao ligar: ${error}',
			'companionRemote.remote.disconnectConfirm' => 'Pretende desligar-se da sessão remota?',
			'companionRemote.remote.reconnecting' => 'A voltar a ligar...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Tentativa ${current} de 5',
			'companionRemote.remote.retryNow' => 'Tentar agora',
			'companionRemote.remote.tabRemote' => 'Remoto',
			'companionRemote.remote.tabPlay' => 'Reproduzir',
			'companionRemote.remote.tabMore' => 'Mais',
			'companionRemote.remote.menu' => 'Menu',
			'companionRemote.remote.tabNavigation' => 'Navegação por separadores',
			'companionRemote.remote.tabDiscover' => 'Descobrir',
			'companionRemote.remote.tabLibraries' => 'Bibliotecas',
			'companionRemote.remote.tabSearch' => 'Pesquisar',
			'companionRemote.remote.tabDownloads' => 'Transferências',
			'companionRemote.remote.tabSettings' => 'Definições',
			'companionRemote.remote.previous' => 'Anterior',
			'companionRemote.remote.playPause' => 'Reproduzir/Pausar',
			'companionRemote.remote.next' => 'Próximo',
			'companionRemote.remote.seekBack' => 'Retroceder',
			'companionRemote.remote.stop' => 'Parar',
			'companionRemote.remote.seekForward' => 'Avançar',
			'companionRemote.remote.volume' => 'Volume',
			'companionRemote.remote.volumeDown' => 'Diminuir',
			'companionRemote.remote.volumeUp' => 'Aumentar',
			'companionRemote.remote.fullscreen' => 'Ecrã inteiro',
			'companionRemote.remote.subtitles' => 'Legendas',
			'companionRemote.remote.audio' => 'Áudio',
			'companionRemote.remote.searchHint' => 'Pesquisar no computador...',
			'companionRemote.errors.noNetworkInterface' => 'Nenhuma interface de rede encontrada',
			'companionRemote.errors.authenticationFailed' => 'Falha na autenticação',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'Falha ao iniciar o servidor remoto: ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'Falha ao enviar o comando remoto: ${error}',
			'companionRemote.errors.joinTimedOut' => 'Tempo esgotado ao entrar na sessão',
			'companionRemote.errors.failedToConnectAnyAddress' => 'Falha ao ligar a qualquer endereço',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => 'Ligação perdida após ${attempts} tentativas',
			'companionRemote.errors.connectionLost' => 'Ligação perdida',
			'companionRemote.closedBeforeAuth' => 'A ligação foi encerrada antes da autenticação',
			'videoSettings.playbackSpeed' => 'Velocidade de reprodução',
			'videoSettings.normalSpeed' => 'Normal',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'Ativo (${duration})',
			'videoSettings.zoom' => 'Zoom',
			'videoSettings.sleepTimer' => 'Temporizador de suspensão',
			'videoSettings.audioSync' => 'Sincronização do áudio',
			'videoSettings.subtitleSync' => 'Sincronização das legendas',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.hdrUnsupported' => 'O HDR não está disponível aqui — o compositor do ambiente de trabalho ou a saída de vídeo não o suporta.',
			'videoSettings.hdrToneMapping' => 'Mapeamento de tons HDR',
			'videoSettings.hdrToneMappingCompositor' => 'Compositor',
			'videoSettings.hdrToneMappingCompositorDescription' => 'Passar os metadados HDR da origem e deixar que o compositor do ambiente de trabalho faça o mapeamento.',
			'videoSettings.hdrToneMappingPlayer' => 'Reprodutor',
			'videoSettings.hdrToneMappingPlayerDescription' => 'Mapear para o brilho máximo do ecrã no reprodutor e comunicar o resultado ao compositor.',
			'videoSettings.hdrToneMappingFailed' => 'Não foi possível alterar o mapeamento de tons HDR — o modo anterior continua ativo.',
			'videoSettings.audioOutput' => 'Saída de áudio',
			'videoSettings.performanceOverlay' => 'Painel de desempenho',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'Surround',
			'videoSettings.audioOutputSpatial' => 'Áudio espacial',
			'videoSettings.audioOutputStereo' => 'Estéreo',
			'videoSettings.audioNormalization' => 'Normalizar intensidade sonora',
			'videoSettings.audioNormalizationDisablesPassthrough' => 'Descodifica o áudio para PCM; a passagem direta fica desativada enquanto esta opção estiver ativa',
			'performanceOverlay.color' => 'Cor',
			'performanceOverlay.performance' => 'Desempenho',
			'performanceOverlay.buffer' => 'Buffer',
			'performanceOverlay.app' => 'Aplicação',
			'performanceOverlay.decoder' => 'Descodificador',
			'performanceOverlay.rawDecoder' => 'Descodificador bruto',
			'performanceOverlay.tunneling' => 'Túnel',
			'performanceOverlay.passthrough' => 'Passagem direta',
			'performanceOverlay.aspect' => 'Aspeto',
			'performanceOverlay.rotation' => 'Rotação',
			'performanceOverlay.dvSource' => 'Origem DV',
			'performanceOverlay.dvPath' => 'Caminho DV',
			'performanceOverlay.dvRouteDecoder' => 'Descodificador Dolby Vision',
			'performanceOverlay.dvRouteDecoderP81' => 'Descodificador Dolby Vision (P7→8.1)',
			'performanceOverlay.dvRouteBaseLayer' => 'Camada base',
			'performanceOverlay.dvRouteBaseLayerHdr10' => 'Camada base HDR10',
			'performanceOverlay.dvRouteBaseLayerHlg' => 'Camada base HLG',
			'performanceOverlay.dvRouteBaseLayerSdr' => 'Camada base SDR',
			'performanceOverlay.dvRouteReshaped' => 'Remodelagem RPU (gpu-next)',
			'performanceOverlay.p7Conversion' => 'Conv. P7',
			'performanceOverlay.sampleRate' => 'Taxa de amostragem',
			'performanceOverlay.pixelFormat' => 'Formato de pixel',
			'performanceOverlay.hwFormat' => 'Formato HW',
			'performanceOverlay.matrix' => 'Matriz',
			'performanceOverlay.primaries' => 'Primárias',
			'performanceOverlay.transfer' => 'Transferência',
			'performanceOverlay.renderFps' => 'FPS de renderização',
			'performanceOverlay.displayFps' => 'FPS do ecrã',
			'performanceOverlay.avSync' => 'Sincronização A/V',
			'performanceOverlay.dropped' => 'Descartados',
			'performanceOverlay.dvRpus' => 'DV RPUs',
			'performanceOverlay.dvRpuAverage' => 'Média DV RPU',
			'performanceOverlay.dvSampleAverage' => 'Média amostra DV',
			'performanceOverlay.maxLuma' => 'Luma máx.',
			'performanceOverlay.minLuma' => 'Luma mín.',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => 'Cache usada',
			'performanceOverlay.cacheLimit' => 'Limite da cache',
			'performanceOverlay.speed' => 'Velocidade',
			'performanceOverlay.player' => 'Reprodutor',
			'performanceOverlay.playMethod' => 'Método de reprodução',
			_ => null,
		} ?? switch (path) {
			'performanceOverlay.memory' => 'Memória',
			'performanceOverlay.uiFps' => 'UI FPS',
			'performanceOverlay.fps' => 'FPS',
			'performanceOverlay.decoderAndroidHw' => 'Android HW',
			'performanceOverlay.decoderNvidiaHw' => 'NVIDIA HW',
			'performanceOverlay.decoderQualcommHw' => 'Qualcomm HW',
			'performanceOverlay.decoderMediatekHw' => 'MediaTek HW',
			'performanceOverlay.decoderExynosHw' => 'Exynos HW',
			'performanceOverlay.decoderSoftware' => 'Software',
			'performanceOverlay.decoderHardware' => 'Hardware',
			'performanceOverlay.tunnelingActive' => 'Ativo',
			'performanceOverlay.dvRpuFailed' => ({required Object converted, required Object failures}) => '${converted} (${failures} com falha)',
			'externalPlayer.title' => 'Reprodutor externo',
			'externalPlayer.useExternalPlayer' => 'Usar reprodutor externo',
			'externalPlayer.useExternalPlayerDescription' => 'Abrir vídeos noutra aplicação',
			'externalPlayer.selectPlayer' => 'Selecionar reprodutor',
			'externalPlayer.customPlayers' => 'Reprodutores personalizados',
			'externalPlayer.systemDefault' => 'Predefinição do sistema',
			'externalPlayer.addCustomPlayer' => 'Adicionar reprodutor personalizado',
			'externalPlayer.playerName' => 'Nome do reprodutor',
			'externalPlayer.playerNameHint' => 'O meu reprodutor',
			'externalPlayer.playerCommand' => 'Comando',
			'externalPlayer.playerPackage' => 'Nome do pacote',
			'externalPlayer.playerUrlScheme' => 'Esquema de URL',
			'externalPlayer.off' => 'Desativado',
			'externalPlayer.launchFailed' => 'Falha ao abrir o reprodutor externo',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} não está instalado',
			'externalPlayer.playInExternalPlayer' => 'Reproduzir no reprodutor externo',
			'metadataEdit.editMetadata' => 'Editar...',
			'metadataEdit.screenTitle' => 'Editar metadados',
			'metadataEdit.basicInfo' => 'Informações básicas',
			'metadataEdit.artwork' => 'Imagens',
			'metadataEdit.advancedSettings' => 'Definições avançadas',
			'metadataEdit.title' => 'Título',
			'metadataEdit.sortTitle' => 'Título para ordenação',
			'metadataEdit.originalTitle' => 'Título original',
			'metadataEdit.releaseDate' => 'Data de lançamento',
			'metadataEdit.contentRating' => 'Classificação etária',
			'metadataEdit.studio' => 'Estúdio',
			'metadataEdit.tagline' => 'Slogan',
			'metadataEdit.summary' => 'Sinopse',
			'metadataEdit.poster' => 'Póster',
			'metadataEdit.background' => 'Imagem de fundo',
			'metadataEdit.logo' => 'Logótipo',
			'metadataEdit.squareArt' => 'Imagem quadrada',
			'metadataEdit.selectPoster' => 'Selecionar póster',
			'metadataEdit.selectBackground' => 'Selecionar imagem de fundo',
			'metadataEdit.selectLogo' => 'Selecionar logótipo',
			'metadataEdit.selectSquareArt' => 'Selecionar imagem quadrada',
			'metadataEdit.fromUrl' => 'A partir de URL',
			'metadataEdit.uploadFile' => 'Carregar ficheiro',
			'metadataEdit.enterImageUrl' => 'Introduza o URL da imagem',
			'metadataEdit.imageUrl' => 'URL da imagem',
			'metadataEdit.metadataUpdated' => 'Metadados atualizados',
			'metadataEdit.metadataUpdateFailed' => 'Falha ao atualizar os metadados',
			'metadataEdit.artworkUpdated' => 'Imagem atualizada',
			'metadataEdit.artworkUpdateFailed' => 'Falha ao atualizar a imagem',
			'metadataEdit.noArtworkAvailable' => 'Nenhuma imagem disponível',
			'metadataEdit.artworkOption' => ({required Object index}) => 'Opção de imagem ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => 'Opção de imagem ${index}, selecionada',
			'metadataEdit.notSet' => 'Não definido',
			'metadataEdit.libraryDefault' => 'Predefinição da biblioteca',
			'metadataEdit.accountDefault' => 'Predefinição da conta',
			'metadataEdit.seriesDefault' => 'Predefinição da série',
			'metadataEdit.episodeSorting' => 'Ordenação de episódios',
			'metadataEdit.oldestFirst' => 'Mais antigos primeiro',
			'metadataEdit.newestFirst' => 'Mais recentes primeiro',
			'metadataEdit.keep' => 'Manter',
			'metadataEdit.allEpisodes' => 'Todos os episódios',
			'metadataEdit.latestEpisodes' => ({required Object count}) => '${count} episódios mais recentes',
			'metadataEdit.latestEpisode' => 'Episódio mais recente',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => 'Episódios adicionados nos últimos ${count} dias',
			'metadataEdit.deleteAfterPlaying' => 'Eliminar episódios após reproduzir',
			'metadataEdit.never' => 'Nunca',
			'metadataEdit.afterADay' => 'Após um dia',
			'metadataEdit.afterAWeek' => 'Após uma semana',
			'metadataEdit.afterAMonth' => 'Após um mês',
			'metadataEdit.onNextRefresh' => 'Na próxima atualização',
			'metadataEdit.seasons' => 'Temporadas',
			'metadataEdit.show' => 'Mostrar',
			'metadataEdit.hide' => 'Ocultar',
			'metadataEdit.episodeOrdering' => 'Ordem dos episódios',
			'metadataEdit.tmdbAiring' => 'The Movie Database (Exibição)',
			'metadataEdit.tvdbAiring' => 'TheTVDB (Exibição)',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB (Absoluto)',
			'metadataEdit.metadataLanguage' => 'Idioma dos metadados',
			'metadataEdit.useOriginalTitle' => 'Usar título original',
			'metadataEdit.preferredAudioLanguage' => 'Idioma de áudio preferido',
			'metadataEdit.preferredSubtitleLanguage' => 'Idioma de legendas preferido',
			'metadataEdit.subtitleMode' => 'Modo de seleção automática de legendas',
			'metadataEdit.manuallySelected' => 'Seleção manual',
			'metadataEdit.shownWithForeignAudio' => 'Mostrar com áudio estrangeiro',
			'metadataEdit.alwaysEnabled' => 'Sempre ativado',
			'metadataEdit.tags' => 'Tags',
			'metadataEdit.addTag' => 'Adicionar tag',
			'metadataEdit.genre' => 'Género',
			'metadataEdit.director' => 'Realizador',
			'metadataEdit.writer' => 'Argumentista',
			'metadataEdit.producer' => 'Produtor',
			'metadataEdit.country' => 'País',
			'metadataEdit.collection' => 'Coleção',
			'metadataEdit.label' => 'Etiqueta',
			'metadataEdit.quickTag' => 'Tag rápida...',
			'matchScreen.match' => 'Associar...',
			'matchScreen.fixMatch' => 'Corrigir correspondência...',
			'matchScreen.unmatch' => 'Desassociar',
			'matchScreen.unmatchConfirm' => 'Limpar esta correspondência? O Plex tratará o item como sem correspondência até voltar a ser associado.',
			'matchScreen.unmatchSuccess' => 'Item desassociado',
			'matchScreen.unmatchFailed' => 'Falha ao desassociar o item',
			'matchScreen.matchApplied' => 'Correspondência aplicada',
			'matchScreen.matchFailed' => 'Falha ao aplicar a correspondência',
			'matchScreen.titleHint' => 'Título',
			'matchScreen.yearHint' => 'Ano',
			'matchScreen.search' => 'Pesquisar',
			'matchScreen.noMatchesFound' => 'Nenhuma correspondência encontrada',
			'serverTasks.title' => 'Tarefas do servidor',
			'serverTasks.failedToLoad' => 'Falha ao carregar as tarefas',
			'serverTasks.noTasks' => 'Nenhuma tarefa em execução',
			'trakt.title' => 'Trakt',
			'trakt.connected' => 'Ligado',
			'trakt.connectedAs' => ({required Object username}) => 'Ligado como @${username}',
			'trakt.disconnectConfirm' => 'Desligar a conta do Trakt?',
			'trakt.disconnectConfirmBody' => 'O Plezy deixará de enviar eventos para o Trakt. Pode voltar a ligar quando quiser.',
			'trakt.scrobble' => 'Scrobbling em tempo real',
			'trakt.scrobbleDescription' => 'Envia eventos de reprodução, pausa e paragem para o Trakt durante a visualização.',
			'trakt.watchedSync' => 'Sincronizar estado de visto',
			'trakt.watchedSyncDescription' => 'Ao marcar itens como vistos no Plezy, também serão marcados no Trakt.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Ligar ao Seerr',
			'seerr.serverUrl' => 'URL do servidor',
			'seerr.serverUrlHelper' => 'O endereço da sua instância do Seerr',
			'seerr.checkServer' => 'Continuar',
			'seerr.signInWithJellyfin' => 'Iniciar sessão com o Jellyfin',
			'seerr.signInWithEmby' => 'Iniciar sessão com o Emby',
			'seerr.signInWithLocal' => 'Usar uma conta local',
			'seerr.email' => 'E-mail',
			'seerr.noSignInMethods' => 'Esta instância do Seerr não oferece nenhum método de acesso compatível com o Plezy.',
			'seerr.instance' => 'Instância',
			'seerr.disconnectConfirm' => 'Desligar o Seerr?',
			'seerr.disconnectConfirmBody' => 'O Plezy esquecerá esta instância do Seerr. Volte a ligar quando quiser.',
			'seerr.request' => 'Pedir',
			'seerr.request4k' => 'Pedir em 4K',
			'seerr.seasons' => 'Temporadas',
			'seerr.allSeasons' => 'Todas as temporadas',
			'seerr.advancedOptions' => 'Avançado',
			'seerr.destinationServer' => 'Servidor de destino',
			'seerr.qualityProfile' => 'Perfil de qualidade',
			'seerr.rootFolder' => 'Pasta raiz',
			'seerr.languageProfile' => 'Perfil de idioma',
			'seerr.tags' => 'Etiquetas',
			'seerr.noTags' => 'Sem etiquetas',
			'seerr.defaultOption' => ({required Object name}) => '${name} (predefinido)',
			'seerr.animeNote' => 'Esta série é um anime.',
			'seerr.requestSubmitted' => 'Pedido enviado',
			'seerr.requestFailed' => ({required Object error}) => 'Falha no pedido: ${error}',
			'seerr.requestsLoadFailed' => 'Não foi possível carregar as opções de pedido',
			'seerr.nothingToRequest' => 'Tudo já está disponível ou foi pedido.',
			'seerr.statusAvailable' => 'Disponível',
			'seerr.statusPartiallyAvailable' => 'Parcialmente disponível',
			'seerr.statusRequested' => 'Pedido',
			'seerr.statusProcessing' => 'A processar',
			'seerr.statusBlocklisted' => 'Na lista de bloqueio',
			'seerr.couldNotReach' => ({required Object url, required Object error}) => 'Não foi possível contactar ${url}: ${error}',
			'seerr.noInstanceAtUrl' => ({required Object url, required Object status}) => 'Nenhuma instância do Seerr em ${url} (HTTP ${status})',
			'seerr.behindAuthProxy' => 'Um proxy inverso com autenticação (SSO ou autenticação HTTP) respondeu em vez do Seerr. O Plezy não consegue iniciar sessão através dele: permita que o caminho /api/v1 do Seerr ignore o proxy para esta aplicação, ou use um endereço que chegue diretamente ao Seerr.',
			'seerr.invalidUrl' => 'Introduza um endereço de servidor como https://seerr.example.com',
			'seerr.quickConnectUnsupported' => 'Esta instância do Seerr não suporta o Quick Connect. É necessário o Seerr 3.4 ou mais recente.',
			'seerr.notInitialized' => 'Esta instância do Seerr não concluiu a configuração inicial',
			'seerr.noPlexTokenForReauth' => 'Nenhum token do Plex disponível para voltar a iniciar sessão',
			'seerr.noStoredCredentials' => 'Nenhuma credencial guardada disponível para voltar a iniciar sessão',
			'seerr.signInRejected' => 'O início de sessão foi rejeitado',
			'seerr.noSessionCookie' => 'O Seerr não forneceu um cookie de sessão',
			'seerr.freshCookieRejected' => 'O Seerr rejeitou o novo cookie de sessão',
			'seerr.noUserInformation' => 'O Seerr não devolveu informações do utilizador',
			'seerr.sessionRejectedAfterReauth' => 'A sessão foi rejeitada depois de voltar a iniciar sessão',
			'seerr.permissionDenied' => 'O Seerr negou esta ação: a sua conta já não tem a permissão necessária',
			'seerr.permissionRevoked' => 'Já não tem permissão para pedir isto',
			'services.title' => 'Serviços',
			'services.hubSubtitle' => 'Sincronize o progresso de visualização e peça novos títulos.',
			'services.integrations' => 'Integrações',
			'services.notConnected' => 'Não ligado',
			'services.connectedAs' => ({required Object username}) => 'Ligado como @${username}',
			'services.scrobble' => 'Registar progresso automaticamente',
			'services.scrobbleDescription' => 'Atualiza a sua lista quando termina um episódio ou filme.',
			'services.disconnectConfirm' => ({required Object service}) => 'Desligar ${service}?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'O Plezy deixará de atualizar ${service}. Volte a ligar quando quiser.',
			'services.connectFailed' => ({required Object service}) => 'Não foi possível ligar ao ${service}. Tente novamente.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.simklReconnect.title' => 'Voltar a ligar o Simkl',
			'services.simklReconnect.subtitle' => 'O Simkl está a desativar o método de acesso usado por esta ligação. Ao voltar a ligar, o simkl.com será aberto para aprovar o Plezy — o Plezy nunca vê a sua palavra-passe. O seu histórico de visualização continua no Simkl.',
			'services.deviceCode.title' => ({required Object service}) => 'Ativar o Plezy no ${service}',
			'services.deviceCode.instructions' => 'Digitalize o código QR ou aceda ao endereço abaixo e introduza este código:',
			'services.deviceCode.openToActivate' => ({required Object service}) => 'Abrir ${service} para ativar',
			'services.deviceCode.copyCode' => 'Copiar código de ativação',
			'services.deviceCode.waitingForAuthorization' => 'A aguardar autorização…',
			'services.deviceCode.codeCopied' => 'Código copiado',
			'services.oauthProxy.title' => ({required Object service}) => 'Iniciar sessão no ${service}',
			'services.oauthProxy.body' => 'Digitalize este código QR ou abra o URL em qualquer dispositivo.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => 'Abrir ${service} para iniciar sessão',
			'services.pendingAuth.copyUrl' => 'Copiar URL de acesso',
			'services.pendingAuth.urlCopied' => 'URL copiado',
			'services.libraryFilter.title' => 'Filtro de bibliotecas',
			'services.libraryFilter.subtitleAllSyncing' => 'A sincronizar todas as bibliotecas',
			'services.libraryFilter.subtitleNoneSyncing' => 'Nada a sincronizar',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} bloqueadas',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} permitidas',
			'services.libraryFilter.mode' => 'Modo de filtro',
			'services.libraryFilter.modeBlacklist' => 'Lista de bloqueio',
			'services.libraryFilter.modeWhitelist' => 'Lista de permissões',
			'services.libraryFilter.modeHintBlacklist' => 'Sincronizar todas as bibliotecas, exceto as marcadas abaixo.',
			'services.libraryFilter.modeHintWhitelist' => 'Sincronizar apenas as bibliotecas marcadas abaixo.',
			'services.libraryFilter.libraries' => 'Bibliotecas',
			'services.libraryFilter.noLibraries' => 'Nenhuma biblioteca disponível',
			'addServer.addMediaBrowserTitle' => ({required Object product}) => 'Adicionar servidor ${product}',
			'addServer.serverUrls' => 'URLs do servidor',
			'addServer.serverUrlsHelper' => 'São permitidos vários URLs, separados por vírgulas.',
			'addServer.findServer' => 'Encontrar servidor',
			'addServer.searchingLocalMediaBrowserServers' => ({required Object product}) => 'A procurar servidores ${product} locais...',
			'addServer.localMediaBrowserServers' => ({required Object product}) => 'Servidores ${product} locais',
			'addServer.username' => 'Utilizador',
			'addServer.password' => 'Palavra-passe',
			'addServer.signIn' => 'Iniciar sessão',
			'addServer.change' => 'Alterar',
			'addServer.required' => 'Obrigatório',
			'addServer.couldNotReachServer' => ({required Object error}) => 'Não foi possível ligar ao servidor: ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'Falha ao iniciar sessão: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'O Quick Connect falhou: ${error}',
			'addServer.addPlexTitle' => 'Iniciar sessão com o Plex',
			'addServer.pinExpired' => 'O PIN expirou antes de iniciar sessão. Tente novamente.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'Falha ao registar a conta: ${error}',
			'addServer.enterMediaBrowserUrlError' => ({required Object product}) => 'Introduza o URL do seu servidor ${product}',
			'addServer.addConnectionTitle' => 'Adicionar ligação',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => 'Adicionar a ${name}',
			'addServer.signInWithPlexCard' => 'Iniciar sessão com o Plex',
			'addServer.signInWithPlexCardSubtitle' => 'Autorize este dispositivo. Os servidores partilhados são adicionados.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Autorize uma conta Plex. Os utilizadores do Plex Home tornam-se perfis.',
			'addServer.connectToMediaBrowserCard' => ({required Object product}) => 'Ligar ao ${product}',
			'addServer.connectToMediaBrowserCardSubtitle' => 'Introduza o URL do servidor, o nome de utilizador e a palavra-passe.',
			'addServer.connectToMediaBrowserCardSubtitleScoped' => ({required Object product, required Object name}) => 'Inicie sessão no seu servidor ${product}. Associado a ${name}.',
			'addServer.borrowFromAnotherProfile' => 'Usar a ligação de outro perfil',
			'addServer.borrowFromAnotherProfileSubtitle' => 'Reutilize a ligação de outro perfil. Os perfis protegidos por PIN exigem o PIN.',
			'addServer.invalidCredentials' => 'Utilizador ou palavra-passe inválidos',
			'addServer.authResponseNotJson' => 'A resposta de autenticação não era um JSON válido',
			'addServer.authResponseIncomplete' => 'A resposta de início de sessão do servidor estava incompleta',
			'addServer.quickConnectRejected' => 'O Quick Connect foi rejeitado pelo servidor',
			'addServer.quickConnectNotJson' => 'A resposta do Quick Connect não era um JSON válido',
			'addServer.quickConnectMissingFields' => 'A resposta do Quick Connect não contém um código ou segredo',
			'addServer.quickConnectPollRejected' => 'A consulta do Quick Connect foi rejeitada pelo servidor',
			'addServer.serverTimedOut' => 'O servidor não respondeu a tempo',
			'addServer.responseNotJson' => 'A resposta do servidor não era um JSON válido',
			'addServer.responseMissingIdentity' => ({required Object product}) => 'A resposta não contém um ID ou nome de servidor — este é um servidor ${product}?',
			'addServer.probeFailed' => ({required Object error}) => 'Não foi possível ligar ao servidor: ${error}',
			'addServer.enterAtLeastOneUrl' => ({required Object product}) => 'Introduza pelo menos um URL de servidor ${product}',
			'addServer.noReachableServer' => ({required Object product}) => 'Nenhum servidor ${product} acessível foi encontrado',
			'addServer.urlsPointToDifferentServers' => ({required Object product}) => 'Estes URLs apontam para servidores ${product} diferentes',
			'addServer.urlDoesNotMatchServer' => ({required Object product}) => 'Este URL não corresponde ao servidor ${product}',
			'addServer.redirectUnsupported' => 'O servidor redirecionou para um URL não suportado',
			'addServer.redirectDifferentHost' => ({required Object product}) => 'O servidor redirecionou para outro anfitrião. Introduza diretamente o URL final do ${product}.',
			'addServer.redirectInsecure' => 'O servidor redirecionou de HTTPS para um URL inseguro',
			'addServer.redirectUnsupportedEnterFinal' => ({required Object product}) => 'O servidor redirecionou para um URL não suportado. Introduza diretamente o URL final do ${product}.',
			'deepLinks.invalid' => 'Este link do Plezy não é válido.',
			'deepLinks.profileNotFound' => ({required Object profile}) => 'Nenhum perfil corresponde a "${profile}".',
			'deepLinks.serverUnavailable' => 'Não foi possível contactar o servidor deste link.',
			'deepLinks.notFound' => 'Não foi possível encontrar este título nas suas bibliotecas.',
			'deepLinks.unsupportedItem' => 'Este link não pode ser reproduzido.',
			'deepLinks.noLiveTv' => 'Nenhum servidor de TV em direto está disponível para este link.',
			'deepLinks.channelNotFound' => ({required Object channel}) => 'Não foi possível encontrar o canal "${channel}".',
			'deepLinks.showLink' => 'Mostrar link',
			'deepLinks.showProfileLink' => 'Mostrar link do perfil',
			'deepLinks.dialogTitle' => 'Link',
			'deepLinks.showHint' => 'Abrir este link reproduz o próximo episódio. Adicione &mode=shuffle para reproduzir a série em modo aleatório.',
			'deepLinks.movieHint' => 'Abrir este link reproduz o filme.',
			'deepLinks.episodeHint' => 'Abrir este link reproduz este episódio.',
			'deepLinks.profileHint' => 'Abrir este link muda para este perfil.',
			'deepLinks.openAsProfile' => ({required Object name}) => 'Abrir como ${name}',
			'deepLinks.copy' => 'Copiar',
			'deepLinks.copied' => 'Link copiado',
			_ => null,
		};
	}
}
