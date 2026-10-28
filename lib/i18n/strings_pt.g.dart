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
class TranslationsPt extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsPt({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.pt,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <pt>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsPt _root = this; // ignore: unused_field

	@override 
	TranslationsPt $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsPt(meta: meta ?? this.$meta);

	// Translations
	@override late final Translations$app$pt app = Translations$app$pt.internal(_root);
	@override late final Translations$appIcon$pt appIcon = Translations$appIcon$pt.internal(_root);
	@override late final Translations$auth$pt auth = Translations$auth$pt.internal(_root);
	@override late final Translations$common$pt common = Translations$common$pt.internal(_root);
	@override late final Translations$screens$pt screens = Translations$screens$pt.internal(_root);
	@override late final Translations$update$pt update = Translations$update$pt.internal(_root);
	@override late final Translations$settings$pt settings = Translations$settings$pt.internal(_root);
	@override late final Translations$themeEditor$pt themeEditor = Translations$themeEditor$pt.internal(_root);
	@override late final Translations$search$pt search = Translations$search$pt.internal(_root);
	@override late final Translations$hotkeys$pt hotkeys = Translations$hotkeys$pt.internal(_root);
	@override late final Translations$fileInfo$pt fileInfo = Translations$fileInfo$pt.internal(_root);
	@override late final Translations$mediaMenu$pt mediaMenu = Translations$mediaMenu$pt.internal(_root);
	@override late final Translations$rateSheet$pt rateSheet = Translations$rateSheet$pt.internal(_root);
	@override late final Translations$accessibility$pt accessibility = Translations$accessibility$pt.internal(_root);
	@override late final Translations$tooltips$pt tooltips = Translations$tooltips$pt.internal(_root);
	@override late final Translations$audioTracks$pt audioTracks = Translations$audioTracks$pt.internal(_root);
	@override late final Translations$videoControls$pt videoControls = Translations$videoControls$pt.internal(_root);
	@override late final Translations$messages$pt messages = Translations$messages$pt.internal(_root);
	@override late final Translations$subtitlingStyling$pt subtitlingStyling = Translations$subtitlingStyling$pt.internal(_root);
	@override late final Translations$mpvConfig$pt mpvConfig = Translations$mpvConfig$pt.internal(_root);
	@override late final Translations$dialog$pt dialog = Translations$dialog$pt.internal(_root);
	@override late final Translations$profiles$pt profiles = Translations$profiles$pt.internal(_root);
	@override late final Translations$connections$pt connections = Translations$connections$pt.internal(_root);
	@override late final Translations$accountPreferences$pt accountPreferences = Translations$accountPreferences$pt.internal(_root);
	@override late final Translations$discover$pt discover = Translations$discover$pt.internal(_root);
	@override late final Translations$errors$pt errors = Translations$errors$pt.internal(_root);
	@override late final Translations$libraries$pt libraries = Translations$libraries$pt.internal(_root);
	@override late final Translations$about$pt about = Translations$about$pt.internal(_root);
	@override late final Translations$serverSelection$pt serverSelection = Translations$serverSelection$pt.internal(_root);
	@override late final Translations$hubDetail$pt hubDetail = Translations$hubDetail$pt.internal(_root);
	@override late final Translations$logs$pt logs = Translations$logs$pt.internal(_root);
	@override late final Translations$startup$pt startup = Translations$startup$pt.internal(_root);
	@override late final Translations$licenses$pt licenses = Translations$licenses$pt.internal(_root);
	@override late final Translations$navigation$pt navigation = Translations$navigation$pt.internal(_root);
	@override late final Translations$explore$pt explore = Translations$explore$pt.internal(_root);
	@override late final Translations$liveTv$pt liveTv = Translations$liveTv$pt.internal(_root);
	@override late final Translations$collections$pt collections = Translations$collections$pt.internal(_root);
	@override late final Translations$playlists$pt playlists = Translations$playlists$pt.internal(_root);
	@override late final Translations$music$pt music = Translations$music$pt.internal(_root);
	@override late final Translations$watchTogether$pt watchTogether = Translations$watchTogether$pt.internal(_root);
	@override late final Translations$downloads$pt downloads = Translations$downloads$pt.internal(_root);
	@override late final Translations$shaders$pt shaders = Translations$shaders$pt.internal(_root);
	@override late final Translations$companionRemote$pt companionRemote = Translations$companionRemote$pt.internal(_root);
	@override late final Translations$videoSettings$pt videoSettings = Translations$videoSettings$pt.internal(_root);
	@override late final Translations$performanceOverlay$pt performanceOverlay = Translations$performanceOverlay$pt.internal(_root);
	@override late final Translations$externalPlayer$pt externalPlayer = Translations$externalPlayer$pt.internal(_root);
	@override late final Translations$metadataEdit$pt metadataEdit = Translations$metadataEdit$pt.internal(_root);
	@override late final Translations$matchScreen$pt matchScreen = Translations$matchScreen$pt.internal(_root);
	@override late final Translations$serverTasks$pt serverTasks = Translations$serverTasks$pt.internal(_root);
	@override late final Translations$trakt$pt trakt = Translations$trakt$pt.internal(_root);
	@override late final Translations$seerr$pt seerr = Translations$seerr$pt.internal(_root);
	@override late final Translations$services$pt services = Translations$services$pt.internal(_root);
	@override late final Translations$addServer$pt addServer = Translations$addServer$pt.internal(_root);
	@override late final Translations$cast$pt cast = Translations$cast$pt.internal(_root);
	@override late final Translations$automation$pt automation = Translations$automation$pt.internal(_root);
	@override late final Translations$notifications$pt notifications = Translations$notifications$pt.internal(_root);
	@override late final Translations$appAccess$pt appAccess = Translations$appAccess$pt.internal(_root);
	@override late final Translations$detail$pt detail = Translations$detail$pt.internal(_root);
	@override late final Translations$watchLink$pt watchLink = Translations$watchLink$pt.internal(_root);
	@override late final Translations$homeLayout$pt homeLayout = Translations$homeLayout$pt.internal(_root);
	@override late final Translations$platform$pt platform = Translations$platform$pt.internal(_root);
	@override late final Translations$universalMedia$pt universalMedia = Translations$universalMedia$pt.internal(_root);
	@override late final Translations$fileSources$pt fileSources = Translations$fileSources$pt.internal(_root);
	@override late final Translations$lending$pt lending = Translations$lending$pt.internal(_root);
	@override late final Translations$audiobook$pt audiobook = Translations$audiobook$pt.internal(_root);
	@override late final Translations$sourceSetup$pt sourceSetup = Translations$sourceSetup$pt.internal(_root);
	@override late final Translations$comics$pt comics = Translations$comics$pt.internal(_root);
	@override late final Translations$games$pt games = Translations$games$pt.internal(_root);
	@override late final Translations$deepLinks$pt deepLinks = Translations$deepLinks$pt.internal(_root);
}

// Path: app
class Translations$app$pt extends Translations$app$en {
	Translations$app$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'PlezyNG';
}

// Path: appIcon
class Translations$appIcon$pt extends Translations$appIcon$en {
	Translations$appIcon$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ícone do app';
	@override String get defaultIcon => 'Padrão';
	@override String get current => 'Ícone atual';
	@override String get locked => 'Acesso ao tempo necessário';
	@override String get lockedHint => 'Comece o seu teste de 7 dias ou desbloquee PlezyNG para a vida para usar ícones alternativos.';
	@override String get changeFailed => 'Não foi possível alterar o ícone do app';
	@override String get launcherHint => 'O novo ícone aparece na tela inicial assim que você sair do PlezyNG.';
	@override String get tvLauncherHint => 'O novo banner aparece assim que você sair do PlezyNG. O Android TV pode continuar mostrando o antigo até a TV ser reiniciada.';
	@override late final Translations$appIcon$names$pt names = Translations$appIcon$names$pt.internal(_root);
	@override String get description => 'Escolha o ícone mostrado pelo seu lançador de dispositivo. as previsões mostram como cada opção parece.';
}

// Path: auth
class Translations$auth$pt extends Translations$auth$en {
	Translations$auth$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Entrar com Plex';
	@override String get showQRCode => 'Mostrar código QR';
	@override String get authenticate => 'Autenticar';
	@override String get authenticationTimeout => 'A autenticação expirou. Tente novamente.';
	@override String get scanQRToSignIn => 'Leia este código QR para entrar';
	@override String get waitingForAuth => 'Aguardando autenticação...\nEntre pelo navegador.';
	@override String get useBrowser => 'Usar navegador';
	@override String get or => 'ou';
	@override String connectToMediaBrowser({required Object product}) => 'Conectar ao ${product}';
	@override String get quickConnect => 'Quick Connect';
	@override String get useQuickConnect => 'Usar Quick Connect';
	@override String get quickConnectInstructions => 'Abra o Quick Connect no Jellyfin e insira este código.';
	@override String get quickConnectWaiting => 'Aguardando aprovação…';
	@override String get quickConnectCancel => 'Cancelar';
	@override String get quickConnectExpired => 'Quick Connect expirou. Tente novamente.';
	@override String get localDataRecoveryRequired => 'O PlezyNG não conseguiu recuperar com segurança os dados locais de acesso e de reproduções pendentes. Entre novamente.';
	@override String get pinCheckRejected => 'A verificação do PIN do Plex foi rejeitada';
	@override String get connectToDirectPlex => 'Conecte-se ao servidor local Plex';
}

// Path: common
class Translations$common$pt extends Translations$common$en {
	Translations$common$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Cancelar';
	@override String get save => 'Salvar';
	@override String get close => 'Fechar';
	@override String get closeMiniPlayer => 'Mini jogador próximo';
	@override String get closeWorkspaceWindow => 'janela próxima';
	@override String get returnToFullView => 'Voltar para a vista completa';
	@override String get manageMediaSessions => 'Gestão de sessões de mídia';
	@override String get hideMediaSessions => 'Esconde sessões de mídia';
	@override String get mediaSessions => 'Sessões de mídia';
	@override String get mediaSessionsHint => 'Selecione para trazer uma sessão adiante.Park esconde a janela, mas mantém-a aberta.Retorno abre em vista completo; perto termina.';
	@override String get sessionInWorkspace => 'No espaço de trabalho';
	@override String get sessionParked => 'Estacionamento';
	@override String get sessionFullscreen => 'Ecrã completa';
	@override String get switchToNextWindow => 'Swap com a próxima janela';
	@override String get moveWindow => 'Move janela';
	@override String get finishMovingWindow => 'Fim da janela em movimento';
	@override String get moveWindowHint => 'Pressione e traça a janela para movê-la. Este controle também permite o movimento de chave da arca.';
	@override String get movingWindowHelp => 'Drag to move · Arrow keys adjust · Enter saves · Escape canceles';
	@override String get resizeWindow => 'Revisão janela';
	@override String get resizeWindowHint => 'Coloque esta mão ou use as chaves da arca para redirecionar a janela.';
	@override String get workspaceWindowHint => 'Use o controle de movimento ou a pressão longa e traça para se mover.';
	@override String get workspacePaneHint => 'Selecione este painel para focá-lo. Use seu controle de tela completa para expandir.';
	@override String workspaceWindowLabel({required Object title}) => 'janela de sessão: ${title}';
	@override String get workspaceTitleHint => 'Tire a barra de título para se mover; use o botão de tela completa para expandir.';
	@override String get moveToSessionTray => 'Mover para sessão tray';
	@override String get moveToSessionTrayHint => 'Esta sessão está disponível sem mostrar a sua janela.';
	@override String get closeSessionHint => 'Feche esta janela e termina a sessão.';
	@override String get sideBySideLayout => 'Switch para layout lado a lado';
	@override String get floatingWindows => 'Switch para fluir janelas';
	@override String get clear => 'Limpar';
	@override String get reset => 'Redefinir';
	@override String get later => 'Depois';
	@override String get submit => 'Enviar';
	@override String get confirm => 'Confirmar';
	@override String get retry => 'Tentar novamente';
	@override String get logout => 'Sair';
	@override String get unknown => 'Desconhecido';
	@override String get refresh => 'Atualizar';
	@override String get yes => 'Sim';
	@override String get no => 'Não';
	@override String get delete => 'Excluir';
	@override String get edit => 'Editar';
	@override String get shuffle => 'Aleatório';
	@override String get addTo => 'Adicionar a...';
	@override String get createNew => 'Criar novo';
	@override String get connect => 'Conectar';
	@override String get disconnect => 'Desconectar';
	@override String get play => 'Reproduzir';
	@override String get pause => 'Pausar';
	@override String get resume => 'Retomar';
	@override String get error => 'Erro';
	@override String get search => 'Buscar';
	@override String get home => 'Início';
	@override String get back => 'Voltar';
	@override String get settings => 'Configurações';
	@override String get mute => 'Silenciar';
	@override String get ok => 'OK';
	@override String get off => 'Desativado';
	@override String get options => 'Opções';
	@override String seasonNumber({required Object number}) => 'Temporada ${number}';
	@override String episodeNumberTitle({required Object number, required Object title}) => 'Episódio ${number} - ${title}';
	@override String chapterNumber({required Object number}) => 'Capítulo ${number}';
	@override String get reconnect => 'Reconectar';
	@override String get viewAll => 'Ver tudo';
	@override String get checkingNetwork => 'Verificando rede...';
	@override String get loadingServers => 'Carregando servidores...';
	@override String get connectingToServers => 'Conectando aos servidores...';
	@override String get startingOfflineMode => 'Iniciando modo offline...';
	@override String get loading => 'Carregando...';
	@override String get fullscreen => 'Tela cheia';
	@override String get exitFullscreen => 'Sair da tela cheia';
	@override String get pressBackAgainToExit => 'Pressione voltar novamente para sair';
	@override late final Translations$common$ratingSource$pt ratingSource = Translations$common$ratingSource$pt.internal(_root);
	@override String get notAvailable => 'N/D';
	@override String get url => 'URL';
	@override String get letterKeys => 'ABC';
	@override late final Translations$common$mediaKind$pt mediaKind = Translations$common$mediaKind$pt.internal(_root);
}

// Path: screens
class Translations$screens$pt extends Translations$screens$en {
	Translations$screens$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Licenças';
	@override String get switchProfile => 'Trocar Perfil';
	@override String get subtitleStyling => 'Estilo de Legendas';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Logs';
}

// Path: update
class Translations$update$pt extends Translations$update$en {
	Translations$update$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get available => 'Atualização disponível';
	@override String versionAvailable({required Object version}) => 'A versão ${version} está disponível';
	@override String currentVersion({required Object version}) => 'Atual: ${version}';
	@override String get skipVersion => 'Pular esta versão';
	@override String get viewRelease => 'Ver Lançamento';
	@override String get latestVersion => 'Você está na versão mais recente';
	@override String get checkFailed => 'Falha ao verificar atualizações';
}

// Path: settings
class Translations$settings$pt extends Translations$settings$en {
	Translations$settings$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Configurações';
	@override String get supportDeveloper => 'Apoie o PlezyNG';
	@override String get supportDeveloperDescription => 'Doe para apoiar o desenvolvimento';
	@override String get lifetimeAccess => 'PlezyNG acesso ao tempo de vida';
	@override String get language => 'Idioma';
	@override String get theme => 'Tema';
	@override String get appearance => 'Aparência';
	@override String get detailPage => 'Página detalhado';
	@override String get themeSongsEnabled => 'Jogue canções temáticas';
	@override String get themeSongsEnabledDescription => 'Jogue músicas temáticas disponíveis enquanto vê detalhes de mídia.';
	@override String get themeSongVolume => 'Título: Canção Volume';
	@override String get videoPlayback => 'Reprodução de Vídeo';
	@override String get videoPlaybackDescription => 'Configurar comportamento de reprodução';
	@override String get advanced => 'Avançado';
	@override String get episodePosterMode => 'Estilo do pôster do episódio';
	@override String get seriesPoster => 'Pôster da série';
	@override String get seasonPoster => 'Pôster da temporada';
	@override String get episodeThumbnail => 'Miniatura';
	@override String get showHeroSectionDescription => 'Exibir carrossel de conteúdo em destaque na tela inicial';
	@override String get secondsLabel => 'Segundos';
	@override String get minutesLabel => 'Minutos';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => 'Insira a duração (${min}-${max})';
	@override String get systemTheme => 'Sistema';
	@override String get lightTheme => 'Claro';
	@override String get darkTheme => 'Escuro';
	@override String get oledTheme => 'OLED';
	@override String get emberTheme => 'Brasa';
	@override String get glacierTheme => 'Geleira';
	@override String get forestTheme => 'Floresta';
	@override String get plumTheme => 'Ameixa';
	@override String get paperTheme => 'Papel';
	@override String get libraryDensity => 'Densidade da Biblioteca';
	@override String get displayScale => 'Escala de exibição';
	@override String get compact => 'Compacto';
	@override String get comfortable => 'Confortável';
	@override String get gridSpacing => 'Espaçamento da grade';
	@override String get gridSpacingTight => 'Compacto';
	@override String get gridSpacingNormal => 'Normal';
	@override String get gridSpacingSpacious => 'Espaçoso';
	@override String get tvCornerSpotlightBackdrop => 'Imagem de destaque no canto';
	@override String get tvCornerSpotlightBackdropDescription => 'Mostrar a imagem de destaque no canto superior direito em vez de preencher a tela';
	@override String get viewMode => 'Modo de Visualização';
	@override String get gridView => 'Grade';
	@override String get listView => 'Lista';
	@override String get showHeroSection => 'Mostrar Seção de Destaque';
	@override String get showHomeBackdrop => 'Mostrar arte de backdrop';
	@override String get showHomeBackdropDescription => 'Mostrar grandes obras de arte por trás feitas em ramas de casa';
	@override String get contentScreensaverEnabled => 'Conteúdo de screensaver';
	@override String get contentScreensaverEnabledDescription => 'Mostrar arte em tela completa depois que o aplicativo foi idle';
	@override String get contentScreensaverDelay => 'Comece a monitorar depois';
	@override String get contentScreensaverLibraries => 'Escreensaver bibliotecas';
	@override String get contentScreensaverLibrariesDescription => 'Escolha as bibliotecas que fornecem imagens para a proteção de ecrã. Se não selecionar nenhuma, serão usadas imagens de todas as bibliotecas.';
	@override String get contentScreensaverAllLibraries => 'Todas as bibliotecas';
	@override String contentScreensaverSelectedLibraries({required Object count}) => '${count} bibliotecas selecionadas';
	@override String get contentScreensaverNoLibraries => 'Não há bibliotecas de mídia conectadas.';
	@override String get contentScreensaverDismissHint => 'Pressione qualquer botão ou toque para desistir';
	@override String get newEpisodeNotifications => 'Novos episódios de notificação';
	@override String get newEpisodeNotificationsDescription => 'Alerta quando um novo episódio é adicionado a um show que você está capturado. verifica enquanto Plezy está aberto.';
	@override String get continueWatchingRowSize => 'Continue a ver o tamanho da linha';
	@override String continueWatchingRowSizeValue({required Object label}) => '${label} cartões';
	@override String get rowSizeCompact => 'Compacto';
	@override String get rowSizeStandard => 'padrão';
	@override String get rowSizeLarge => 'Grande';
	@override String get continueWatchingAction => 'Ação da seção Continuar assistindo';
	@override String get continueWatchingPlay => 'Reproduzir';
	@override String get continueWatchingDetails => 'Abrir detalhes';
	@override String get episodeAction => 'Ação do episódio';
	@override String get episodePlay => 'Reproduzir';
	@override String get episodeDetails => 'Abrir detalhes';
	@override String get useGlobalHubs => 'Usar layout inicial';
	@override String get useGlobalHubsDescription => 'Mostrar hubs iniciais unificados. Caso contrário, usar recomendações da biblioteca.';
	@override String get showServerNameOnHubs => 'Mostrar Nome do Servidor nos Hubs';
	@override String get showServerNameOnHubsDescription => 'Sempre mostrar nomes dos servidores nos títulos dos hubs.';
	@override String get groupLibrariesByServer => 'Agrupar Bibliotecas por Servidor';
	@override String get groupLibrariesByServerDescription => 'Agrupar bibliotecas da barra lateral por servidor de mídia.';
	@override String get alwaysKeepSidebarOpen => 'Manter Barra Lateral Sempre Aberta';
	@override String get alwaysKeepSidebarOpenDescription => 'A barra lateral fica expandida e a área de conteúdo se ajusta';
	@override String get showUnwatchedCount => 'Mostrar Contagem de Não Assistidos';
	@override String get showUnwatchedCountDescription => 'Exibir contagem de episódios não assistidos em séries e temporadas';
	@override String get showWatchedIndicators => 'Mostrar Indicadores de Assistidos';
	@override String get showWatchedIndicatorsDescription => 'Exibir uma marca de verificação em filmes, séries e episódios assistidos';
	@override String get showEpisodeNumberOnCards => 'Mostrar Número do Episódio nos Cards';
	@override String get showEpisodeNumberOnCardsDescription => 'Mostrar temporada e episódio nos cartões de episódio';
	@override String get showSeasonPostersOnTabs => 'Mostrar Pôsteres de Temporada nas Abas';
	@override String get showSeasonPostersOnTabsDescription => 'Mostrar o pôster de cada temporada acima da aba';
	@override String get tvFullCardLayout => 'Cartões TV completos';
	@override String get tvFullCardLayoutDescription => 'Usar cartões de TV só com imagem e nomes dos atores sobrepostos';
	@override String get focusGlow => 'Brilho de foco';
	@override String get focusGlowDescription => 'Mostrar um brilho suave ao redor do cartão em foco';
	@override String get visualEffects => 'Efeitos visuais';
	@override String get visualEffectsAuto => 'Automático';
	@override String get visualEffectsAutoDescription => 'Reduzir os efeitos automaticamente em dispositivos de baixo consumo';
	@override String get visualEffectsFull => 'Completos';
	@override String get visualEffectsReduced => 'Reduzidos';
	@override String get visualEffectsReducedDescription => 'Menos animações e imagens em menor resolução';
	@override String get hideSpoilers => 'Ocultar spoilers de episódios não assistidos';
	@override String get hideSpoilersDescription => 'Desfocar miniaturas e descrições de episódios não assistidos';
	@override String get playerBackend => 'Mecanismo de reprodução';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'Decodificação por Hardware';
	@override String get hardwareDecodingDescription => 'Usar aceleração por hardware quando disponível';
	@override String get playbackBuffer => 'Buffer de reprodução';
	@override String get playbackBufferAuto => 'Automático (recomendado)';
	@override String get playbackBufferLarge => 'Grande';
	@override String get playbackBufferExtraLarge => 'Extra grande';
	@override String get playbackBufferDescription => 'Faz buffer extra contra conexões instáveis. Também limitado pelo tamanho do buffer.';
	@override String get streamBufferSize => 'Baixão de tamanho';
	@override String streamBufferSizeValue({required Object size}) => '${size} MB';
	@override String get streamBufferSizeDescription => 'Quanto vídeo para carregar em frente ao jogar diretamente. transcodes param no próprio buffer de transcódigo do servidor. 0 = Auto';
	@override String get streamBufferSizeExoNote => 'Repasa o Playback Buffer quando configurado, captado na metade do limite de memória da aplicação';
	@override String get streamBufferMegabytes => 'Megabytes';
	@override String get defaultQualityTitle => 'Qualidade padrão';
	@override String get cellularQualityTitle => 'Qualidade padrão nos dados móveis';
	@override String get remoteQualityTitle => 'Qualidade de streaming remoto';
	@override String get remoteQualitySameAsDefault => 'Como a qualidade padrão';
	@override String get cellularQualitySameAsDefault => 'Igual à qualidade padrão';
	@override String get directPlayCoveredQuality => 'Reproduzir Vídeos Menores na Qualidade Original';
	@override String get directPlayCoveredQualityDescription => 'Reproduzir diretamente os vídeos que já estão dentro do limite de qualidade em vez de transcodificá-los';
	@override String get videoCodecs => 'Codecs de vídeo';
	@override String get videoCodecsDescription => 'Codecs desmarcados são transcodificados pelo servidor';
	@override String get videoCodecsAlwaysAccepted => 'Sempre aceito';
	@override String get musicQualityTitle => 'Qualidade da música';
	@override String get subtitleStyling => 'Estilo de Legendas';
	@override String get subtitleStylingDescription => 'Personalizar aparência das legendas';
	@override String get smallSkipDuration => 'Duração do Avanço Curto';
	@override String get largeSkipDuration => 'Duração do Avanço Longo';
	@override String get rewindOnResume => 'Rebobinar ao retomar';
	@override String secondsUnit({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(seconds,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} segundo',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} segundos',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} segundos',
	);
	@override String get defaultSleepTimer => 'Temporizador de suspensão padrão';
	@override String minutesUnit({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(minutes,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minuto',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minutos',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minutos',
	);
	@override String get rememberTrackSelections => 'Lembrar seleção de faixas por série/filme';
	@override String get chooseTracksBeforePlayback => 'Escolha áudio e subtitulos antes de reproduzir';
	@override String get chooseTracksBeforePlaybackDescription => 'Selecione a fonte de áudio e subtítulos antes de cada vídeo começar.';
	@override String get alwaysShowSubtitlesOnDevice => 'Sempre exibir subtitulos neste dispositivo';
	@override String get alwaysShowSubtitlesOnDeviceDescription => 'Quando o servidor não tem nenhum subtítulo selecionado, escolha uma pista localmente.';
	@override String get autoDownloadPreferredSubtitle => 'Feches de subtitulos preferidos';
	@override String get autoDownloadPreferredSubtitleDescription => 'Selecione um subtítulo disponível em seu idioma preferido localmente.Se nenhum existe, peça ao servidor que encontre um quando suportado.';
	@override String get rememberTrackSelectionsDescription => 'Lembrar escolhas de áudio e legendas por título';
	@override String get rememberTrackSelectionsBackendRule => 'O Plex salva cada escolha no servidor por arquivo; o Jellyfin também ativa a opção Lembrar seleções da conta; o Emby não é compatível';
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
	@override String get clickVideoTogglesPlaybackDescription => 'Clicar no vídeo para reproduzir ou pausar em vez de mostrar os controles.';
	@override String get videoPlayerControls => 'Controles do reprodutor de vídeo';
	@override String get keyboardShortcuts => 'Atalhos de Teclado';
	@override String get keyboardShortcutsDescription => 'Personalizar atalhos de teclado';
	@override String get videoPlayerNavigation => 'Navegação do reprodutor de vídeo';
	@override String get videoPlayerNavigationDescription => 'Usar as teclas de seta para navegar pelos controles do reprodutor';
	@override String get watchTogetherRelay => 'Servidor de retransmissão do Assistir Juntos';
	@override String get watchTogetherRelayDescription => 'Servidores de retransmissão públicos do Open Watch Party, a menos que você defina o seu';
	@override String get watchTogetherRelayHint => 'https://minha-retransmissao.exemplo.com.br';
	@override String get watchTogetherRelayInvalid => 'Insira uma URL base de retransmissão HTTP ou HTTPS válida.';
	@override String get crashReporting => 'Relatório de Erros';
	@override String get crashReportingDescription => 'Enviar relatórios de erros para ajudar a melhorar o app';
	@override String get debugLogging => 'Log de Depuração';
	@override String get debugLoggingDescription => 'Ativar log detalhado para solução de problemas';
	@override String get viewLogs => 'Ver Logs';
	@override String get viewLogsDescription => 'Ver logs do app';
	@override String get clearImageCache => 'Limpar cache de imagens';
	@override String get clearImageCacheDescription => 'Limpar artes e miniaturas em cache. As imagens podem carregar mais devagar até serem baixadas novamente.';
	@override String get clearImageCacheSuccess => 'Cache de imagens limpo com sucesso';
	@override String get resetSettings => 'Redefinir Configurações';
	@override String get resetSettingsDescription => 'Restaurar configurações padrão. Não pode ser desfeito.';
	@override String get resetSettingsSuccess => 'Configurações redefinidas com sucesso';
	@override String get backup => 'Backup';
	@override String get exportSettings => 'Exportar Configurações';
	@override String get exportSettingsDescription => 'Salvar suas preferências em um arquivo';
	@override String get exportSettingsSuccess => 'Configurações exportadas';
	@override String get importSettings => 'Importar Configurações';
	@override String get importSettingsDescription => 'Restaurar preferências a partir de um arquivo';
	@override String get importSettingsConfirm => 'Isso substituirá suas configurações atuais. Continuar?';
	@override String get importSettingsSuccess => 'Configurações importadas';
	@override String get importSettingsInvalidFile => 'Este arquivo não é uma exportação válida do PlezyNG';
	@override String get importSettingsNoUser => 'Entre na conta antes de importar as configurações';
	@override String get cloudBackup => 'Nuvem Backup';
	@override String get cloudBackupDescription => 'Faça backup das configurações transferíveis em um endereço WebDAV por HTTPS. As conexões aos servidores e as credenciais permanecem neste dispositivo.';
	@override String get cloudBackupUrl => 'WebDAV URL do arquivo JSON';
	@override String get cloudBackupUsername => 'Usuário';
	@override String get cloudBackupPassword => 'Senha';
	@override String get cloudBackupSaved => 'Cloud Backup Destino Salvo';
	@override String get cloudBackupNow => 'Voltar agora';
	@override String get cloudBackupComplete => 'Configuração de backup upload';
	@override String get cloudBackupRestore => 'Restauração de backup';
	@override String get cloudBackupRestoreConfirm => 'Isso substituirá as configurações portáteis correspondentes neste dispositivo.';
	@override String get cloudBackupRestored => 'Atualização de configurações recuperadas da backup da nuvem';
	@override String get shortcutsReset => 'Atalhos redefinidos para o padrão';
	@override String get resetShortcutsConfirm => 'Isso substituirá seus atalhos personalizados pelos padrões. Continuar?';
	@override String get about => 'Sobre';
	@override String get aboutDescription => 'Informações do app e licenças';
	@override String get updates => 'Atualizações';
	@override String get updateAvailable => 'Atualização Disponível';
	@override String get checkForUpdates => 'Verificar Atualizações';
	@override String get autoCheckUpdatesOnStartup => 'Verificar atualizações automaticamente ao iniciar';
	@override String get autoCheckUpdatesOnStartupDescription => 'Notificar ao iniciar quando houver atualização disponível';
	@override String get validationErrorEnterNumber => 'Insira um número válido';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'A duração deve estar entre ${min} e ${max} ${unit}';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Atalho já atribuído a ${action}';
	@override String shortcutUpdated({required Object action}) => 'Atalho atualizado para ${action}';
	@override String get saveFailed => 'Não foi possível salvar as alterações. Tente novamente.';
	@override String get autoPlayAndSkip => 'Reprodução automática e pulos';
	@override String get autoPlayNextEpisode => 'Reproduzir próximo episódio automaticamente';
	@override String get autoPlayNextEpisodeDescription => 'Iniciar o próximo episódio automaticamente quando um terminar';
	@override String get shuffleStartsFromBeginning => 'Reprodução Aleatória Começa do Início';
	@override String get shuffleStartsFromBeginningDescription => 'Iniciar cada episódio do início na reprodução aleatória em vez de retomá-lo';
	@override String get plexCinemaPreRoll => 'Use o servidor de cinema intros';
	@override String get plexCinemaPreRollDescription => 'Jogue Plex pre-rolls ou Jellyfin e Emby intros configurados antes de um filme começar.';
	@override String get playNextCountdown => 'Contagem regressiva do próximo episódio';
	@override String get playNextCountdownImmediate => 'Reproduzir imediatamente';
	@override String get skipIntroMode => 'Pular Abertura';
	@override String get skipIntroModeOffDescription => 'Reproduzir as aberturas normalmente sem botão de pulo';
	@override String get skipIntroModeButtonDescription => 'Mostrar um botão de pulo quando uma abertura começar';
	@override String get skipIntroModeAutoDescription => 'Pular as aberturas automaticamente após o atraso abaixo';
	@override String get skipCreditsMode => 'Pular Créditos';
	@override String get skipCreditsModeOffDescription => 'Reproduzir os créditos normalmente sem botão de pulo';
	@override String get skipCreditsModeButtonDescription => 'Mostrar um botão de pulo quando os créditos começarem';
	@override String get skipCreditsModeAutoDescription => 'Pular os créditos automaticamente e reproduzir o próximo episódio';
	@override String get skipAdsMode => 'Escape de anúncios';
	@override String get skipAdsModeOffDescription => 'Jogue anúncios detectados normalmente sem um botão de escape';
	@override String get skipAdsModeButtonDescription => 'Mostrar um botão de escape quando o Plex detecta um anúncio';
	@override String get skipAdsModeAutoDescription => 'Desligue os anúncios detectados automaticamente após o atraso abaixo';
	@override String get musicPlayback => 'Música Playback';
	@override String get musicSweetFades => 'Sóceos doces';
	@override String get musicSweetFadesDescription => 'Fade música em bordas de track quando Plex tem dados de som.';
	@override String get skipMarkerModeOff => 'Desativado';
	@override String get skipMarkerModeButton => 'Mostrar botão';
	@override String get skipMarkerModeAuto => 'Automático';
	@override String get forceSkipMarkerFallback => 'Forçar marcadores alternativos';
	@override String get forceSkipMarkerFallbackDescription => 'Usar padrões de títulos de capítulos mesmo quando o Plex tiver marcadores';
	@override String get theIntroDbFallback => 'Use o TheIntroDB como um intro fallback';
	@override String get theIntroDbFallbackDescription => 'Use as temporadas da comunidade apenas quando o servidor não tem um marcador de intro.';
	@override String get autoSkipDelay => 'Atraso para pular automaticamente';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Aguardar ${seconds} segundos antes de pular automaticamente';
	@override String get introPattern => 'Padrão do marcador de introdução';
	@override String get introPatternDescription => 'Expressão regular que identifica marcadores de introdução nos títulos dos capítulos';
	@override String get creditsPattern => 'Padrão do marcador de créditos';
	@override String get creditsPatternDescription => 'Expressão regular que identifica marcadores de créditos nos títulos dos capítulos';
	@override String get prerolls => 'Preróis';
	@override String get playPrerollsBeforeMovies => 'Jogue Preróis antes dos filmes';
	@override String get playPrerollsBeforeMoviesDescription => 'Jogue um clipe aleatório da sua seleção abaixo antes de cada filme. pressione para escapar.';
	@override String get prerollLibrary => 'Biblioteca Preroll';
	@override String get prerollLibraryNotSet => 'Não definido';
	@override String get prerollLibraryNoneFound => 'Não há bibliotecas encontradas em seus servidores.';
	@override String get prerollSelection => 'Prefeitos selecionados';
	@override String get prerollSelectionPickLibraryFirst => 'Escolha uma biblioteca primeiro';
	@override String get prerollSelectionNoneSelected => 'Não há pré-requisitos selecionados';
	@override String prerollSelectionCount({required Object count}) => '${count} selecionados';
	@override String get prerollItemPicker => 'Escolha os pré-requisitos';
	@override String get prerollItemPickerLoadFailed => 'Não podia carregar itens desta biblioteca.';
	@override String get invalidRegex => 'Expressão regular inválida';
	@override String get regex => 'Expressão regular';
	@override String get downloads => 'Downloads';
	@override String get downloadLocationDescription => 'Escolha onde armazenar conteúdo baixado';
	@override String get downloadLocationDefault => 'Padrão (Armazenamento do App)';
	@override String get downloadLocationCustom => 'Local Personalizado';
	@override String get selectFolder => 'Selecionar Pasta';
	@override String get resetToDefault => 'Redefinir para Padrão';
	@override String currentPath({required Object path}) => 'Atual: ${path}';
	@override String get downloadLocationChanged => 'Local de download alterado';
	@override String get downloadLocationReset => 'Local de download redefinido para padrão';
	@override String get downloadLocationInvalid => 'A pasta selecionada não permite gravação';
	@override String get downloadLocationPickerUnavailable => 'A seleção de pasta não está disponível neste dispositivo';
	@override String get downloadOnWifiOnly => 'Baixar apenas por Wi-Fi';
	@override String get downloadOnWifiOnlyDescription => 'Impedir downloads ao usar dados móveis';
	@override String get autoRemoveWatchedDownloads => 'Remover automaticamente os downloads assistidos';
	@override String get autoRemoveWatchedDownloadsDescription => 'Excluir automaticamente os downloads assistidos';
	@override String get autoDownloadContinueWatching => 'Auto-Download Continuar a Assistir';
	@override String get autoDownloadContinueWatchingDescription => 'Mantenha os itens na sua caixa de monitoramento continua baixados e remova-os uma vez que deixam a caixa de monitoramentos';
	@override String get downloadQuality => 'Download Qualidade';
	@override String get downloadQualityDescription => 'Plex prepara uma cópia convertida em seu download quue. Jellyfin e Emby transcódigo enquanto o arquivo é baixado; transferências interrompidas podem precisar de reiniciar.';
	@override String get askDownloadQualityEachTime => 'Escolha a qualidade para cada download';
	@override String get askDownloadQualityEachTimeDescription => 'Mostrar o picker de qualidade antes de quebrar cada download de vídeo';
	@override String get cellularDownloadBlocked => 'Os downloads estão bloqueados nos dados móveis. Use Wi-Fi ou altere a configuração.';
	@override String get maxVolume => 'Volume Máximo';
	@override String get maxVolumeDescription => 'Permitir aumento de volume acima de 100% para mídias silenciosas';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Mostrar o que você está assistindo no Discord';
	@override String get services => 'Serviços';
	@override String get servicesDescription => 'Conecte Trakt, MyAnimeList, Seerr e mais';
	@override String get manageLibrariesDescription => 'Reordene e oculte bibliotecas';
	@override String get companionRemoteServer => 'Servidor de controle remoto';
	@override String get companionRemoteServerDescription => 'Permitir que dispositivos móveis na sua rede controlem este app';
	@override String get companionRemoteServerStartFailed => 'Não foi possível iniciar o servidor de controle remoto';
	@override String get companionRemoteServerStopFailed => 'Não foi possível parar o servidor de controle remoto';
	@override String get autoPip => 'Picture-in-picture automático';
	@override String get autoPipDescription => 'Entrar automaticamente no modo picture-in-picture ao sair do app durante a reprodução';
	@override String get matchContentFrameRate => 'Ajustar à taxa de quadros do conteúdo';
	@override String get matchContentFrameRateDescription => 'Ajustar a taxa de atualização da tela ao conteúdo de vídeo';
	@override String get matchContentResolution => 'Ajustar à resolução do conteúdo';
	@override String get matchContentResolutionDescription => 'Muda a tela para a resolução nativa do vídeo para que a TV cuide do upscaling. Menus e legendas também são ampliados durante a reprodução';
	@override String get matchRefreshRate => 'Ajustar à taxa de atualização';
	@override String get matchRefreshRateDescription => 'Ajustar a taxa de atualização da tela em tela cheia';
	@override String get matchDynamicRange => 'Ajustar à faixa dinâmica';
	@override String get matchDynamicRangeDescription => 'Ativar HDR para conteúdo HDR e depois voltar para SDR';
	@override String get displaySwitchDelay => 'Atraso na troca do modo de exibição';
	@override String get tunneledPlayback => 'Reprodução em túnel';
	@override String get tunneledPlaybackDescription => 'Usar o tunelamento de vídeo. Desative se o vídeo ficar preto ao reproduzir em HDR ou o movimento travar.';
	@override String get audioPassthrough => 'Passagem direta de áudio';
	@override String get audioPassthroughDescription => 'Enviar o áudio Dolby/DTS ao receptor ou à TV sem recodificação, preservando o som surround. Desative se não houver som.';
	@override String get audioPassthroughDescriptionApple => 'Usar o decodificador Dolby nativo da Apple para Dolby Digital Plus, incluindo Atmos. DTS e TrueHD continuam sendo reproduzidos como PCM multicanal. Desative se não houver som.';
	@override String get audioPassthroughDescriptionAppleSpatial => 'Usar o decodificador Dolby nativo da Apple para Dolby Digital Plus, incluindo Atmos. No iOS, iPadOS e tvOS 26 ou posterior, TrueHD Atmos e DTS:X são reproduzidos como áudio espacial. As demais faixas DTS e TrueHD são reproduzidas como PCM multicanal. Desative se não houver som.';
	@override String get audioPassthroughOverriddenByNormalization => 'Desativada enquanto a normalização de intensidade sonora estiver ativa';
	@override String get audioChannelLimit => 'Canais de áudio';
	@override String get audioChannelLimitDescription => 'Mixar o áudio decodificado em menos canais para alto-falantes, fones de ouvido ou sistemas HDMI que não reproduzem todos os canais';
	@override String get audioChannelLimitOriginal => 'Original';
	@override String get audioChannelLimitOriginalDescription => 'Reproduzir todos os canais da faixa';
	@override String get audioChannelLimitSurround51 => 'Até 5.1';
	@override String get audioChannelLimitSurround51Description => 'Mixar 7.1 em 5.1 para TVs e receptores que só aceitam PCM 5.1. A passagem direta não é afetada.';
	@override String get audioChannelLimitStereo => 'Estéreo';
	@override String get audioChannelLimitStereoDescription => 'Mixar em dois canais para alto-falantes estéreo ou fones de ouvido. Desativa a passagem direta.';
	@override String get downmixCenterBoost => 'Reforço do canal central';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'Reforço (dB)';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => 'Normalizar volume na conversão para estéreo';
	@override String get audioDownmixNormalizeDescription => 'Reduzir o volume da mixagem para evitar saturação. Desative para manter o volume original, que pode distorcer em cenas muito altas.';
	@override String get dvConversionMode => 'Conversão Dolby Vision';
	@override String get dvConversionModeDescription => 'Escolha como os arquivos Dolby Vision Profile 7 são tratados.';
	@override String get dvConversionAuto => 'Automático';
	@override String get dvConversionNative => 'Nativo / desativado';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Usar a detecção de recursos do dispositivo e o comportamento alternativo padrão';
	@override String get dvConversionNativeDescription => 'Forçar DV7 nativo e impedir uma nova tentativa de conversão de DV';
	@override String get dvConversionDv81Description => 'Forçar a conversão RPU integrada para Dolby Vision perfil 8.1';
	@override String get dvConversionHevcStripDescription => 'Remover as camadas RPU/EL do Dolby Vision e apresentar HEVC sem Dolby Vision';
	@override String get experimentalDolbyVision => 'Dolby Vision experimental';
	@override String get experimentalDolbyVisionDescription => 'Usar o renderizador FEL experimental na próxima reprodução. Requer uma compilação separada do motor.';
	@override String get dvExperimentUnavailableDescription => 'Este experimento está disponível apenas no Linux por enquanto.';
	@override String get dvCompatibilityFallback => 'Alternativa de compatibilidade';
	@override String get dvCompatibilityFallbackDescription => 'Usar o renderizador padrão se o experimento não iniciar. Os dados FEL podem ser perdidos.';
	@override String get dvExperimentDiagnostics => 'Registro do experimento de vídeo';
	@override String get dvExperimentDiagnosticsDescription => 'Ativar registros detalhados do reprodutor na próxima reprodução.';
	@override String get disableDolbyVision => 'Desativar Dolby Vision';
	@override String get disableDolbyVisionDescription => 'Reproduzir a camada HDR10 ou HLG do arquivo em vez de Dolby Vision, quando houver';
	@override String get hdrSdrConversion => 'Conversão de HDR para SDR';
	@override String get hdrSdrConversionDescription => 'Escolha o que converte vídeos HDR quando a tela não consegue exibir HDR.';
	@override String get hdrSdrConversionAuto => 'Automático';
	@override String get hdrSdrConversionAutoDescription => 'Dispositivo no Android 9 ou posterior, reprodutor em versões anteriores';
	@override String get hdrSdrConversionDevice => 'Dispositivo';
	@override String get hdrSdrConversionDeviceDescription => 'O hardware de vídeo do dispositivo faz a conversão. Mais rápido, mas as cores dependem do dispositivo';
	@override String get hdrSdrConversionPlayer => 'Reprodutor';
	@override String get hdrSdrConversionPlayerDescription => 'O reprodutor faz a conversão. Cores consistentes, mas o 4K pode travar em TV boxes mais simples';
	@override String get deinterlace => 'Desentrelaçamento';
	@override String get deinterlaceDescription => 'Remover artefatos de pente de vídeo entrelaçado (apenas no reprodutor mpv)';
	@override String get deinterlaceOff => 'Desativado';
	@override String get deinterlaceOffDescription => 'Exibir o vídeo entrelaçado como é decodificado';
	@override String get deinterlaceVideo => 'Vídeo';
	@override String get deinterlaceVideoDescription => 'Transformar cada campo em um quadro completo. Para vídeos gravados para TV, como esportes, noticiários e shows';
	@override String get deinterlaceFilm => 'Filme';
	@override String get deinterlaceFilmDescription => 'Restaurar os quadros originais de filmes e animações convertidos por telecine para 29,97 fps, comum em DVDs NTSC. Vídeos gravados para TV travam. A TV ao vivo usa Vídeo';
	@override String get requireProfileSelectionOnOpen => 'Pedir perfil ao abrir o app';
	@override String get requireProfileSelectionOnOpenDescription => 'Mostrar a seleção de perfil sempre que o app for aberto';
	@override String get forceTvMode => 'Forçar modo TV';
	@override String get forceTvModeDescription => 'Forçar o layout de TV em dispositivos sem detecção automática. Requer reiniciar o app.';
	@override String get startInFullscreen => 'Iniciar em tela cheia';
	@override String get startInFullscreenDescription => 'Abrir o PlezyNG em modo de tela cheia ao iniciar';
	@override String get exitFullscreenOnPlayerClose => 'Sair da tela cheia ao fechar o reprodutor';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Sair automaticamente da tela cheia ao fechar o reprodutor de vídeo';
	@override String get autoHidePerformanceOverlay => 'Ocultar automaticamente o painel de desempenho';
	@override String get autoHidePerformanceOverlayDescription => 'Esmaecer o painel de desempenho junto com os controles de reprodução';
	@override String get showNavBarLabels => 'Mostrar Rótulos da Barra de Navegação';
	@override String get showNavBarLabelsDescription => 'Exibir rótulos de texto sob os ícones da barra de navegação';
	@override String get startupSection => 'Seção inicial';
	@override String get preferredServer => 'Preferido servidor';
	@override String get preferredServerDescription => 'Priorize os resultados deste servidor, mantendo todos os servidores conectados disponíveis.';
	@override String get preferredServerAutomatic => 'Automático';
	@override String get showExploreTab => 'Mostrar aba Explorar';
	@override String get showExploreTabDescription => 'Exibir a aba Explorar com conteúdo do Plex Discover e dos rastreadores conectados';
	@override String get hideEmptyLibraries => 'Esconde bibliotecas vazias';
	@override String get hideEmptyLibrariesDescription => 'Remova bibliotecas com um número de itens reportados pelo servidor de zero da navegação.';
	@override String get liveTvDefaultFavorites => 'Canais favoritos por padrão';
	@override String get liveTvDefaultFavoritesDescription => 'Mostrar apenas os canais favoritos ao abrir a TV ao vivo';
	@override String get general => 'Geral';
	@override String get generalDescription => 'Idioma, inicialização e comportamento da janela';
	@override String get languageAndRegion => 'Idioma e Região';
	@override String get startup => 'Inicialização';
	@override String get display => 'Tela';
	@override String get libraryAndCards => 'Biblioteca e Cards';
	@override String get homeScreen => 'Tela inicial';
	@override String get navigation => 'Navegação';
	@override String get window => 'Janela';
	@override String get liveTv => 'TV ao Vivo';
	@override String get player => 'Reprodutor';
	@override String get videoAndDisplay => 'Vídeo e Tela';
	@override String get audio => 'Áudio';
	@override String get quality => 'Qualidade';
	@override String get subtitles => 'Legendas';
	@override String get seekAndTiming => 'Busca e tempo';
	@override String get behavior => 'Comportamento';
	@override String get gestures => 'Gestos';
	@override String get gestureBrightnessSwipe => 'Deslize para brilho';
	@override String get gestureBrightnessSwipeDescription => 'Deslize para cima ou para baixo na borda esquerda para ajustar o brilho';
	@override String get gestureVolumeSwipe => 'Deslize para volume';
	@override String get gestureVolumeSwipeDescription => 'Deslize para cima ou para baixo na borda direita para ajustar o volume';
	@override String get gesturePinchToZoom => 'Pinça para zoom';
	@override String get gesturePinchToZoomDescription => 'Pince o vídeo para ampliar ou reduzir';
	@override String get gestureSeekSwipe => 'Busca de Swipe';
	@override String get gestureSeekSwipeDescription => 'Desligue para a esquerda ou para a direita em qualquer lugar no vídeo para procurar; liberar para saltar';
	@override String get rememberBrightnessLevel => 'Lembrar Nível de Brilho';
	@override String get rememberBrightnessLevelDescription => 'Iniciar a reprodução com o brilho definido pelo último deslize';
	@override String get controls => 'Controles';
	@override String get rememberPlayerChanges => 'Lembrar alterações do reprodutor';
	@override String get rememberPlayerChangesDescription => 'Onde uma alteração feita durante a reprodução é salva e reaplicada';
	@override String get scopePlaybackSpeed => 'Velocidade de reprodução';
	@override String get scopeShaderPreset => 'Predefinição de shader';
	@override String get scopeAspectRatio => 'Proporção da tela';
	@override String get scopeSyncOffsets => 'Sincronização de áudio e legendas';
	@override String get playerScopeOff => 'Não salvar';
	@override String get playerScopeGlobal => 'Em todos os lugares';
	@override String get playerScopeLibrary => 'Por biblioteca';
	@override String get playerScopeTitle => 'Por série ou filme';
	@override String get exportDialogTitle => 'Exportar configurações do PlezyNG';
	@override String get followSystem => 'Seguir o sistema';
	@override String get followAppLanguage => 'Igual ao idioma da interface';
	@override String get regionFormat => 'Formatos regionais';
	@override String get regionFormatDescription => 'Escolha como as datas, os números e as unidades de medida são apresentados.';
	@override String get metadataLanguage => 'Idioma dos metadados';
	@override String get metadataLanguageDescription => 'Idioma preferido para títulos e descrições quando o servidor o suportar. As preferências de áudio e legendas são definidas separadamente.';
	@override String get enterFullscreenOnPlaybackStart => 'Insira a tela completa quando o playback começa';
	@override String get enterFullscreenOnPlaybackStartDescription => 'Abre vídeo de desktop em tela completa quando o playback começa';
	@override String get extendVideoIntoDisplayCutout => 'Extender vídeo para exibição cutout';
	@override String get extendVideoIntoDisplayCutoutDescription => 'Deixe o vídeo de tela completa usar a câmera cutout em telefones Android';
	@override String get languageDescription => 'Escolha a língua utilizada para os controles e mensagens do PlezyNG. Seguindo o sistema rastreia o idioma do seu dispositivo.';
	@override String get themeDescription => 'Escolha as cores e contraste utilizados em toda a aplicação.';
	@override String get libraryDensityDescription => 'Mude o número de cartões da biblioteca em cada linha.';
	@override String get displayScaleDescription => 'Recupere a interface nesta tela do carro sem alterar o tamanho de texto em todo o seu dispositivo.';
	@override String get themeSongVolumeDescription => 'Defina o volume de músicas temáticas em relação a outros áudio.';
	@override String get viewModeDescription => 'Escolha se os itens da biblioteca aparecem como posters em uma rede ou como uma lista compacta.';
	@override String get gridViewDescription => 'Arranje itens da biblioteca em linhas e colunas de posters.';
	@override String get listViewDescription => 'Mostrar itens da biblioteca em uma lista vertical com mais texto por item.';
	@override String get gridSpacingDescription => 'Coloque a lacuna entre os cartazes nas redes da biblioteca.';
	@override String get gridSpacingTightDescription => 'Faça mais posters em todo o ecrã com pequenas lacunas.';
	@override String get gridSpacingNormalDescription => 'Use a diferença padrão entre os cartões.';
	@override String get gridSpacingSpaciousDescription => 'Adicione maiores lacunas entre os posters para mais separação.';
	@override String get episodePosterModeDescription => 'Escolha qual obra de arte aparece nas cartas de episódio.';
	@override String get seriesPosterDescription => 'Use o poster da série do show para cada episódio.';
	@override String get seasonPosterDescription => 'Use o poster de temporada para cada episódio quando disponível.';
	@override String get episodeThumbnailDescription => 'Use um quadro do episódio quando disponível.';
	@override String get continueWatchingActionDescription => 'Escolha o que acontece quando você ativar um cartão de acompanhamento contínuo.';
	@override String get continueWatchingPlayDescription => 'Comece o filme ou episódio imediatamente.';
	@override String get continueWatchingDetailsDescription => 'Abra a página de título primeiro para que você possa revisar os detalhes e escolher uma ação.';
	@override String get episodeActionDescription => 'Escolha o que acontece quando você ativar um cartão de episódio.';
	@override String get episodePlayDescription => 'Comece o episódio imediatamente.';
	@override String get episodeDetailsDescription => 'Abra a página de episódio antes do playback.';
	@override String get contentScreensaverDelayDescription => 'Escolha quanto tempo PlezyNG espera sem entrada antes de mostrar obras de arte.';
	@override String get continueWatchingRowSizeDescription => 'Escolha o tamanho das cartas na linha Continuing Watching.';
	@override String get rowSizeCompactDescription => 'Mostrar cartões menores para que mais itens se encaixem em toda a linha.';
	@override String get rowSizeStandardDescription => 'Use o tamanho de cartão padrão.';
	@override String get rowSizeLargeDescription => 'Mostrar cartas maiores com mais detalhes de arte.';
	@override String get visualEffectsDescription => 'Escolha o orçamento de animação e efeitos artísticos para este dispositivo.';
	@override String get visualEffectsFullDescription => 'Use os efeitos de animação e arte em todos os dispositivos.';
	@override String get startupSectionDescription => 'Escolha qual seção abre quando PlezyNG começa.';
	@override late final Translations$settings$startupSectionOptions$pt startupSectionOptions = Translations$settings$startupSectionOptions$pt.internal(_root);
	@override String get smallSkipDurationDescription => 'Defina a distância movida pela curta direção traseira e para frente busca controles.';
	@override String get largeSkipDurationDescription => 'Defina a distância movida pelo longo traseiro e para frente procura controlos.';
	@override String get rewindOnResumeDescription => 'Move o playback de volta por essa quantia quando retoma um vídeo.';
	@override String get defaultSleepTimerDescription => 'Defina a duração inicial utilizada quando você começa o horário de sono.';
	@override String get playNextCountdownDescription => 'Aguarde muito antes de começar o próximo episódio.Set para 0 para começar imediatamente.';
	@override String get autoSkipDelaySettingDescription => 'Aplica-se quando um intro, crédito ou anúncio é configurado para exceder automaticamente.';
	@override String get downmixCenterBoostDescription => 'Aumente o diálogo no canal central quando o áudio circundante é misturado para baixo em estereó.';
	@override String get displaySwitchDelayDescription => 'Aguarde antes de alterar o modo de exibição para que a TV ou receptor possa terminar seu switch anterior.';
	@override String get playerBackendDescription => 'Escolha qual motor de reprodução decode e retrata vídeo neste dispositivo.';
	@override String get exoPlayerDescription => 'Use o jogador nativo do Android baseado no Media3 e as vias de hardware suportadas.';
	@override String get mpvDescription => 'Use mpv, que expõe controles adicionais de reprodução, subtítulos e processamento de vídeo.';
	@override String get scopeOffDescription => 'Mantenha as alterações apenas para a sessão de reprodução atual.';
	@override String get scopeGlobalDescription => 'Reutilizar o mesmo valor para cada biblioteca e título.';
	@override String get scopeLibraryDescription => 'Lembre-se de um valor separado para cada biblioteca.';
	@override String get scopeTitleDescription => 'Lembre-se de um valor separado para cada show ou filme.';
	@override String get specialsOrderingServerDescription => 'Mantenha a ordem do episódio fornecida pelo servidor de mídia.';
	@override String get specialsOrderingAirDateDescription => 'Coloque especiais entre episódios regulares pela sua data de ar.';
	@override String get specialsOrderingLastDescription => 'Colocar cada especial após as estações regulares.';
	@override String get skipIntroModeDescription => 'Escolha se os marcadores intro jogam normalmente, mostram um botão de escape ou escapam automaticamente.';
	@override String get skipCreditsModeDescription => 'Escolha se os créditos jogam normalmente, exibe um botão de escape ou escape automaticamente.';
	@override String get skipAdsModeDescription => 'Escolha se os anúncios detectados jogam normalmente, mostram um botão de escape ou escapam automaticamente.';
	@override String get playbackBufferAutoDescription => 'Deixe o jogador ativo escolher seu tamanho de buffer normal.';
	@override String get playbackBufferLargeDescription => 'Mantenha mais mídia pronta antes do playback; isso usa mais memória.';
	@override String get playbackBufferExtraLargeDescription => 'Mantenha o maior buffer de leitura; isso usa a maioria da memória.';
	@override String get defaultQualityDescription => 'Configurar a resolução de vídeo padrão e bitrate o telhado para os fluxos que o servidor transcoda.';
	@override String get cellularQualityDescription => 'Override Qualidade padrão quando o dispositivo está usando uma conexão celular-somente.';
	@override String get remoteQualityDescription => 'Override Default Quality quando se conecta a um servidor através de uma conexão remota.';
	@override String get qualityPresetOriginalDescription => 'Jogue a fonte à sua qualidade disponível sem pedir ao servidor que o transcode.';
	@override String get qualityPresetTranscodeOptionDescription => 'Peça ao servidor para um fluxo convertido usando a resolução e bitrate mostrados acima.';
	@override String get qualityPresetSameAsDefaultDescription => 'Utilize a qualidade selecionada em Qualidade padrão.';
	@override String get musicQualityDescription => 'Configure a taxa de áudio máxima solicitada do servidor; O original mantém o fluxo fonte.';
	@override String get musicQualityOriginalDescription => 'Jogue o áudio de origem sem um transcódigo capped com bitrate.';
	@override String get musicQualityTranscodeOptionDescription => 'Solicite um transcódigo de servidor capped perto da taxa de bit mostrada acima; a saída real pode variar.';
	@override String get maxVolumeInputLabel => 'Volume máximo (%)';
	@override String get checkForUpdatesDescription => 'Verifique agora se uma versão mais recente do PlezyNG está disponível.';
	@override String get appearanceDescription => 'Escolha o tema do aplicativo e ajuste os cartões da biblioteca, as linhas domésticas e a navegação.';
	@override String get prerollLibraryDescription => 'Escolha a biblioteca que contém os clipes disponíveis como pre-rolls do filme.';
	@override String get prerollSelectionDescription => 'Escolha quais clipes da biblioteca selecionada podem ser jogados antes dos filmes.';
	@override String get contentScreensaverDelayOptionDescription => 'Aguarde muitos minutos sem entrada antes de mostrar o trabalho artístico do monitor.';
	@override String get videoCodecOptionDescription => 'Permitir reprodução direta para este codec quando suportado. codecs não verificados são transcodados pelo servidor de mídia.';
}

// Path: themeEditor
class Translations$themeEditor$pt extends Translations$themeEditor$en {
	Translations$themeEditor$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get builtIn => 'Integrados';
	@override String get presets => 'Predefinidos';
	@override String get custom => 'Personalizado';
	@override String get customEmpty => 'Ainda não criado';
	@override String get editCustom => 'Editar tema personalizado';
	@override String get editCustomDescription => 'Escolha você mesmo cada cor';
	@override String get locked => 'Acesso ao tempo necessário';
	@override String get savedLocked => 'Salvo - disponível com acesso ao tempo todo';
	@override String get title => 'Tema personalizado';
	@override String get startFrom => 'Começar a partir de';
	@override String get startFromDescription => 'Copiar todas as cores de outro tema';
	@override String get colors => 'Cores';
	@override String get preview => 'Pré-visualização';
	@override late final Translations$themeEditor$slots$pt slots = Translations$themeEditor$slots$pt.internal(_root);
	@override String get opacity => 'Opacidade';
	@override String get hexHint => '#RRGGBB ou #AARRGGBB';
	@override String get fromOtherThemes => 'De outros temas';
	@override String swatchLabel({required Object color, required Object theme}) => '${color} (${theme})';
	@override late final Translations$themeEditor$contrast$pt contrast = Translations$themeEditor$contrast$pt.internal(_root);
	@override String lowContrast({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, abaixo dos ${minimum}:1 recomendados';
	@override String get discardTitle => 'Descartar alterações?';
	@override String get discardMessage => 'Suas alterações de cor não salvas serão perdidas.';
	@override String get discard => 'Descartar';
	@override String previewCardTitle({required Object number}) => 'Episódio ${number}';
	@override String previewCardSubtitle({required Object minutes}) => '${minutes} min restantes';
	@override String get previewSwitch => 'Reprodução automática';
	@override String get previewMutedText => 'O texto secundário fica assim';
	@override String get themeSystemDescription => 'Siga a aparência do seu dispositivo e mude entre luz e escuro automaticamente.';
	@override String get themeLightDescription => 'Use um fundo brilhante com texto escuro.';
	@override String get themeDarkDescription => 'Use um fundo escuro com texto claro.';
	@override String get themeOledDescription => 'Use superfícies preto que reduzem a luz nas telas OLED.';
	@override String get themeEmberDescription => 'Use cores de acento amarelo e vermelho quente.';
	@override String get themeGlacierDescription => 'Use cores de acento azul fresco.';
	@override String get themeForestDescription => 'Use cores de acento verde e natural.';
	@override String get themePlumDescription => 'Use cores de acento violeta e pluma.';
	@override String get themePaperDescription => 'Use superfícies de papel quentes e cores inspiradas em tinta.';
	@override String get themeCustomDescription => 'Use a paleta de cores que você criou no editor de tema personalizado.';
	@override String get editorDescription => 'Escolha uma cor de paleta, ajuste a sua soma, saturação, brilho ou opacidade e veja a atualização prévia antes de economizar.';
}

// Path: search
class Translations$search$pt extends Translations$search$en {
	Translations$search$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Buscar filmes, séries, músicas...';
	@override String get tryDifferentTerm => 'Tente um termo de busca diferente';
	@override String get searchYourMedia => 'Buscar suas mídias';
	@override String get enterTitleActorOrKeyword => 'Insira um título, ator ou palavra-chave';
	@override String get people => 'Pessoas';
}

// Path: hotkeys
class Translations$hotkeys$pt extends Translations$hotkeys$en {
	Translations$hotkeys$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Definir Atalho para ${actionName}';
	@override String get clearShortcut => 'Limpar atalho';
	@override String get noShortcutSet => 'Nenhum atalho definido';
	@override String get currentShortcut => 'Atalho atual:';
	@override String get pressToRecord => 'Selecionar para gravar um atalho';
	@override String get recordingShortcut => 'Pressione o atalho agora';
	@override late final Translations$hotkeys$actions$pt actions = Translations$hotkeys$actions$pt.internal(_root);
}

// Path: fileInfo
class Translations$fileInfo$pt extends Translations$fileInfo$en {
	Translations$fileInfo$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Informações do arquivo';
	@override String get overview => 'Visão geral';
	@override String get video => 'Vídeo';
	@override String get audio => 'Áudio';
	@override String get subtitles => 'Legendas';
	@override String get images => 'Imagens incorporadas';
	@override String get dataStreams => 'Fluxos de dados';
	@override String get lyrics => 'Letras';
	@override String get file => 'Arquivo';
	@override String get attachments => 'Anexos';
	@override String get delivery => 'Entrega';
	@override String versionCounter({required Object index, required Object count}) => 'Versão ${index} de ${count}';
	@override String fileCounter({required Object index, required Object count}) => 'Arquivo ${index} de ${count}';
	@override String get noStreams => 'O servidor não relatou fluxos para este arquivo.';
	@override String get copyPath => 'Copiar caminho';
	@override String get pathCopied => 'Caminho do arquivo copiado';
	@override String get codec => 'Codec';
	@override String get codecTag => 'Tag do codec';
	@override String get resolution => 'Resolução';
	@override String get codedResolution => 'Resolução codificada';
	@override String get bitrate => 'Taxa de bits';
	@override String get frameRate => 'Taxa de Quadros';
	@override String get rotation => 'Rotação';
	@override String get comment => 'Comentário';
	@override String get audioDescription => 'Descrição de áudio';
	@override String get headerCompression => 'Compactação de cabeçalho';
	@override String get sidecarFile => 'Arquivo sidecar';
	@override String get transportTimestamp => 'Carimbo de transporte';
	@override String get displayOffset => 'Deslocamento de exibição';
	@override String get previewFailureCode => 'Código de falha da pré-visualização';
	@override String get previewRetries => 'Tentativas da pré-visualização';
	@override String get aspectRatio => 'Proporção';
	@override String get pixelAspectRatio => 'Proporção de aspecto de pixel';
	@override String get profile => 'Perfil';
	@override String get level => 'Nível';
	@override String get bitDepth => 'Profundidade de bits';
	@override String get pixelFormat => 'Formato de pixel';
	@override String get colorSpace => 'Espaço de Cor';
	@override String get colorRange => 'Faixa de Cor';
	@override String get colorPrimaries => 'Primárias de Cor';
	@override String get colorTransfer => 'Transferência de cor';
	@override String get chromaSubsampling => 'Subamostragem de Croma';
	@override String get chromaLocation => 'Localização do croma';
	@override String get scanType => 'Tipo de varredura';
	@override String get interlaced => 'Entrelaçado';
	@override String get anamorphic => 'Anamórfico';
	@override String get referenceFrames => 'Quadros de referência';
	@override String get dynamicRange => 'Faixa dinâmica';
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
	@override String get provider => 'Provedor';
	@override String get matchScore => 'Pontuação de correspondência';
	@override String get externalDelivery => 'Pode ser servido separadamente';
	@override String get sidecarPath => 'Caminho do sidecar';
	@override String get sourceStream => 'Copiado de';
	@override String get temporary => 'Temporário';
	@override String get timeBase => 'Base de tempo';
	@override String get overallBitrate => 'Taxa de bits total';
	@override String get path => 'Caminho';
	@override String get fileName => 'Nome do arquivo';
	@override String get size => 'Tamanho';
	@override String get totalSize => 'Tamanho total';
	@override String get container => 'Contêiner';
	@override String get duration => 'Duração';
	@override String get previewThumbnails => 'Miniaturas de pré-visualização';
	@override String get previewIndex => 'Índice de pré-visualização';
	@override String get packetLength => 'Tamanho do pacote';
	@override String get filePresent => 'Arquivo presente';
	@override String get fileReadable => 'Legível pelo servidor';
	@override String get streamPath => 'Caminho do fluxo';
	@override String get optimizedForStreaming => 'Otimizado para transmissão';
	@override String get has64bitOffsets => 'Deslocamentos de 64 bits';
	@override String get protocol => 'Protocolo';
	@override String get mediaType => 'Tipo de mídia';
	@override String get sourceKind => 'Tipo de origem';
	@override String get optimizedVersion => 'Versão otimizada';
	@override String get optimizationTarget => 'Alvo de otimização';
	@override String get deletedAt => 'Excluído';
	@override String get remoteSource => 'Origem remota';
	@override String get infiniteStream => 'Fluxo infinito';
	@override String get directPlay => 'Reprodução direta';
	@override String get directStream => 'Fluxo direto';
	@override String get transcoding => 'Transcodificação';
	@override String get etag => 'ETag';
	@override String get versionId => 'ID da versão';
	@override String get fileId => 'ID do arquivo';
	@override String get defaultAudioTrack => 'Faixa de áudio padrão';
	@override String get defaultSubtitleTrack => 'Faixa de legenda padrão';
	@override String get subtitlesOff => 'Desativadas';
	@override String get flagDefault => 'Padrão';
	@override String get flagForced => 'Forçada';
	@override String get flagSelected => 'Selecionada';
	@override String get flagExternal => 'Externa';
	@override String get flagHearingImpaired => 'Deficiência auditiva';
	@override String get flagDub => 'Dublada';
	@override String get flagOriginal => 'Original';
	@override String get channelsMono => 'Mono';
	@override String dolbyVisionProfile({required Object profile}) => 'Perfil ${profile}';
}

// Path: mediaMenu
class Translations$mediaMenu$pt extends Translations$mediaMenu$en {
	Translations$mediaMenu$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Marcar como Assistido';
	@override String get markAsUnwatched => 'Marcar como Não Assistido';
	@override String get removeFromContinueWatching => 'Remover de Continuar Assistindo';
	@override String get viewDetails => 'Ver detalhes';
	@override String get goToSeries => 'Ir para a série';
	@override String get shufflePlay => 'Reprodução Aleatória';
	@override String get shuffleNotAvailableOffline => 'Reprodução aleatória indisponível offline';
	@override String get fileInfo => 'Informações do arquivo';
	@override String get deleteEpisodeFromServer => 'Excluir episódio do servidor';
	@override String get deleteSeasonFromServer => 'Excluir temporada do servidor';
	@override String get deleteShowFromServer => 'Excluir série do servidor';
	@override String get deleteMovieFromServer => 'Excluir filme do servidor';
	@override String get deleteEpisodeTitle => 'Excluir este episódio?';
	@override String get deleteSeasonTitle => 'Excluir esta temporada?';
	@override String get deleteShowTitle => 'Excluir esta série?';
	@override String get deleteMovieTitle => 'Excluir este filme?';
	@override String get deleteEpisodeConfirm => 'Excluir episódio';
	@override String get deleteSeasonConfirm => 'Excluir temporada';
	@override String get deleteShowConfirm => 'Excluir série';
	@override String get deleteMovieConfirm => 'Excluir filme';
	@override String get deleteAnyway => 'Excluir mesmo assim';
	@override String confirmDeleteTarget({required Object title}) => 'Excluir permanentemente ${title} do seu servidor?';
	@override String get deleteMultipleWarning => 'Isso inclui todos os episódios e seus arquivos.';
	@override String deleteEpisodeCountWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: 'Isso exclui o ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episódio e o arquivo dele.',
		other: 'Isso exclui todos os ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episódios e os arquivos deles.',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: 'Este item está armazenado como ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} arquivo, que será excluído.',
		other: 'Este item está armazenado em ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} arquivos, e todos eles serão excluídos.',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: 'Mais ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episódio está armazenado no mesmo arquivo e também será excluído:',
		other: 'Mais ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episódios estão armazenados no mesmo arquivo e também serão excluídos:',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'O PlezyNG não conseguiu verificar quais arquivos serão removidos, então pode excluir mais do que o item acima. Cancele e tente novamente, ou exclua mesmo assim.';
	@override String get deleteScopeUnverifiedNoFileInfo => 'Seu servidor não forneceu detalhes do arquivo para este item, então o PlezyNG não pode verificar quais arquivos serão removidos. Pode excluir mais do que o item acima.';
	@override String get mediaDeletedSuccessfully => 'Item de mídia excluído com sucesso';
	@override String get mediaFailedToDelete => 'Falha ao excluir item de mídia';
	@override String get rate => 'Avaliar';
	@override String get playFromBeginning => 'Reproduzir do início';
	@override String get playVersion => 'Reproduzir versão...';
}

// Path: rateSheet
class Translations$rateSheet$pt extends Translations$rateSheet$en {
	Translations$rateSheet$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Avaliar';
	@override String get server => 'Servidor';
	@override String get favorite => 'Favorito';
	@override String get favorited => 'Adicionado aos favoritos';
	@override String get saved => 'Salvo';
	@override String get notAvailable => 'Nenhuma correspondência encontrada';
	@override String get noConnectedServices => 'Conecte um serviço nas Configurações para avaliar por lá.';
}

// Path: accessibility
class Translations$accessibility$pt extends Translations$accessibility$en {
	Translations$accessibility$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, filme';
	@override String mediaCardShow({required Object title}) => '${title}, série de TV';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'assistido';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent} por cento assistido';
	@override String get mediaCardUnwatched => 'não assistido';
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
	@override String get autoScrollPlay => 'Iniciar rolagem automática';
	@override String get autoScrollPause => 'Pausar rolagem automática';
	@override String get hueShort => 'M';
	@override String get saturationShort => 'S';
	@override String get valueShort => 'V';
	@override String get red => 'vermelho';
	@override String get green => 'Verde';
	@override String get blue => 'azul';
	@override String get redShort => 'R';
	@override String get greenShort => 'G';
	@override String get blueShort => 'B';
	@override String get colorModeHsv => 'HSV';
	@override String get colorModeRgb => 'RGB';
	@override String get title => 'Acessibilidade';
	@override String get summary => 'Texto, contraste, movimento e controlos';
	@override String get systemHint => 'As configurações de acessibilidade do seu dispositivo sempre se aplicam. Estas opções adicionam ajustes ao longo de PlezyNG.';
	@override String get readability => 'Leitura e visibilidade';
	@override String get textSize => 'Tamanho de texto adicional';
	@override String get preview => 'Encontre sua próxima história. leia, ouça e assiste a seu próprio ritmo.';
	@override String get boldText => 'Interface de texto';
	@override String get highContrast => 'Contraste elevado';
	@override String get highContrastHint => 'Texto mais forte, desenhos e indicadores de foco em superfícies claras ou escuras.';
	@override String get interaction => 'Moção e Interação';
	@override String get reduceMotion => 'Reduzir a movimentação';
	@override String get reduceMotionHint => 'Parar as animações do indicador de foco, as transições de página e os efeitos decorativos.';
	@override String get largeTargets => 'Objetivos de toque mais grandes';
	@override String get largeTargetsHint => 'Dê controles compartilhados mais espaço para toque e navegação assistiva.';
	@override String get navigationHint => 'Use Tab e Shift+Tab para navegar entre os controles, Enter ou a barra de espaço para ativar e Escape ou Voltar para fechar. O zoom e as preferências de leitura ficam disponíveis quando um livro está aberto.';
	@override String get textSizeDescription => 'Escala o texto de interface em PlezyNG, além da configuração do tamanho de texto do sistema do seu dispositivo.';
	@override String get boldTextHint => 'Use um peso mais pesado para etiquetas de interface e mensagens para torná-los mais fáceis de distinguir.';
}

// Path: tooltips
class Translations$tooltips$pt extends Translations$tooltips$en {
	Translations$tooltips$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Reprodução aleatória';
	@override String get playTrailer => 'Reproduzir trailer';
	@override String get markAsWatched => 'Marcar como assistido';
	@override String get markAsUnwatched => 'Marcar como não assistido';
}

// Path: audioTracks
class Translations$audioTracks$pt extends Translations$audioTracks$en {
	Translations$audioTracks$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => 'Faixa de áudio ${n}';
}

// Path: videoControls
class Translations$videoControls$pt extends Translations$videoControls$en {
	Translations$videoControls$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Áudio';
	@override String get subtitlesLabel => 'Legendas';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String get letterbox => 'Letterbox';
	@override String get fillScreen => 'Preencher tela';
	@override String get stretch => 'Esticar';
	@override String get lockRotation => 'Travar rotação';
	@override String get unlockRotation => 'Destravar rotação';
	@override String get timerActive => 'Temporizador ativo';
	@override String playbackWillPauseIn({required Object duration}) => 'A reprodução pausará em ${duration}';
	@override String get sleepTimerEndOfVideo => 'Fim do vídeo atual';
	@override String get sleepTimerStopAtHeader => 'Parar em';
	@override String get sleepTimerDurationHeader => 'Temporizador';
	@override String get playbackWillPauseAtEnd => 'A reprodução pausará no final deste vídeo';
	@override String get stillWatching => 'Ainda assistindo?';
	@override String pausingIn({required Object seconds}) => 'Pausando em ${seconds}s';
	@override String get continueWatching => 'Continuar';
	@override String get autoPlayNext => 'Reproduzir Próximo Automaticamente';
	@override String get playNext => 'Reproduzir Próximo';
	@override String get playButton => 'Reproduzir';
	@override String get pauseButton => 'Pausar';
	@override String get playbackPaused => 'Pausado';
	@override String get playbackResumed => 'Reproduzindo';
	@override String get loadingVideo => 'Carregando vídeo';
	@override String get showPlaybackControls => 'Mostrar controles de reprodução';
	@override String get hidePlaybackControls => 'Ocultar controles de reprodução';
	@override String seekBackwardButton({required Object seconds}) => 'Retroceder ${seconds} segundos';
	@override String seekForwardButton({required Object seconds}) => 'Avançar ${seconds} segundos';
	@override String get previousButton => 'Episódio anterior';
	@override String get nextButton => 'Próximo episódio';
	@override String get previousChapterButton => 'Capítulo anterior';
	@override String get nextChapterButton => 'Próximo capítulo';
	@override String get muteButton => 'Silenciar';
	@override String get unmuteButton => 'Ativar som';
	@override String get settingsButton => 'Configurações de reprodução';
	@override String get tracksButton => 'Áudio e legendas';
	@override String get chaptersButton => 'Capítulos';
	@override String get segmentLoopHelp => 'Faça uma seção durante este playback. Configura A, depois confira B mais tarde na linha de tempo.';
	@override String get setLoopStart => 'Começando com o gênero (A)';
	@override String get setLoopEnd => 'Coloque o fim do loop (B)';
	@override String get clearSegmentLoop => 'Clareamento de segmento';
	@override String get setLoopStartFirst => 'Coloque o início (A) antes do fim (B).';
	@override String get loopEndAfterStart => 'O final da curva deve ser mais tarde do que o início.';
	@override String get segmentLoopUnavailable => 'Segment looping não está disponível para este playback.';
	@override String get loopPointNotSet => 'Não estabelece';
	@override String get bookmarksHelp => 'As notas são salvas neste dispositivo. selecione uma para ir a esse tempo.';
	@override String get bookmarksButton => 'Bookmarcação';
	@override String get chaptersAndBookmarks => 'Capítulos e Bookmarks';
	@override String get segmentLoop => 'Segmentação Loop';
	@override String get addBookmark => 'Adicionar Bookmark';
	@override String get bookmarkName => 'Nome do Bookmark';
	@override String get bookmarkNameHint => 'Por exemplo, a cena de abertura';
	@override String bookmarkDefaultName({required Object n}) => 'Bookmarcação ${n}';
	@override String get bookmarkNameRequired => 'Digite um nome para este livro.';
	@override String get deleteBookmark => 'Eliminar o Bookmark';
	@override String get bookmarkLimitReached => 'Este item já tem 100 bookmarks.';
	@override String get bookmarkUnavailable => 'Não podia salvar ou remover este bookmark.';
	@override String get bookmarkSaved => 'Bookmark foi salvo.';
	@override String get bookmarkDeleted => 'Bookmark foi apagado.';
	@override String loopPointSet({required Object point, required Object time}) => 'Ponto de Loop ${point} Estabelecendo em ${time}.';
	@override String get noChaptersOrBookmarks => 'Não há capítulos ou livros disponíveis.';
	@override String get versionQualityButton => 'Versão e qualidade';
	@override String get versionColumnHeader => 'Versão';
	@override String get qualityColumnHeader => 'Qualidade';
	@override String get qualityOriginal => 'Original';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => 'Transcodificação indisponível — reproduzindo qualidade original';
	@override String get subtitleUnavailableFallback => 'Não foi possível carregar as legendas selecionadas — a reprodução continuará sem legendas';
	@override String get pipButton => 'Modo Picture-in-Picture';
	@override String get aspectRatioButton => 'Proporção';
	@override String get ambientLighting => 'Iluminação ambiente';
	@override String get fullscreenButton => 'Entrar em tela cheia';
	@override String get exitFullscreenButton => 'Sair da tela cheia';
	@override String get alwaysOnTopButton => 'Sempre no topo';
	@override String get rotationLockButton => 'Travar rotação';
	@override String get lockScreen => 'Travar tela';
	@override String get screenLockButton => 'Travar tela';
	@override String get timelineSlider => 'Linha do tempo do vídeo';
	@override String get volumeSlider => 'Nível de volume';
	@override String endsAt({required Object time}) => 'Termina às ${time}';
	@override String get pipActive => 'Reproduzindo em Picture-in-Picture';
	@override String get pipFailed => 'Falha ao iniciar picture-in-picture';
	@override String get screenshotSaved => 'Captura de tela salva';
	@override String get screenshotFailed => 'Não foi possível fazer a captura de tela';
	@override String zoomPercent({required Object percent}) => 'Zoom ${percent}%';
	@override String volumePercent({required Object percent}) => 'Volume ${percent}%';
	@override late final Translations$videoControls$pipErrors$pt pipErrors = Translations$videoControls$pipErrors$pt.internal(_root);
	@override String get chapters => 'Capítulos';
	@override String get noChaptersAvailable => 'Nenhum capítulo disponível';
	@override String get queue => 'Fila';
	@override String get noQueueItems => 'Nenhum item na fila';
	@override String get noAudioDevicesAvailable => 'Nenhum dispositivo de áudio disponível';
	@override String get searchSubtitles => 'Pesquisar legendas';
	@override String get language => 'Idioma';
	@override String get noSubtitlesFound => 'Nenhuma legenda encontrada';
	@override String get subtitleDownloaded => 'Legenda baixada';
	@override String get subtitleDownloadedNotApplied => 'A legenda foi baixada, mas não foi possível selecioná-la';
	@override String get subtitleDownloadFailed => 'Falha ao baixar legenda';
	@override String get searchLanguages => 'Pesquisar idiomas...';
	@override String get skipIntro => 'Pular abertura';
	@override String get skipCredits => 'Pular créditos';
	@override String get nextEpisode => 'Próximo episódio';
	@override String subtitleTrack({required Object n}) => 'Faixa ${n}';
	@override String subtitleFile({required Object name}) => 'Legenda ${name}';
	@override String forcedTrack({required Object label}) => '${label} (Forçada)';
	@override String get osdSubtitlesOff => 'Legendas: desativadas';
	@override String osdSubtitles({required Object track}) => 'Legendas: ${track}';
	@override String osdAudio({required Object track}) => 'Áudio: ${track}';
	@override String frameCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Conexão',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} quadros',
	);
	@override String get trackSelectionTitle => 'Escolha as faixas antes do playback';
	@override String get trackSelectionAuto => 'Seleção automática';
	@override String get openMiniPlayer => 'Descrição do Mini Player';
	@override String get returnToFullPlayer => 'Voltar para o jogador completo';
	@override String get loadSubtitleFile => 'Carregar o arquivo subtítulo...';
	@override String get subtitleLoadFailed => 'Não conseguiu carregar o arquivo subtítulo';
	@override String get skipAds => 'Escape de anúncios';
	@override String get tapToUnlock => 'Toque para desbloquear';
	@override String get tapAgainToUnlock => 'Toque novamente para desbloquear';
}

// Path: messages
class Translations$messages$pt extends Translations$messages$en {
	Translations$messages$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Marcado como assistido';
	@override String get markedAsUnwatched => 'Marcado como não assistido';
	@override String get markedAsWatchedOffline => 'Marcado como assistido (será sincronizado quando online)';
	@override String get markedAsUnwatchedOffline => 'Marcado como não assistido (será sincronizado quando online)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'Removido automaticamente: ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: 'Removido automaticamente ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} download assistido',
		other: 'Removidos automaticamente ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} downloads assistidos',
	);
	@override String get removedFromContinueWatching => 'Removido de Continuar assistindo';
	@override String errorLoading({required Object error}) => 'Erro: ${error}';
	@override String get searchPartialResults => 'Alguns servidores de mídia não puderam ser pesquisados. Exibindo os resultados disponíveis.';
	@override String get streamInterrupted => 'A transmissão foi interrompida. Pressione reproduzir ou avance para tentar novamente.';
	@override String get liveStreamInterrupted => 'A transmissão ao vivo foi interrompida. Pressione reproduzir para tentar novamente.';
	@override String get fileInfoNotAvailable => 'Informações do arquivo não disponíveis';
	@override String get playbackAuthenticationRequired => 'Entre novamente no servidor de mídia para reproduzir este item.';
	@override String get playbackServerUnavailable => 'O servidor de mídia está indisponível. Tente novamente mais tarde.';
	@override String get playbackDataInvalid => 'O servidor retornou informações de reprodução inválidas.';
	@override String get playbackCancelled => 'A reprodução foi cancelada.';
	@override String get playbackFailed => 'Não foi possível iniciar a reprodução.';
	@override String playbackFailedDetail({required Object error}) => 'Não foi possível iniciar a reprodução: ${error}';
	@override String get audioOutputFailed => 'A saída de áudio parou de responder. Verifique a conexão de áudio da TV ou do receptor; se outros aplicativos também estiverem sem som, reinicie o dispositivo.';
	@override String get mediaUnavailable => 'Este conteúdo não está mais disponível.';
	@override String errorLoadingFileInfo({required Object error}) => 'Erro ao carregar as informações do arquivo: ${error}';
	@override String get errorLoadingSeries => 'Erro ao carregar série';
	@override String get musicNotSupported => 'A reprodução de música ainda não é compatível';
	@override String get noDescriptionAvailable => 'Nenhuma descrição disponível';
	@override String get noProfilesAvailable => 'Nenhum perfil disponível';
	@override String get contactAdminForProfiles => 'Entre em contato com o administrador do servidor para adicionar perfis';
	@override String get unableToDetermineLibrarySection => 'Não foi possível determinar a seção da biblioteca deste item';
	@override String get logsCleared => 'Logs limpos';
	@override String get logsCopied => 'Logs copiados para a área de transferência';
	@override String get noLogsAvailable => 'Nenhum log disponível';
	@override String libraryScanning({required Object title}) => 'Escaneando "${title}"...';
	@override String libraryScanStarted({required Object title}) => 'Escaneamento da biblioteca iniciado para "${title}"';
	@override String libraryScanFailed({required Object error}) => 'Falha ao escanear biblioteca: ${error}';
	@override String metadataRefreshing({required Object title}) => 'Atualizando metadados de "${title}"...';
	@override String metadataRefreshStarted({required Object title}) => 'Atualização de metadados iniciada para "${title}"';
	@override String metadataRefreshFailed({required Object error}) => 'Falha ao atualizar metadados: ${error}';
	@override String get logoutConfirm => 'Tem certeza de que deseja sair?';
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
	@override String get switchingToCompatiblePlayer => 'Alternando para um reprodutor compatível...';
	@override String get serverLimitTitle => 'Falha na reprodução';
	@override String get serverLimitBody => 'Erro do servidor (HTTP 500). Um limite de largura de banda ou transcodificação provavelmente rejeitou esta sessão. Peça ao proprietário do servidor para ajustá-lo.';
	@override String get mediaUnreadableTitle => 'Arquivo indisponível';
	@override String get mediaUnreadableBody => 'O servidor encontrou este item, mas não conseguiu ler o arquivo (HTTP 404). O arquivo provavelmente foi movido, excluído ou o armazenamento está offline. Peça ao responsável pelo servidor para verificar o arquivo e reexaminar a biblioteca.';
	@override String get serverBusyTitle => 'Transmissão indisponível';
	@override String get serverBusyBody => 'O servidor continuou se recusando a transmitir este arquivo (HTTP 503). Ele pode estar reiniciando ou ocupado, ou o armazenamento do arquivo pode estar offline. Tente novamente em instantes — se isso continuar acontecendo, peça ao proprietário do servidor para verificar o servidor e o armazenamento do arquivo.';
	@override String get playbackNotAllowedTitle => 'Reprodução não permitida';
	@override String get playbackNotAllowedBody => 'O servidor se recusou a transmitir este item (HTTP 403). Sua conta pode não ter permissão para reproduzi-lo, ou o servidor pode permitir a reprodução apenas na própria rede local.';
	@override String get logsUploaded => 'Logs enviados';
	@override String get logsUploadFailed => 'Falha ao enviar logs';
	@override String get logId => 'ID do log';
	@override String get burnedSubtitlesUseMenu => 'As legendas estão incorporadas a esta transmissão. Altere-as no menu de legendas.';
	@override String get noVideoUrl => 'Nenhuma URL de vídeo disponível';
	@override String get playbackNoMediaSources => 'O servidor não retornou nenhuma fonte de mídia reproduzível';
	@override String get playbackDataNotPrepared => 'A reprodução foi iniciada antes que os dados estivessem prontos';
	@override String get streamSelectionUnavailable => 'A seleção de fluxos não está disponível para esta fonte';
	@override String get streamSelectionFailed => 'Não foi possível aplicar os fluxos selecionados';
	@override String get trackSelectionNotRemembered => 'Esta escolha de faixa se aplica apenas à reprodução atual.';
	@override String get serverUnavailableForProfile => 'Nenhum servidor está disponível para o perfil ativo';
}

// Path: subtitlingStyling
class Translations$subtitlingStyling$pt extends Translations$subtitlingStyling$en {
	Translations$subtitlingStyling$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get previewSample => 'O rápido fogo marrão salta sobre o cão louco';
	@override String get text => 'Texto';
	@override String get border => 'Borda';
	@override String get background => 'Fundo';
	@override String get fontSize => 'Tamanho da Fonte';
	@override String get textColor => 'Cor do Texto';
	@override String get borderSize => 'Tamanho da Borda';
	@override String get borderColor => 'Cor da Borda';
	@override String get backgroundOpacity => 'Opacidade do Fundo';
	@override String get backgroundColor => 'Cor de Fundo';
	@override String get position => 'Posição';
	@override String get assOverride => 'Substituição ASS';
	@override String get overrideScale => 'Dimensionar';
	@override String get overrideForce => 'Forçar';
	@override String get overrideStrip => 'Remover estilo';
	@override String get positionTop => 'Superior';
	@override String get positionBottom => 'Inferior';
	@override String get useMargins => 'Usar margens';
	@override String get useMarginsDescription => 'Permitir legendas de texto no espaço fora do vídeo. Legendas estilizadas podem manter sua posição original.';
	@override String get anchorToScreen => 'Ancorar à tela';
	@override String get anchorToScreenDescription => 'Exibir as legendas de texto nas faixas pretas abaixo de vídeos em tela ampla';
	@override String get bold => 'Negrito';
	@override String get italic => 'Itálico';
	@override String get renderResolution => 'Resolução de renderização';
	@override String get renderResolutionScreen => 'Resolução da tela';
	@override String get renderResolutionVideo => 'Resolução do vídeo';
	@override String get fontSizeDescription => 'Configurar o tamanho do texto subtítulo neste dispositivo.';
	@override String get textColorDescription => 'Escolha a cor utilizada para o texto subtítulo.';
	@override String get borderSizeDescription => 'Defina a espessura do outline em torno do texto subtítulo.';
	@override String get borderColorDescription => 'Escolha a cor utilizada para o subtítulo.';
	@override String get backgroundColorDescription => 'Escolha a cor por trás do texto subjetivo.';
	@override String get backgroundOpacityDescription => 'Defina o quão transparente é o fundo do subtítulo: 0% é claro e 100% sólido.';
	@override String get positionDescription => 'Move os subtítulos verticalmente. 0% é o topo do vídeo e 100% é o fundo.';
	@override String get assOverrideDescription => 'Escolha se o jogador segue, ajusta, substitui ou remove estilos incorporados em subtítulos ASS.';
	@override late final Translations$subtitlingStyling$assOverrideOptions$pt assOverrideOptions = Translations$subtitlingStyling$assOverrideOptions$pt.internal(_root);
	@override String get renderResolutionDescription => 'Escolha a resolução usada para rasterizar imagens e subtítulos ASS. Escalas Android inferiores podem reduzir o trabalho de renderização, mas parecem mais suaves.';
	@override late final Translations$subtitlingStyling$renderResolutionOptions$pt renderResolutionOptions = Translations$subtitlingStyling$renderResolutionOptions$pt.internal(_root);
	@override String get boldDescription => 'Desenhe texto subtítulo em um peso mais pesado.';
	@override String get italicDescription => 'Desenho de subtitulo em italiano.';
}

// Path: mpvConfig
class Translations$mpvConfig$pt extends Translations$mpvConfig$en {
	Translations$mpvConfig$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => 'Configurações avançadas do reprodutor de vídeo';
	@override String get presets => 'Predefinições';
	@override String get noPresets => 'Nenhuma predefinição salva';
	@override String get saveAsPreset => 'Salvar como Predefinição...';
	@override String get presetName => 'Nome da Predefinição';
	@override String get presetNameHint => 'Insira um nome para esta predefinição';
	@override String get loadPreset => 'Carregar';
	@override String get deletePreset => 'Excluir';
	@override String get presetSaved => 'Predefinição salva';
	@override String get presetLoaded => 'Predefinição carregada';
	@override String get presetDeleted => 'Predefinição excluída';
	@override String get confirmDeletePreset => 'Tem certeza de que deseja excluir esta predefinição?';
	@override String get configPlaceholder => 'gpu-api=vulkan\nhwdec=auto\n# comment';
	@override String get lineHint => 'option=value';
	@override String get addLine => 'Adicionar linha';
	@override String get removeLine => 'Remover linha';
	@override String get embeddedVoHint => 'vo, gpu-context e gpu-api são ignorados no Linux: o vídeo incorporado é sempre renderizado via vo=libmpv no plano de vídeo, e gpu-next (necessário para shaders de computação como ArtCNN) não pode ser executado incorporado.';
}

// Path: dialog
class Translations$dialog$pt extends Translations$dialog$en {
	Translations$dialog$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Confirmar Ação';
}

// Path: profiles
class Translations$profiles$pt extends Translations$profiles$en {
	Translations$profiles$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'Adicionar perfil PlezyNG';
	@override String get switchingProfile => 'Mudando perfil…';
	@override String get deleteThisProfileTitle => 'Excluir este perfil?';
	@override String deleteThisProfileMessage({required Object displayName}) => 'Remover ${displayName}. As conexões não serão afetadas.';
	@override String get active => 'Ativo';
	@override String get manage => 'Gerenciar';
	@override String get delete => 'Excluir';
	@override String get signOut => 'Sair';
	@override String get signOutPlexTitle => 'Sair do Plex?';
	@override String signOutPlexMessage({required Object displayName}) => 'Remover ${displayName} e todos os usuários do Plex Home? Você pode entrar novamente quando quiser.';
	@override String get signOutPlexDeleteDownloads => 'Também excluir downloads';
	@override String get signOutPlexDeleteDownloadsDescription => 'Caso contrário, eles permanecem neste dispositivo e voltam quando você entrar novamente nesta conta.';
	@override String get signedOutPlex => 'Saiu do Plex.';
	@override String get signOutFailed => 'Falha ao sair.';
	@override String get sectionTitle => 'Perfis';
	@override String get summarySingle => 'Adicione perfis para combinar usuários gerenciados e identidades locais';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} perfis · ativo: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} perfis';
	@override String get removeConnectionTitle => 'Remover conexão?';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => 'Remover acesso de ${displayName} a ${connectionLabel}. Outros perfis mantêm o acesso.';
	@override String get deleteProfileTitle => 'Excluir perfil?';
	@override String deleteProfileMessage({required Object displayName}) => 'Remover ${displayName} e suas conexões. Servidores continuam disponíveis.';
	@override String get profileNameLabel => 'Nome do perfil';
	@override String get pinProtectionLabel => 'Proteção por PIN';
	@override String get copyAutomationLink => 'Copia Android link de automação';
	@override String get copyAutomationLinkDescription => 'Selecione este perfil de uma intenção ou automação Android. verificações de PIN do perfil ainda se aplicam.';
	@override String get automationLinkCopied => 'O link de automação do perfil é copiado.';
	@override String get pinManagedByPlex => 'PIN gerenciado pelo Plex. Edite em plex.tv.';
	@override String get noPinSetEditOnPlex => 'Nenhum PIN definido. Para exigir um, edite o usuário do Plex Home em plex.tv.';
	@override String get setPin => 'Definir PIN';
	@override String get setPinTitle => 'Definir PIN';
	@override String get confirmPinTitle => 'Confirmar PIN';
	@override String get pinSet => 'PIN definido';
	@override String get changePin => 'Alterar';
	@override String get removePin => 'Remover';
	@override String get connectionsLabel => 'Conexões';
	@override String get add => 'Adicionar';
	@override String get deleteProfileButton => 'Excluir perfil';
	@override String get noConnectionsHint => 'Sem conexões — adicione uma para usar este perfil.';
	@override String get noConnections => 'Sem conexões';
	@override String get plexHomeAccount => 'Conta Plex Home';
	@override String plexAccountChip({required Object account}) => 'Conta Plex: ${account}';
	@override String plexAccountUserChip({required Object user, required Object account}) => '${user} via ${account}';
	@override String get connectionDefault => 'Padrão';
	@override String connectionAs({required Object displayName}) => 'como ${displayName}';
	@override String get makeDefault => 'Definir como padrão';
	@override String get removeConnection => 'Remover';
	@override String get profileRenamed => 'Perfil renomeado.';
	@override String borrowAddTo({required Object displayName}) => 'Adicionar a ${displayName}';
	@override String get borrowExplain => 'Use a conexão de outro perfil. Perfis protegidos por PIN exigem PIN.';
	@override String get borrowEmpty => 'Nenhuma conexão disponível ainda.';
	@override String get borrowEmptySubtitle => 'Conecte Plex, Jellyfin ou Emby a outro perfil primeiro.';
	@override String get borrowLoadFailed => 'Não foi possível carregar as conexões disponíveis. Tente novamente.';
	@override String borrowFromProfile({required Object displayName}) => 'De ${displayName}';
	@override String get borrowConnectionBorrowed => 'Conexão adicionada ao perfil.';
	@override String get borrowFailed => 'Não foi possível adicionar a conexão.';
	@override String get incorrectPin => 'PIN incorreto.';
	@override String get incorrectPinTryAgain => 'PIN incorreto. Tente novamente.';
	@override String get sourceProfileMissingParentAccount => 'O perfil de origem não tem a conta principal.';
	@override String get failedToLoadHomeUsers => 'Não foi possível carregar os usuários do Plex Home. Verifique sua conexão e tente novamente.';
	@override String get failedToVerifyPin => 'Não foi possível verificar o PIN.';
	@override String get newProfile => 'Novo perfil';
	@override String get profileNameHint => 'Ex.: Visitantes, Crianças, Sala de família';
	@override String get pinProtectionOptional => 'Proteção por PIN (opcional)';
	@override String get pinExplain => 'PIN de 4 dígitos necessário para trocar perfis.';
	@override String get continueButton => 'Continuar';
	@override String get pinsDontMatch => 'Os PINs não correspondem';
	@override String get tokenIdentityMismatch => 'O token do perfil do Plex foi associado a um servidor inesperado';
	@override String get settingsLocked => 'As configurações estão bloqueadas para este perfil.';
	@override String get unlockSettings => 'Desbloquear configurações';
	@override String get showExploreForProfile => 'Mostrar Explore para este perfil';
	@override String get showExploreForProfileDescription => 'Desligue para remover Explore da navegação deste perfil.';
}

// Path: connections
class Translations$connections$pt extends Translations$connections$en {
	Translations$connections$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Conexões';
	@override String get addConnection => 'Adicionar conexão';
	@override String get addConnectionSubtitleNoProfile => 'Entre com Plex ou conecte um servidor Jellyfin ou Emby';
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'Adicionar a ${displayName}: Plex, Jellyfin, Emby ou outra conexão de perfil';
	@override String sessionExpiredOne({required Object name}) => 'Sessão de ${name} expirada';
	@override String sessionExpiredMany({required Object count}) => 'Sessões expiradas em ${count} servidores';
	@override String accessDeniedOne({required Object name}) => '${name} negou acesso a esta conta';
	@override String accessDeniedMany({required Object count}) => '${count} servidores negaram acesso a esta conta';
	@override String get signInAgain => 'Entrar novamente';
	@override String editMediaBrowserTitle({required Object product}) => 'Editar conexão do ${product}';
	@override String editMediaBrowserIntro({required Object serverName}) => 'Adicione ou remova URLs para ${serverName}. O PlezyNG usará a URL acessível com menor latência.';
}

// Path: accountPreferences
class Translations$accountPreferences$pt extends Translations$accountPreferences$en {
	Translations$accountPreferences$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Preferências da conta';
	@override String hubSubtitleSingle({required Object account}) => 'Opções de áudio, legendas e biblioteca salvas em ${account}';
	@override String hubSubtitleMultiple({required Object count}) => 'Opções de áudio, legendas e biblioteca salvas em ${count} contas';
	@override String get pickAccount => 'Cada conta armazena suas próprias preferências. Escolha a que deseja editar.';
	@override String get storedOnAccount => 'Estas opções são salvas na própria conta, então todos os apps conectados a ela as utilizam — inclusive o PlezyNG nos seus outros dispositivos.';
	@override String get noAccounts => 'Nenhuma conta para configurar';
	@override String get noAccountsHint => 'Entre no Plex ou conecte um servidor Jellyfin ou Emby, e as preferências armazenadas nessa conta aparecerão aqui.';
	@override String get unavailable => 'Não foi possível acessar esta conta';
	@override String get loadFailed => 'Não foi possível carregar estas preferências';
	@override String get noPreference => 'Sem preferência';
	@override String get notSet => 'Não definido';
	@override late final Translations$accountPreferences$groups$pt groups = Translations$accountPreferences$groups$pt.internal(_root);
	@override String get preferredAudioLanguage => 'Idioma de áudio preferido';
	@override String get autoSelectAudio => 'Escolher áudio pelo idioma';
	@override String get autoSelectAudioDescription => 'Desativado mantém a faixa de áudio que o arquivo marca como padrão.';
	@override String get preferredSubtitleLanguage => 'Idioma de legenda preferido';
	@override String get subtitleMode => 'Ativar legendas';
	@override late final Translations$accountPreferences$subtitleModes$pt subtitleModes = Translations$accountPreferences$subtitleModes$pt.internal(_root);
	@override String get subtitleAccessibility => 'Legendas SDH';
	@override late final Translations$accountPreferences$subtitleAccessibilityOptions$pt subtitleAccessibilityOptions = Translations$accountPreferences$subtitleAccessibilityOptions$pt.internal(_root);
	@override String get forcedSubtitles => 'Legendas forçadas';
	@override late final Translations$accountPreferences$forcedSubtitleOptions$pt forcedSubtitleOptions = Translations$accountPreferences$forcedSubtitleOptions$pt.internal(_root);
	@override String get displayMissingEpisodes => 'Mostrar episódios ausentes';
	@override String get displayMissingEpisodesDescription => 'Listar episódios que o servidor conhece, mas para os quais não há arquivo.';
	@override String get hidePlayedInLatest => 'Ocultar itens assistidos em Recentes';
	@override String get hidePlayedInLatestDescription => 'Manter fora das linhas Recentes do servidor os itens que você já assistiu.';
	@override String get displayCollectionsView => 'Mostrar a visualização de Coleções';
	@override String get displayCollectionsViewDescription => 'Oferecer a visualização de Coleções do servidor junto às suas bibliotecas.';
	@override String get rewatchingInNextUp => 'Manter séries reassistidas em A seguir';
	@override String get rewatchingInNextUpDescription => 'Ao terminar uma série, comece a assistir de novo e A seguir acompanha a reexibição em vez de remover a série.';
	@override String get watchedIndicator => 'Indicadores de assistido';
	@override late final Translations$accountPreferences$watchedIndicatorOptions$pt watchedIndicatorOptions = Translations$accountPreferences$watchedIndicatorOptions$pt.internal(_root);
	@override String get mediaReviewsVisibility => 'Avaliações e resenhas';
	@override late final Translations$accountPreferences$mediaReviewsOptions$pt mediaReviewsOptions = Translations$accountPreferences$mediaReviewsOptions$pt.internal(_root);
	@override String get preferredAudioLanguageDescription => 'Preferir as faixas de áudio neste idioma quando o servidor ou jogador seleciona automaticamente uma faixa.';
	@override String get preferredSubtitleLanguageDescription => 'Prefira rastrear subtítulos neste idioma quando os subtitulos são selecionados automaticamente.';
	@override String get subtitleAccessibilityDescription => 'Escolha se as capções SDH são preferidas ou necessárias durante a seleção automática de subtitulos.';
	@override String get forcedSubtitleDescription => 'Escolha se as faixas forçadas são preferidas ou necessárias durante a seleção automática.';
	@override String get watchedIndicatorDescription => 'Escolha quais tipos de mídia recebem um checkmark observado na interface do servidor.';
	@override String get mediaReviewsVisibilityDescription => 'Escolha qual audiência e classificações críticas o servidor mostra nas páginas de mídia.';
	@override String get subtitleModeDescription => 'Escolha quando os subtítulos se ativam automaticamente para esta conta do servidor.';
	@override String get hubDescription => 'Estas preferências são armazenadas na sua conta de servidor de mídia e podem aplicar-se também a outros clientes.';
}

// Path: discover
class Translations$discover$pt extends Translations$discover$en {
	Translations$discover$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Descobrir';
	@override String get noContentAvailable => 'Nenhum conteúdo disponível';
	@override String get addMediaToLibraries => 'Adicione mídias às suas bibliotecas';
	@override String get continueWatching => 'Continuar Assistindo';
	@override String continueWatchingIn({required Object library}) => 'Continuar assistindo em ${library}';
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
	@override late final Translations$discover$findNext$pt findNext = Translations$discover$findNext$pt.internal(_root);
	@override String get extras => 'Trailers e extras';
	@override String get studio => 'Estúdio';
	@override String get rating => 'Avaliação';
	@override String get director => 'Diretor';
	@override String get directors => 'Diretores';
	@override String get movie => 'Filme';
	@override String get tvShow => 'Série de TV';
	@override String minutesLeft({required Object minutes}) => '${minutes} min restantes';
	@override String get moreLikeThis => 'Títulos semelhantes';
	@override String titleCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} título',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} títulos',
	);
	@override late final Translations$discover$person$pt person = Translations$discover$person$pt.internal(_root);
}

// Path: errors
class Translations$errors$pt extends Translations$errors$en {
	Translations$errors$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Falha na busca: ${error}';
	@override String get searchUnavailable => 'A busca não conseguiu alcançar nenhum servidor de mídia.';
	@override String connectionTimeout({required Object context}) => 'Tempo de conexão esgotado ao carregar ${context}';
	@override String get connectionFailed => 'Não foi possível conectar ao servidor de mídia';
	@override String unableToLoad({required Object context}) => 'Não foi possível carregar ${context}. Tente novamente.';
	@override String get noClientAvailable => 'Nenhum cliente disponível';
	@override String get pleaseEnterToken => 'Insira um token';
	@override String get invalidToken => 'Token inválido';
	@override String failedToVerifyToken({required Object error}) => 'Falha ao verificar token: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Falha ao trocar para ${displayName}';
	@override String failedToDeleteProfile({required Object displayName}) => 'Falha ao excluir ${displayName}';
	@override String get failedToRate => 'Não foi possível atualizar a classificação';
	@override String get reasonTimedOut => 'o tempo de conexão se esgotou';
	@override String get reasonUnreachable => 'não foi possível alcançar o servidor';
	@override String get reasonRefused => 'o servidor recusou a solicitação';
	@override String get reasonNotFound => 'o item não está mais no servidor';
	@override String get reasonServerError => 'o servidor relatou um erro';
	@override String get reasonCancelled => 'a solicitação foi cancelada';
	@override String get reasonUnexpected => 'ocorreu um erro inesperado';
}

// Path: libraries
class Translations$libraries$pt extends Translations$libraries$en {
	Translations$libraries$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get playRandomMovie => 'Jogue um filme aleatório';
	@override String get randomPickFailed => 'Não podia escolher um filme aleatório desta biblioteca.';
	@override String get title => 'Bibliotecas';
	@override String get fallbackTitle => 'Biblioteca';
	@override String get scanLibraryFiles => 'Escanear Arquivos da Biblioteca';
	@override String get scanLibrary => 'Escanear Biblioteca';
	@override String get analyze => 'Analisar';
	@override String get analyzeLibrary => 'Analisar Biblioteca';
	@override String get refreshMetadata => 'Atualizar Metadados';
	@override String get emptyTrash => 'Esvaziar Lixeira';
	@override String emptyingTrash({required Object title}) => 'Esvaziando lixeira de "${title}"...';
	@override String trashEmptied({required Object title}) => 'Lixeira esvaziada de "${title}"';
	@override String failedToEmptyTrash({required Object error}) => 'Falha ao esvaziar lixeira: ${error}';
	@override String analyzing({required Object title}) => 'Analisando "${title}"...';
	@override String analysisStarted({required Object title}) => 'Análise iniciada para "${title}"';
	@override String failedToAnalyze({required Object error}) => 'Falha ao analisar biblioteca: ${error}';
	@override String get noLibrariesFound => 'Nenhuma biblioteca encontrada';
	@override String get allLibrariesHidden => 'Todas as bibliotecas estão ocultas';
	@override String hiddenLibrariesCount({required Object count}) => 'Bibliotecas ocultas (${count})';
	@override String get thisLibraryIsEmpty => 'Esta biblioteca está vazia';
	@override String get noItemsMatchFilters => 'Nenhum item corresponde aos filtros ativos';
	@override String get resetFilters => 'Redefinir filtros';
	@override String get all => 'Todos';
	@override String get clearAll => 'Limpar tudo';
	@override String scanLibraryConfirm({required Object title}) => 'Tem certeza de que deseja escanear "${title}"?';
	@override String analyzeLibraryConfirm({required Object title}) => 'Tem certeza de que deseja analisar "${title}"?';
	@override String refreshMetadataConfirm({required Object title}) => 'Tem certeza de que deseja atualizar os metadados de "${title}"?';
	@override String emptyTrashConfirm({required Object title}) => 'Tem certeza de que deseja esvaziar a lixeira de "${title}"?';
	@override String get manageLibraries => 'Gerenciar Bibliotecas';
	@override String get sort => 'Ordenar';
	@override String get sortBy => 'Ordenar por';
	@override String get filters => 'Filtros';
	@override String get confirmActionMessage => 'Tem certeza de que deseja realizar esta ação?';
	@override String get showLibrary => 'Mostrar biblioteca';
	@override String get hideLibrary => 'Ocultar biblioteca';
	@override String get libraryOptions => 'Opções da biblioteca';
	@override String get content => 'conteúdo da biblioteca';
	@override String get selectLibrary => 'Selecionar biblioteca';
	@override String filtersWithCount({required Object count}) => 'Filtros (${count})';
	@override String get noRecommendations => 'Nenhuma recomendação disponível';
	@override String get noCollections => 'Nenhuma coleção nesta biblioteca';
	@override String get noFoldersFound => 'Nenhuma pasta encontrada';
	@override String get folders => 'pastas';
	@override late final Translations$libraries$tabs$pt tabs = Translations$libraries$tabs$pt.internal(_root);
	@override late final Translations$libraries$groupings$pt groupings = Translations$libraries$groupings$pt.internal(_root);
	@override late final Translations$libraries$filterCategories$pt filterCategories = Translations$libraries$filterCategories$pt.internal(_root);
	@override late final Translations$libraries$sortLabels$pt sortLabels = Translations$libraries$sortLabels$pt.internal(_root);
	@override late final Translations$libraries$advancedFilters$pt advancedFilters = Translations$libraries$advancedFilters$pt.internal(_root);
	@override late final Translations$libraries$selection$pt selection = Translations$libraries$selection$pt.internal(_root);
}

// Path: about
class Translations$about$pt extends Translations$about$en {
	Translations$about$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Sobre';
	@override String get openSourceLicenses => 'Licenças de código aberto';
	@override String versionLabel({required Object version}) => 'Versão ${version}';
	@override String get appDescription => 'Um belo cliente de Plex, Jellyfin e Emby feito com Flutter';
	@override String get viewLicensesDescription => 'Ver as licenças de bibliotecas de terceiros';
	@override String get privacyPolicy => 'Política de Privacidade';
}

// Path: serverSelection
class Translations$serverSelection$pt extends Translations$serverSelection$en {
	Translations$serverSelection$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Nenhum servidor encontrado para ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Falha ao carregar servidores: ${error}';
	@override String get noValidServers => 'Nenhum servidor utilizável foi encontrado nesta conta';
}

// Path: hubDetail
class Translations$hubDetail$pt extends Translations$hubDetail$en {
	Translations$hubDetail$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Título';
	@override String get releaseYear => 'Ano de Lançamento';
	@override String get dateAdded => 'Data de Adição';
	@override String get rating => 'Avaliação';
	@override String get noItemsFound => 'Nenhum item encontrado';
}

// Path: logs
class Translations$logs$pt extends Translations$logs$en {
	Translations$logs$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Limpar Logs';
	@override String get copyLogs => 'Copiar Logs';
	@override String get uploadLogs => 'Enviar Logs';
	@override String get saveLogs => 'Salve logs para arquivos';
	@override String logsSaved({required Object path}) => 'Registo salvo para ${path}';
	@override String get saveLogsFailed => 'Não consegui salvar o arquivo de log.';
}

// Path: startup
class Translations$startup$pt extends Translations$startup$en {
	Translations$startup$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'O PlezyNG não conseguiu iniciar';
	@override String get failedBody => 'Algo deu errado durante a inicialização. Os detalhes abaixo identificam o que falhou.';
	@override String get failedBodyRepairable => 'O arquivo de configurações salvo do PlezyNG está danificado e precisa ser reconstruído antes que o PlezyNG possa iniciar. Tentar novamente não vai ajudar — escolha Reparar armazenamento.';
	@override String get phaseLabel => 'Etapa';
	@override String get showDetails => 'Mostrar detalhes';
	@override String get hideDetails => 'Ocultar detalhes';
	@override String get copyDetails => 'Copiar detalhes';
	@override String get detailsCopied => 'Detalhes copiados para a área de transferência';
	@override String get uploadDetails => 'Enviar detalhes';
	@override String get repairStorage => 'Reparar armazenamento';
	@override String get repairTitle => 'Reparar dados armazenados?';
	@override String get repairBodyCommon => 'O arquivo de configurações do PlezyNG está danificado e não pode ser lido. Reparar redefine todas as configurações para o padrão.';
	@override String get repairBodyOneCredential => 'Um login salvo está danificado e não pode ser lido. Reparar remove apenas ele; suas outras configurações permanecem intactas.';
	@override String get repairBodySignInsKept => 'Seus servidores e perfis devem permanecer conectados.';
	@override String get repairBodySignInsLost => 'A chave que protege seus logins salvos não pode ser recuperada deste arquivo, então você terá que entrar novamente em todos os servidores e perfis. Nada no seu servidor de mídia é afetado.';
	@override String get repairBodySessionsUncertain => 'Os rastreadores (MAL, AniList, Simkl, Trakt) e o Seerr são armazenados separadamente e podem ou não ser preservados. O PlezyNG informará exatamente o que foi mantido.';
	@override String get repairConfirm => 'Reparar';
	@override String get repairSucceeded => 'Armazenamento reparado';
	@override String get repairNeedsRestart => 'Armazenamento reparado — reinício necessário';
	@override String get restartRequiredBody => 'Seus dados foram reparados, mas o PlezyNG precisa iniciar do zero antes de usá-los. Feche o PlezyNG e abra-o novamente.';
	@override String get quitPlezy => 'Sair do PlezyNG';
	@override String get repairFailed => 'Falha no reparo';
	@override String get repairKeptSignIns => 'Seus servidores e perfis ainda estão conectados.';
	@override String get repairLostSignIns => 'A chave que protege seus logins salvos não pôde ser recuperada. Você terá que entrar novamente em todos os servidores e perfis.';
	@override String get repairLostSessions => 'Pelo menos uma conexão de rastreador ou do Seerr foi perdida e precisa ser reconectada.';
	@override String get backupTitle => 'Uma cópia do arquivo danificado foi mantida';
	@override String get backupWarning => 'Ele contém suas credenciais de login. Não envie nem compartilhe.';
	@override String get deleteBackup => 'Excluir cópia';
	@override String get backupDeleted => 'Cópia excluída.';
	@override String get previousFailureTitle => 'O PlezyNG falhou ao iniciar da última vez';
}

// Path: licenses
class Translations$licenses$pt extends Translations$licenses$en {
	Translations$licenses$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Pacotes Relacionados';
	@override String get license => 'Licença';
	@override String licenseNumber({required Object number}) => 'Licença ${number}';
	@override String licensesCount({required Object count}) => '${count} licenças';
}

// Path: navigation
class Translations$navigation$pt extends Translations$navigation$en {
	Translations$navigation$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Bibliotecas';
	@override String get downloads => 'Downloads';
	@override String get liveTv => 'TV ao Vivo';
	@override String get explore => 'Explorar';
}

// Path: explore
class Translations$explore$pt extends Translations$explore$en {
	Translations$explore$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override late final Translations$explore$mdblistShelves$pt mdblistShelves = Translations$explore$mdblistShelves$pt.internal(_root);
	@override String get title => 'Explorar';
	@override String get selectSource => 'Selecionar fonte';
	@override late final Translations$explore$rows$pt rows = Translations$explore$rows$pt.internal(_root);
	@override late final Translations$explore$status$pt status = Translations$explore$status$pt.internal(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episódio',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episódios',
	);
	@override String get cast => 'Elenco';
	@override String get characters => 'Personagens';
	@override String get addToWatchlist => 'Adicionar à lista para assistir';
	@override String get removeFromWatchlist => 'Remover da lista para assistir';
	@override String get addedToWatchlist => 'Adicionado à lista de interesses';
	@override String get removedFromWatchlist => 'Removido da lista de interesses';
	@override String get watchlistUpdateFailed => 'Não foi possível atualizar a lista para assistir';
	@override String get watchlistNoMatch => 'Não foi possível associar este item a uma lista de interesses';
	@override String get notInLibrary => 'Não está na sua biblioteca';
	@override String get inTheseLibraries => 'Nestas bibliotecas';
	@override String get checkingLibrary => 'Verificando sua biblioteca...';
	@override String libraryCheckFailed({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: 'Não foi possível verificar ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} servidor',
		other: 'Não foi possível verificar ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} servidores',
	);
	@override String get emptyTitle => 'Ainda não há nada aqui';
	@override String emptyMessage({required Object source}) => 'As linhas de ${source} aparecerão aqui quando tiverem conteúdo.';
	@override String searchHint({required Object source}) => 'Buscar em ${source}';
	@override String searchEmpty({required Object query}) => 'Nenhum resultado para "${query}"';
	@override String searchPrompt({required Object source}) => 'Busque filmes e séries em ${source}.';
	@override String get searchFailed => 'Falha na busca. Verifique sua conexão e tente novamente.';
	@override late final Translations$explore$badge$pt badge = Translations$explore$badge$pt.internal(_root);
	@override late final Translations$explore$stats$pt stats = Translations$explore$stats$pt.internal(_root);
	@override late final Translations$explore$season$pt season = Translations$explore$season$pt.internal(_root);
	@override late final Translations$explore$format$pt format = Translations$explore$format$pt.internal(_root);
	@override late final Translations$explore$sourceMaterial$pt sourceMaterial = Translations$explore$sourceMaterial$pt.internal(_root);
	@override late final Translations$explore$creditRole$pt creditRole = Translations$explore$creditRole$pt.internal(_root);
	@override late final Translations$explore$relation$pt relation = Translations$explore$relation$pt.internal(_root);
	@override String broadcast({required Object day, required Object time}) => 'Vai ao ar ${day} às ${time}';
	@override String broadcastWithZone({required Object day, required Object time, required Object timezone}) => 'Vai ao ar ${day} às ${time} ${timezone}';
	@override late final Translations$explore$detail$pt detail = Translations$explore$detail$pt.internal(_root);
	@override String totalResults({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} resultado',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} resultados',
	);
}

// Path: liveTv
class Translations$liveTv$pt extends Translations$liveTv$en {
	Translations$liveTv$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'TV ao Vivo';
	@override String get guide => 'Guia';
	@override String get noChannels => 'Nenhum canal disponível';
	@override String get noDvr => 'Nenhum DVR configurado em nenhum servidor';
	@override String get serverUnavailable => 'O servidor de TV ao vivo não está disponível.';
	@override String get serverNotConnected => 'O servidor de TV ao vivo não está conectado.';
	@override String get noPrograms => 'Nenhum dado de programação disponível';
	@override String get liveStreamFailed => 'Falha na transmissão ao vivo';
	@override String get unknownProgram => 'Programa desconhecido';
	@override String get timelineLiveProgram => 'Programa ao vivo (a reprodução pode estar fora deste programa)';
	@override String get timelineBuffer => 'Timelã de Buffer';
	@override String get timelineUnavailable => 'Horário inacessível';
	@override String get timelineEstimated => 'Otimização do playback';
	@override String get timelinePending => 'Encontendo a busca';
	@override String get timelineStale => 'O calendário pode ser obsoleto';
	@override String get unknownHub => 'Desconhecido';
	@override String get unknownError => 'Erro desconhecido';
	@override String channelNumber({required Object number}) => 'Canal ${number}';
	@override String get unknownChannel => 'Canal desconhecido';
	@override String get live => 'AO VIVO';
	@override String get premiereBadge => 'Nova';
	@override String get reloadGuide => 'Recarregar Guia';
	@override String get searchGuide => 'Buscar no guia';
	@override String get searchHint => 'Buscar canais e programas';
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
	@override String get whatsOn => 'O que está passando';
	@override String get watchChannel => 'Assistir ao canal';
	@override String get favorites => 'Favoritos';
	@override String get reorderFavorites => 'Reordenar favoritos';
	@override String get noFavoriteChannels => 'Nenhum canal favorito';
	@override String get noFavoriteChannelsHint => 'Mostre todos os canais e mantenha um canal pressionado para adicioná-lo aos favoritos.';
	@override String get showAllChannels => 'Mostrar todos os canais';
	@override String get favoritesLoadFailed => 'Não foi possível carregar os favoritos. Verifique sua conexão e tente novamente.';
	@override String get favoritesUpdateFailed => 'Não foi possível atualizar os favoritos. Verifique sua conexão e tente novamente.';
	@override String get joinSession => 'Entrar na sessão em andamento';
	@override String watchFromStart({required Object minutes}) => 'Assistir do início (${minutes} min atrás)';
	@override String get watchLive => 'Assistir ao vivo';
	@override String get goToLive => 'Ir para o ponto ao vivo';
	@override String get record => 'Gravar';
	@override String get recordEpisode => 'Gravar episódio';
	@override String get recordSeries => 'Gravar série';
	@override String get recordOptions => 'Opções de gravação';
	@override String get saveTo => 'Salvar em';
	@override String get recordings => 'Gravações';
	@override String get scheduledRecordings => 'Agendadas';
	@override String get recordingRules => 'Regras de gravação';
	@override String get noScheduledRecordings => 'Sem gravações agendadas';
	@override String get manageRecording => 'Gerenciar gravação';
	@override String get cancelRecording => 'Cancelar gravação';
	@override String get cancelRecordingTitle => 'Cancelar esta gravação?';
	@override String cancelRecordingMessage({required Object title}) => '${title} não será mais gravado.';
	@override String get deleteRule => 'Excluir regra';
	@override String get deleteRuleTitle => 'Excluir regra de gravação?';
	@override String deleteRuleMessage({required Object title}) => 'Episódios futuros de ${title} não serão gravados.';
	@override String get recordingScheduled => 'Gravação agendada';
	@override String get alreadyScheduled => 'Este programa já está agendado';
	@override String get dvrAdminRequired => 'As configurações de DVR exigem uma conta de administrador';
	@override String get recordingFailed => 'Não foi possível agendar a gravação';
	@override String get recordingTargetMissing => 'Não foi possível determinar a biblioteca de gravação';
	@override String get recordNotAvailable => 'Gravação indisponível para este programa';
	@override String get recordingCancelled => 'Gravação cancelada';
	@override String get recordingRuleDeleted => 'Regra de gravação excluída';
	@override String get processRecordingRules => 'Reavaliar regras';
	@override String get recordingInProgress => 'Gravando agora';
	@override String recordingsCount({required Object count}) => '${count} agendadas';
	@override String get editRule => 'Editar regra';
	@override String get editRuleAction => 'Editar';
	@override String get recordingRuleUpdated => 'Regra de gravação atualizada';
	@override String get guideReloadRequested => 'Atualização do guia solicitada';
	@override String get guideReloadFailed => 'Não foi possível atualizar o guia';
	@override String get rulesProcessRequested => 'Reavaliação de regras solicitada';
	@override String get rulesProcessFailed => 'Não foi possível reavaliar as regras de gravação';
	@override String get recordShow => 'Gravar programa';
	@override late final Translations$liveTv$recordSettings$pt recordSettings = Translations$liveTv$recordSettings$pt.internal(_root);
	@override String startingInMinutes({required Object minutes}) => 'Começa em ${minutes} min';
	@override String dayAtTime({required Object day, required Object time}) => '${day} às ${time}';
	@override String invalidPlaybackData({required Object product}) => '${product} retornou dados inválidos de reprodução de TV ao Vivo';
	@override String get failedToStartChannel => 'Não foi possível iniciar o canal ao vivo';
	@override String get failedToBuildStreamUrl => 'Não foi possível gerar a URL da transmissão';
	@override String playbackStartFailed({required Object reason}) => 'Não foi possível iniciar o canal: ${reason}';
	@override String channelSwitchFailed({required Object reason}) => 'Não foi possível trocar de canal: ${reason}';
}

// Path: collections
class Translations$collections$pt extends Translations$collections$en {
	Translations$collections$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Coleções';
	@override String get collection => 'Coleção';
	@override String get empty => 'A coleção está vazia';
	@override String get deleteCollection => 'Excluir Coleção';
	@override String deleteConfirm({required Object title}) => 'Excluir "${title}"? Não pode ser desfeito.';
	@override String get deleted => 'Coleção excluída';
	@override String get deleteFailed => 'Falha ao excluir coleção';
	@override String deleteFailedWithError({required Object error}) => 'Falha ao excluir coleção: ${error}';
	@override String get selectCollection => 'Selecionar Coleção';
	@override String get collectionName => 'Nome da Coleção';
	@override String get enterCollectionName => 'Insira o nome da coleção';
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
class Translations$playlists$pt extends Translations$playlists$en {
	Translations$playlists$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Playlists';
	@override String get playlist => 'Playlist';
	@override String get noPlaylists => 'Nenhuma playlist encontrada';
	@override String get create => 'Criar Playlist';
	@override String get playlistName => 'Nome da Playlist';
	@override String get enterPlaylistName => 'Insira o nome da playlist';
	@override String get delete => 'Excluir Playlist';
	@override String get removeItem => 'Remover da Playlist';
	@override String get smartPlaylist => 'Playlist Inteligente';
	@override String itemCount({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} item',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} itens',
	);
	@override String get emptyPlaylist => 'Esta playlist está vazia';
	@override String get deleteConfirm => 'Excluir Playlist?';
	@override String deleteMessage({required Object name}) => 'Tem certeza de que deseja excluir "${name}"?';
	@override String get created => 'Playlist criada';
	@override String get deleted => 'Playlist excluída';
	@override String get itemAdded => 'Adicionado à playlist';
	@override String get itemRemoved => 'Removido da playlist';
	@override String get selectPlaylist => 'Selecionar Playlist';
	@override String get searchPlaylists => 'Pesquisar playlists...';
	@override String get errorCreating => 'Falha ao criar playlist';
	@override String get errorDeleting => 'Falha ao excluir playlist';
	@override String get errorLoading => 'Falha ao carregar playlists';
	@override String get errorAdding => 'Falha ao adicionar à playlist';
	@override String get errorReordering => 'Falha ao reordenar item da playlist';
	@override String get errorRemoving => 'Falha ao remover da playlist';
}

// Path: music
class Translations$music$pt extends Translations$music$en {
	Translations$music$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => 'Ir para o álbum';
	@override String get goToArtist => 'Ir para o artista';
	@override String get instantMix => 'Mix instantâneo';
	@override String get playNext => 'Reproduzir a seguir';
	@override String get addToQueue => 'Adicionar à fila';
	@override String discNumber({required Object n}) => 'Disco ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} faixa',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} faixas',
	);
	@override String get nowPlaying => 'Reproduzindo agora';
	@override String playingFrom({required Object title}) => 'Reproduzindo de ${title}';
	@override String get queue => 'Fila';
	@override String get clearQueue => 'Limpar fila';
	@override String get lyrics => 'Letra';
	@override String get visualizer => 'Visualizador';
	@override String get visualizerProfileLoading => 'Leia a análise de traços...';
	@override String get visualizerAmbientMotion => 'MOVIMENTO Ambiental';
	@override String get visualizerPlexLoudness => 'Plex ruído';
	@override String get visualizerPreviousPreset => 'Estilo visual anterior';
	@override String get visualizerNextPreset => 'Próximo Estilo Visual';
	@override String get visualizerPresetAurora => 'Aurora';
	@override String get visualizerPresetBloom => 'Blumão';
	@override String get visualizerPresetOrbitals => 'Orbitários';
	@override String get visualizerPresetPrism => 'Prism';
	@override String get visualizerPresetTunnel => 'Túnel';
	@override String get visualizerPresetTrackMap => 'Track mapa';
	@override String get noLyrics => 'Nenhuma letra disponível';
	@override String get sleepTimer => 'Temporizador de suspensão';
	@override String get sleepTimerEndOfTrack => 'Fim da faixa';
	@override String sleepTimerMinutes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minuto',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minutos',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minutos',
	);
	@override String get stopPlayback => 'Parar reprodução';
	@override String get previousTrack => 'Faixa anterior';
	@override String get nextTrack => 'Próxima faixa';
	@override String get repeat => 'Repetir';
	@override String get repeatAll => 'Repetir tudo';
	@override String get repeatOne => 'Repetir uma faixa';
	@override String get instantMixNoServer => 'Nenhum servidor está disponível para uma mistura instantânea';
	@override String get instantMixFailed => 'Falha ao carregar o mix instantâneo';
	@override String get instantMixEmpty => 'O mix instantâneo não retornou nenhuma faixa';
	@override String noAudioUrl({required Object track}) => 'Nenhuma URL de áudio está disponível para ${track}';
	@override late final Translations$music$discography$pt discography = Translations$music$discography$pt.internal(_root);
}

// Path: watchTogether
class Translations$watchTogether$pt extends Translations$watchTogether$en {
	Translations$watchTogether$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Assistir Juntos';
	@override String get description => 'Assista a conteúdos sincronizados com amigos e familiares';
	@override String get createRoom => 'Criar sala';
	@override String get creatingRoom => 'Criando sala...';
	@override String get joinRoom => 'Entrar na sala';
	@override String get joiningRoom => 'Entrando na sala...';
	@override String get connecting => 'Conectando...';
	@override String get relayPublic => 'As salas usam os servidores de retransmissão públicos do Open Watch Party.';
	@override String relayCustom({required Object url}) => 'As salas usam seu servidor de retransmissão em ${url}.';
	@override String get recentRooms => 'Salas recentes';
	@override String get roomActions => 'Ações da sala';
	@override String get renameRoom => 'Renomear sala';
	@override String get removeRoom => 'Remover';
	@override String get enterRoomCode => 'Insira o código de 6 caracteres do anfitrião.';
	@override String get roomCode => 'Código da sala';
	@override String get paste => 'Colar';
	@override String get noCodeInClipboard => 'A área de transferência não contém um código de sala';
	@override String get copyCode => 'Copiar código';
	@override String get codeCopied => 'Código da sala copiado';
	@override String get shareInvite => 'Compartilhar convite';
	@override String get inviteCopied => 'Convite copiado. Cole-o em uma mensagem.';
	@override String inviteMessage({required Object code}) => 'Entre na minha sala do Assistir Juntos no PlezyNG: abra "Assistir Juntos", escolha "Entrar na sala" e insira ${code}.';
	@override String get openSessionControls => 'Abrir os controles da sessão Assistir Juntos';
	@override String get reconnecting => 'Reconectando...';
	@override String get reconnectingDescription => 'A conexão caiu. Você voltará à sala automaticamente.';
	@override String get connected => 'Conectado';
	@override String get disconnected => 'Desconectado';
	@override String get youAreHost => 'Você é o anfitrião';
	@override String hostedBy({required Object name}) => 'Anfitrião: ${name}';
	@override String get hostControlsPlayback => 'O anfitrião controla a reprodução';
	@override String get anyoneCanControl => 'Qualquer pessoa pode controlar a reprodução';
	@override String get roomLocked => 'Sala bloqueada';
	@override String get nowPlaying => 'Reproduzindo agora';
	@override String get nothingPlaying => 'Nada em reprodução';
	@override String get nothingPlayingHost => 'Reproduza algo de qualquer biblioteca para compartilhar com a sala.';
	@override String get nothingPlayingGuest => 'Quando o anfitrião reproduzir algo, o conteúdo será aberto aqui.';
	@override String get notShareable => 'Este vídeo não corresponde a nenhum item do catálogo, então apenas pessoas com acesso ao mesmo servidor podem reproduzi-lo.';
	@override String get searching => 'Procurando este vídeo nas suas bibliotecas...';
	@override String get yourCopy => 'Sua cópia';
	@override String get sharingYourCopy => 'Você está compartilhando sua cópia';
	@override String playingOtherLength({required Object difference}) => 'Reproduzindo sua cópia, ${difference}';
	@override String get mismatchTitle => 'Sua cópia tem outra duração';
	@override String mismatchDescription({required Object difference}) => 'Sua cópia mais próxima é ${difference} que o vídeo da sala. Pode ser outro corte ou outra versão.';
	@override String get playAnyway => 'Reproduzir mesmo assim';
	@override String get chooseAnotherCopy => 'Escolher outra cópia';
	@override String get dontPlay => 'Não reproduzir';
	@override String get unavailableTitle => 'Você não tem este vídeo';
	@override String get unavailableDescription => 'O PlezyNG não o encontrou nas suas bibliotecas. Escolha uma cópia manualmente ou busque novamente.';
	@override String get chooseCopy => 'Escolher uma cópia';
	@override String get searchAgain => 'Buscar novamente';
	@override String get noCandidates => 'Nenhuma cópia encontrada nas suas bibliotecas.';
	@override String get choiceFailed => 'Não foi possível reproduzir esta cópia para a sala';
	@override String lengthLonger({required Object duration}) => '${duration} mais longa';
	@override String lengthShorter({required Object duration}) => '${duration} mais curta';
	@override String get lengthSame => 'Mesma duração';
	@override String get lengthUnknown => 'Duração desconhecida';
	@override String get joinCurrentPlayback => 'Entrar na reprodução atual';
	@override String get joinCurrentPlaybackDescription => 'Voltar ao conteúdo que o anfitrião está assistindo agora';
	@override String get stopMedia => 'Parar o vídeo para todos';
	@override String get syncOffset => 'Ajuste de sincronia';
	@override String get syncOffsetDescription => 'Ajuste seu vídeo se ele estiver adiantado ou atrasado em relação à sala.';
	@override String offsetHint({required Object difference}) => 'Sua cópia é ${difference} que o vídeo da sala.';
	@override String applyDifference({required Object offset}) => 'Usar ${offset}';
	@override String get offsetMinusSecond => '-1 s';
	@override String get offsetMinusTenth => '-100 ms';
	@override String get offsetPlusTenth => '+100 ms';
	@override String get offsetPlusSecond => '+1 s';
	@override String get participants => 'Participantes';
	@override String participantCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} participante',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} participantes',
	);
	@override String get hostBadge => 'ANFITRIÃO';
	@override String nameYou({required Object name}) => '${name} (você)';
	@override String get playerIdle => 'Ocioso';
	@override String get playerLoading => 'Carregando';
	@override String get playerReady => 'Pronto';
	@override String get playerBuffering => 'Em buffer';
	@override String get matchSearching => 'Procurando';
	@override String get matchMatched => 'Tem o vídeo';
	@override String get matchMismatched => 'Duração diferente';
	@override String get matchUnavailable => 'Não tem o vídeo';
	@override String participantOffset({required Object offset}) => 'Ajuste ${offset}';
	@override String get makeHost => 'Tornar anfitrião';
	@override String get makeHostQuestion => 'Transferir anfitrião?';
	@override String makeHostConfirm({required Object name}) => '${name} controlará a reprodução e conduzirá a sessão para todos.';
	@override String get transfer => 'Transferir';
	@override String get removeParticipant => 'Remover da sala';
	@override String removeParticipantQuestion({required Object name}) => 'Remover ${name}?';
	@override String removeParticipantConfirm({required Object name}) => '${name} sairá da sala. A pessoa poderá entrar novamente com o código, a menos que você bloqueie a sala.';
	@override String get remove => 'Remover';
	@override String get roomSettings => 'Configurações da sala';
	@override String get letEveryoneControl => 'Permitir que todos controlem a reprodução';
	@override String get lockRoom => 'Bloquear sala';
	@override String get lockRoomDescription => 'Ninguém novo pode entrar';
	@override String get leaveRoom => 'Sair da sala';
	@override String get leaveRoomQuestion => 'Sair da sala?';
	@override String get leaveRoomConfirm => 'Você pode entrar novamente com o código da sala.';
	@override String get leave => 'Sair';
	@override String get endRoom => 'Encerrar sala';
	@override String get endRoomQuestion => 'Encerrar sala?';
	@override String get endRoomConfirm => 'Isso encerra a sala para todos.';
	@override String get end => 'Encerrar';
	@override String get playBlockedTitle => 'A reprodução não começou';
	@override String get playBlockedDescription => 'Pressione reproduzir para começar a assistir com a sala.';
	@override late final Translations$watchTogether$notices$pt notices = Translations$watchTogether$notices$pt.internal(_root);
	@override late final Translations$watchTogether$ended$pt ended = Translations$watchTogether$ended$pt.internal(_root);
	@override late final Translations$watchTogether$errors$pt errors = Translations$watchTogether$errors$pt.internal(_root);
	@override String untitledEpisode({required Object number}) => 'Episódio ${number}';
}

// Path: downloads
class Translations$downloads$pt extends Translations$downloads$en {
	Translations$downloads$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Downloads';
	@override String get manage => 'Gerenciar';
	@override String get tvShows => 'Séries de TV';
	@override String get movies => 'Filmes';
	@override String get music => 'Música';
	@override String tracksQueued({required Object count}) => '${count} faixas na fila para download';
	@override String get noDownloads => 'Nenhum download ainda';
	@override String get noDownloadsDescription => 'O conteúdo baixado aparecerá aqui para assistir offline';
	@override String get downloadNow => 'Baixar';
	@override String get deleteDownload => 'Excluir download';
	@override String get retryDownload => 'Tentar download novamente';
	@override String get downloadQueued => 'Download na fila';
	@override String get downloadResumed => 'Download retomado';
	@override String get serverErrorBitrate => 'Erro do servidor: o arquivo pode exceder o limite remoto de taxa de bits';
	@override String get storageFull => 'Os downloads foram interrompidos para proteger o espaço disponível. Libere espaço ou escolha outro local de download e tente novamente.';
	@override String get storageUnavailable => 'Os downloads foram interrompidos porque não foi possível verificar o armazenamento disponível. Verifique o local de download e tente novamente.';
	@override String episodesQueued({required Object count}) => '${count} episódios na fila de download';
	@override String get downloadDeleted => 'Download excluído';
	@override String deleteConfirm({required Object title}) => 'Excluir "${title}" deste dispositivo?';
	@override String get deleteCollectionDownloads => 'Excluir downloads';
	@override String deleteCollectionDownloadsConfirm({required Object title}) => 'Excluir todos os downloads de "${title}" deste dispositivo?';
	@override String get collectionDownloadsDeleted => 'Downloads excluídos';
	@override String get cancelledDownloadTitle => 'Download cancelado';
	@override String get cancelledDownloadMessage => 'Este download foi cancelado. O que você deseja fazer?';
	@override String get allEpisodesAlreadyDownloaded => 'Todos os episódios já foram baixados';
	@override String get resumeDownload => 'Retomar download';
	@override String get cancelledDownload => 'Download cancelado';
	@override String syncingFile({required Object file, required Object status}) => '${file} (sincronizando ${status})';
	@override String downloadedFileClickToComplete({required Object file}) => '${file} baixado — clique para concluir';
	@override String get partialDownloadClickToComplete => 'Parcialmente baixado — clique para concluir';
	@override String get deleting => 'Excluindo...';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Excluindo ${title}... (${current} de ${total})';
	@override String get queuedTooltip => 'Na fila';
	@override String queuedFilesTooltip({required Object files}) => 'Na fila: ${files}';
	@override String get downloadingTooltip => 'Baixando...';
	@override String downloadingFilesTooltip({required Object files}) => 'Baixando ${files}';
	@override String get noDownloadsTree => 'Nenhum download';
	@override String get pauseAll => 'Pausar todos';
	@override String get resumeAll => 'Retomar todos';
	@override String get retryAll => 'Tentar todos novamente';
	@override String get retryFailed => 'Tentar novamente os downloads com falha';
	@override String get deleteAll => 'Excluir todos';
	@override String get selectVersion => 'Selecionar versão';
	@override String get allEpisodes => 'Todos os episódios';
	@override String get unwatchedOnly => 'Apenas não assistidos';
	@override String nextNUnwatched({required Object count}) => 'Próximos ${count} episódios não assistidos';
	@override String get customAmount => 'Quantidade personalizada...';
	@override String get customAmountAny => 'Quanto a cada (todos)';
	@override String get randomEpisodes => 'Episódios Rados';
	@override String get includeSpecials => 'Incluir especiais';
	@override String get howManyEpisodes => 'Quantos episódios?';
	@override String get invalidEpisodeCount => 'Insira uma quantidade válida de episódios.';
	@override String get keepSynced => 'Manter sincronizado';
	@override String get downloadOnce => 'Baixar uma vez';
	@override String keepNUnwatched({required Object count}) => 'Manter ${count} episódios não assistidos';
	@override String get editSyncRule => 'Editar regra de sincronização';
	@override String get removeSyncRule => 'Remover regra de sincronização';
	@override String removeSyncRuleConfirm({required Object title}) => 'Parar de sincronizar "${title}"? Os episódios baixados serão mantidos.';
	@override String removeListSyncRuleConfirm({required Object title}) => 'Parar a sincronização de "${title}"?';
	@override String get deleteSyncRuleDownloads => 'Também excluir downloads associados';
	@override String get deleteSyncRuleDownloadsDescription => 'Downloads usados por outra regra de sincronização ou perfil serão mantidos.';
	@override String syncRuleCreated({required Object count}) => 'Regra de sincronização criada — mantendo ${count} episódios não assistidos';
	@override String get syncRuleUpdated => 'Regra de sincronização atualizada';
	@override String get syncRuleRemoved => 'Regra de sincronização removida';
	@override String get syncRuleAndDownloadsRemoved => 'Regra de sincronização e downloads associados removidos';
	@override String get syncRuleCleanupBusy => 'As regras de sincronização estão sendo atualizadas. Tente novamente em instantes.';
	@override String get syncRuleCleanupUnavailable => 'Os downloads associados não puderam ser identificados com segurança. Reconecte o servidor e tente novamente, ou remova a regra sem excluir os downloads.';
	@override String syncedNewEpisodes({required Object count, required Object title}) => '${count} novos episódios sincronizados para ${title}';
	@override String get syncNow => 'Síntese agora';
	@override String get downloadsUpToDate => 'As downloads estão atualizadas';
	@override String syncComplete({required Object queued, required Object removed}) => 'Sínculo completo · ${queued} queued, ${removed} removido';
	@override String get activeSyncRules => 'Regras de sincronização';
	@override String get reviewOrphanFiles => 'Rever downloads sem registo';
	@override String get orphanReviewTitle => 'Rever downloads sem registo';
	@override String get orphanReviewDescription => 'Estes ficheiros etiquetados estão nas pastas predefinidas de downloads geridos pela aplicação PlezyNG, mas não têm um registo de download correspondente nem uma tarefa ativa. Verifique a lista antes de os eliminar.';
	@override String orphanReviewCount({required Object count, required Object size}) => '${count} ficheiros · ${size}';
	@override String orphanDeleteFiles({required Object count}) => 'Eliminar ${count} ficheiros';
	@override String get orphanCleanupNone => 'Não foram encontrados ficheiros de download sem registo';
	@override String get orphanCleanupFailed => 'PlezyNG não conseguiu analisar com segurança a pasta de downloads gerida. Nenhum ficheiro foi eliminado.';
	@override String get orphanCleanupChanged => 'A lista de downloads foi alterada durante a revisão. Reveja os ficheiros novamente antes de limpar.';
	@override String orphanCleanupComplete({required Object count, required Object size}) => 'Eliminados ${count} ficheiros sem registo · libertado ${size}';
	@override String get noSyncRules => 'Nenhuma regra de sincronização';
	@override String get manageSyncRule => 'Gerenciar sincronização';
	@override String get editEpisodeCount => 'Número de episódios';
	@override String get editSyncFilter => 'Filtro de sincronização';
	@override String get syncAllItems => 'Sincronizando todos os itens';
	@override String get syncUnwatchedItems => 'Sincronizando itens não assistidos';
	@override String syncRuleServerContext({required Object server, required Object status}) => 'Servidor: ${server} • ${status}';
	@override String get syncRuleAvailable => 'Disponível';
	@override String get syncRuleOffline => 'Offline';
	@override String get syncRuleSignInRequired => 'É necessário entrar';
	@override String get syncRuleAccessDenied => 'Acesso negado';
	@override String get syncRuleNotAvailableForProfile => 'Indisponível para o perfil atual';
	@override String get syncRuleUnknownServer => 'Servidor desconhecido';
	@override String get syncRuleListCreated => 'Regra de sincronização criada';
	@override late final Translations$downloads$backgroundWarning$pt backgroundWarning = Translations$downloads$backgroundWarning$pt.internal(_root);
	@override String get options => 'Opções de downloads';
	@override late final Translations$downloads$groupings$pt groupings = Translations$downloads$groupings$pt.internal(_root);
	@override String get unknownLibrary => 'Biblioteca desconhecida';
	@override String get unknownShow => 'Série desconhecida';
	@override String get unknownSeason => 'Temporada desconhecida';
	@override String get unknownAlbum => 'Álbum desconhecido';
	@override String completedOfTotal({required Object completed, required Object total}) => '${completed}/${total} concluídos';
	@override String storageUsed({required Object size}) => 'Armazém utilizado: ${size}';
	@override String downloadCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} transferência',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} transferências',
	);
	@override String showCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} apresentação',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} apresentações',
	);
	@override String movieCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} filme',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} filmes',
	);
	@override String albumCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} álbum',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} álbuns',
	);
	@override String get errorFileNotFound => 'Arquivo não encontrado (404)';
	@override String get errorDownloadNotAllowed => 'Download não permitido pelo servidor (403)';
	@override String get errorDownloadFailed => 'Falha no download';
	@override String errorDownloadFailedWithReason({required Object reason}) => 'Falha no download: ${reason}';
	@override String get convertingOnServer => 'Conversão em servidor...';
	@override String convertingOnServerPercent({required Object percent}) => 'Conversão em servidor · ${percent}%';
	@override String errorHttpStatus({required Object status}) => 'Falha no download (HTTP ${status})';
	@override String errorPostProcessing({required Object reason}) => 'Falha no pós-processamento: ${reason}';
	@override String get reasonFileNotSaved => 'não foi possível salvar o arquivo neste dispositivo';
	@override String get reasonCannotResume => 'não foi possível retomar o download parcial';
	@override String get reasonDeviceStorageFull => 'este dispositivo está sem espaço de armazenamento';
	@override String get notificationDownloading => 'Baixando...';
	@override String get notificationComplete => 'Download concluído';
	@override String get notificationPaused => 'Download pausado';
}

// Path: shaders
class Translations$shaders$pt extends Translations$shaders$en {
	Translations$shaders$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Shaders';
	@override String get noShaderDescription => 'Sem aprimoramento de vídeo';
	@override String get nvscalerDescription => 'Dimensionamento de imagem da NVIDIA para vídeos mais nítidos';
	@override String get artcnnVariantNeutral => 'Neutro';
	@override String get artcnnVariantDenoise => 'Redução de ruído';
	@override String get artcnnVariantDenoiseSharpen => 'Redução de ruído + nitidez';
	@override String get qualityFast => 'Rápido';
	@override String get qualityHQ => 'Alta Qualidade';
	@override String get mode => 'Modo';
	@override String get importShader => 'Importar Shader';
	@override String get customShaderDescription => 'Shader GLSL personalizado';
	@override String get shaderImported => 'Shader importado';
	@override String get shaderImportFailed => 'Falha ao importar shader';
	@override String get deleteShader => 'Excluir Shader';
	@override String deleteShaderConfirm({required Object name}) => 'Excluir "${name}"?';
}

// Path: companionRemote
class Translations$companionRemote$pt extends Translations$companionRemote$en {
	Translations$companionRemote$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Controle remoto';
	@override String connectedTo({required Object name}) => 'Conectado a ${name}';
	@override String get unknownDevice => 'Dispositivo desconhecido';
	@override late final Translations$companionRemote$session$pt session = Translations$companionRemote$session$pt.internal(_root);
	@override late final Translations$companionRemote$pairing$pt pairing = Translations$companionRemote$pairing$pt.internal(_root);
	@override late final Translations$companionRemote$remote$pt remote = Translations$companionRemote$remote$pt.internal(_root);
	@override late final Translations$companionRemote$errors$pt errors = Translations$companionRemote$errors$pt.internal(_root);
	@override String get closedBeforeAuth => 'A conexão foi encerrada antes da autenticação';
}

// Path: videoSettings
class Translations$videoSettings$pt extends Translations$videoSettings$en {
	Translations$videoSettings$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'Velocidade de Reprodução';
	@override String get normalSpeed => 'Normal';
	@override String sleepTimerActive({required Object duration}) => 'Ativo (${duration})';
	@override String get zoom => 'Zoom';
	@override String get sleepTimer => 'Temporizador de suspensão';
	@override String get audioSync => 'Sincronia de áudio';
	@override String get subtitleSync => 'Sincronia de legendas';
	@override String get hdr => 'HDR';
	@override String get hdrUnsupported => 'O HDR não está disponível aqui — este compositor da área de trabalho ou esta saída de vídeo não é compatível com ele.';
	@override String get hdrToneMapping => 'Mapeamento de tons HDR';
	@override String get hdrToneMappingCompositor => 'Compositor';
	@override String get hdrToneMappingCompositorDescription => 'Repassar os metadados HDR da fonte e deixar que o compositor da área de trabalho faça o mapeamento.';
	@override String get hdrToneMappingPlayer => 'Reprodutor';
	@override String get hdrToneMappingPlayerDescription => 'Mapear para o brilho máximo da tela no reprodutor e informar o resultado ao compositor.';
	@override String get hdrToneMappingFailed => 'Não foi possível alterar o mapeamento de tons HDR — o modo anterior continua ativo.';
	@override String get audioOutput => 'Saída de áudio';
	@override String get videoTrack => 'Faixa de vídeo';
	@override String get videoTrackDescription => 'Escolha qual fluxo de vídeo apresentar. Disponível na reprodução com MPV quando o ficheiro contém faixas de vídeo alternativas.';
	@override String get videoTrackDefault => 'Predefinida';
	@override String get videoTrackUnavailable => 'Não existem faixas de vídeo alternativas disponíveis.';
	@override String get videoTrackFailed => 'Não foi possível alterar a faixa de vídeo.';
	@override String videoTrackNumber({required Object id}) => 'Faixa ${id}';
	@override String get performanceOverlay => 'Painel de desempenho';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'Surround';
	@override String get audioOutputSpatial => 'Áudio espacial';
	@override String get audioOutputStereo => 'Estéreo';
	@override String get audioEqualizer => 'Avaliação de áudio';
	@override String get audioEqualizerDescription => 'Equalizador de 10 bandas para MPVOs filtros de áudio usam áudio decodado e desligam passthrough.';
	@override String get audioEqualizerFlat => 'Neutro';
	@override String get audioEqualizerActive => 'Personalizado';
	@override String get audioEqualizerSaveFailed => 'Não poderia salvar as configurações do equalizador de áudio.';
	@override String get audioEffectsDescription => 'Os efeitos usam áudio descodificado, por isso o ajuste se desvia. ambiente de quarto e estereó ampliação dependem do MPV Construir e rastrear.';
	@override String get audioStereoWidth => 'Extensão Stereo';
	@override String get audioSpatializer => 'ambiente de quarto';
	@override String get audioSpatializerDescription => 'Adicione reflexões de sala tranquila.';
	@override String get audioPitch => 'Mudança de Pitch';
	@override String get audioPitchDescription => 'Mude a velocidade sem mudança de velocidade. MPV A construção deve incluir Rubber Band.';
	@override String get audioEffectUnavailable => 'Este efeito não está disponível para esta pista ou MPV Construção .';
	@override String get backgroundVideoAudio => 'Audio de vídeo de fundo';
	@override String get backgroundVideoAudioDescription => 'Mantenha o vídeo a tocar quando você sair do jogador; a imagem está escondida até que você retornar. Android usa uma notificação de reprodução de mídia.';
	@override String get audioNormalization => 'Normalizar intensidade sonora';
	@override String get audioNormalizationDisablesPassthrough => 'Decodifica o áudio para PCM; a passagem direta fica desativada enquanto esta opção estiver ativa';
}

// Path: performanceOverlay
class Translations$performanceOverlay$pt extends Translations$performanceOverlay$en {
	Translations$performanceOverlay$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get color => 'Cor';
	@override String get performance => 'Desempenho';
	@override String get buffer => 'Buffer';
	@override String get app => 'App';
	@override String get decoder => 'Decodificador';
	@override String get rawDecoder => 'Decodificador bruto';
	@override String get tunneling => 'Túnel';
	@override String get passthrough => 'Passagem direta';
	@override String get aspect => 'Aspecto';
	@override String get rotation => 'Rotação';
	@override String get dvSource => 'Fonte DV';
	@override String get dvPath => 'Caminho DV';
	@override String get dvRouteDecoder => 'Decodificador Dolby Vision';
	@override String get dvRouteDecoderP81 => 'Decodificador Dolby Vision (P7→8.1)';
	@override String get dvRouteBaseLayer => 'Camada base';
	@override String get dvRouteBaseLayerHdr10 => 'Camada base HDR10';
	@override String get dvRouteBaseLayerHlg => 'Camada base HLG';
	@override String get dvRouteBaseLayerSdr => 'Camada base SDR';
	@override String get dvRouteReshaped => 'Remodelagem RPU (gpu-next)';
	@override String get dvRouteFelGraphActive => 'P7 FEL gráfico experimental (não qualificado)';
	@override String get p7Conversion => 'Conv. P7';
	@override String get sampleRate => 'Taxa de amostragem';
	@override String get pixelFormat => 'Formato de pixel';
	@override String get hwFormat => 'Formato HW';
	@override String get matrix => 'Matriz';
	@override String get primaries => 'Primárias';
	@override String get transfer => 'Transferência';
	@override String get renderFps => 'FPS de renderização';
	@override String get displayFps => 'FPS da tela';
	@override String get avSync => 'Sincronia A/V';
	@override String get dropped => 'Descartados';
	@override String get dvRpus => 'DV RPUs';
	@override String get dvRpuAverage => 'Média DV RPU';
	@override String get dvSampleAverage => 'Média amostra DV';
	@override String get maxLuma => 'Luma máx.';
	@override String get minLuma => 'Luma mín.';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => 'Cache usado';
	@override String get cacheLimit => 'Limite do cache';
	@override String get speed => 'Velocidade';
	@override String get player => 'Reprodutor';
	@override String get playMethod => 'Jogo Método';
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
class Translations$externalPlayer$pt extends Translations$externalPlayer$en {
	Translations$externalPlayer$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Reprodutor externo';
	@override String get useExternalPlayer => 'Usar reprodutor externo';
	@override String get useExternalPlayerDescription => 'Abrir vídeos em outro app';
	@override String get selectPlayer => 'Selecionar reprodutor';
	@override String get customPlayers => 'Reprodutores personalizados';
	@override String get systemDefault => 'Padrão do sistema';
	@override String get addCustomPlayer => 'Adicionar reprodutor personalizado';
	@override String get playerName => 'Nome do reprodutor';
	@override String get playerNameHint => 'Meu reprodutor';
	@override String get playerCommand => 'Comando';
	@override String get playerPackage => 'Nome do pacote';
	@override String get playerUrlScheme => 'Esquema de URL';
	@override String get off => 'Desativado';
	@override String get launchFailed => 'Falha ao abrir o reprodutor externo';
	@override String appNotInstalled({required Object name}) => '${name} não está instalado';
	@override String get playInExternalPlayer => 'Reproduzir no reprodutor externo';
	@override String get description => 'Escolha outro aplicativo para abrir vídeos em. Os jogadores disponíveis dependem do seu dispositivo e das aplicações instaladas.';
	@override String get systemDefaultDescription => 'Deixe o sistema operacional abrir o vídeo com sua aplicação padrão.';
	@override String playerOptionDescription({required Object player}) => 'Abra vídeos com ${player}.';
	@override String get playerNameDescription => 'O rótulo mostrado na lista de jogadores.';
	@override String get playerPackageDescription => 'Insira o nome do pacote Android da aplicação de jogador, como com.example.player.';
	@override String get playerCommandDescription => 'Entre o comando do jogador instalado ou a estrada executável para este dispositivo.';
	@override String get playerUrlSchemeDescription => 'Introduza o esquema URL e o modelo de URL opcional usado para lançar o jogador.';
}

// Path: metadataEdit
class Translations$metadataEdit$pt extends Translations$metadataEdit$en {
	Translations$metadataEdit$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'Editar...';
	@override String get screenTitle => 'Editar Metadados';
	@override String get basicInfo => 'Informações Básicas';
	@override String get artwork => 'Arte';
	@override String get advancedSettings => 'Configurações Avançadas';
	@override String get title => 'Título';
	@override String get sortTitle => 'Título para Ordenação';
	@override String get originalTitle => 'Título Original';
	@override String get releaseDate => 'Data de Lançamento';
	@override String get contentRating => 'Classificação Indicativa';
	@override String get studio => 'Estúdio';
	@override String get tagline => 'Slogan';
	@override String get summary => 'Sinopse';
	@override String get poster => 'Pôster';
	@override String get background => 'Plano de Fundo';
	@override String get logo => 'Logo';
	@override String get squareArt => 'Imagem Quadrada';
	@override String get selectPoster => 'Selecionar pôster';
	@override String get selectBackground => 'Selecionar Plano de Fundo';
	@override String get selectLogo => 'Selecionar Logo';
	@override String get selectSquareArt => 'Selecionar Imagem Quadrada';
	@override String get fromUrl => 'Da URL';
	@override String get uploadFile => 'Enviar Arquivo';
	@override String get enterImageUrl => 'Insira a URL da imagem';
	@override String get imageUrl => 'URL da Imagem';
	@override String get metadataUpdated => 'Metadados atualizados';
	@override String get metadataUpdateFailed => 'Falha ao atualizar metadados';
	@override String get artworkUpdated => 'Arte atualizada';
	@override String get artworkUpdateFailed => 'Falha ao atualizar arte';
	@override String get noArtworkAvailable => 'Nenhuma arte disponível';
	@override String artworkOption({required Object index}) => 'Opção de arte ${index}';
	@override String selectedArtworkOption({required Object index}) => 'Opção de arte ${index}, selecionada';
	@override String get notSet => 'Não definido';
	@override String get libraryDefault => 'Padrão da biblioteca';
	@override String get accountDefault => 'Padrão da conta';
	@override String get seriesDefault => 'Padrão da série';
	@override String get episodeSorting => 'Ordenação de Episódios';
	@override String get oldestFirst => 'Mais antigos primeiro';
	@override String get newestFirst => 'Mais recentes primeiro';
	@override String get keep => 'Manter';
	@override String get allEpisodes => 'Todos os episódios';
	@override String latestEpisodes({required Object count}) => '${count} episódios mais recentes';
	@override String get latestEpisode => 'Episódio mais recente';
	@override String episodesAddedPastDays({required Object count}) => 'Episódios adicionados nos últimos ${count} dias';
	@override String get deleteAfterPlaying => 'Excluir Episódios Após Reproduzir';
	@override String get never => 'Nunca';
	@override String get afterADay => 'Após um dia';
	@override String get afterAWeek => 'Após uma semana';
	@override String get afterAMonth => 'Após um mês';
	@override String get onNextRefresh => 'Na próxima atualização';
	@override String get seasons => 'Temporadas';
	@override String get show => 'Mostrar';
	@override String get hide => 'Ocultar';
	@override String get episodeOrdering => 'Ordenação de Episódios';
	@override String get tmdbAiring => 'The Movie Database (Exibição)';
	@override String get tvdbAiring => 'TheTVDB (Exibição)';
	@override String get tvdbAbsolute => 'TheTVDB (Absoluto)';
	@override String get metadataLanguage => 'Idioma dos Metadados';
	@override String get useOriginalTitle => 'Usar Título Original';
	@override String get preferredAudioLanguage => 'Idioma de Áudio Preferido';
	@override String get preferredSubtitleLanguage => 'Idioma de Legenda Preferido';
	@override String get subtitleMode => 'Modo de Seleção Automática de Legendas';
	@override String get manuallySelected => 'Seleção manual';
	@override String get shownWithForeignAudio => 'Exibir com áudio estrangeiro';
	@override String get alwaysEnabled => 'Sempre ativado';
	@override String get tags => 'Tags';
	@override String get addTag => 'Adicionar tag';
	@override String get genre => 'Gênero';
	@override String get director => 'Diretor';
	@override String get writer => 'Roteirista';
	@override String get producer => 'Produtor';
	@override String get country => 'País';
	@override String get collection => 'Coleção';
	@override String get label => 'Rótulo';
	@override String get quickTag => 'Tag rápida...';
}

// Path: matchScreen
class Translations$matchScreen$pt extends Translations$matchScreen$en {
	Translations$matchScreen$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get match => 'Associar...';
	@override String get fixMatch => 'Corrigir correspondência...';
	@override String get unmatch => 'Desassociar';
	@override String get unmatchConfirm => 'Limpar esta correspondência? Plex tratará como sem correspondência até refazer.';
	@override String get unmatchSuccess => 'Item desassociado';
	@override String get unmatchFailed => 'Falha ao desassociar item';
	@override String get matchApplied => 'Correspondência aplicada';
	@override String get matchFailed => 'Falha ao aplicar correspondência';
	@override String get titleHint => 'Título';
	@override String get yearHint => 'Ano';
	@override String get search => 'Pesquisar';
	@override String get noMatchesFound => 'Nenhuma correspondência encontrada';
}

// Path: serverTasks
class Translations$serverTasks$pt extends Translations$serverTasks$en {
	Translations$serverTasks$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tarefas do servidor';
	@override String get failedToLoad => 'Falha ao carregar tarefas';
	@override String get noTasks => 'Nenhuma tarefa em execução';
}

// Path: trakt
class Translations$trakt$pt extends Translations$trakt$en {
	Translations$trakt$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'Conectado';
	@override String connectedAs({required Object username}) => 'Conectado como @${username}';
	@override String get disconnectConfirm => 'Desconectar a conta do Trakt?';
	@override String get disconnectConfirmBody => 'O PlezyNG deixará de enviar eventos ao Trakt. Você pode reconectar quando quiser.';
	@override String get scrobble => 'Scrobbling em tempo real';
	@override String get scrobbleDescription => 'Envia eventos de reprodução, pausa e parada ao Trakt durante a exibição.';
	@override String get watchedSync => 'Sincronizar status de assistido';
	@override String get watchedSyncDescription => 'Ao marcar itens como assistidos no PlezyNG, eles também serão marcados no Trakt.';
}

// Path: seerr
class Translations$seerr$pt extends Translations$seerr$en {
	Translations$seerr$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => 'Conectar ao Seerr';
	@override String get serverUrl => 'URL do servidor';
	@override String get serverUrlHelper => 'O endereço da sua instância do Seerr';
	@override String get checkServer => 'Continuar';
	@override String get signInWithJellyfin => 'Entrar com Jellyfin';
	@override String get signInWithEmby => 'Entrar com Emby';
	@override String get signInWithLocal => 'Usar uma conta local';
	@override String get email => 'E-mail';
	@override String get noSignInMethods => 'Esta instância do Seerr não oferece nenhum método de acesso compatível com o PlezyNG.';
	@override String get instance => 'Instância';
	@override String get disconnectConfirm => 'Desconectar Seerr?';
	@override String get disconnectConfirmBody => 'O PlezyNG esquecerá esta instância do Seerr. Reconecte quando quiser.';
	@override String get request => 'Solicitar';
	@override String get request4k => 'Solicitar em 4K';
	@override String get seasons => 'Temporadas';
	@override String get allSeasons => 'Todas as temporadas';
	@override String get advancedOptions => 'Avançado';
	@override String get destinationServer => 'Servidor de destino';
	@override String get qualityProfile => 'Perfil de qualidade';
	@override String get rootFolder => 'Pasta raiz';
	@override String get languageProfile => 'Perfil de idioma';
	@override String get tags => 'Etiquetas';
	@override String get noTags => 'Sem etiquetas';
	@override String defaultOption({required Object name}) => '${name} (padrão)';
	@override String get animeNote => 'Esta série é um anime.';
	@override String get requestSubmitted => 'Solicitação enviada';
	@override String requestFailed({required Object error}) => 'Falha na solicitação: ${error}';
	@override String get requestsLoadFailed => 'Não foi possível carregar as opções de solicitação';
	@override String get nothingToRequest => 'Tudo já está disponível ou solicitado.';
	@override String get statusAvailable => 'Disponível';
	@override String get statusPartiallyAvailable => 'Parcialmente disponível';
	@override String get statusRequested => 'Solicitado';
	@override String get statusProcessing => 'Processando';
	@override String get statusBlocklisted => 'Na lista de bloqueio';
	@override String couldNotReach({required Object url, required Object error}) => 'Não foi possível acessar ${url}: ${error}';
	@override String noInstanceAtUrl({required Object url, required Object status}) => 'Nenhuma instância do Seerr em ${url} (HTTP ${status})';
	@override String get behindAuthProxy => 'Um proxy reverso com autenticação (SSO ou autenticação HTTP) respondeu no lugar do Seerr. O PlezyNG não consegue entrar através dele: permita que o caminho /api/v1 do Seerr ignore o proxy para este aplicativo, ou use um endereço que alcance o Seerr diretamente.';
	@override String get invalidUrl => 'Insira um endereço de servidor como https://seerr.example.com';
	@override String get quickConnectUnsupported => 'Esta instância do Seerr não oferece suporte a Quick Connect. Ela precisa do Seerr 3.4 ou mais recente.';
	@override String get notInitialized => 'Esta instância do Seerr não concluiu a configuração inicial';
	@override String get noPlexTokenForReauth => 'Nenhum token do Plex está disponível para entrar novamente';
	@override String get noStoredCredentials => 'Nenhuma credencial armazenada está disponível para entrar novamente';
	@override String get signInRejected => 'A entrada foi rejeitada';
	@override String get noSessionCookie => 'O Seerr não forneceu um cookie de sessão';
	@override String get freshCookieRejected => 'O Seerr rejeitou o novo cookie de sessão';
	@override String get noUserInformation => 'O Seerr não retornou informações do usuário';
	@override String get sessionRejectedAfterReauth => 'A sessão foi rejeitada após entrar novamente';
	@override String get permissionDenied => 'O Seerr negou esta ação: sua conta não tem mais a permissão necessária';
	@override String get permissionRevoked => 'Você não tem mais permissão para solicitar isso';
}

// Path: services
class Translations$services$pt extends Translations$services$en {
	Translations$services$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Serviços';
	@override String get hubSubtitle => 'Sincronize o progresso de exibição e solicite novos títulos.';
	@override String get integrations => 'Integrações';
	@override String get notConnected => 'Não conectado';
	@override String connectedAs({required Object username}) => 'Conectado como @${username}';
	@override String get scrobble => 'Registrar progresso automaticamente';
	@override String get scrobbleDescription => 'Atualiza sua lista quando você termina um episódio ou filme.';
	@override String disconnectConfirm({required Object service}) => 'Desconectar ${service}?';
	@override String disconnectConfirmBody({required Object service}) => 'O PlezyNG deixará de atualizar ${service}. Reconecte quando quiser.';
	@override String connectFailed({required Object service}) => 'Não foi possível conectar ao ${service}. Tente novamente.';
	@override late final Translations$services$names$pt names = Translations$services$names$pt.internal(_root);
	@override late final Translations$services$simklReconnect$pt simklReconnect = Translations$services$simklReconnect$pt.internal(_root);
	@override late final Translations$services$deviceCode$pt deviceCode = Translations$services$deviceCode$pt.internal(_root);
	@override late final Translations$services$oauthProxy$pt oauthProxy = Translations$services$oauthProxy$pt.internal(_root);
	@override late final Translations$services$pendingAuth$pt pendingAuth = Translations$services$pendingAuth$pt.internal(_root);
	@override late final Translations$services$libraryFilter$pt libraryFilter = Translations$services$libraryFilter$pt.internal(_root);
	@override String get seerrDescription => 'Conecte-se a Seerr ou Overseerr para pesquisar títulos e enviar pedidos de mídia.';
	@override late final Translations$services$trackerDescriptions$pt trackerDescriptions = Translations$services$trackerDescriptions$pt.internal(_root);
}

// Path: addServer
class Translations$addServer$pt extends Translations$addServer$en {
	Translations$addServer$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String addMediaBrowserTitle({required Object product}) => 'Adicionar servidor ${product}';
	@override String get serverUrls => 'URLs do servidor';
	@override String get serverUrlsHelper => 'Várias URLs são permitidas, separadas por vírgulas.';
	@override String get findServer => 'Encontrar servidor';
	@override String searchingLocalMediaBrowserServers({required Object product}) => 'Procurando servidores ${product} locais...';
	@override String localMediaBrowserServers({required Object product}) => 'Servidores ${product} locais';
	@override String get username => 'Usuário';
	@override String get password => 'Senha';
	@override String get signIn => 'Entrar';
	@override String get change => 'Alterar';
	@override String get required => 'Obrigatório';
	@override String couldNotReachServer({required Object error}) => 'Não foi possível conectar ao servidor: ${error}';
	@override String signInFailed({required Object error}) => 'Falha ao entrar: ${error}';
	@override String quickConnectFailed({required Object error}) => 'Quick Connect falhou: ${error}';
	@override String get addPlexTitle => 'Entrar com Plex';
	@override String get pinExpired => 'O PIN expirou antes de entrar. Tente novamente.';
	@override String failedToRegisterAccount({required Object error}) => 'Falha ao registrar a conta: ${error}';
	@override String enterMediaBrowserUrlError({required Object product}) => 'Digite a URL do seu servidor ${product}';
	@override String get addConnectionTitle => 'Adicionar conexão';
	@override String addConnectionTitleScoped({required Object name}) => 'Adicionar a ${name}';
	@override String get signInWithPlexCard => 'Entrar com Plex';
	@override String get signInWithPlexCardSubtitle => 'Autorize este dispositivo. Servidores compartilhados são adicionados.';
	@override String get signInWithPlexCardSubtitleScoped => 'Autorize uma conta Plex. Os usuários do Plex Home se tornam perfis.';
	@override String connectToMediaBrowserCard({required Object product}) => 'Conectar ao ${product}';
	@override String get connectToMediaBrowserCardSubtitle => 'Digite a URL do servidor, o nome de usuário e a senha.';
	@override String connectToMediaBrowserCardSubtitleScoped({required Object product, required Object name}) => 'Entre no seu servidor ${product}. Vinculado a ${name}.';
	@override String get borrowFromAnotherProfile => 'Pegar emprestado de outro perfil';
	@override String get borrowFromAnotherProfileSubtitle => 'Reutilize a conexão de outro perfil. Perfis protegidos por PIN exigem PIN.';
	@override String get invalidCredentials => 'Usuário ou senha inválidos';
	@override String get authResponseNotJson => 'A resposta de autenticação não era um JSON válido';
	@override String get authResponseIncomplete => 'A resposta de login do servidor estava incompleta';
	@override String get quickConnectRejected => 'O Quick Connect foi rejeitado pelo servidor';
	@override String get quickConnectNotJson => 'A resposta do Quick Connect não era um JSON válido';
	@override String get quickConnectMissingFields => 'A resposta do Quick Connect não contém um código ou segredo';
	@override String get quickConnectPollRejected => 'A consulta do Quick Connect foi rejeitada pelo servidor';
	@override String get serverTimedOut => 'O servidor não respondeu a tempo';
	@override String get responseNotJson => 'A resposta do servidor não era um JSON válido';
	@override String responseMissingIdentity({required Object product}) => 'A resposta não contém um ID ou nome de servidor — este é um servidor ${product}?';
	@override String probeFailed({required Object error}) => 'Não foi possível conectar ao servidor: ${error}';
	@override String enterAtLeastOneUrl({required Object product}) => 'Insira pelo menos uma URL de servidor ${product}';
	@override String noReachableServer({required Object product}) => 'Nenhum servidor ${product} acessível foi encontrado';
	@override String urlsPointToDifferentServers({required Object product}) => 'Estas URLs apontam para servidores ${product} diferentes';
	@override String urlDoesNotMatchServer({required Object product}) => 'Esta URL não corresponde ao servidor ${product}';
	@override String get redirectUnsupported => 'O servidor redirecionou para uma URL não compatível';
	@override String redirectDifferentHost({required Object product}) => 'O servidor redirecionou para outro host. Insira diretamente a URL final do ${product}.';
	@override String get redirectInsecure => 'O servidor redirecionou de HTTPS para uma URL insegura';
	@override String redirectUnsupportedEnterFinal({required Object product}) => 'O servidor redirecionou para uma URL não compatível. Insira diretamente a URL final do ${product}.';
	@override String get directPlexServerUrl => 'URL do servidor Plex';
	@override String get directPlexServerUrlHelper => 'Entre o IP local e o portão do seu Plex Media Server.';
	@override String get directPlexServerUrlHint => 'http://192.168.1.100:32400';
	@override String get plexToken => 'Plex Token (opcional)';
	@override String get plexTokenHelper => 'Deixe o acesso branco se o acesso sem auth for permitido neste servidor.';
	@override String get plexTokenRequired => 'Verificação requerida. por favor, entre seu token Plex (X-Plex-Token).';
	@override String get connectDirectPlexCard => 'Plex Serviço de Mídia (Direito / Local)';
	@override String get connectDirectPlexCardSubtitle => 'Conecte-se diretamente usando IP local ou URL sem conta plex.tv.';
	@override String connectDirectPlexCardSubtitleScoped({required Object name}) => 'Conecte-se diretamente usando o IP local ou URL. Conecte-o a ${name}.';
	@override String get insecureTitle => 'conexão não criptografada';
	@override String insecureDescription({required Object url}) => '${url} utiliza HTTP. Outras pessoas na rede podem ler ou alterar a sua palavra-passe, os seus tokens e os seus conteúdos multimédia. Utilize HTTPS quando estiver disponível. Continue apenas se confiar nesta rede e aceitar o risco.';
	@override String get allowHttp => 'Permitir HTTP';
	@override String get httpsRequired => 'Use HTTPS ou permita expressamente uma conexão não criptografada.';
}

// Path: cast
class Translations$cast$pt extends Translations$cast$en {
	Translations$cast$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get chooseDevice => 'Caminhar para um dispositivo';
	@override String get searching => 'Buscando por dispositivos de cast...';
	@override String connectedTo({required Object device}) => 'Conectado a ${device}';
	@override String get device => 'CAST DEFINITOR';
	@override String get readyToCast => 'Pronto para jogar';
	@override String get subtitle => 'Legendas';
	@override String get serverNotAvailable => 'O servidor de mídia não está disponível.';
	@override String get stopCasting => 'Parar de casting';
	@override String get castToDevice => 'Capa para o dispositivo';
	@override String get noEpisodeAvailable => 'Não há episódio disponível para ser lançado.';
	@override String get startFailed => 'Não pode começar a casting. verificar o servidor e tentar novamente.';
}

// Path: automation
class Translations$automation$pt extends Translations$automation$en {
	Translations$automation$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get noActivePlayback => 'Não há sessão de vídeo ativa para controlar.';
}

// Path: notifications
class Translations$notifications$pt extends Translations$notifications$en {
	Translations$notifications$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get newEpisodeTitle => 'Novo episódio';
	@override String newEpisodeBody({required Object show, required Object episode}) => '${show} · ${episode}';
}

// Path: appAccess
class Translations$appAccess$pt extends Translations$appAccess$en {
	Translations$appAccess$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tente todos os recursos grátis por 7 dias';
	@override String get description => 'Comece um teste de sete dias com acesso completo a cada funcionalidade PlezyNG. não há taxa durante o teste e não há assinatura. Após o teste, uma compra de vida no preço da sua loja desbloqueia PlezyNG para a vida.';
	@override String get trialEndedDescription => 'Desbloquear cada funcionalidade em PlezyNG para a vida com uma compra ao preço da sua loja.';
	@override String get startTrial => 'Começa o meu teste gratuito de 7 dias';
	@override String get trialActive => 'Seu teste de 7 dias de função completa está ativo.';
	@override String get trialEnded => 'Seu julgamento de 7 dias terminou';
	@override String get trialStartFailed => 'Não consigo salvar o teste neste dispositivo. por favor tente novamente.';
	@override String get lifetimeTitle => 'PlezyNG desbloqueado para a vida';
	@override String get lifetimeBody => 'Você tem acesso ao tempo todo a cada funcionalidade PlezyNG.';
	@override String get manageTitle => 'PlezyNG acesso ao tempo de vida';
	@override String get manageDescription => 'Tente cada recurso gratuito por 7 dias, depois desbloquee tudo para a vida com um pagamento ao preço da sua loja.';
	@override String buy({required Object price}) => 'Desbloquear todas as funcionalidades para ${price}';
	@override String get loadingPrice => 'Preço de Loading Store...';
	@override String get retryPrice => 'Retorno do preço Lookup';
	@override String get restore => 'Restaurar a compra de vida';
	@override String get pending => 'Sua compra está à espera de pagamento ou aprovação. acesso ao tempo integral desbloqueia assim que a loja o concluir.';
	@override String get storeUnavailable => 'Verifique se você está assinado na loja e as compras são permitidas neste dispositivo.';
	@override String get productNotFound => 'O PlezyNG de desbloqueio de vida ainda não está disponível neste lote.';
	@override String get productQueryFailed => 'Não podia carregar o preço da loja. Verifique a sua conexão e tente novamente.';
	@override String get purchaseFailed => 'A compra não passou, tente novamente.';
	@override String get restoreFailed => 'Não poderia chegar à loja para restaurar a sua compra. tente novamente.';
	@override String get nothingToRestore => 'No PlezyNG compra de vida foi encontrado para esta conta da loja.';
}

// Path: detail
class Translations$detail$pt extends Translations$detail$en {
	Translations$detail$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String endsAt({required Object time}) => 'Termina às ${time}';
}

// Path: watchLink
class Translations$watchLink$pt extends Translations$watchLink$en {
	Translations$watchLink$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get serverUnavailable => 'Não poderia chegar a um servidor Plex para este link.';
	@override String get notFound => 'Não poderia encontrar este show ou filme em seus servidores Plex.';
	@override String get ambiguous => 'Este link se encaixa com itens em mais de um servidor.Add a server to the link.';
	@override String get plexOnly => 'Os links de visualização atualmente só suportam Plex servidores.';
	@override String get unsupportedItem => 'Veja links só pode abrir um show ou um filme.';
	@override String get menuItem => 'Veja o link';
	@override String get dialogTitle => 'Veja o link';
	@override String get dialogShowHint => 'Ao abrir este link, o próximo episódio é jogado.Add &mode=shuffle para o final para jogar o show no shuffle.';
	@override String get dialogMovieHint => 'Ao abrir este link, o filme é jogado.';
	@override String get copy => 'Copia';
	@override String get copied => 'Link copiado';
}

// Path: homeLayout
class Translations$homeLayout$pt extends Translations$homeLayout$en {
	Translations$homeLayout$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Home Layout';
	@override String get resetToast => 'Home Reset para o layout original Plezy herói';
	@override String get resetHeroTitle => 'Resetando o layout do herói para a estoque Plezy?';
	@override String get resetHeroBody => 'Desligue a configuração de herói de cada linha e retorna o único banner de rotação na parte superior da Casa, como antes que as linhas de herói existissem.';
	@override String get removeRowTitle => 'Remover a linha de casa?';
	@override String removeRowBody({required Object title}) => '${title} será excluído. isto não pode ser negado.';
	@override String get sync => 'Síntese';
	@override String get syncAccountTitle => 'Sincronize layout com sua conta Plex';
	@override String get syncAccountOn => 'On: este dispositivo compartilha ordem de linha, linhas, Hero e Auto-slide com os outros dispositivos.';
	@override String get syncAccountOff => 'Desligado: este dispositivo mantém o seu próprio layout.';
	@override String get syncNow => 'Síntese agora';
	@override String get plexHomeManager => 'Plex Gestor de casa';
	@override String get managePlexRows => 'Gestão Plex linhas em Plezy';
	@override String get managePlexRowsDescription => 'Abre para organizar as linhas selecionadas em casa';
	@override String get organizeHomeRows => 'Organize as linhas domésticas';
	@override String organizeHomeRowsDescription({required Object n}) => '${n} linhas: movimento, herói, auto-slide, remover';
	@override String organizeLibraryRows({required Object library}) => 'Organize ${library} linhas';
	@override String organizeLibraryRowsDescription({required Object n}) => 'Continue a assistir + ${n} linhas: movimento, Biblioteca, Home, Hero, Auto-slide';
	@override String get renderAsHero => 'Render como um cartão de herói';
	@override String get heroOnlySingleCollection => 'Disponível somente quando esta linha resolve os títulos reais de uma coleção única';
	@override String get hero => 'Herói';
	@override String get autoSlide => 'Auto-Slide';
	@override String get autoSlideDescription => 'As entradas (PC) e o d-pad (TV) sempre funcionam e reiniciar o timer.';
	@override String get autoSlideEditDescription => 'Também desliza por conta própria a cada alguns segundos. desligado: só se move quando você clicar em uma bala (PC) ou pressionar esquerda/direita no remoto (TV).';
	@override String get enableHeroFirst => 'Primeiro, o herói';
	@override String get showOnHome => 'Mostrando em Home Screen';
	@override String get home => 'Início';
	@override String get removeFromHome => 'Remover de casa';
	@override String get selectRowsFirst => 'Selecione as linhas de casa abaixo primeiro.';
	@override String plexManagedRows({required Object n}) => '${n} Plex linhas gerenciadas';
	@override String get continueWatching => 'Continuar Assistindo';
	@override String get continueWatchingLibraryDescription => 'A própria linha de progresso da biblioteca';
	@override String get continueWatchingHomeDescription => 'A linha de progressão de recesso mostrada em Home';
	@override String get nextUpHomeDescription => 'A próxima sequência de episódios não observados mostrada separadamente em Home';
	@override String get library => 'Biblioteca';
	@override String get showInRecommended => 'Exposição em Biblioteca Recomendada';
	@override String get customPlexRow => 'Cadeia de Cadeia Plex';
	@override String get heroNeedsLibrary => 'Veja a Biblioteca primeiro – Hero precisa de algum lugar para mostrar';
	@override String get heroNeedsSurface => 'Veja a Biblioteca ou a Casa primeiro — Hero precisa de algum lugar para mostrar';
	@override String get removeHub => 'Remover o Hub';
	@override String get noPlexRows => 'No Plex linhas gerenciadas retornou para esta biblioteca.';
	@override String get openDetails => 'Detalhes abertos';
	@override String get heroCards => 'Cartões de herói';
	@override String get tapHeroCard => 'Tapeando um cartão de herói';
	@override String get tvPlayFocus => 'TV remoto: botão de gravação';
	@override String get tvPlayFocusDescription => 'O D-pad para baixo parou no botão Play antes de se mover para a próxima linha.';
	@override String get tvWrap => 'TV remoto: cartões de heroína de loop';
	@override String get tvWrapDescription => 'Direito no último cartão vai para o primeiro. off paradas no último cartões. esquerda no primeiro cartão sempre vai para a barra lateral.';
	@override String get castOnHero => 'Apresentação de Banner Hero';
	@override String get castOnHeroDescription => 'Mostra o cast along the bottom of a hero banner. Off mantém apenas o título e resumo.';
	@override String get customRows => 'Roda personalizada';
	@override String get loading => 'Apresentação de layout...';
	@override String get noCustomRows => 'Não há rodas de costume ainda';
	@override String get addRowHint => 'Use Acesso à linha de casa para criar uma.';
	@override String get addHomeRow => 'Adicionar Home Rue';
	@override String get addHomeRowDescription => 'Escolha uma categoria; a nova linha é adicionada ao Organizador automaticamente';
	@override String get removeRow => 'Remover a linha';
	@override String get recentlyAdded => 'Adicionados recentemente';
	@override String get recentlyReleased => 'Recentemente liberado';
	@override String get movieCollections => 'Filmes Colecções';
	@override String get showCollections => 'Mostrar coleções';
	@override String get rowTitle => 'RODO Título';
	@override String get content => 'Conteúdo';
	@override String get showThisRowIn => 'Mostre esta linha em:';
	@override String get libraryRecommended => 'Biblioteca recomendada';
	@override String get heroCard => 'Cartão de herói';
	@override String get heroCardDescription => 'Mostra como uma cartão de rotação de largura completa em vez de um poster shelf.';
	@override String get heroUnavailableDescription => 'Disponível apenas quando esta linha resolve os títulos reais de uma coleção única – com mais de uma colecionada selecionada não há nenhum título para girar.';
	@override String get librariesSelection => 'Livrarias (deixe todas as bibliotecas não verificadas para incluir todas as bibliotecarias)';
	@override String get librariesMergedDescription => 'Cada biblioteca que você assistir aqui é misturada nesta linha.';
	@override String get movieCollectionsSelection => 'Colecções de filmes (deixe todos não verificados para cada biblioteca selecionada)';
	@override String get showCollectionsSelection => 'Mostrar coleções (deixe todas as bibliotecas não verificadas para cada biblioteca selecionada)';
	@override String get collectionRowsDescription => 'Se exatamente uma coleção se encaixa, seus títulos se mostram diretamente na linha.Se mais de uma coleção encaixa e cada coleção se mostra como um único poster, clique em ela para abrir essa coleção.';
	@override String get allCollections => 'Todas as coleções';
	@override String get noRowsHere => 'Não há linhas aqui ainda.';
	@override String get hideWatchedRows => 'Esconde itens observados em linhas';
	@override String get hideWatchedRowsDescription => 'Títulos totalmente assistidos deixam Casa e biblioteca Sinais recomendados.';
	@override String get untitledCollection => 'Colecção sem título';
	@override String get moveRowHint => 'Up/Down: mover a linha · Selecione: desligue aqui · Retorno: cancelar';
	@override String get organizeRowsHint => 'Selecione uma linha (ou mantenha Selecione): mova-a · esquerda/direita: opções de linha · Volta: feito';
	@override String get layoutNavDescription => 'Escolha linhas, bibliotecas e categorias de coleção';
	@override String get editHomeRow => 'Edit Home Roda';
	@override String get resetHeroButton => 'Resetar layout de herói para stock Plezy';
	@override String get reorderingUnlocked => 'Reorganização desbloqueada';
	@override String get reorderingLocked => 'Reorganização fechada';
	@override String get rowsCanBeDragged => 'As cordas podem ser tiradas — toque no fechamento para evitar que';
	@override String get tapLockToDrag => 'Tire o fechamento para traçar as linhas';
	@override String customRowLabel({required Object title}) => 'Cadeia: ${title}';
	@override String libraryHubLabel({required Object library, required Object hub}) => '${library}: ${hub}';
	@override String get hide => 'Ocultar';
	@override String get remove => 'Remover';
	@override String get libraryResumeRow => 'A Biblioteca de Resumo';
	@override String get pressAgainToDelete => 'Pressione novamente para apagar';
	@override String actionState({required Object action, required Object state}) => '${action}: ${state}';
	@override String get on => 'em';
	@override String get resetHeroButtonDescription => 'Retorna a configuração do herói de cada linha e traz o único banner de rotação para cima, como antes que as linhas de herói existiam.';
	@override String get tapHeroCardDescription => 'Escolha se tapando ou selecionando um cartão Hero começa a reproduzir ou abre seus detalhes.';
	@override String get heroTapPlayDescription => 'Comece o item selecionado imediatamente.';
	@override String get heroTapDetailsDescription => 'Abra os detalhes do item selecionado antes de escolher uma ação.';
}

// Path: platform
class Translations$platform$pt extends Translations$platform$en {
	Translations$platform$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get localNetworkPermission => 'PlezyNG conecta-se aos seus servidores de mídia e dispositivos de reprodução na sua rede local.';
	@override String get locationPermission => 'PlezyNG usa o acesso à localização quando o iOS o exige para detectar sua rede local e conectar-se aos seus servidores de mídia.';
	@override String get photoLibraryPermission => 'Escolha imagens da sua biblioteca de fotos para usar como capas e ilustrações dos arquivos de mídia.';
	@override String get cameraPermission => 'Escanear códigos QR para combinar um Companion Remote.';
}

// Path: universalMedia
class Translations$universalMedia$pt extends Translations$universalMedia$en {
	Translations$universalMedia$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Mídia aberta';
	@override String get shortcutHelp => 'Jogue um link, playlist ou arquivo para esta sessão.';
	@override String get intro => 'Abra um link, playlist ou arquivo. o Playback usa o jogador padrão do PlezyNG e não adiciona história à sua biblioteca.';
	@override String get openWhat => 'O que você gostaria de abrir?';
	@override String get stream => 'Endereço de Stream';
	@override String get playlist => 'Playlist';
	@override String get files => 'Arquivos de dispositivos';
	@override String get favorites => 'Redução dos favoritos';
	@override String get address => 'Endereço de mídia';
	@override String get addressHelp => 'URLs com parâmetros de autenticação ou assinatura reconhecidos são usados apenas para esta sessão e não podem ser salvos como favoritos.';
	@override String get displayName => 'Nome de exibição (opcional)';
	@override String get displayNameHelp => 'Escolha um nome curto para o jogador e controles de mídia do sistema.';
	@override String get allowHttp => 'Permitir uma conexão HTTP não criptografada';
	@override String get allowHttpHelp => 'O HTTP não criptografará a conexão. permita-a apenas em uma rede confiável. Use o HTTPS quando possível.';
	@override String get advancedProtocols => 'MPV somente: introduza um endereço RTSP, RTMP/RTMPS, UDP ou RTP. Esses endereços não podem ser salvos como favoritos.';
	@override String get liveStream => 'Tratar como vivo';
	@override String get liveStreamHelp => 'Use isso para vídeo ou rádio ao vivo.A aplicação esconde a barra de tempo, botões de escape e opção go-to-time.';
	@override String get privateSession => 'Apenas esta reprodução usa o endereço.Save a favor de um fluxo elegível para mantê-lo neste perfil.';
	@override String get saveFavorite => 'Salve o favorito';
	@override String get playNow => 'Jogue agora';
	@override String get favoriteSaved => 'Stream favorito salvo para este perfil';
	@override String skippedEntries({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: 'Escapou ${count} entrada de playlist não suportada ou insegura.',
		many: 'Escapou ${count} entradas de lista de reprodução não suportadas ou inseguras.',
		other: 'Escapou ${count} entradas de lista de reprodução não suportadas ou inseguras.',
	);
	@override String get playlistAddress => 'Endereço Playlist';
	@override String get playlistAddressHelp => 'Abra uma lista de reprodução M3U, M3u8, ou PLS a partir de um endereço web. links de streaming direto não salvam a lista.';
	@override String get choosePlaylist => 'Escolha o arquivo de playlist';
	@override String get openPlaylist => 'Playlist aberta';
	@override String get playlistFormatsHelp => 'Uma lista de reprodução pode conter até 1.000 itens e 2 MB. HLS manifesta-se aberta como fluxos para que o jogador possa escolher uma qualidade.';
	@override String get saveQueuePlaylist => 'Guardar fila como lista de reprodução';
	@override String get queuePlaylistSaved => 'A lista de reprodução foi guardada junto aos ficheiros multimédia.';
	@override String get queuePlaylistUnavailable => 'Esta fila não pode ser guardada como uma lista local reutilizável.';
	@override String get queuePlaylistFolderRequired => 'Escolha uma localização na mesma pasta dos ficheiros da fila.';
	@override String get noFavorites => 'Não foram salvos favoritos ainda. favoritos permanecem neste perfil.';
	@override String get removeFavorite => 'Remover streaming favorito';
	@override String get filesHelp => 'Escolha arquivos de áudio, vídeo ou ISO para uma quebra temporária. arquivos e URLs não são adicionados ao histórico da biblioteca.';
	@override String get chooseFiles => 'Escolha arquivos';
	@override String fileQueue({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '1 arquivo selecionado',
		many: '${count} arquivos selecionados',
		other: '${count} arquivos selecionados',
	);
	@override String get wifiTransfer => 'Enviar arquivos por Wi-Fi';
	@override String get wifiTransferHelp => 'Transferir arquivos suportados de um navegador na mesma rede confiável.';
	@override String get wifiTransferIntro => 'Abra este endereço num navegador em outro dispositivo. selecione arquivos para adicioná-los à biblioteca de Arquivos e Livros deste dispositivo.';
	@override String get wifiTransferPrivacy => 'Este dispositivo recebe arquivos através da sua rede local. Qualquer pessoa que conhece este endereço pode enviar arquivos até você parar a transferência ou o endereçamento expira após 15 minutos. Máximo: 100 arquivos, 4 GiB por arquivo, 10 GiB total.';
	@override String get wifiTransferStarting => 'Preparação de uma transferência privada, limitada ao tempo...';
	@override String get wifiTransferUnavailable => 'Não pode iniciar a transferência. Verifique o acesso da rede local e tente novamente.';
	@override String get openThisAddress => 'Abra um desses endereços no dispositivo de envio';
	@override String get copyAddress => 'Cópia do endereço de transferência';
	@override String get addressCopied => 'Endereço de transferência copiado';
	@override String transferExpires({required Object time}) => 'Este endereço expira em ${time}.';
	@override String uploadCount({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: 'arquivo ${count} recebido',
		many: 'arquivos ${count} recebidos',
		other: 'arquivos ${count} recebidos',
	);
	@override String uploadedData({required Object size}) => 'Recebido ${size}';
	@override String get stopTransfer => 'Cessar transferência e invalidar endereço';
	@override String get startTransfer => 'Início Transferência';
	@override String get wifiImportedFiles => 'Transferência Wi-Fi';
	@override String get wifiBrowserTitle => 'Enviar arquivos para PlezyNG';
	@override String get wifiBrowserIntro => 'Escolha arquivos de áudio, vídeo, ebook ou comédia para enviar. Os arquivos são salvos na biblioteca dos arquivos e livros deste dispositivo. Máximo: 100 arquivos, 4 GiB por arquivo, 10 GiB total.';
	@override String get uploadFilesLabel => 'Arquivos para enviar';
	@override String get uploadSelected => 'Carregar arquivos selecionados';
	@override String get uploadSelectFirst => 'Escolha um ou mais arquivos primeiro.';
	@override String get uploading => 'Envio';
	@override String get uploadComplete => 'Arquivo adicionado para PlezyNG.';
	@override String get uploadFailed => 'O arquivo não pode ser adicionado.Mantenha esta página aberta e tente novamente.';
	@override String get liveCue => 'Viva';
	@override String get liveSession => 'Streaming ao vivo';
	@override String get liveCueHelp => 'Para vídeo ou rádio ao vivo, o aplicativo esconde a barra de tempo e escapa os botões.';
	@override String get sessionOnly => 'Este playback é apenas sessão';
	@override String get sessionOnlyHelp => 'Playback nunca salva progresso ou história. Salve o fluxo como um favorito para mantê-lo neste perfil se é elegível.';
	@override String get pictureAdjustments => 'Adaptação de imagem';
	@override String get pictureHelp => 'Essas mudanças de imagem afetam apenas este playback. eles se resistem quando o playback termina.';
	@override String get resetPicture => 'Resetando a imagem';
	@override String get brightness => 'brilho';
	@override String get contrast => 'Contraste';
	@override String get gamma => 'Gama';
	@override String get hue => 'Hue';
	@override String get saturation => 'Saturno';
	@override String get view360 => 'Vista plana para 360° de vídeo';
	@override String get view360Help => 'Use isso para o vídeo 360° equirectangular. MPV precisa do filtro v360 da FFmpeg para esta visualização.';
	@override String get view360Unavailable => 'Esta configuração mpv não poderia aplicar o filtro de 360°.';
	@override String get view360Yaw => 'Visão Horizontal';
	@override String get view360Pitch => 'Visão Vertical';
	@override String get view360FieldOfView => 'Campo de Visão';
	@override String get recordStream => 'Recordes de streaming ao vivo';
	@override String get stopRecording => 'Parar e salvar a gravação';
	@override String get recordingStarted => 'A gravação é ativa. deixando o playback parou e salva a gravación.';
	@override String get recordingSaved => 'A gravação foi concluída e salvada.';
	@override String get recordingActive => 'Deixe o playback parar e salve.';
	@override String get recordingFormatHelp => 'Para vídeo, selecione MKV ou MPEG-TS. Para áudio, escolha MKA ou MKV.';
	@override String get replaceRecordingTitle => 'Substitui essa gravação?';
	@override String get replaceRecordingHelp => 'O PlezyNG recupera o arquivo existente durante a gravação.Se não consegue salvar o novo registro, o plezyNG restaura o backup.';
	@override String get replaceRecording => 'Substituição de arquivo';
	@override String get discHelp => 'Abra um disco no disco óptico deste computador. Você também pode abrir uma imagem ISO dos arquivos de dispositivo.';
	@override String get discs => 'Discos ópticos';
	@override String get editionOrTitle => 'Edição ou título do disco';
	@override String get dvd => 'DVD';
	@override String get bluray => 'Blu-ray em';
	@override String get audioCd => 'CD de áudio';
	@override String get discAvailability => 'A reprodução de discos precisa de um edifício MPV compatível, disco suportado e permissão do sistema operacional.';
	@override String get converterTitle => 'Converter um arquivo de mídia local';
	@override String get converterHelp => 'Converter um arquivo local ou remuque-o com FFmpeg.';
	@override String get converterIntro => 'Converter um arquivo de áudio ou vídeo local para um formato que funciona em vários dispositivos.';
	@override String get converterPrivacy => 'FFmpeg deve ser instalado neste computador. conversão lê apenas arquivos locais. não descarga fluxos ou remove DRM.';
	@override String get converterChooseInput => 'Escolha um arquivo de mídia local';
	@override String get converterFormat => 'Formato de saída';
	@override String get converterMp4 => 'MP4 · H.264 e AAC';
	@override String get converterM4a => 'M4A - Áudio AAC';
	@override String get converterMp3 => 'MP3 - Áudio';
	@override String get allowFtp => 'Permitir FTP';
	@override String get allowFtpHelp => 'FTP envia mídias sem criptografia. Use apenas em redes confiáveis.';
	@override String get converterSaveAs => 'Mídia convertida como';
	@override String get converterExtensionMismatch => 'Escolha um nome de arquivo com a extensão de saída selecionada.';
	@override String get converterUnsupportedInput => 'Escolha um arquivo de áudio ou vídeo.';
	@override String get converterLocalOnly => 'O arquivo selecionado não está disponível como um caminho de dispositivo local.';
	@override String get converterReplaceTitle => 'Substitui esse arquivo?';
	@override String get converterReplaceHelp => 'PlezyNG recupera o arquivo existente até que a cópia convertida seja salvida.';
	@override String get converterStarting => 'Começando com FFmpeg...';
	@override String get converterProgress => 'Converter para esse computador...';
	@override String get converterComplete => 'Conversão completa. o novo arquivo está pronto.';
	@override String get converterFfmpegMissing => 'FFmpeg está faltando ou não suporta este formato.';
	@override String get converterFailed => 'Verifique se o arquivo fonte pode ser lido e o destino tem espaço livre suficiente.';
	@override String get converterCancelled => 'A conversão foi cancelada. a saída incompleta foi removida.';
	@override String get converterDesktopOnly => 'A conversão local está disponível em computadores de desktop com FFmpeg instalado.';
	@override String get converterStart => 'Conversão de arquivos';
	@override String get mediaToolsTitle => 'Ferramentas de mídia';
	@override String get mediaToolsShortcut => 'Capturar ou compartilhar mídia, adicionar extensões de pesquisa, ou usar a linha de comando.';
	@override String get mediaToolsIntro => 'Escolha uma ferramenta focada. capturar e stream-out usar FFmpeg instalado neste desktop. extensões e comandos CLI usar pedidos HTTPS limitados e o fluxo Open media existente.';
	@override String get mediaToolsAccessibility => 'As opções de ferramentas e controles funcionam com o toque, indicador, teclado e foco D-pad. As mudanças no status de gravação, compartilhamento e pesquisa são anunciadas.';
	@override String get mediaTool => 'Ferramentas de mídia';
	@override String get captureIntro => 'Recorde a sua tela ou uma câmera para um arquivo MP4 neste computador. FFmpeg deve ser instalado e incluir o codificador H.264.';
	@override String get captureNoDevices => 'Não foi encontrado nenhum ecrã ou câmera. Verifique o suporte de captura da FFmpeg e permissões de privacidade do sistema operacional.';
	@override String get captureSource => 'tela ou câmera';
	@override String get captureScreen => 'ecrã';
	@override String get captureAudioSource => 'Introdução de áudio (opcional)';
	@override String get captureAudioHelp => 'Adicione áudio a partir de um microfone ou entrada disponível. as escolhas do dispositivo dependem da FFmpeg e das permissões do sistema.';
	@override String get captureAudioNone => 'Não há áudio';
	@override String get captureDefaultAudio => 'Introdução de áudio';
	@override String get captureWaylandHelp => 'Wayland limita esta captura XWayland para o X display. Windows fora XWayland pode não aparecer.';
	@override String get captureFrameRate => 'Rápido de gravação';
	@override String get capturePrivacy => 'A gravação é salvida apenas para o arquivo que você escolher. captura de microfone é opcional. PlezyNG não carrega a gravação.';
	@override String get captureSaveAs => 'Salve a gravação de tela como';
	@override String get captureExtensionMismatch => 'Escolha um nome de arquivo que termina em .mp4.';
	@override String get captureFfmpegMissing => 'FFmpeg ou o codificador de vídeo H.264 não está disponível. instale um edifício FFmpeg suportado, então tente novamente.';
	@override String get captureFailed => 'Verifique permissão do dispositivo, armazenamento disponível e suporte FFmpeg.';
	@override String get captureSaved => 'A gravação de tela foi salvida.';
	@override String get captureElapsedLabel => 'Tempo de gravação';
	@override String get captureStart => 'Começa a gravação';
	@override String get capturePreview => 'Pré-visualizar no leitor';
	@override String get capturePreviewHelp => 'Pré-visualize a origem selecionada no leitor padrão. A pré-visualização só dura nesta sessão e não guarda uma gravação. O suporte dos dispositivos e as permissões dependem do MPV e do sistema operativo. A pré-visualização usa apenas vídeo; as gravações guardadas podem incluir áudio opcional.';
	@override String get capturePreviewActive => 'Pré-visualização em direto · sem gravação';
	@override String get captureStop => 'Parar e salvar';
	@override String get captureMode => 'captura';
	@override String get shareMode => 'Compartilhar';
	@override String get shareIntro => 'Envie um arquivo de mídia local para outro dispositivo em sua rede privada. PlezyNG cria um fluxo temporário HLS.';
	@override String get sharePrivacy => 'Qualquer pessoa na sua rede local que recebe o link privado pode assistir enquanto estiver ativo. o link expira após 60 minutos. parar de compartilhar para fechar o servidor e invalidar o link.';
	@override String get shareChooseFile => 'Escolha o arquivo de mídia';
	@override String get shareChooseHelp => 'Selecione um arquivo local de áudio ou vídeo. o arquivo permanece neste computador.';
	@override String get shareFfmpegMissing => 'FFmpeg ou os codificadores H.264/AAC não estão disponíveis. instalar FFmpeg com o suporte de codificação H.264 e AAC.';
	@override String get shareFailed => 'O fluxo não podia começar ou parar inesperadamente. verificar FFmpeg e acesso à rede.';
	@override String get shareActive => 'O fluxo está pronto na sua rede privada.';
	@override String get shareEnded => 'A mídia chegou ao fim e já não é compartilhada.';
	@override String get shareStopped => 'O link temporário já não é válido.';
	@override String get shareUrlCopied => 'Endereço de transmissão copiado.';
	@override String get shareOpenUrl => 'Abra este endereço em um jogador no outro dispositivo';
	@override String get shareQrLabel => 'Código QR para o endereço de fluxo temporário';
	@override String get shareQrHelp => 'Escanear com um jogador compatível conectado à mesma rede privada.';
	@override String get shareHttpHint => 'Este fluxo usa HTTP não criptografado. em PlezyNG, permita HTTP antes de abri-lo.';
	@override String get shareCopyUrl => 'Cópia de endereço de fluxo';
	@override String get shareExpiresLabel => 'O link expira em';
	@override String get shareStarting => 'Preparando o fluxo...';
	@override String get shareStart => 'Comece a compartilhar';
	@override String get shareStop => 'Pare de compartilhar';
	@override String get extensionsMode => 'Extensões e CLI';
	@override String get extensionsIntro => 'Adicione uma extensão de pesquisa de dados apenas para encontrar mídias. Escolha um resultado para carregá-lo no formulário familiar Open media.';
	@override String get extensionsPrivacy => 'Um manifesto pode definir um HTTPS endpoint de pesquisa e campos de resposta de mapa. não pode executar código, adicionar cabeçalhos de solicitação, ler arquivos, ou lançar comandos de shell.';
	@override String get extensionImport => 'Adicionar extensão manifesto';
	@override String get extensionEmpty => 'Não há serviços de pesquisa ainda. Escolha um arquivo manifesto confiável JSON para adicionar um.';
	@override String get extensionChoose => 'Serviço de busca';
	@override String get extensionSearchConsent => 'Cada pesquisa envia suas palavras para este serviço HTTPS. Os resultados só se abrem depois de você selecionar um.';
	@override String get extensionSearchLabel => 'Pesquisa de mídia';
	@override String get extensionSearch => 'Pesquisa';
	@override String get extensionSearching => 'Buscando...';
	@override String get extensionNoResults => 'Não foram retornados resultados de mídia segura. tente outra pesquisa.';
	@override String get extensionInstallTitle => 'Adicione este serviço de busca?';
	@override String get extensionReplaceTitle => 'Actualiza este serviço de busca?';
	@override String get extensionService => 'Serviço';
	@override String get extensionEndpoint => 'HTTPS ponto final';
	@override String get extensionConsent => 'Seu texto de busca é enviado para este serviço. o manifesto não contém código executável. Continue apenas se você confiar neste ponto final.';
	@override String get extensionInstall => 'Adicionar serviço';
	@override String get extensionReplace => 'Serviço de atualização';
	@override String get extensionRemoveTitle => 'Remover este serviço de busca?';
	@override String get extensionRemoveHelp => 'Isso remove o serviço deste perfil. a PlezyNG não se comunica com o seu ponto final.';
	@override String get extensionRemove => 'Remover Serviço';
	@override String get extensionInvalidManifest => 'Este arquivo não é um manifesto de extensão suportado. ver o guia Open media para o formato.';
	@override String get extensionSaveFailed => 'A extensão não poderia ser salvida para o perfil ativo.';
	@override String get extensionSearchFailed => 'O serviço de busca não devolveu uma resposta válida. verificar o ponto final e tentar novamente.';
	@override String get cliTitle => 'Linha de comando';
	@override String get cliHelp => 'Use o guia plezyctl para validar um manifesto ou pesquisar a mesma extensão. Revise seu serviço HTTPS antes de cada pesquisa. Resultados abrem no formulário de mídia existente; selecione o botão de reprodução para começar.';
	@override String get cliCopyExample => 'Exemplo de comando de cópia';
	@override String get cliCopied => 'Exemplo de comando copiado.';
}

// Path: fileSources
class Translations$fileSources$pt extends Translations$fileSources$en {
	Translations$fileSources$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Arquivos e livros';
	@override String get subtitle => 'Leia, ouça e veja de seus próprios arquivos.';
	@override String get add => 'Adicionar fonte';
	@override String get importFiles => 'Importação de arquivos';
	@override String get localFiles => 'Neste dispositivo';
	@override String get source => 'Fonte';
	@override String get name => 'Nome';
	@override String get endpoint => 'URL do servidor';
	@override String get smbEndpointHint => 'Exemplo: smb://nas/Movies';
	@override String get smbEndpointInvalid => 'Introduza um servidor SMB e uma pasta partilhada.';
	@override String get root => 'Fólio ou Prefixo';
	@override String get smbFolderHelp => 'Deixe em branco para usar toda a pasta partilhada ou introduza uma pasta dentro dela.';
	@override String get username => 'Usuário';
	@override String get smbDomain => 'Domínio (opcional)';
	@override String get password => 'Senha';
	@override String get token => 'API Tópico';
	@override String get accessKey => 'ID de acesso';
	@override String get secretKey => 'A chave de acesso';
	@override String get sessionToken => 'Sessão de sessão (opcional)';
	@override String get region => 'Região';
	@override String get clientId => 'ID do cliente OAuth';
	@override String get clientSecret => 'OAuth Client Secret (só no Google Desktop)';
	@override String get allowHttp => 'Permitir HTTP sem encriptação numa rede de confiança';
	@override String get smbEncryption => 'Encriptar a ligação SMB3';
	@override String get smbEncryptionHint => 'Usar encriptação SMB3 quando o NAS a suportar.';
	@override String get connect => 'Conectar';
	@override String get cancel => 'Cancelar';
	@override String get save => 'Salvar';
	@override String get close => 'Fechar';
	@override String get removeSource => 'Fonte desconectado';
	@override String get disconnectMessage => 'Desconectar esta fonte? Os arquivos baixados e seu histórico de leitura e audição permanecerão neste dispositivo.';
	@override String get localFolder => 'Escolha o Folheto';
	@override String get empty => 'Ainda não há nada aqui';
	@override String get emptyHint => 'Adicione uma fonte ou importar um livro, audiobook, música ou vídeo.';
	@override String get search => 'Procure esta pasta';
	@override String get searchCached => 'Busca de biblioteca salvo';
	@override String get refresh => 'Atualizar';
	@override String get loadMore => 'Carregar mais';
	@override String get offline => 'Disponível offline';
	@override String get download => 'Mantenha offline';
	@override String get removeDownload => 'Remover cópia offline';
	@override String get continueReading => 'Continue a ler';
	@override String get continueListening => 'Continue a ouvir';
	@override String get continueWatching => 'Continue a observar';
	@override String get read => 'Leia';
	@override String get listen => 'ouvir';
	@override String get play => 'Reproduzir';
	@override String get pause => 'Pausar';
	@override String get stop => 'Parar';
	@override String get startOver => 'Comece por';
	@override String get finished => 'Concluído';
	@override String get markFinished => 'Marcão terminou';
	@override String get markUnfinished => 'Marcadores Infinitos';
	@override String get editions => 'Edições e arquivos';
	@override String get chapters => 'Capítulos';
	@override String get bookmarks => 'Bookmarks e Notas';
	@override String get bookmark => 'Adicionar Bookmark';
	@override String get highlight => 'Alevado';
	@override String get note => 'Notícia';
	@override String get delete => 'Excluir';
	@override String get export => 'Notas de Exportação';
	@override String get exported => 'Notas exportadas';
	@override String get sync => 'Síntese de progresso';
	@override String get synced => 'Progresso Síntese';
	@override String get conflict => 'Outro dispositivo tem uma posição diferente. escolha onde continuar.';
	@override String get useLocal => 'Use esse dispositivo';
	@override String get useRemote => 'Use outros dispositivos';
	@override String get history => 'História da posição';
	@override String get groupAudio => 'Ouça como um livro de audição';
	@override String get groupHint => 'Combine os arquivos de áudio atualmente carregados nesta pasta. carregar todas as páginas primeiro.';
	@override String get order => 'Arquivo Ordem';
	@override String get moveUp => 'Move em cima';
	@override String get moveDown => 'Move abaixo';
	@override String get speed => 'Velocidade do Playback';
	@override String get sleep => 'Temporizador de suspensão';
	@override String get sleepOff => 'Desativado';
	@override String get endChapter => 'Fim do capítulo';
	@override String minutes({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minuto',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minutos',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minutos',
	);
	@override String get skipBack => 'Escape de volta';
	@override String get skipForward => 'Escape em frente';
	@override String get smartRewind => 'Atualidade após uma pausa';
	@override String get playbackOptions => 'Escolhendo opções';
	@override String remaining({required Object time}) => '${time} restante';
	@override String get contents => 'Conteúdo';
	@override String get readerSettings => 'Leia as definições';
	@override String get fontSize => 'tamanho de texto';
	@override String get lineHeight => 'Linha de espaço';
	@override String get margin => 'Margens';
	@override String get font => 'Tipo de Face';
	@override String get serif => 'Séries';
	@override String get sans => 'Sem serifismo';
	@override String get mono => 'Monopóstico';
	@override String get columns => 'Colunas';
	@override String get scroll => 'Escrever verticalmente';
	@override String get justify => 'Justificando o texto';
	@override String get readerTheme => 'Aparência da página';
	@override String get appTheme => 'Siga o tema do app';
	@override String get paper => 'Papel';
	@override String get sepia => 'Sepia';
	@override String get night => 'Noite';
	@override String get readAloud => 'Ler esta página em voz alta';
	@override String get readAlong => 'Leia em conjunto';
	@override String get stopReading => 'Parar a narrativa';
	@override String get searchBook => 'Busca em livro';
	@override String get noMatches => 'Não há jogos';
	@override String get previousPage => 'Página anterior';
	@override String get nextPage => 'Próximo Página';
	@override String page({required Object number}) => 'Página ${number}';
	@override String get externalBlocked => 'Os links externos do livro estão desativados no leitor.';
	@override String get loading => 'Abertura...';
	@override String get narrator => 'narração';
	@override String get audio => 'Áudio';
	@override String get video => 'Vídeo';
	@override String get ebooks => 'Ebooks';
	@override String get all => 'Todos';
	@override String get downloads => 'Arquivos Offline';
	@override String get confirmDelete => 'Remova a cópia offline selecionada? sua posição e notas permanecerão.';
	@override String get errorAuthentication => 'Inscreva-se novamente para reconectar essa fonte.';
	@override String get errorPermission => 'Esta fonte não concedeu acesso ao arquivo solicitado.';
	@override String get errorUnavailable => 'A fonte não está disponível. tente novamente, ou abra uma cópia offline.';
	@override String get errorUnsupported => 'Este formato ou conexão não é suportado neste dispositivo. verifique o guia de configuração de fonte.';
	@override String get errorInvalidData => 'Este arquivo ou resposta do servidor não pode ser lido de forma segura.';
	@override String get errorCancelled => 'A operação foi cancelada.';
	@override String get errorConflict => 'A posição mudou em outra sessão. reabre o item para selecionar uma posição.';
	@override String get signIn => 'Entrar';
	@override String get reconnect => 'Reconectar';
	@override String get folderHelp => 'Deixe branco para começar na raiz fonte. URLs S3 incluem o bucket.';
	@override String get preferences => 'Preferências';
	@override String get timePosition => 'Posição';
	@override String get audioTrack => 'Audio Track';
	@override String get subtitleTrack => 'Subtítulo Track';
	@override String get none => 'Nenhuma';
	@override String get fullscreen => 'Ecrã completa';
	@override String get syncLocation => 'Folha de sincronização de progresso (opcional)';
	@override String get syncLocationHint => 'Um folder dedicado WebDAV para PlezyNG estado. usa escritos condicionais; os meios de comunicação permanecem inalterados.';
	@override String get audiobooks => 'Audiolivros';
	@override String get comics => 'Banda desenhada';
	@override String get scan => 'Escaneamento de livros e mídia';
	@override String get browserReader => 'Leitor aberto';
	@override String get browserReaderHelp => 'O leitor está aberto no seu navegador.Mantenha o PlezyNG aberto para salvar seu lugar e notas.';
	@override String get on => 'em';
	@override String get advancedSetup => 'App Registro';
	@override String get microsoftSignIn => 'Inscreva-se com a Microsoft';
	@override String get zoomIn => 'Zoom em';
	@override String get zoomOut => 'Zoom em Out';
	@override String get fitPage => 'Página FIT';
	@override String get fitWidth => 'Ficou em largura';
	@override String get actualSize => 'Tamanho atual';
	@override String get goToPage => 'Ir para página';
	@override String get goToSection => 'Vá para o capítulo';
	@override String pageRange({required Object count}) => 'Entre um número de 1 para ${count}';
	@override String get pageLayout => 'Página Layout';
	@override String get automatic => 'Automático';
	@override String get singlePage => 'Página única';
	@override String get twoPages => 'Duas páginas';
	@override String get readingDirection => 'Leitura Direção';
	@override String get leftToRight => 'De esquerda para direita';
	@override String get rightToLeft => 'Da direita para a esquerda';
	@override String get letterSpacing => 'Carta de espaço';
	@override String get wordSpacing => 'Palavra espaçado';
	@override String get readerControlsHelp => 'Afaste dois dedos ou use os controles de zoom para ampliar as páginas. Arraste para mover a página. Ctrl/⌘ com + ou − ajusta o zoom; Ctrl/⌘ com 0 o redefine. Page Up e Page Down mudam de página.';
	@override String get imagePage => 'Página de banda desenhada';
	@override String get resetReader => 'Resetando as preferências de leitura';
	@override String get zoom => 'Zoom';
	@override String get useFiles => 'Use arquivos e livros';
	@override String get cancelScan => 'Cancelar o scan';
	@override String get googleDrive => 'Google Drive';
	@override String get offlineQuota => 'Limite de download Offline';
	@override String get offlineQuotaHelp => 'Defina o espaço máximo usado por cópias offline, arquivos importados e downloads qued. A redução do limite não remove cópios existentes.';
	@override String get offlineStorageUsage => 'armazenamento offline';
	@override String get reservedStorage => 'Reservação';
	@override String get downloadQueue => 'Descarregar Queue';
	@override String get downloadRunning => 'Baixe';
	@override String get downloadQueued => 'Aguardando';
	@override String get downloadPaused => 'Pausa';
	@override String get downloadFailed => 'Necessidade de retiro';
	@override String get importing => 'Importação';
	@override String get importInterrupted => 'Importação interrompida · remover para limpar';
	@override String get errorQuotaExceeded => 'O limite de armazenamento offline foi alcançado. elevar o limite ou remover uma cópia descarregada.';
	@override String get errorStorageLow => 'Não há armazenamento gratuito suficiente para manter a reserva protegida.';
	@override String get errorStorageUnavailable => 'PlezyNG não podia verificar o armazenamento do dispositivo gratuito, então a escrita foi interrompida.';
	@override String get removeDownloadJob => 'Remover download';
	@override String get downloadAlreadyComplete => 'Este download terminou antes que pudesse ser removido. o item está agora disponível offline.';
	@override String get confirmRemoveDownloadJob => 'Remova este download e desligue quaisquer dados partialmente baixados? sua posição e notas permanecerão.';
}

// Path: lending
class Translations$lending$pt extends Translations$lending$en {
	Translations$lending$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bibliotecas Públicas';
	@override String get add => 'Adicione uma biblioteca';
	@override String get other => 'Outra biblioteca';
	@override String get libraryName => 'Nome da Biblioteca';
	@override String get libraryUrl => 'Site da Biblioteca';
	@override String get libraryUrlHint => 'Use o catálogo da sua biblioteca ou página de assinatura.';
	@override String get intro => 'Empréstimo da sua biblioteca.Mantenha seus livros fechados.';
	@override String get handoff => 'Inscreva-se, empreste e leia com segurança com o serviço da sua biblioteca.';
	@override String get openService => 'Biblioteca aberta';
	@override String get findLibrary => 'Encontre uma biblioteca';
	@override String get search => 'Busca de livros e autores';
	@override String get catalogue => 'Catálogo';
	@override String get loans => 'Empréstimos';
	@override String get holds => 'Reservas';
	@override String get signIn => 'Inscreva-se com a sua biblioteca';
	@override String get waiting => 'Finalize a assinatura no seu navegador e, em seguida, volte aqui.';
	@override String get cancel => 'Cancelar';
	@override String get disconnect => 'Remover a biblioteca';
	@override String get disconnectMessage => 'Remover esta biblioteca deste perfil? Seus empréstimos e reservas continuarão registrados na biblioteca.';
	@override String get getBook => 'Obtenha Livro';
	@override String get checkAvailability => 'Verifique a disponibilidade';
	@override String get available => 'Disponível para empréstimo';
	@override String get unavailable => 'Atualmente não disponível';
	@override String get borrow => 'Pegar emprestado';
	@override String get placeHold => 'Reservar';
	@override String get returnBook => 'Retorno cedo';
	@override String get cancelHold => 'Cancelar reserva';
	@override String get confirmBorrow => 'Você empresta esse título da sua biblioteca?';
	@override String get confirmReturn => 'Devolver este título agora? Talvez seja necessário pegá-lo emprestado novamente para continuar.';
	@override String get confirmCancelHold => 'Cancelar sua reserva deste título?';
	@override String get email => 'Mantenha o email de notificação';
	@override String due({required Object date}) => 'Duração ${date}';
	@override String queue({required Object position}) => 'Posição ${position} em linha';
	@override String get empty => 'Não há títulos aqui ainda.';
	@override String get openLibraryNote => 'Explore o catálogo da Open Library. Opções de leitura e empréstimo são exibidas na página de cada título.';
	@override String get more => 'Carregar mais';
	@override String get gateway => 'Biblioteca de inscrição em serviço';
	@override String get gatewayHint => 'Fornecido pela sua biblioteca ou pelo administrador PlezyNG.';
	@override String get advanced => 'Integração da Biblioteca';
	@override String get loadLibraries => 'Escolha sua biblioteca';
	@override String get expired => 'O empréstimo já expirou.';
	@override String get updated => 'Biblioteca atualizada';
	@override String get continueService => 'Continuar em serviço';
	@override String get comingSoon => 'Empréstimo em app · Vem em breve';
	@override String get comingSoonDescription => 'Você pode usar sua biblioteca em Libby enquanto terminamos conectando-a.';
	@override String get suspendHold => 'Suspensão de manutenção';
	@override String get resumeHold => 'Resumo de Manutenção';
	@override String get suspendMessage => 'Manter seu lugar na fila e deixar o próximo leitor pegar esta cópia emprestada? Você poderá retomar a reserva mais tarde.';
	@override String get resumeMessage => 'Retomar esta reserva para que a biblioteca possa oferecer a próxima cópia disponível?';
	@override String get editEmail => 'Mudança de notificação de email';
}

// Path: audiobook
class Translations$audiobook$pt extends Translations$audiobook$en {
	Translations$audiobook$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get syncTitle => 'Leitura e escuta sincronização';
	@override String get syncHelp => 'Mantenha as posições de leitura, as posições de escuta, o estado de conclusão, as notas e as notas em todos os seus dispositivos. Escolha uma conta de armazenamento anexada e use o mesmo código de sincronização em cada dispositivo. Ler e ouvir permanecem separados.';
	@override String get addSyncSource => 'Adicione o Google Drive, o OneDrive, o Dropbox, o WebDAV ou o S3 em Arquivos e Livros primeiro.';
	@override String get syncDestination => 'Conta de armazenamento de sincronização';
	@override String get syncFolder => 'Sincronização de folha ou prefixo';
	@override String get syncFolderHelp => 'Use uma pasta existente separada dentro da sua fonte WebDAV, ou um prefixo dedicado S3.';
	@override String get syncCode => 'Código de sincronização';
	@override String get syncCodeHelp => 'Crie um código em seu primeiro dispositivo e, em seguida, introduza esse código em seus outros dispositivos.Mantenha uma cópia privada: é a chave para o seu estado criptografado.Utiliza um código diferente para cada pessoa.';
	@override String get showCode => 'Mostrar ou esconder o código de sincronização';
	@override String get newSyncCode => 'Crie um novo código de sincronização';
	@override String get saveSync => 'Save e Sincronize';
	@override String get disableSync => 'Desligue a sincronização neste dispositivo';
	@override String get syncSourceDisconnect => 'Remover esta fonte irá desativar a leitura e a escuta de sincronização aqui. arquivos de sincronização criptografados permanecerão no provedor.';
	@override String get syncReconnect => 'Reconectar a conta de armazenamento';
	@override String lastSynced({required Object time}) => 'Última sincronização em ${time}';
	@override String get syncPrivacy => 'Somente progressos e notas criptografados são armazenados. arquivos de áudio e ebook, tokens de conta e senhas não são carregados. Google Drive e OneDrive usa armazenamento de aplicativos; Dropbox usa PlezyNG Sync. A habilitação de sincronização pode solicitar acesso adicional de escrita. Enquanto ativado, este destino possui sincronização de progresso; o progresso do servidor permanece separado.';
	@override String get syncConflicts => 'Escolha onde reencontrar';
	@override String get conflictHelp => 'Essas alterações foram feitas de forma independente. escolha a posição ou a versão de marcador para manter. Um tempo mais tarde ou uma porcentagem mais alta não ganha automaticamente.';
	@override String syncDevice({required Object device}) => 'Atividade ${device}';
	@override String get syncUnknownDevice => 'Dispositivo desconhecido';
	@override String get deletedBookmark => 'Livro eliminado';
	@override String get finished => 'Finalizado';
	@override String readingPosition({required Object percent}) => 'Ler · ${percent}%';
	@override String get chapterTimeline => 'Capítulo Progresso';
	@override String get bookTimeline => 'Livro completo Progresso';
	@override String bookRemaining({required Object time}) => 'Tempo restante neste livro: ${time}';
	@override String chapterRemaining({required Object time}) => 'Tempo restante neste capítulo: ${time}';
	@override String get unknownRemaining => 'Tempo total disponível enquanto as partes são jogadas';
	@override String get undoSeek => 'Última busca';
	@override String get customSpeed => 'Velocidade Custom Playback';
	@override String get speedHelp => 'Escolha uma velocidade de 0,25× a 4×.';
	@override String get apply => 'Aplique';
	@override String get customSleep => 'Tempo de sono personalizado';
	@override String get sleepMinutes => 'Minutos (1 a 1440)';
	@override String sleepChapters({required Object count}) => 'Parar após ${count} capítulos';
	@override String get extendSleep => 'Adicionar 5 minutos';
	@override String sleepRemaining({required Object time}) => 'Tempo de sono: ${time}';
	@override String get useDefaults => 'Use esses controles de escuta para novos livros';
	@override String get librarySort => 'Livros Sorte';
	@override String get sortTitle => 'Título';
	@override String get sortAuthor => 'Autor';
	@override String get sortNarrator => 'narração';
	@override String get sortSeries => 'Série Ordem';
	@override String get sortRecent => 'Recentemente aberta';
	@override String get statusFilter => 'Status de leitura';
	@override String get statusAll => 'Todos os livros';
	@override String get statusNew => 'Não começou';
	@override String get statusProgress => 'em progresso';
	@override String get statusFinished => 'Finalizado';
	@override String get goToTime => 'Vá ao tempo';
	@override String get timeHelp => 'Horas: minutos: segundos ou minutos: segundos';
	@override String get recoveryHelp => 'Exportar uma cópia recentemente criptografada antes de mover ou reparar dados de sincronização. Importações se misturam com o estado atual; eles nunca substituem a história local da sincronización.';
	@override String get recoveryExport => 'Exportação de arquivos de recuperação criptografados';
	@override String get recoveryImport => 'Importar arquivo de recuperação criptografado';
	@override String get recoveryImportConfirm => 'Combine este arquivo de recuperação criptografado com as posições e notas de leitura atuais? História existente será mantida. bibliotecas compartilhadas e IDs de itens não são incluídos; definir IDs correspondentes em cada dispositivo antes da importação.';
	@override String get recoveryExported => 'arquivo de recuperação criptografado salvo.';
	@override String get recoveryImported => 'Dados de recuperação combinados.';
}

// Path: sourceSetup
class Translations$sourceSetup$pt extends Translations$sourceSetup$en {
	Translations$sourceSetup$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get savedCertificate => 'Certificado do servidor salvo';
	@override String get nfsEndpointInvalid => 'Digite uma URL NFS, como nfs://nas:2049/export.';
	@override String get dlnaNone => 'Nenhum servidor DLNA encontrado. Digite manualmente a URL de descrição do dispositivo.';
	@override String get dlnaServers => 'Servidores de mídia DLNA';
	@override String get dlnaUnavailable => 'A descoberta DLNA não está disponível nesta rede. Digite manualmente a URL de descrição do dispositivo.';
	@override String get dlnaSearching => 'Procurando servidores DLNA na rede local';
	@override String get networkSearching => 'Pesquisando na rede local…';
	@override String get dlnaDiscover => 'Descobrir servidores DLNA';
	@override String get dlnaHelp => 'A descoberta depende de multicast na rede local. Se nenhum servidor aparecer, digite acima a URL de descrição do dispositivo dele.';
	@override String get dlnaRoot => 'ID do objeto DLNA; deixe em branco para usar a raiz do dispositivo.';
	@override String get passwordOrKey => 'Digite uma senha ou adicione uma chave privada abaixo.';
	@override String get sshFingerprint => 'Impressão digital SHA256 da chave de host SSH';
	@override String get sshFingerprintHelp => 'Verifique com o administrador do servidor. No servidor, execute ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub e use o valor SHA256.';
	@override String get sshFingerprintKeep => 'Deixe em branco para manter a impressão digital fixada atual ou digite uma nova impressão digital do servidor.';
	@override String get sshAuthentication => 'Autenticação SSH por chave pública';
	@override String get sshAuthenticationHelp => 'Opcional; a autenticação por senha também é aceita.';
	@override String get privateKey => 'Chave privada (formato PEM ou OpenSSH)';
	@override String get privateKeyPassphrase => 'Frase secreta da chave privada';
	@override String get nfsMountPort => 'Porta TCP do serviço de montagem NFS';
	@override String get nfsMountPortHelp => 'Padrão: 20048';
	@override String get nfsUserId => 'ID de usuário NFS (AUTH_SYS)';
	@override String get nfsUserIdHelp => 'Padrão: 1000. Use o ID permitido pelo compartilhamento NFS do NAS.';
	@override String get nfsGroupId => 'ID de grupo NFS (AUTH_SYS)';
	@override String get nfsGroupIdHelp => 'Padrão: 1000. Use o ID de grupo permitido pelo compartilhamento NFS do NAS.';
	@override String get nfsEncryption => 'Exigir NFS criptografado (RPC-with-TLS)';
	@override String get nfsEncryptionHelp => 'Exigir TLS 1.3 para NFS e o serviço de montagem. Se o NAS não oferecer suporte, a conexão será recusada.';
	@override String get nfsTrustCertificate => 'CA NFS personalizada ou certificado do servidor (PEM, opcional)';
	@override String get nfsTrustHelp => 'Deixe em branco para usar certificados confiáveis para este dispositivo. Se necessário, adicione um certificado de uma CA privada ou um certificado de servidor autoassinado; os nomes devem corresponder ao host da URL NFS.';
	@override String get nfsTrustInvalid => 'Use um certificado de CA ou de servidor no formato PEM. Não inclua uma chave privada.';
	@override String get addTrustCertificate => 'Adicionar certificado de confiança personalizado';
	@override String get replaceTrustCertificate => 'Substituir o certificado personalizado salvo';
	@override String get nfsTlsHelp => 'RPC-with-TLS usa as portas habituais de NFS e do serviço de montagem e exige que o NAS ofereça suporte a RFC 9289. TLS 1.3 é obrigatório. O nome do host ou o IP deve corresponder ao certificado. Os UID/GID de AUTH_SYS continuam valendo no canal criptografado.';
	@override String get clientCertificate => 'Certificado do cliente (opcional)';
	@override String get clientCertificateHelp => 'Permite que o NAS autentique este cliente; os IDs de AUTH_SYS continuam sujeitos à política do compartilhamento NFS do NAS.';
	@override String get savedIdentity => 'Será usada uma identidade de cliente salva.';
	@override String get replaceIdentity => 'Substituir a identidade de cliente salva';
	@override String get chooseIdentity => 'Escolher identidade de cliente PKCS#12';
	@override String get identityPassphrase => 'Frase secreta da identidade de cliente';
	@override String get identityPassphraseHelp => 'Deixe em branco se o arquivo não tiver uma frase secreta.';
	@override String get removeIdentity => 'Remover qualquer identidade de cliente salva';
	@override String get identityStorageHelp => 'As identidades de cliente são salvas no armazenamento criptografado de credenciais da fonte. Mantenha esta seção inalterada para conservar a identidade salva.';
	@override String get nfsLimitations => 'NFSv3 somente leitura sobre TCP. Sem RPC-with-TLS, o tráfego NFS não é criptografado. O NAS deve permitir os IDs de AUTH_SYS selecionados e portas de cliente não privilegiadas (geralmente pela opção de exportação “insecure”). NFSv4 e UDP não são compatíveis.';
	@override String get nfsSetupHelp => 'Ajuda para configurar NFS';
	@override String get nfsSetupHint => 'Confira estas configurações se a conexão não for estabelecida.';
	@override String get nfsSetupDetails => 'Use um compartilhamento NFSv3 sobre TCP. Quando a criptografia for obrigatória, os serviços NFS e de montagem devem oferecer suporte a RPC-with-TLS. Deixe o certificado personalizado em branco para usar um certificado de servidor confiável para este dispositivo, ou adicione o certificado de CA ou autoassinado do NAS. O nome no certificado deve corresponder ao host do endpoint. Se o NAS exigir TLS mútuo, adicione sua identidade de cliente PKCS#12. Por fim, confirme que o compartilhamento permite os UID/GID de AUTH_SYS configurados e a política de portas do cliente.';
	@override String get ftpHelp => 'FTP usa modo passivo. Use ftp:// para FTP sem criptografia, ftpes:// para TLS explícito ou ftps:// para TLS (implícito na porta 990; explícito nas outras portas).';
	@override String get openSubtitles => 'OpenSubtitles';
	@override String get subtitleSetup => 'Busca opcional de legendas para vídeos independentes.';
	@override String get apiKey => 'Chave API';
	@override String get optionalUsername => 'Nome de usuário da conta (opcional)';
	@override String get optionalPassword => 'Senha da conta (opcional)';
	@override String get subtitlePrivacy => 'Obtenha uma chave API em opensubtitles.com. A busca envia o título do vídeo e os IDs de IMDb/TMDB disponíveis, nunca o arquivo de vídeo. A chave e as credenciais opcionais da conta são criptografadas junto com esta fonte.';
	@override String get automaticMetadata => 'Metadados de vídeo online automáticos';
	@override String get metadataPrivacy => 'Envia apenas título/ano do nome do arquivo e números dos episódios, ou um ID NFO; nunca envia mídia ou credenciais. Os campos NFO mantêm a prioridade.';
	@override String get nfsEncryptionFailure => 'Para NFS criptografado, verifique o suporte a RFC 9289 e TLS 1.3 nos dois serviços do NAS, o nome no certificado e os UID/GID do compartilhamento. PlezyNG não tentará esta conexão novamente sem criptografia.';
	@override String get sourceConnecting => 'Conectando à fonte';
	@override String get metadataSearchPrivacy => 'Esta busca de títulos é enviada ao Trakt. Ela envia o título digitado, não o vídeo nem as credenciais da fonte.';
	@override String get chooseMatch => 'Escolher uma correspondência';
	@override String get metadataMatchHelp => 'Confira o título e o ano antes de escolher. O Trakt recebe o título pesquisado; o vídeo permanece na fonte.';
	@override String get metadataNoMatches => 'Nenhum título correspondente encontrado online. Tente outro título.';
	@override String get metadataSearch => 'Buscar metadados online';
	@override String get metadataLoading => 'Buscando detalhes de filmes e séries online…';
	@override String get metadataFromTrakt => 'Metadados online do Trakt';
	@override String get metadataNoAutomaticMatch => 'Nenhuma correspondência automática encontrada para o título. Pesquise o título para escolher uma correspondência.';
	@override String get metadataFailed => 'Não foi possível carregar os metadados online. A reprodução e os detalhes locais continuam disponíveis.';
	@override String get videoDetailsLoading => 'Carregando detalhes do vídeo';
	@override String get subtitleKeyRequired => 'É necessária uma chave API do OpenSubtitles';
	@override String get subtitleKeyHelp => 'Edite esta fonte de arquivos e adicione uma chave API do OpenSubtitles nas configurações opcionais de legendas.';
	@override String get subtitleSearchFailed => 'A busca de legendas falhou. Confira a chave API, a conexão e o acesso ao serviço.';
	@override String get subtitleApplyFailed => 'Não foi possível baixar ou aplicar esta legenda. Confira a conexão e tente outro resultado.';
	@override String get subtitleSearch => 'Buscar no OpenSubtitles';
	@override String get subtitleSearchPrivacy => 'A busca usa o título e os IDs de IMDb/TMDB disponíveis. O arquivo de vídeo permanece na fonte. Antes de escolher, confira o idioma, as indicações de legendas forçadas ou para pessoas com deficiência auditiva e a avaliação.';
	@override String get movieOrShow => 'Filme ou série';
	@override String get subtitleTitleHint => 'Digite um título para refinar os resultados';
	@override String get subtitleLanguage => 'Idioma das legendas';
	@override String get subtitleSearching => 'Buscando no OpenSubtitles';
	@override String get subtitleNoMatches => 'Nenhuma legenda correspondente encontrada. Tente outro título ou idioma.';
	@override String get downloadSubtitle => 'Baixar legenda';
	@override String get subtitle => 'Legenda';
	@override String get nfsTlsRequired => 'RPC-with-TLS obrigatório';
	@override String get nfsUnencrypted => 'NFS sem criptografia';
	@override String get tlsEncrypted => 'Criptografado com TLS';
	@override String get ftpPlain => 'FTP sem criptografia';
	@override String get sshPinned => 'SSH criptografado · chave de host fixada';
	@override String get smbEncrypted => 'Criptografia SMB3 ativada';
	@override String get smbUnencrypted => 'Criptografia SMB3 desativada';
	@override String get httpUnencrypted => 'HTTP sem criptografia de transporte';
	@override String get checkEndpointSecurity => 'Verificar a segurança do endpoint';
	@override String fieldRequired({required Object label}) => 'Campo obrigatório: ${label}.';
	@override String integerRange({required Object label, required Object min, required Object max}) => 'Digite ${label} de ${min} a ${max}.';
	@override String replaceFile({required Object name}) => 'Substituir ${name}';
	@override String selectedIdentity({required Object name}) => 'Identidade de cliente selecionada: ${name}';
	@override String subtitleRating({required Object rating}) => 'Avaliação ${rating}';
	@override String subtitleDownloading({required Object title}) => 'Baixando legenda: ${title}';
	@override String get sharedEntryPair => 'Pair este item';
	@override String get sharedEntryPairHelp => 'Digite o mesmo ID para este item em cada dispositivo. Use um identificador compartilhado estável ou gerar um e copiá-lo para o item correspondente. Progress pares apenas quando os tipos de arquivo da edição, tamanhos e ordens correspondem. Blank remove esse mapeamento.';
	@override String get sharedEntryId => 'ID do item compartilhado';
	@override String get generateSharedEntryId => 'Identificar o item compartilhado';
	@override String get sharedLibraryId => 'ID de biblioteca compartilhada (opcional)';
	@override String get sharedLibraryHelp => 'Use o mesmo ID em dispositivos que abrem a mesma biblioteca.Este ID público ajuda a acompanhar os progressos de leitura e notas através de diferentes conexões fonte; não é uma senha.Quando os provedores usam diferentes IDs de item, pares esses itens das suas pantallas detalhadas.';
	@override String get sharedLibraryInvalid => 'Use 8 a 100 letras, números, pontos, subscores ou hyphens.';
	@override String get generateSharedLibraryId => 'Crie um ID de biblioteca compartilhado';
	@override String get nfsReadAhead => 'Requisitos de read-ahead da NFS';
	@override String get nfsReadAheadHelp => 'Mais leituras paralelas podem melhorar a passagem em uma NAS rápida ou rede. Use 1 se o servidor limitar pedidos concorrentes.';
	@override String get nfsReadTest => 'Medir o desempenho da leitura NFS';
	@override String get nfsReadTestHelp => 'Leia até 64 MiB do maior arquivo para medir esta conexão NAS. Isso usa a largura de banda da rede.';
	@override String get nfsQualificationResult => 'NFS Leia a medição';
	@override String get nfsReadBytes => 'Dados de leitura';
	@override String get nfsReadSpeed => 'Velocidade Medida';
	@override String get nfsReadRequests => 'Leia pedidos';
	@override String get sharedEntryConflict => 'Este ID de item compartilhado já está em parceria com outro item nesta biblioteca.';
}

// Path: comics
class Translations$comics$pt extends Translations$comics$en {
	Translations$comics$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get fitHeight => 'Ajustar à altura';
	@override String get readingMode => 'Modo de leitura';
	@override String get paged => 'Páginas';
	@override String get webtoon => 'Deslocamento contínuo';
	@override String get coverAlone => 'Mostrar a capa sozinha';
	@override String get splitWide => 'Dividir páginas largas';
	@override String get splitWideHelp => 'Mostra cada metade separadamente, na ordem de leitura. A apresentação de duas páginas lado a lado fica suspensa enquanto esta opção estiver ativa.';
	@override String get thumbnails => 'Miniaturas das páginas';
	@override String get controlsHelp => 'Deslize para mudar de página. Toque duas vezes para alterar o ajuste. No deslocamento contínuo, deslize na vertical ou use Page Up e Page Down.';
	@override String get savedForComic => 'As definições de apresentação são guardadas para esta banda desenhada neste perfil.';
	@override String get readLists => 'Listas de leitura';
	@override String get collections => 'Coleções';
}

// Path: games
class Translations$games$pt extends Translations$games$en {
	Translations$games$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

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
class Translations$deepLinks$pt extends Translations$deepLinks$en {
	Translations$deepLinks$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get invalid => 'Este link Plezy não é válido.';
	@override String profileNotFound({required Object profile}) => 'Nenhum perfil corresponde a "${profile}".';
	@override String get serverUnavailable => 'Não podia chegar ao servidor para este link.';
	@override String get notFound => 'Não podia encontrar esse título em suas bibliotecas.';
	@override String get unsupportedItem => 'Este link não pode ser jogado.';
	@override String get noLiveTv => 'Nenhum servidor de TV ao vivo está disponível para este link.';
	@override String channelNotFound({required Object channel}) => 'Não podia encontrar o canal "${channel}".';
	@override String get showLink => 'Mostrar link';
	@override String get showProfileLink => 'Mostrar perfil link';
	@override String get dialogTitle => 'Link';
	@override String get showHint => 'Abra este link joga o próximo episódio. Adicione &mode=shuffle para jogar o show no shuffle.';
	@override String get movieHint => 'Ao abrir este link, o filme é jogado.';
	@override String get episodeHint => 'A abertura deste link joga este episódio.';
	@override String get profileHint => 'Abre este link switch para esse perfil.';
	@override String openAsProfile({required Object name}) => 'Abra como ${name}';
	@override String get copy => 'Copia';
	@override String get copied => 'Link copiado';
}

// Path: appIcon.names
class Translations$appIcon$names$pt extends Translations$appIcon$names$en {
	Translations$appIcon$names$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

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
	@override String get sticker => 'Adesivo';
	@override String get ticket => 'Ingresso';
	@override String get pop => 'Pop';
	@override String get strata => 'Estratos';
	@override String get facet => 'Faceta';
	@override String get tilde => 'Til';
}

// Path: common.ratingSource
class Translations$common$ratingSource$pt extends Translations$common$ratingSource$en {
	Translations$common$ratingSource$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

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
class Translations$common$mediaKind$pt extends Translations$common$mediaKind$en {
	Translations$common$mediaKind$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

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
	@override String get clip => 'Clipe';
	@override String get photo => 'Foto';
	@override String get folder => 'Pasta';
}

// Path: settings.startupSectionOptions
class Translations$settings$startupSectionOptions$pt extends Translations$settings$startupSectionOptions$en {
	Translations$settings$startupSectionOptions$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get discover => 'Abre recomendações e itens de fontes de descoberta conectadas.';
	@override String get libraries => 'Abra suas bibliotecas de mídia conectadas.';
	@override String get liveTv => 'Abra a TV ao vivo quando um servidor o fornece; caso contrário, a startup cai de volta para o Home.';
	@override String get search => 'Pesquisa de mídia aberta.';
}

// Path: themeEditor.slots
class Translations$themeEditor$slots$pt extends Translations$themeEditor$slots$en {
	Translations$themeEditor$slots$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get bg => 'Fundo';
	@override String get surface => 'Superfície';
	@override String get outline => 'Contorno';
	@override String get text => 'Texto';
	@override String get textMuted => 'Texto secundário';
	@override String get accent => 'Destaque';
}

// Path: themeEditor.contrast
class Translations$themeEditor$contrast$pt extends Translations$themeEditor$contrast$en {
	Translations$themeEditor$contrast$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

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
class Translations$hotkeys$actions$pt extends Translations$hotkeys$actions$en {
	Translations$hotkeys$actions$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'Reproduzir/Pausar';
	@override String get volumeUp => 'Aumentar Volume';
	@override String get volumeDown => 'Diminuir Volume';
	@override String seekForward({required Object seconds}) => 'Avançar (${seconds}s)';
	@override String seekBackward({required Object seconds}) => 'Retroceder (${seconds}s)';
	@override String get fullscreenToggle => 'Alternar Tela Cheia';
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
	@override String get speedReset => 'Redefinir Velocidade';
	@override String get zoomIn => 'Aumentar zoom';
	@override String get zoomOut => 'Diminuir zoom';
	@override String get zoomReset => 'Redefinir zoom';
	@override String get subSeekNext => 'Ir para Próxima Legenda';
	@override String get subSeekPrev => 'Ir para Legenda Anterior';
	@override String get subtitleDelayIncrease => 'Atrasar Legendas';
	@override String get subtitleDelayDecrease => 'Adiantar Legendas';
	@override String get shaderToggle => 'Alternar Shaders';
	@override String get skipMarker => 'Pular introdução/créditos';
	@override String get screenshot => 'Capturar tela';
	@override String get framePrevious => 'Anterior Frame';
	@override String get frameNext => 'Próximo Frame';
}

// Path: videoControls.pipErrors
class Translations$videoControls$pipErrors$pt extends Translations$videoControls$pipErrors$en {
	Translations$videoControls$pipErrors$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Requer Android 8.0 ou superior';
	@override String get iosVersion => 'Requer iOS 15.0 ou superior';
	@override String get permissionDisabled => 'Picture-in-picture está desativado. Ative nas configurações do sistema.';
	@override String get notSupported => 'O dispositivo não suporta modo picture-in-picture';
	@override String get voSwitchFailed => 'Falha ao trocar saída de vídeo para picture-in-picture';
	@override String get failed => 'Falha ao iniciar picture-in-picture';
	@override String get prepareFailed => 'Não foi possível preparar o picture-in-picture';
	@override String unknown({required Object error}) => 'Ocorreu um erro: ${error}';
}

// Path: subtitlingStyling.assOverrideOptions
class Translations$subtitlingStyling$assOverrideOptions$pt extends Translations$subtitlingStyling$assOverrideOptions$en {
	Translations$subtitlingStyling$assOverrideOptions$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get no => 'Mantenha as letras, cores, tamanhos e colocações escritas no arquivo subtítulo.';
	@override String get yes => 'Permitir que as configurações de estilo do subtitulo do jogador ajustem os subtitulos ASS.';
	@override String get scale => 'Aplique o estilo do jogador e a escala de tamanhos incorporados para corresponder às dimensões do vídeo.';
	@override String get force => 'Substituir os estilos ASS incorporados com o estilo subtítulo do jogador.';
	@override String get strip => 'Remova o formato ASS incorporado e faça o texto sub-título claramente.';
}

// Path: subtitlingStyling.renderResolutionOptions
class Translations$subtitlingStyling$renderResolutionOptions$pt extends Translations$subtitlingStyling$renderResolutionOptions$en {
	Translations$subtitlingStyling$renderResolutionOptions$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get screen => 'Render na resolução de superfície da tela completa para o resultado mais agudo.';
	@override String get video => 'Render usando a resolução de vídeo como referência, o que pode reduzir o trabalho em telas de alta resolução.';
	@override String get threeQuarter => 'Render em 75% da resolução de superfície do ecrã para uma poupança modesta de desempenho.';
	@override String get half => 'Render a 50% da resolução de superfície do ecrã para reduzir o trabalho, com bordas mais suaves.';
	@override String get third => 'Render em um terço da resolução de superfície do ecrã para reduzir o trabalho, com bordas mais suaves.';
	@override String get quarter => 'Render a um quarto da resolução de superfície do ecrã para reduzir o trabalho, com o resultado mais suave.';
}

// Path: accountPreferences.groups
class Translations$accountPreferences$groups$pt extends Translations$accountPreferences$groups$en {
	Translations$accountPreferences$groups$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get audioAndSubtitles => 'Áudio e legendas';
	@override String get libraryDisplay => 'Biblioteca';
	@override String get personalMedia => 'Mídia pessoal';
}

// Path: accountPreferences.subtitleModes
class Translations$accountPreferences$subtitleModes$pt extends Translations$accountPreferences$subtitleModes$en {
	Translations$accountPreferences$subtitleModes$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get none => 'Seleção manual';
	@override String get noneDescription => 'Nunca ativar legendas por conta própria.';
	@override String get defaultMode => 'Seguir as marcações da faixa';
	@override String get defaultModeDescription => 'Usar as marcações padrão e forçada armazenadas em cada faixa de legenda.';
	@override String get always => 'Sempre ativado';
	@override String get alwaysDescription => 'Ativar uma faixa de legenda no idioma preferido sempre que houver uma.';
	@override String get onlyForced => 'Apenas legendas forçadas';
	@override String get onlyForcedDescription => 'Carregar apenas as faixas marcadas como forçadas.';
	@override String get smart => 'Exibir com áudio estrangeiro';
	@override String get smartDescription => 'Ativar legendas apenas quando o áudio estiver em outro idioma.';
}

// Path: accountPreferences.subtitleAccessibilityOptions
class Translations$accountPreferences$subtitleAccessibilityOptions$pt extends Translations$accountPreferences$subtitleAccessibilityOptions$en {
	Translations$accountPreferences$subtitleAccessibilityOptions$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get preferNonSdh => 'Preferir legendas não SDH';
	@override String get preferSdh => 'Preferir legendas SDH';
	@override String get onlySdh => 'Apenas legendas SDH';
	@override String get onlyNonSdh => 'Apenas legendas não SDH';
	@override String get preferNonSdhDescription => 'Preferir subtitulos padrão quando as versões padrão e SDH estão disponíveis.';
	@override String get preferSdhDescription => 'Prefira subtitulos SDH quando disponíveis, mas permite subtitulares padrão como um retrocesso.';
	@override String get onlySdhDescription => 'Use apenas subtítulos SDH; não caia de volta aos subtitulos padrão.';
	@override String get onlyNonSdhDescription => 'Use apenas subtítulos padrão; exclui subtítos SDH.';
}

// Path: accountPreferences.forcedSubtitleOptions
class Translations$accountPreferences$forcedSubtitleOptions$pt extends Translations$accountPreferences$forcedSubtitleOptions$en {
	Translations$accountPreferences$forcedSubtitleOptions$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get preferNonForced => 'Preferir legendas não forçadas';
	@override String get preferForced => 'Preferir legendas forçadas';
	@override String get onlyForced => 'Apenas legendas forçadas';
	@override String get onlyNonForced => 'Apenas legendas não forçadas';
	@override String get preferNonForcedDescription => 'Prefere subtitulos regulares, mas permite pistas forçadas como uma queda.';
	@override String get preferForcedDescription => 'Prefere pistas forçadas quando disponíveis, mas permite subtitulos regulares como uma queda.';
	@override String get onlyForcedDescription => 'Utilize apenas traços marcados como forçados.';
	@override String get onlyNonForcedDescription => 'Exclude os traços marcados como forçados.';
}

// Path: accountPreferences.watchedIndicatorOptions
class Translations$accountPreferences$watchedIndicatorOptions$pt extends Translations$accountPreferences$watchedIndicatorOptions$en {
	Translations$accountPreferences$watchedIndicatorOptions$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get none => 'Nunca';
	@override String get moviesAndShows => 'Filmes e séries de TV';
	@override String get movies => 'Apenas filmes';
	@override String get shows => 'Apenas séries de TV';
	@override String get noneDescription => 'Não mostre sinais de verificação observados.';
	@override String get moviesAndShowsDescription => 'Mostrar marcadores assistidos para filmes e programas de TV.';
	@override String get moviesDescription => 'Mostrar marcadores assistidos apenas para filmes.';
	@override String get showsDescription => 'Mostrar checkmarks assistidos apenas para programas de TV.';
}

// Path: accountPreferences.mediaReviewsOptions
class Translations$accountPreferences$mediaReviewsOptions$pt extends Translations$accountPreferences$mediaReviewsOptions$en {
	Translations$accountPreferences$mediaReviewsOptions$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get usersAndCritics => 'Usuários e críticos';
	@override String get usersOnly => 'Apenas usuários';
	@override String get criticsOnly => 'Apenas críticos';
	@override String get nobody => 'Oculto';
	@override String get usersAndCriticsDescription => 'Mostre as avaliações dos usuários e as classificações críticas.';
	@override String get usersOnlyDescription => 'Mostrar classificações e avaliações apresentadas pelos usuários.';
	@override String get criticsOnlyDescription => 'Mostrar avaliações críticas e comentários.';
	@override String get nobodyDescription => 'Esconde classificações e avaliações.';
}

// Path: discover.findNext
class Translations$discover$findNext$pt extends Translations$discover$findNext$en {
	Translations$discover$findNext$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Descubra seu próximo favorito';
	@override String get open => 'Descubra seu próximo favorito';
	@override String get anyTime => 'Sem limite de tempo';
	@override String get timeAvailable => 'Quanto tempo você tem?';
	@override String get filters => 'Escolha para este momento';
	@override String get watch => 'Assistir';
	@override String get listen => 'Ouvir';
	@override String get read => 'Ler';
	@override String finishable({required Object duration}) => 'Dá para terminar em ${duration}';
	@override String aboutDuration({required Object duration}) => 'Cerca de ${duration}';
	@override String nextUnit({required Object duration}) => 'Próximo capítulo · ${duration}';
	@override String totalDuration({required Object duration}) => '${duration} no total';
	@override String get timingVaries => 'A duração pode variar';
	@override String get notNow => 'Agora não';
	@override String get swipeHint => 'Deslize a capa na direção de uma seta ou use os botões abaixo.';
	@override String get saved => 'Sugestões salvas';
	@override String savedCount({required Object count}) => 'Sugestões salvas · ${count}';
	@override String get undo => 'Desfazer';
	@override String get details => 'Detalhes';
	@override String get noPicks => 'Ainda não há opções';
	@override String get noPicksHint => 'Conecte uma biblioteca ou adicione uma fonte de mídia para começar.';
	@override String get noMatches => 'Nada combina com este momento';
	@override String get noMatchesHint => 'Experimente outro tipo de conteúdo ou reserve mais tempo.';
	@override String get allDone => 'Você já viu todas as sugestões';
	@override String get allDoneHint => 'Comece uma nova seleção para ver essas opções novamente.';
	@override String get refresh => 'Buscar outra seleção';
	@override String sourceReason({required Object source}) => 'De ${source}';
	@override String libraryReason({required Object library}) => 'De ${library}';
	@override String get ownedReason => 'Da sua biblioteca';
	@override String get liveNow => 'No ar agora';
	@override String get watchLive => 'Assistir ao vivo';
	@override String get filterAnything => 'Qualquer tipo';
	@override String get filterWatch => 'Assistir';
	@override String get filterListen => 'Ouvir';
	@override String get filterRead => 'Ler';
	@override String get twentyMinutes => '20 min';
	@override String get fortyFiveMinutes => '45 min';
	@override String get ninetyMinutes => '90 min';
	@override String get apply => 'Aplicar';
	@override String get openFailed => 'Esta opção não está mais disponível. Atualize para verificar novamente.';
	@override String get changeFailed => 'Não foi possível salvar a alteração. Tente novamente.';
	@override String get savedLimit => 'A lista de sugestões salvas está cheia. Remova uma sugestão para salvar outra.';
	@override String get chooseHint => 'Abra um título, guarde-o para mais tarde ou passe ao seguinte.';
	@override String get howItWorks => 'Como funciona';
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

// Path: discover.person
class Translations$discover$person$pt extends Translations$discover$person$en {
	Translations$discover$person$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get born => 'Nascimento';
	@override String get died => 'Falecimento';
	@override String get birthplace => 'Local de nascimento';
	@override String dateWithAge({required Object date, required Object age}) => '${date} (${age} anos)';
	@override String dateWithAgeAtDeath({required Object date, required Object age}) => '${date} (aos ${age} anos)';
}

// Path: libraries.tabs
class Translations$libraries$tabs$pt extends Translations$libraries$tabs$en {
	Translations$libraries$tabs$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Recomendados';
	@override String get browse => 'Navegar';
	@override String get collections => 'Coleções';
	@override String get playlists => 'Playlists';
}

// Path: libraries.groupings
class Translations$libraries$groupings$pt extends Translations$libraries$groupings$en {
	Translations$libraries$groupings$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

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
class Translations$libraries$filterCategories$pt extends Translations$libraries$filterCategories$en {
	Translations$libraries$filterCategories$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get genre => 'Gênero';
	@override String get year => 'Ano';
	@override String get contentRating => 'Classificação indicativa';
	@override String get tag => 'Tag';
	@override String get unwatched => 'Não assistidos';
	@override String get unplayed => 'Não reproduzidos';
	@override String get favorites => 'Favoritos';
	@override String get filePath => 'Caminho do arquivo';
}

// Path: libraries.sortLabels
class Translations$libraries$sortLabels$pt extends Translations$libraries$sortLabels$en {
	Translations$libraries$sortLabels$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Título';
	@override String get dateAdded => 'Data de adição';
	@override String get releaseDate => 'Data de lançamento';
	@override String get rating => 'Avaliação';
	@override String get communityRating => 'Avaliação da comunidade';
	@override String get criticRating => 'Avaliação da crítica';
	@override String get userRating => 'Avaliação do usuário';
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
	@override String get dateShared => 'Data de compartilhamento';
	@override String get latestEpisodeAirDate => 'Última data de exibição do episódio';
	@override String get lastEpisodeDateAdded => 'Data de adição do último episódio';
	@override String get dateDownloaded => 'Data de download';
	@override String get size => 'Tamanho';
	@override String get library => 'Biblioteca';
}

// Path: libraries.advancedFilters
class Translations$libraries$advancedFilters$pt extends Translations$libraries$advancedFilters$en {
	Translations$libraries$advancedFilters$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get include => 'Incluir';
	@override String get exclude => 'Excluir';
	@override String get any => 'Qualquer';
	@override String get yes => 'Sim';
	@override String get no => 'Não';
	@override String not({required Object value}) => 'Exceto ${value}';
	@override String valueCount({required Object count}) => '${count} selecionados';
	@override String valueCountExcluded({required Object count}) => '${count} excluídos';
	@override String get searchValues => 'Buscar valores';
	@override String get noValues => 'Nenhum valor';
	@override String get matchContains => 'Contém';
	@override String get matchNotContains => 'Não contém';
	@override String get matchIs => 'É';
	@override String get matchIsNot => 'Não é';
	@override String get matchBeginsWith => 'Começa com';
	@override String get matchEndsWith => 'Termina com';
	@override String get textHint => 'Digite para filtrar';
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

// Path: libraries.selection
class Translations$libraries$selection$pt extends Translations$libraries$selection$en {
	Translations$libraries$selection$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get selectItems => 'Selecione Itens';
	@override String selectedCount({required Object count}) => '${count} selecionados';
	@override String get actions => 'Ações de Selecção';
	@override String get confirmDescendants => 'Isso muda todos os episódios nos shows e estações selecionados.';
	@override String get confirmUnwatched => 'Isso também apaga o progresso de reprodução dos itens selecionados.';
	@override String confirmCount({required Object count}) => 'Produtos selecionados: ${count}.';
	@override String completed({required Object count}) => 'Artigos atualizados: ${count}.';
	@override String partialFailure({required Object succeeded, required Object failed}) => 'Atualização ${succeeded}; falha ${failed}. item falha permanece selecionado.';
}

// Path: explore.mdblistShelves
class Translations$explore$mdblistShelves$pt extends Translations$explore$mdblistShelves$en {
	Translations$explore$mdblistShelves$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get manage => 'Gerenciamento Explore as placas';
	@override String get manageDescription => 'Escolha e arregle listas da sua conta MDBList';
	@override String get description => 'Escolha listas de filmes e TV públicos da sua conta MDBList. crie ou copie listas em MDBList, e depois refresque.';
	@override String get selected => 'Cadeiras selecionadas';
	@override String get available => 'Lista de contas disponíveis';
	@override String get noLists => 'Não há filmes públicos ou listas de TV devolvidas. crie ou copie uma lista no MDBList, e depois refresque.';
	@override String get displayName => 'Nome de exibição Shelf';
	@override String get nameHint => 'Deixe o nome branco para usar o nome da lista de fontes.';
	@override String get add => 'Adicionar Shelf';
	@override String get save => 'Salva as cadeiras';
	@override String moveUp({required Object title}) => 'Move ${title} para cima';
	@override String moveDown({required Object title}) => 'Move ${title} para baixo';
	@override String get unavailable => 'Esta lista não está disponível. retire ou remova a sua armadilha em configurações.';
	@override String get rateLimited => 'MDBList limite de solicitação alcançado. por favor retire mais tarde.';
	@override String get loadFailed => 'Não pode carregar as placas. verificar a sua conexão e retiro.';
	@override String get saveFailed => 'Não posso salvar as cadeiras, por favor, retire.';
	@override String get accountChanged => 'A conta ou perfil mudou. reabre essas configurações.';
	@override String get settingsUnreadable => 'As folhas salvas não podem ser lidas. selecione suas listas novamente para substituir essas configurações.';
}

// Path: explore.rows
class Translations$explore$rows$pt extends Translations$explore$rows$en {
	Translations$explore$rows$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'Lista para assistir';
	@override String get recommendedMovies => 'Filmes recomendados';
	@override String get recommendedShows => 'Séries recomendadas';
	@override String get trendingMovies => 'Filmes em alta';
	@override String get trendingShows => 'Séries em alta';
	@override String get popularMovies => 'Filmes populares';
	@override String get popularShows => 'Séries populares';
	@override String get trendingAnime => 'Anime em alta';
	@override String get suggestedAnime => 'Anime sugerido';
	@override String get airingAnime => 'Melhores animes em exibição';
	@override String get popularAnime => 'Anime mais popular';
	@override String get trending => 'Em alta';
	@override String get upcomingMovies => 'Próximos filmes';
	@override String get upcomingShows => 'Próximas séries';
}

// Path: explore.status
class Translations$explore$status$pt extends Translations$explore$status$en {
	Translations$explore$status$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get airing => 'Em exibição';
	@override String get ended => 'Finalizada';
	@override String get canceled => 'Cancelada';
	@override String get upcoming => 'Em breve';
}

// Path: explore.badge
class Translations$explore$badge$pt extends Translations$explore$badge$en {
	Translations$explore$badge$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String rankPopular({required Object n}) => '#${n} popular';
	@override String rankAiring({required Object n}) => '#${n} no ar';
	@override String rankRated({required Object n}) => '#${n} avaliado';
	@override String rankTrending({required Object n}) => '#${n} em alta';
	@override String rankSeasonal({required Object n, required Object season}) => '#${n} em ${season}';
	@override String watchingNow({required Object n}) => '${n} assistindo';
	@override String get available => 'Disponível';
	@override String get partiallyAvailable => 'Parcialmente disponível';
	@override String get availableIn4k => '4K disponível';
	@override String get requested => 'Solicitado';
	@override String get pendingApproval => 'Aguardando aprovação';
	@override String get processing => 'Processando';
	@override String get declined => 'Recusado';
	@override String get requestFailed => 'Falha na solicitação';
	@override String get requested4k => '4K solicitado';
	@override String seasonsAvailable({required Object available, required Object total}) => '${available}/${total} temporadas';
	@override String nextEpisodeIn({required Object episode, required Object duration}) => 'Ep ${episode} em ${duration}';
	@override String nextAiringIn({required Object duration}) => 'Próximo em ${duration}';
	@override String episodesShort({required Object n}) => '${n} epps';
	@override String minutesPerEpisode({required Object n}) => '${n} min/ep';
	@override String get adult => '18+';
}

// Path: explore.stats
class Translations$explore$stats$pt extends Translations$explore$stats$en {
	Translations$explore$stats$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String listed({required Object n}) => '${n} listados';
	@override String viewersDay({required Object n}) => '${n} assistiram hoje';
	@override String viewersWeek({required Object n}) => '${n} assistiram esta semana';
	@override String viewersMonth({required Object n}) => '${n} assistiram este mês';
	@override String viewersYear({required Object n}) => '${n} assistiram este ano';
	@override String viewersAllTime({required Object n}) => '${n} espectadores';
	@override String planning({required Object n}) => '${n} pretendem assistir';
	@override String favorited({required Object n}) => '${n} favoritos';
	@override String dropRate({required Object percent}) => '${percent} abandonaram';
	@override String comments({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} comentário',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} comentários',
	);
	@override String votes({required Object n}) => '${n} votos';
	@override String watching({required Object n}) => '${n} assistindo';
	@override String completed({required Object n}) => '${n} concluíram';
	@override String onHold({required Object n}) => '${n} em pausa';
	@override String dropped({required Object n}) => '${n} abandonaram';
}

// Path: explore.season
class Translations$explore$season$pt extends Translations$explore$season$en {
	Translations$explore$season$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get winter => 'Inverno';
	@override String get spring => 'Primavera';
	@override String get summer => 'Verão';
	@override String get fall => 'Outono';
	@override String withYear({required Object season, required Object year}) => '${season} ${year}';
}

// Path: explore.format
class Translations$explore$format$pt extends Translations$explore$format$en {
	Translations$explore$format$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

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
class Translations$explore$sourceMaterial$pt extends Translations$explore$sourceMaterial$en {
	Translations$explore$sourceMaterial$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get original => 'Original';
	@override String get manga => 'Mangá';
	@override String get lightNovel => 'Light novel';
	@override String get novel => 'Romance';
	@override String get visualNovel => 'Visual novel';
	@override String get game => 'Jogo';
	@override String get webComic => 'Webcomic';
	@override String get musicRelease => 'Música';
	@override String get otherMedia => 'Outro';
}

// Path: explore.creditRole
class Translations$explore$creditRole$pt extends Translations$explore$creditRole$en {
	Translations$explore$creditRole$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get actor => 'Ator';
	@override String get director => 'Diretor';
	@override String get writer => 'Roteirista';
	@override String get producer => 'Produtor';
	@override String get creator => 'Criador';
	@override String get composer => 'Compositor';
}

// Path: explore.relation
class Translations$explore$relation$pt extends Translations$explore$relation$en {
	Translations$explore$relation$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

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
class Translations$explore$detail$pt extends Translations$explore$detail$en {
	Translations$explore$detail$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get originalTitle => 'Título original';
	@override String get alsoKnownAs => 'Também conhecido como';
	@override String get studios => 'Estúdios';
	@override String get country => 'País';
	@override String get language => 'Idioma';
	@override String get released => 'Lançado';
	@override String get physicalRelease => 'Em disco';
	@override String get ended => 'Encerrado';
	@override String addedOn({required Object date}) => 'Adicionado em ${date}';
	@override String get yourRating => 'Sua avaliação';
	@override String get budget => 'Orçamento';
	@override String get revenue => 'Bilheteria';
	@override String get contentAdvisory => 'Classificação indicativa';
	@override String get tags => 'Tags';
	@override String get revealSpoilerTags => 'Mostrar tags de spoiler';
	@override String get links => 'Links';
	@override String get watchOn => 'Assistir em';
	@override String get watchTrailer => 'Ver trailer';
	@override String openOn({required Object site}) => 'Abrir em ${site}';
	@override String get crew => 'Equipe';
	@override String get ratings => 'Avaliações';
	@override String get schedule => 'Programação';
	@override String recommendedByUsers({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: 'Recomendado por ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} usuário',
		other: 'Recomendado por ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} usuários',
	);
	@override String recommendedBy({required Object who}) => 'Recomendado por ${who}';
	@override String favoritedBy({required Object who}) => 'Favoritado por ${who}';
	@override String unairedEpisodes({required Object n}) => '${n} ainda não exibidos';
	@override String recommendedByPercent({required Object percent}) => 'Recomendado por ${percent} dos espectadores';
	@override String get relatedTitles => 'Títulos relacionados';
	@override String get background => 'Contexto';
}

// Path: liveTv.recordSettings
class Translations$liveTv$recordSettings$pt extends Translations$liveTv$recordSettings$en {
	Translations$liveTv$recordSettings$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

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
class Translations$music$discography$pt extends Translations$music$discography$en {
	Translations$music$discography$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get singlesAndEps => 'Singles e EPs';
	@override String get live => 'Ao vivo';
	@override String get compilations => 'Compilações';
}

// Path: watchTogether.notices
class Translations$watchTogether$notices$pt extends Translations$watchTogether$notices$en {
	Translations$watchTogether$notices$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String pressedPlay({required Object name}) => '${name} iniciou a reprodução';
	@override String get playbackStarted => 'Reprodução iniciada';
	@override String paused({required Object name}) => '${name} pausou';
	@override String get playbackPaused => 'Reprodução pausada';
	@override String jumpedTo({required Object name, required Object position}) => '${name} pulou para ${position}';
	@override String roomJumpedTo({required Object position}) => 'Pulou para ${position}';
	@override String changedSpeed({required Object name, required Object speed}) => '${name} definiu a velocidade para ${speed}';
	@override String speedChanged({required Object speed}) => 'Velocidade definida para ${speed}';
	@override String startedMedia({required Object name, required Object title}) => '${name} iniciou ${title}';
	@override String mediaStarted({required Object title}) => 'Reproduzindo agora: ${title}';
	@override String stoppedMedia({required Object name}) => '${name} parou o vídeo';
	@override String get mediaStopped => 'O vídeo parou';
	@override String waitingFor({required Object name}) => 'Aguardando ${name}...';
	@override String get waitingForSomeone => 'Aguardando alguém se sincronizar...';
	@override String get finished => 'Concluído';
	@override String hostChangedTo({required Object name}) => '${name} agora é o anfitrião';
	@override String get youAreNowHost => 'Agora você é o anfitrião';
	@override String joined({required Object name}) => '${name} entrou';
	@override String left({required Object name}) => '${name} saiu';
	@override String get controlRefused => 'Apenas o anfitrião pode controlar a reprodução';
	@override String get searchFailed => 'Não foi possível buscar o vídeo da sala em alguns servidores';
	@override String get playBlocked => 'Pressione reproduzir para começar';
	@override String get shareFailed => 'Não foi possível compartilhar este vídeo com a sala';
	@override String get downloadNotShared => 'Os downloads não são compartilhados com a sala enquanto o servidor de origem estiver offline';
	@override String get openFailed => 'Não foi possível abrir o vídeo da sala';
}

// Path: watchTogether.ended
class Translations$watchTogether$ended$pt extends Translations$watchTogether$ended$en {
	Translations$watchTogether$ended$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get ended => 'O anfitrião encerrou a sala';
	@override String get kicked => 'Você foi removido da sala';
	@override String get expired => 'A sala expirou';
	@override String get replaced => 'Você entrou nesta sala em outro dispositivo';
	@override String get lost => 'A conexão com a sala foi perdida';
}

// Path: watchTogether.errors
class Translations$watchTogether$errors$pt extends Translations$watchTogether$errors$en {
	Translations$watchTogether$errors$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get invalidCode => 'Isso não é um código de sala. Os códigos têm 6 letras e números, sem 0, 1, I, L ou O.';
	@override String get roomNotFound => 'Nenhuma sala tem esse código. Ela pode ter sido encerrada.';
	@override String get roomFull => 'Essa sala está cheia.';
	@override String get roomLocked => 'O anfitrião bloqueou essa sala.';
	@override String get relayFull => 'O Assistir Juntos está sobrecarregado no momento. Tente novamente mais tarde.';
	@override String get unreachable => 'Não foi possível acessar o servidor de retransmissão do Assistir Juntos. Verifique sua conexão.';
	@override String get rateLimited => 'Muitas tentativas. Aguarde um momento e tente novamente.';
	@override String get clientBlocked => 'Esta versão do PlezyNG não pode usar o servidor de retransmissão. Atualize o app.';
	@override String get forbidden => 'Apenas o anfitrião pode fazer isso.';
	@override String get notInRoom => 'Você não está em uma sala.';
	@override String get alreadyInRoom => 'Você já está em uma sala.';
	@override String get resumeFailed => 'Não foi possível voltar à sala.';
	@override String get unsupported => 'O servidor de retransmissão não é compatível com isso.';
	@override String get generic => 'Algo deu errado. Tente novamente.';
}

// Path: downloads.backgroundWarning
class Translations$downloads$backgroundWarning$pt extends Translations$downloads$backgroundWarning$en {
	Translations$downloads$backgroundWarning$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get bannerBlocked => 'Os downloads serão interrompidos ao sair do app';
	@override String get bannerDegraded => 'Os downloads em segundo plano podem ser limitados';
	@override String get bannerAction => 'Detalhes';
	@override String get sheetTitle => 'Os downloads em segundo plano estão bloqueados';
	@override String get sheetTitleDegraded => 'Os downloads em segundo plano podem ser limitados';
	@override String get sheetIntro => 'O Android está impedindo que o PlezyNG faça downloads de forma confiável em segundo plano.';
	@override String get sheetIntroDegraded => 'Seu dispositivo está limitando quando o PlezyNG pode fazer downloads em segundo plano.';
	@override String get reasonBackgroundRestricted => 'O uso em segundo plano do PlezyNG está restrito. Defina o uso da bateria ou o uso em segundo plano como "Sem restrições".';
	@override String get reasonStandbyRestricted => 'O Android colocou o PlezyNG em um modo de espera restrito. Defina o uso da bateria como "Sem restrições".';
	@override String get reasonDownloadChannelBlocked => 'As notificações de download estão desativadas; por isso, o progresso e os controles podem ficar indisponíveis.';
	@override String get reasonNotificationsDisabled => 'As notificações estão desativadas. No Android 13 ou mais recente, elas são necessárias para downloads longos em segundo plano.';
	@override String get reasonDataSaver => 'A Economia de dados está ativada e bloqueia downloads em segundo plano usando dados móveis. Os downloads ainda devem funcionar no Wi-Fi.';
	@override String get reasonOemUnknown => 'Os downloads foram interrompidos várias vezes enquanto o PlezyNG estava em segundo plano. Verifique as configurações de bateria ou uso em segundo plano do PlezyNG.';
	@override String get openSettings => 'Abrir configurações';
	@override String get stillNotWorking => 'Ajuda específica para o dispositivo';
	@override String get stillNotWorkingDescription => 'Veja as instruções para seu dispositivo ou, se o problema persistir, envie um log em Configurações › Ver Logs.';
	@override String get dialogTitle => 'Os downloads podem não ser concluídos';
	@override String get dialogDownloadAnyway => 'Baixar mesmo assim';
	@override String get dialogFixFirst => 'Corrigir primeiro';
	@override String get statusTile => 'Downloads em segundo plano';
	@override String get statusOk => 'Execução em segundo plano permitida';
	@override String get statusBlocked => 'Bloqueado pelas configurações do sistema';
	@override String get statusDegraded => 'Limitado pelas configurações do sistema';
	@override String get statusUnknown => 'Ainda não verificado';
	@override String get settingsUnavailable => 'Não foi possível abrir as configurações do sistema neste dispositivo';
	@override String get linkUnavailable => 'Não foi possível abrir dontkillmyapp.com neste dispositivo';
}

// Path: downloads.groupings
class Translations$downloads$groupings$pt extends Translations$downloads$groupings$en {
	Translations$downloads$groupings$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get library => 'Biblioteca';
	@override String get collections => 'Coleções';
}

// Path: companionRemote.session
class Translations$companionRemote$session$pt extends Translations$companionRemote$session$en {
	Translations$companionRemote$session$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'Iniciando servidor remoto...';
	@override String get hostAddress => 'Endereço do host';
	@override String get connected => 'Conectado';
	@override String get serverRunning => 'Servidor remoto ativo';
	@override String get serverStopped => 'Servidor remoto parado';
	@override String get serverRunningDescription => 'Dispositivos móveis na sua rede podem se conectar a este app';
	@override String get serverStoppedDescription => 'Inicie o servidor para permitir que dispositivos móveis se conectem';
	@override String get usePhoneToControl => 'Use seu dispositivo móvel para controlar este app';
	@override String get startServer => 'Iniciar servidor';
	@override String get stopServer => 'Parar servidor';
	@override String get minimize => 'Minimizar';
	@override String get manualAddressHint => 'Endereço de conexão manual:';
}

// Path: companionRemote.pairing
class Translations$companionRemote$pairing$pt extends Translations$companionRemote$pairing$en {
	Translations$companionRemote$pairing$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'Dispositivos PlezyNG com a mesma conta Plex aparecem aqui';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Conectando...';
	@override String get searchingForDevices => 'Procurando dispositivos...';
	@override String get noDevicesFound => 'Nenhum dispositivo encontrado na sua rede';
	@override String get noDevicesHint => 'Abra o PlezyNG no desktop e use a mesma rede Wi-Fi';
	@override String get availableDevices => 'Dispositivos disponíveis';
	@override String get manualConnection => 'Conexão manual';
	@override String get cryptoInitFailed => 'Não foi possível iniciar a conexão segura. Entre no Plex primeiro.';
	@override String get validationHostRequired => 'Insira o endereço do host';
	@override String get validationHostFormat => 'O formato deve ser IP:porta (ex.: 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'A conexão atingiu o tempo limite. Use a mesma rede nos dois dispositivos.';
	@override String get sessionNotFound => 'Dispositivo não encontrado. Verifique se o PlezyNG está em execução no host.';
	@override String get authFailed => 'Falha na autenticação. Ambos os dispositivos precisam da mesma conta Plex.';
	@override String failedToConnect({required Object error}) => 'Falha ao conectar: ${error}';
	@override String get codeTitle => 'Código de par';
	@override String get codeDescription => 'Entre o código mostrado no Companion Remote no dispositivo host. Ambos os dispositivos devem usar uma versão que suporta paragem segura.';
	@override String get codeInvalid => 'Entre todas as 32 letras e números do código de hospedagem.';
	@override String get updateRequired => 'Atualize os dois dispositivos para uma versão que suporta paragem segura.';
	@override String get hostDescription => 'Mantenha-o privado: ele dá controle sobre este perfil.';
	@override String get resetCode => 'Resetando o código de par';
	@override String get resetDescription => 'Desconecte todos os remotos e crie um novo código. Cada remoto precisará se juntar novamente.';
}

// Path: companionRemote.remote
class Translations$companionRemote$remote$pt extends Translations$companionRemote$remote$en {
	Translations$companionRemote$remote$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'Deseja desconectar da sessão remota?';
	@override String get reconnecting => 'Reconectando...';
	@override String attemptOf({required Object current}) => 'Tentativa ${current} de 5';
	@override String get retryNow => 'Tentar agora';
	@override String get tabRemote => 'Remoto';
	@override String get tabPlay => 'Reproduzir';
	@override String get tabMore => 'Mais';
	@override String get menu => 'Menu';
	@override String get tabNavigation => 'Navegação por abas';
	@override String get tabDiscover => 'Descobrir';
	@override String get tabLibraries => 'Bibliotecas';
	@override String get tabSearch => 'Buscar';
	@override String get tabDownloads => 'Downloads';
	@override String get tabSettings => 'Configurações';
	@override String get previous => 'Anterior';
	@override String get playPause => 'Reproduzir/Pausar';
	@override String get next => 'Próximo';
	@override String get seekBack => 'Retroceder';
	@override String get stop => 'Parar';
	@override String get seekForward => 'Avançar';
	@override String get volume => 'Volume';
	@override String get volumeDown => 'Diminuir';
	@override String get volumeUp => 'Aumentar';
	@override String get fullscreen => 'Tela cheia';
	@override String get subtitles => 'Legendas';
	@override String get audio => 'Áudio';
	@override String get searchHint => 'Buscar no desktop...';
}

// Path: companionRemote.errors
class Translations$companionRemote$errors$pt extends Translations$companionRemote$errors$en {
	Translations$companionRemote$errors$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => 'Nenhuma interface de rede encontrada';
	@override String get authenticationFailed => 'Falha na autenticação';
	@override String serverStartFailed({required Object error}) => 'Falha ao iniciar o servidor remoto: ${error}';
	@override String commandFailed({required Object error}) => 'Falha ao enviar o comando remoto: ${error}';
	@override String get joinTimedOut => 'Tempo esgotado ao entrar na sessão';
	@override String get failedToConnectAnyAddress => 'Falha ao conectar a qualquer endereço';
	@override String connectionLostAfterAttempts({required Object attempts}) => 'Conexão perdida após ${attempts} tentativas';
	@override String get connectionLost => 'Conexão perdida';
}

// Path: services.names
class Translations$services$names$pt extends Translations$services$names$en {
	Translations$services$names$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
	@override String get mdblist => 'MDBList';
}

// Path: services.simklReconnect
class Translations$services$simklReconnect$pt extends Translations$services$simklReconnect$en {
	Translations$services$simklReconnect$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Reconectar o Simkl';
	@override String get subtitle => 'O Simkl está desativando o método de acesso usado por esta conexão. Ao reconectar, o simkl.com será aberto para aprovar o PlezyNG — o PlezyNG nunca vê sua senha. Seu histórico de exibição continua no Simkl.';
}

// Path: services.deviceCode
class Translations$services$deviceCode$pt extends Translations$services$deviceCode$en {
	Translations$services$deviceCode$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Ativar o PlezyNG no ${service}';
	@override String get instructions => 'Leia o código QR ou acesse o endereço abaixo e insira este código:';
	@override String openToActivate({required Object service}) => 'Abrir ${service} para ativar';
	@override String get copyCode => 'Copiar código de ativação';
	@override String get waitingForAuthorization => 'Aguardando autorização…';
	@override String get codeCopied => 'Código copiado';
}

// Path: services.oauthProxy
class Translations$services$oauthProxy$pt extends Translations$services$oauthProxy$en {
	Translations$services$oauthProxy$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Entrar no ${service}';
	@override String get body => 'Leia este código QR ou abra a URL em qualquer dispositivo.';
	@override String openToSignIn({required Object service}) => 'Abrir ${service} para entrar';
}

// Path: services.pendingAuth
class Translations$services$pendingAuth$pt extends Translations$services$pendingAuth$en {
	Translations$services$pendingAuth$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get copyUrl => 'Copiar URL de acesso';
	@override String get urlCopied => 'URL copiada';
}

// Path: services.libraryFilter
class Translations$services$libraryFilter$pt extends Translations$services$libraryFilter$en {
	Translations$services$libraryFilter$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Filtro de bibliotecas';
	@override String get subtitleAllSyncing => 'Sincronizando todas as bibliotecas';
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
	@override String get modeDescription => 'Escolha se as bibliotecas verificadas estão bloqueadas de sincronizar ou são as únicas bibliotecas que sincronizam.';
}

// Path: services.trackerDescriptions
class Translations$services$trackerDescriptions$pt extends Translations$services$trackerDescriptions$en {
	Translations$services$trackerDescriptions$pt.internal(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get trakt => 'Sincronize episódios e filmes assistidos com sua conta Trakt.';
	@override String get mal => 'Sincronize listas de anime e veja o progresso com MyAnimeList.';
	@override String get anilist => 'Sincronize listas de anime e veja o progresso com AniList.';
	@override String get simkl => 'Sync assistiu filmes, shows de TV e anime com Simkl.';
	@override String get mdblist => 'Mostrar classificações e listas do MDBList em recomendações e Explore.';
}

/// The flat map containing all translations for locale <pt>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsPt {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'PlezyNG',
			'appIcon.title' => 'Ícone do app',
			'appIcon.defaultIcon' => 'Padrão',
			'appIcon.current' => 'Ícone atual',
			'appIcon.locked' => 'Acesso ao tempo necessário',
			'appIcon.lockedHint' => 'Comece o seu teste de 7 dias ou desbloquee PlezyNG para a vida para usar ícones alternativos.',
			'appIcon.changeFailed' => 'Não foi possível alterar o ícone do app',
			'appIcon.launcherHint' => 'O novo ícone aparece na tela inicial assim que você sair do PlezyNG.',
			'appIcon.tvLauncherHint' => 'O novo banner aparece assim que você sair do PlezyNG. O Android TV pode continuar mostrando o antigo até a TV ser reiniciada.',
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
			'appIcon.names.sticker' => 'Adesivo',
			'appIcon.names.ticket' => 'Ingresso',
			'appIcon.names.pop' => 'Pop',
			'appIcon.names.strata' => 'Estratos',
			'appIcon.names.facet' => 'Faceta',
			'appIcon.names.tilde' => 'Til',
			'appIcon.description' => 'Escolha o ícone mostrado pelo seu lançador de dispositivo. as previsões mostram como cada opção parece.',
			'auth.signInWithPlex' => 'Entrar com Plex',
			'auth.showQRCode' => 'Mostrar código QR',
			'auth.authenticate' => 'Autenticar',
			'auth.authenticationTimeout' => 'A autenticação expirou. Tente novamente.',
			'auth.scanQRToSignIn' => 'Leia este código QR para entrar',
			'auth.waitingForAuth' => 'Aguardando autenticação...\nEntre pelo navegador.',
			'auth.useBrowser' => 'Usar navegador',
			'auth.or' => 'ou',
			'auth.connectToMediaBrowser' => ({required Object product}) => 'Conectar ao ${product}',
			'auth.quickConnect' => 'Quick Connect',
			'auth.useQuickConnect' => 'Usar Quick Connect',
			'auth.quickConnectInstructions' => 'Abra o Quick Connect no Jellyfin e insira este código.',
			'auth.quickConnectWaiting' => 'Aguardando aprovação…',
			'auth.quickConnectCancel' => 'Cancelar',
			'auth.quickConnectExpired' => 'Quick Connect expirou. Tente novamente.',
			'auth.localDataRecoveryRequired' => 'O PlezyNG não conseguiu recuperar com segurança os dados locais de acesso e de reproduções pendentes. Entre novamente.',
			'auth.pinCheckRejected' => 'A verificação do PIN do Plex foi rejeitada',
			'auth.connectToDirectPlex' => 'Conecte-se ao servidor local Plex',
			'common.cancel' => 'Cancelar',
			'common.save' => 'Salvar',
			'common.close' => 'Fechar',
			'common.closeMiniPlayer' => 'Mini jogador próximo',
			'common.closeWorkspaceWindow' => 'janela próxima',
			'common.returnToFullView' => 'Voltar para a vista completa',
			'common.manageMediaSessions' => 'Gestão de sessões de mídia',
			'common.hideMediaSessions' => 'Esconde sessões de mídia',
			'common.mediaSessions' => 'Sessões de mídia',
			'common.mediaSessionsHint' => 'Selecione para trazer uma sessão adiante.Park esconde a janela, mas mantém-a aberta.Retorno abre em vista completo; perto termina.',
			'common.sessionInWorkspace' => 'No espaço de trabalho',
			'common.sessionParked' => 'Estacionamento',
			'common.sessionFullscreen' => 'Ecrã completa',
			'common.switchToNextWindow' => 'Swap com a próxima janela',
			'common.moveWindow' => 'Move janela',
			'common.finishMovingWindow' => 'Fim da janela em movimento',
			'common.moveWindowHint' => 'Pressione e traça a janela para movê-la. Este controle também permite o movimento de chave da arca.',
			'common.movingWindowHelp' => 'Drag to move · Arrow keys adjust · Enter saves · Escape canceles',
			'common.resizeWindow' => 'Revisão janela',
			'common.resizeWindowHint' => 'Coloque esta mão ou use as chaves da arca para redirecionar a janela.',
			'common.workspaceWindowHint' => 'Use o controle de movimento ou a pressão longa e traça para se mover.',
			'common.workspacePaneHint' => 'Selecione este painel para focá-lo. Use seu controle de tela completa para expandir.',
			'common.workspaceWindowLabel' => ({required Object title}) => 'janela de sessão: ${title}',
			'common.workspaceTitleHint' => 'Tire a barra de título para se mover; use o botão de tela completa para expandir.',
			'common.moveToSessionTray' => 'Mover para sessão tray',
			'common.moveToSessionTrayHint' => 'Esta sessão está disponível sem mostrar a sua janela.',
			'common.closeSessionHint' => 'Feche esta janela e termina a sessão.',
			'common.sideBySideLayout' => 'Switch para layout lado a lado',
			'common.floatingWindows' => 'Switch para fluir janelas',
			'common.clear' => 'Limpar',
			'common.reset' => 'Redefinir',
			'common.later' => 'Depois',
			'common.submit' => 'Enviar',
			'common.confirm' => 'Confirmar',
			'common.retry' => 'Tentar novamente',
			'common.logout' => 'Sair',
			'common.unknown' => 'Desconhecido',
			'common.refresh' => 'Atualizar',
			'common.yes' => 'Sim',
			'common.no' => 'Não',
			'common.delete' => 'Excluir',
			'common.edit' => 'Editar',
			'common.shuffle' => 'Aleatório',
			'common.addTo' => 'Adicionar a...',
			'common.createNew' => 'Criar novo',
			'common.connect' => 'Conectar',
			'common.disconnect' => 'Desconectar',
			'common.play' => 'Reproduzir',
			'common.pause' => 'Pausar',
			'common.resume' => 'Retomar',
			'common.error' => 'Erro',
			'common.search' => 'Buscar',
			'common.home' => 'Início',
			'common.back' => 'Voltar',
			'common.settings' => 'Configurações',
			'common.mute' => 'Silenciar',
			'common.ok' => 'OK',
			'common.off' => 'Desativado',
			'common.options' => 'Opções',
			'common.seasonNumber' => ({required Object number}) => 'Temporada ${number}',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => 'Episódio ${number} - ${title}',
			'common.chapterNumber' => ({required Object number}) => 'Capítulo ${number}',
			'common.reconnect' => 'Reconectar',
			'common.viewAll' => 'Ver tudo',
			'common.checkingNetwork' => 'Verificando rede...',
			'common.loadingServers' => 'Carregando servidores...',
			'common.connectingToServers' => 'Conectando aos servidores...',
			'common.startingOfflineMode' => 'Iniciando modo offline...',
			'common.loading' => 'Carregando...',
			'common.fullscreen' => 'Tela cheia',
			'common.exitFullscreen' => 'Sair da tela cheia',
			'common.pressBackAgainToExit' => 'Pressione voltar novamente para sair',
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
			'common.mediaKind.movie' => 'Filme',
			'common.mediaKind.show' => 'Série',
			'common.mediaKind.season' => 'Temporada',
			'common.mediaKind.episode' => 'Episódio',
			'common.mediaKind.artist' => 'Artista',
			'common.mediaKind.album' => 'Álbum',
			'common.mediaKind.track' => 'Faixa',
			'common.mediaKind.collection' => 'Coleção',
			'common.mediaKind.playlist' => 'Playlist',
			'common.mediaKind.clip' => 'Clipe',
			'common.mediaKind.photo' => 'Foto',
			'common.mediaKind.folder' => 'Pasta',
			'screens.licenses' => 'Licenças',
			'screens.switchProfile' => 'Trocar Perfil',
			'screens.subtitleStyling' => 'Estilo de Legendas',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'Logs',
			'update.available' => 'Atualização disponível',
			'update.versionAvailable' => ({required Object version}) => 'A versão ${version} está disponível',
			'update.currentVersion' => ({required Object version}) => 'Atual: ${version}',
			'update.skipVersion' => 'Pular esta versão',
			'update.viewRelease' => 'Ver Lançamento',
			'update.latestVersion' => 'Você está na versão mais recente',
			'update.checkFailed' => 'Falha ao verificar atualizações',
			'settings.title' => 'Configurações',
			'settings.supportDeveloper' => 'Apoie o PlezyNG',
			'settings.supportDeveloperDescription' => 'Doe para apoiar o desenvolvimento',
			'settings.lifetimeAccess' => 'PlezyNG acesso ao tempo de vida',
			'settings.language' => 'Idioma',
			'settings.theme' => 'Tema',
			'settings.appearance' => 'Aparência',
			'settings.detailPage' => 'Página detalhado',
			'settings.themeSongsEnabled' => 'Jogue canções temáticas',
			'settings.themeSongsEnabledDescription' => 'Jogue músicas temáticas disponíveis enquanto vê detalhes de mídia.',
			'settings.themeSongVolume' => 'Título: Canção Volume',
			'settings.videoPlayback' => 'Reprodução de Vídeo',
			'settings.videoPlaybackDescription' => 'Configurar comportamento de reprodução',
			'settings.advanced' => 'Avançado',
			'settings.episodePosterMode' => 'Estilo do pôster do episódio',
			'settings.seriesPoster' => 'Pôster da série',
			'settings.seasonPoster' => 'Pôster da temporada',
			'settings.episodeThumbnail' => 'Miniatura',
			'settings.showHeroSectionDescription' => 'Exibir carrossel de conteúdo em destaque na tela inicial',
			'settings.secondsLabel' => 'Segundos',
			'settings.minutesLabel' => 'Minutos',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'm',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Insira a duração (${min}-${max})',
			'settings.systemTheme' => 'Sistema',
			'settings.lightTheme' => 'Claro',
			'settings.darkTheme' => 'Escuro',
			'settings.oledTheme' => 'OLED',
			'settings.emberTheme' => 'Brasa',
			'settings.glacierTheme' => 'Geleira',
			'settings.forestTheme' => 'Floresta',
			'settings.plumTheme' => 'Ameixa',
			'settings.paperTheme' => 'Papel',
			'settings.libraryDensity' => 'Densidade da Biblioteca',
			'settings.displayScale' => 'Escala de exibição',
			'settings.compact' => 'Compacto',
			'settings.comfortable' => 'Confortável',
			'settings.gridSpacing' => 'Espaçamento da grade',
			'settings.gridSpacingTight' => 'Compacto',
			'settings.gridSpacingNormal' => 'Normal',
			'settings.gridSpacingSpacious' => 'Espaçoso',
			'settings.tvCornerSpotlightBackdrop' => 'Imagem de destaque no canto',
			'settings.tvCornerSpotlightBackdropDescription' => 'Mostrar a imagem de destaque no canto superior direito em vez de preencher a tela',
			'settings.viewMode' => 'Modo de Visualização',
			'settings.gridView' => 'Grade',
			'settings.listView' => 'Lista',
			'settings.showHeroSection' => 'Mostrar Seção de Destaque',
			'settings.showHomeBackdrop' => 'Mostrar arte de backdrop',
			'settings.showHomeBackdropDescription' => 'Mostrar grandes obras de arte por trás feitas em ramas de casa',
			'settings.contentScreensaverEnabled' => 'Conteúdo de screensaver',
			'settings.contentScreensaverEnabledDescription' => 'Mostrar arte em tela completa depois que o aplicativo foi idle',
			'settings.contentScreensaverDelay' => 'Comece a monitorar depois',
			'settings.contentScreensaverLibraries' => 'Escreensaver bibliotecas',
			'settings.contentScreensaverLibrariesDescription' => 'Escolha as bibliotecas que fornecem imagens para a proteção de ecrã. Se não selecionar nenhuma, serão usadas imagens de todas as bibliotecas.',
			'settings.contentScreensaverAllLibraries' => 'Todas as bibliotecas',
			'settings.contentScreensaverSelectedLibraries' => ({required Object count}) => '${count} bibliotecas selecionadas',
			'settings.contentScreensaverNoLibraries' => 'Não há bibliotecas de mídia conectadas.',
			'settings.contentScreensaverDismissHint' => 'Pressione qualquer botão ou toque para desistir',
			'settings.newEpisodeNotifications' => 'Novos episódios de notificação',
			'settings.newEpisodeNotificationsDescription' => 'Alerta quando um novo episódio é adicionado a um show que você está capturado. verifica enquanto Plezy está aberto.',
			'settings.continueWatchingRowSize' => 'Continue a ver o tamanho da linha',
			'settings.continueWatchingRowSizeValue' => ({required Object label}) => '${label} cartões',
			'settings.rowSizeCompact' => 'Compacto',
			'settings.rowSizeStandard' => 'padrão',
			'settings.rowSizeLarge' => 'Grande',
			'settings.continueWatchingAction' => 'Ação da seção Continuar assistindo',
			'settings.continueWatchingPlay' => 'Reproduzir',
			'settings.continueWatchingDetails' => 'Abrir detalhes',
			'settings.episodeAction' => 'Ação do episódio',
			'settings.episodePlay' => 'Reproduzir',
			'settings.episodeDetails' => 'Abrir detalhes',
			'settings.useGlobalHubs' => 'Usar layout inicial',
			'settings.useGlobalHubsDescription' => 'Mostrar hubs iniciais unificados. Caso contrário, usar recomendações da biblioteca.',
			'settings.showServerNameOnHubs' => 'Mostrar Nome do Servidor nos Hubs',
			'settings.showServerNameOnHubsDescription' => 'Sempre mostrar nomes dos servidores nos títulos dos hubs.',
			'settings.groupLibrariesByServer' => 'Agrupar Bibliotecas por Servidor',
			'settings.groupLibrariesByServerDescription' => 'Agrupar bibliotecas da barra lateral por servidor de mídia.',
			'settings.alwaysKeepSidebarOpen' => 'Manter Barra Lateral Sempre Aberta',
			'settings.alwaysKeepSidebarOpenDescription' => 'A barra lateral fica expandida e a área de conteúdo se ajusta',
			'settings.showUnwatchedCount' => 'Mostrar Contagem de Não Assistidos',
			'settings.showUnwatchedCountDescription' => 'Exibir contagem de episódios não assistidos em séries e temporadas',
			'settings.showWatchedIndicators' => 'Mostrar Indicadores de Assistidos',
			'settings.showWatchedIndicatorsDescription' => 'Exibir uma marca de verificação em filmes, séries e episódios assistidos',
			'settings.showEpisodeNumberOnCards' => 'Mostrar Número do Episódio nos Cards',
			'settings.showEpisodeNumberOnCardsDescription' => 'Mostrar temporada e episódio nos cartões de episódio',
			'settings.showSeasonPostersOnTabs' => 'Mostrar Pôsteres de Temporada nas Abas',
			'settings.showSeasonPostersOnTabsDescription' => 'Mostrar o pôster de cada temporada acima da aba',
			'settings.tvFullCardLayout' => 'Cartões TV completos',
			'settings.tvFullCardLayoutDescription' => 'Usar cartões de TV só com imagem e nomes dos atores sobrepostos',
			'settings.focusGlow' => 'Brilho de foco',
			'settings.focusGlowDescription' => 'Mostrar um brilho suave ao redor do cartão em foco',
			'settings.visualEffects' => 'Efeitos visuais',
			'settings.visualEffectsAuto' => 'Automático',
			'settings.visualEffectsAutoDescription' => 'Reduzir os efeitos automaticamente em dispositivos de baixo consumo',
			'settings.visualEffectsFull' => 'Completos',
			'settings.visualEffectsReduced' => 'Reduzidos',
			'settings.visualEffectsReducedDescription' => 'Menos animações e imagens em menor resolução',
			'settings.hideSpoilers' => 'Ocultar spoilers de episódios não assistidos',
			'settings.hideSpoilersDescription' => 'Desfocar miniaturas e descrições de episódios não assistidos',
			'settings.playerBackend' => 'Mecanismo de reprodução',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'Decodificação por Hardware',
			'settings.hardwareDecodingDescription' => 'Usar aceleração por hardware quando disponível',
			'settings.playbackBuffer' => 'Buffer de reprodução',
			'settings.playbackBufferAuto' => 'Automático (recomendado)',
			'settings.playbackBufferLarge' => 'Grande',
			'settings.playbackBufferExtraLarge' => 'Extra grande',
			'settings.playbackBufferDescription' => 'Faz buffer extra contra conexões instáveis. Também limitado pelo tamanho do buffer.',
			'settings.streamBufferSize' => 'Baixão de tamanho',
			'settings.streamBufferSizeValue' => ({required Object size}) => '${size} MB',
			'settings.streamBufferSizeDescription' => 'Quanto vídeo para carregar em frente ao jogar diretamente. transcodes param no próprio buffer de transcódigo do servidor. 0 = Auto',
			'settings.streamBufferSizeExoNote' => 'Repasa o Playback Buffer quando configurado, captado na metade do limite de memória da aplicação',
			'settings.streamBufferMegabytes' => 'Megabytes',
			'settings.defaultQualityTitle' => 'Qualidade padrão',
			'settings.cellularQualityTitle' => 'Qualidade padrão nos dados móveis',
			'settings.remoteQualityTitle' => 'Qualidade de streaming remoto',
			'settings.remoteQualitySameAsDefault' => 'Como a qualidade padrão',
			'settings.cellularQualitySameAsDefault' => 'Igual à qualidade padrão',
			'settings.directPlayCoveredQuality' => 'Reproduzir Vídeos Menores na Qualidade Original',
			'settings.directPlayCoveredQualityDescription' => 'Reproduzir diretamente os vídeos que já estão dentro do limite de qualidade em vez de transcodificá-los',
			'settings.videoCodecs' => 'Codecs de vídeo',
			'settings.videoCodecsDescription' => 'Codecs desmarcados são transcodificados pelo servidor',
			'settings.videoCodecsAlwaysAccepted' => 'Sempre aceito',
			'settings.musicQualityTitle' => 'Qualidade da música',
			'settings.subtitleStyling' => 'Estilo de Legendas',
			'settings.subtitleStylingDescription' => 'Personalizar aparência das legendas',
			'settings.smallSkipDuration' => 'Duração do Avanço Curto',
			'settings.largeSkipDuration' => 'Duração do Avanço Longo',
			'settings.rewindOnResume' => 'Rebobinar ao retomar',
			'settings.secondsUnit' => ({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(seconds, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} segundo', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} segundos', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} segundos', ), 
			'settings.defaultSleepTimer' => 'Temporizador de suspensão padrão',
			'settings.minutesUnit' => ({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(minutes, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minuto', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minutos', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minutos', ), 
			'settings.rememberTrackSelections' => 'Lembrar seleção de faixas por série/filme',
			'settings.chooseTracksBeforePlayback' => 'Escolha áudio e subtitulos antes de reproduzir',
			'settings.chooseTracksBeforePlaybackDescription' => 'Selecione a fonte de áudio e subtítulos antes de cada vídeo começar.',
			'settings.alwaysShowSubtitlesOnDevice' => 'Sempre exibir subtitulos neste dispositivo',
			'settings.alwaysShowSubtitlesOnDeviceDescription' => 'Quando o servidor não tem nenhum subtítulo selecionado, escolha uma pista localmente.',
			'settings.autoDownloadPreferredSubtitle' => 'Feches de subtitulos preferidos',
			'settings.autoDownloadPreferredSubtitleDescription' => 'Selecione um subtítulo disponível em seu idioma preferido localmente.Se nenhum existe, peça ao servidor que encontre um quando suportado.',
			'settings.rememberTrackSelectionsDescription' => 'Lembrar escolhas de áudio e legendas por título',
			'settings.rememberTrackSelectionsBackendRule' => 'O Plex salva cada escolha no servidor por arquivo; o Jellyfin também ativa a opção Lembrar seleções da conta; o Emby não é compatível',
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
			'settings.clickVideoTogglesPlaybackDescription' => 'Clicar no vídeo para reproduzir ou pausar em vez de mostrar os controles.',
			'settings.videoPlayerControls' => 'Controles do reprodutor de vídeo',
			'settings.keyboardShortcuts' => 'Atalhos de Teclado',
			'settings.keyboardShortcutsDescription' => 'Personalizar atalhos de teclado',
			'settings.videoPlayerNavigation' => 'Navegação do reprodutor de vídeo',
			'settings.videoPlayerNavigationDescription' => 'Usar as teclas de seta para navegar pelos controles do reprodutor',
			'settings.watchTogetherRelay' => 'Servidor de retransmissão do Assistir Juntos',
			'settings.watchTogetherRelayDescription' => 'Servidores de retransmissão públicos do Open Watch Party, a menos que você defina o seu',
			'settings.watchTogetherRelayHint' => 'https://minha-retransmissao.exemplo.com.br',
			'settings.watchTogetherRelayInvalid' => 'Insira uma URL base de retransmissão HTTP ou HTTPS válida.',
			'settings.crashReporting' => 'Relatório de Erros',
			'settings.crashReportingDescription' => 'Enviar relatórios de erros para ajudar a melhorar o app',
			'settings.debugLogging' => 'Log de Depuração',
			'settings.debugLoggingDescription' => 'Ativar log detalhado para solução de problemas',
			'settings.viewLogs' => 'Ver Logs',
			'settings.viewLogsDescription' => 'Ver logs do app',
			'settings.clearImageCache' => 'Limpar cache de imagens',
			'settings.clearImageCacheDescription' => 'Limpar artes e miniaturas em cache. As imagens podem carregar mais devagar até serem baixadas novamente.',
			'settings.clearImageCacheSuccess' => 'Cache de imagens limpo com sucesso',
			'settings.resetSettings' => 'Redefinir Configurações',
			'settings.resetSettingsDescription' => 'Restaurar configurações padrão. Não pode ser desfeito.',
			'settings.resetSettingsSuccess' => 'Configurações redefinidas com sucesso',
			'settings.backup' => 'Backup',
			'settings.exportSettings' => 'Exportar Configurações',
			'settings.exportSettingsDescription' => 'Salvar suas preferências em um arquivo',
			'settings.exportSettingsSuccess' => 'Configurações exportadas',
			'settings.importSettings' => 'Importar Configurações',
			'settings.importSettingsDescription' => 'Restaurar preferências a partir de um arquivo',
			'settings.importSettingsConfirm' => 'Isso substituirá suas configurações atuais. Continuar?',
			'settings.importSettingsSuccess' => 'Configurações importadas',
			'settings.importSettingsInvalidFile' => 'Este arquivo não é uma exportação válida do PlezyNG',
			'settings.importSettingsNoUser' => 'Entre na conta antes de importar as configurações',
			'settings.cloudBackup' => 'Nuvem Backup',
			'settings.cloudBackupDescription' => 'Faça backup das configurações transferíveis em um endereço WebDAV por HTTPS. As conexões aos servidores e as credenciais permanecem neste dispositivo.',
			'settings.cloudBackupUrl' => 'WebDAV URL do arquivo JSON',
			'settings.cloudBackupUsername' => 'Usuário',
			'settings.cloudBackupPassword' => 'Senha',
			'settings.cloudBackupSaved' => 'Cloud Backup Destino Salvo',
			'settings.cloudBackupNow' => 'Voltar agora',
			'settings.cloudBackupComplete' => 'Configuração de backup upload',
			'settings.cloudBackupRestore' => 'Restauração de backup',
			'settings.cloudBackupRestoreConfirm' => 'Isso substituirá as configurações portáteis correspondentes neste dispositivo.',
			'settings.cloudBackupRestored' => 'Atualização de configurações recuperadas da backup da nuvem',
			'settings.shortcutsReset' => 'Atalhos redefinidos para o padrão',
			'settings.resetShortcutsConfirm' => 'Isso substituirá seus atalhos personalizados pelos padrões. Continuar?',
			'settings.about' => 'Sobre',
			'settings.aboutDescription' => 'Informações do app e licenças',
			'settings.updates' => 'Atualizações',
			'settings.updateAvailable' => 'Atualização Disponível',
			'settings.checkForUpdates' => 'Verificar Atualizações',
			'settings.autoCheckUpdatesOnStartup' => 'Verificar atualizações automaticamente ao iniciar',
			'settings.autoCheckUpdatesOnStartupDescription' => 'Notificar ao iniciar quando houver atualização disponível',
			'settings.validationErrorEnterNumber' => 'Insira um número válido',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'A duração deve estar entre ${min} e ${max} ${unit}',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Atalho já atribuído a ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Atalho atualizado para ${action}',
			'settings.saveFailed' => 'Não foi possível salvar as alterações. Tente novamente.',
			'settings.autoPlayAndSkip' => 'Reprodução automática e pulos',
			'settings.autoPlayNextEpisode' => 'Reproduzir próximo episódio automaticamente',
			'settings.autoPlayNextEpisodeDescription' => 'Iniciar o próximo episódio automaticamente quando um terminar',
			'settings.shuffleStartsFromBeginning' => 'Reprodução Aleatória Começa do Início',
			'settings.shuffleStartsFromBeginningDescription' => 'Iniciar cada episódio do início na reprodução aleatória em vez de retomá-lo',
			'settings.plexCinemaPreRoll' => 'Use o servidor de cinema intros',
			'settings.plexCinemaPreRollDescription' => 'Jogue Plex pre-rolls ou Jellyfin e Emby intros configurados antes de um filme começar.',
			'settings.playNextCountdown' => 'Contagem regressiva do próximo episódio',
			'settings.playNextCountdownImmediate' => 'Reproduzir imediatamente',
			'settings.skipIntroMode' => 'Pular Abertura',
			'settings.skipIntroModeOffDescription' => 'Reproduzir as aberturas normalmente sem botão de pulo',
			'settings.skipIntroModeButtonDescription' => 'Mostrar um botão de pulo quando uma abertura começar',
			'settings.skipIntroModeAutoDescription' => 'Pular as aberturas automaticamente após o atraso abaixo',
			'settings.skipCreditsMode' => 'Pular Créditos',
			'settings.skipCreditsModeOffDescription' => 'Reproduzir os créditos normalmente sem botão de pulo',
			'settings.skipCreditsModeButtonDescription' => 'Mostrar um botão de pulo quando os créditos começarem',
			'settings.skipCreditsModeAutoDescription' => 'Pular os créditos automaticamente e reproduzir o próximo episódio',
			'settings.skipAdsMode' => 'Escape de anúncios',
			'settings.skipAdsModeOffDescription' => 'Jogue anúncios detectados normalmente sem um botão de escape',
			'settings.skipAdsModeButtonDescription' => 'Mostrar um botão de escape quando o Plex detecta um anúncio',
			'settings.skipAdsModeAutoDescription' => 'Desligue os anúncios detectados automaticamente após o atraso abaixo',
			'settings.musicPlayback' => 'Música Playback',
			'settings.musicSweetFades' => 'Sóceos doces',
			'settings.musicSweetFadesDescription' => 'Fade música em bordas de track quando Plex tem dados de som.',
			'settings.skipMarkerModeOff' => 'Desativado',
			'settings.skipMarkerModeButton' => 'Mostrar botão',
			'settings.skipMarkerModeAuto' => 'Automático',
			'settings.forceSkipMarkerFallback' => 'Forçar marcadores alternativos',
			'settings.forceSkipMarkerFallbackDescription' => 'Usar padrões de títulos de capítulos mesmo quando o Plex tiver marcadores',
			'settings.theIntroDbFallback' => 'Use o TheIntroDB como um intro fallback',
			'settings.theIntroDbFallbackDescription' => 'Use as temporadas da comunidade apenas quando o servidor não tem um marcador de intro.',
			'settings.autoSkipDelay' => 'Atraso para pular automaticamente',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Aguardar ${seconds} segundos antes de pular automaticamente',
			'settings.introPattern' => 'Padrão do marcador de introdução',
			'settings.introPatternDescription' => 'Expressão regular que identifica marcadores de introdução nos títulos dos capítulos',
			'settings.creditsPattern' => 'Padrão do marcador de créditos',
			'settings.creditsPatternDescription' => 'Expressão regular que identifica marcadores de créditos nos títulos dos capítulos',
			'settings.prerolls' => 'Preróis',
			'settings.playPrerollsBeforeMovies' => 'Jogue Preróis antes dos filmes',
			'settings.playPrerollsBeforeMoviesDescription' => 'Jogue um clipe aleatório da sua seleção abaixo antes de cada filme. pressione para escapar.',
			'settings.prerollLibrary' => 'Biblioteca Preroll',
			'settings.prerollLibraryNotSet' => 'Não definido',
			'settings.prerollLibraryNoneFound' => 'Não há bibliotecas encontradas em seus servidores.',
			'settings.prerollSelection' => 'Prefeitos selecionados',
			'settings.prerollSelectionPickLibraryFirst' => 'Escolha uma biblioteca primeiro',
			'settings.prerollSelectionNoneSelected' => 'Não há pré-requisitos selecionados',
			'settings.prerollSelectionCount' => ({required Object count}) => '${count} selecionados',
			'settings.prerollItemPicker' => 'Escolha os pré-requisitos',
			'settings.prerollItemPickerLoadFailed' => 'Não podia carregar itens desta biblioteca.',
			'settings.invalidRegex' => 'Expressão regular inválida',
			'settings.regex' => 'Expressão regular',
			'settings.downloads' => 'Downloads',
			'settings.downloadLocationDescription' => 'Escolha onde armazenar conteúdo baixado',
			'settings.downloadLocationDefault' => 'Padrão (Armazenamento do App)',
			'settings.downloadLocationCustom' => 'Local Personalizado',
			'settings.selectFolder' => 'Selecionar Pasta',
			'settings.resetToDefault' => 'Redefinir para Padrão',
			'settings.currentPath' => ({required Object path}) => 'Atual: ${path}',
			'settings.downloadLocationChanged' => 'Local de download alterado',
			'settings.downloadLocationReset' => 'Local de download redefinido para padrão',
			'settings.downloadLocationInvalid' => 'A pasta selecionada não permite gravação',
			'settings.downloadLocationPickerUnavailable' => 'A seleção de pasta não está disponível neste dispositivo',
			'settings.downloadOnWifiOnly' => 'Baixar apenas por Wi-Fi',
			'settings.downloadOnWifiOnlyDescription' => 'Impedir downloads ao usar dados móveis',
			'settings.autoRemoveWatchedDownloads' => 'Remover automaticamente os downloads assistidos',
			'settings.autoRemoveWatchedDownloadsDescription' => 'Excluir automaticamente os downloads assistidos',
			'settings.autoDownloadContinueWatching' => 'Auto-Download Continuar a Assistir',
			'settings.autoDownloadContinueWatchingDescription' => 'Mantenha os itens na sua caixa de monitoramento continua baixados e remova-os uma vez que deixam a caixa de monitoramentos',
			'settings.downloadQuality' => 'Download Qualidade',
			'settings.downloadQualityDescription' => 'Plex prepara uma cópia convertida em seu download quue. Jellyfin e Emby transcódigo enquanto o arquivo é baixado; transferências interrompidas podem precisar de reiniciar.',
			'settings.askDownloadQualityEachTime' => 'Escolha a qualidade para cada download',
			'settings.askDownloadQualityEachTimeDescription' => 'Mostrar o picker de qualidade antes de quebrar cada download de vídeo',
			'settings.cellularDownloadBlocked' => 'Os downloads estão bloqueados nos dados móveis. Use Wi-Fi ou altere a configuração.',
			'settings.maxVolume' => 'Volume Máximo',
			'settings.maxVolumeDescription' => 'Permitir aumento de volume acima de 100% para mídias silenciosas',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Mostrar o que você está assistindo no Discord',
			'settings.services' => 'Serviços',
			'settings.servicesDescription' => 'Conecte Trakt, MyAnimeList, Seerr e mais',
			'settings.manageLibrariesDescription' => 'Reordene e oculte bibliotecas',
			'settings.companionRemoteServer' => 'Servidor de controle remoto',
			'settings.companionRemoteServerDescription' => 'Permitir que dispositivos móveis na sua rede controlem este app',
			'settings.companionRemoteServerStartFailed' => 'Não foi possível iniciar o servidor de controle remoto',
			'settings.companionRemoteServerStopFailed' => 'Não foi possível parar o servidor de controle remoto',
			'settings.autoPip' => 'Picture-in-picture automático',
			'settings.autoPipDescription' => 'Entrar automaticamente no modo picture-in-picture ao sair do app durante a reprodução',
			'settings.matchContentFrameRate' => 'Ajustar à taxa de quadros do conteúdo',
			'settings.matchContentFrameRateDescription' => 'Ajustar a taxa de atualização da tela ao conteúdo de vídeo',
			'settings.matchContentResolution' => 'Ajustar à resolução do conteúdo',
			'settings.matchContentResolutionDescription' => 'Muda a tela para a resolução nativa do vídeo para que a TV cuide do upscaling. Menus e legendas também são ampliados durante a reprodução',
			'settings.matchRefreshRate' => 'Ajustar à taxa de atualização',
			'settings.matchRefreshRateDescription' => 'Ajustar a taxa de atualização da tela em tela cheia',
			'settings.matchDynamicRange' => 'Ajustar à faixa dinâmica',
			'settings.matchDynamicRangeDescription' => 'Ativar HDR para conteúdo HDR e depois voltar para SDR',
			'settings.displaySwitchDelay' => 'Atraso na troca do modo de exibição',
			'settings.tunneledPlayback' => 'Reprodução em túnel',
			'settings.tunneledPlaybackDescription' => 'Usar o tunelamento de vídeo. Desative se o vídeo ficar preto ao reproduzir em HDR ou o movimento travar.',
			'settings.audioPassthrough' => 'Passagem direta de áudio',
			'settings.audioPassthroughDescription' => 'Enviar o áudio Dolby/DTS ao receptor ou à TV sem recodificação, preservando o som surround. Desative se não houver som.',
			'settings.audioPassthroughDescriptionApple' => 'Usar o decodificador Dolby nativo da Apple para Dolby Digital Plus, incluindo Atmos. DTS e TrueHD continuam sendo reproduzidos como PCM multicanal. Desative se não houver som.',
			'settings.audioPassthroughDescriptionAppleSpatial' => 'Usar o decodificador Dolby nativo da Apple para Dolby Digital Plus, incluindo Atmos. No iOS, iPadOS e tvOS 26 ou posterior, TrueHD Atmos e DTS:X são reproduzidos como áudio espacial. As demais faixas DTS e TrueHD são reproduzidas como PCM multicanal. Desative se não houver som.',
			'settings.audioPassthroughOverriddenByNormalization' => 'Desativada enquanto a normalização de intensidade sonora estiver ativa',
			'settings.audioChannelLimit' => 'Canais de áudio',
			'settings.audioChannelLimitDescription' => 'Mixar o áudio decodificado em menos canais para alto-falantes, fones de ouvido ou sistemas HDMI que não reproduzem todos os canais',
			'settings.audioChannelLimitOriginal' => 'Original',
			'settings.audioChannelLimitOriginalDescription' => 'Reproduzir todos os canais da faixa',
			'settings.audioChannelLimitSurround51' => 'Até 5.1',
			'settings.audioChannelLimitSurround51Description' => 'Mixar 7.1 em 5.1 para TVs e receptores que só aceitam PCM 5.1. A passagem direta não é afetada.',
			'settings.audioChannelLimitStereo' => 'Estéreo',
			'settings.audioChannelLimitStereoDescription' => 'Mixar em dois canais para alto-falantes estéreo ou fones de ouvido. Desativa a passagem direta.',
			'settings.downmixCenterBoost' => 'Reforço do canal central',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'Reforço (dB)',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => 'Normalizar volume na conversão para estéreo',
			'settings.audioDownmixNormalizeDescription' => 'Reduzir o volume da mixagem para evitar saturação. Desative para manter o volume original, que pode distorcer em cenas muito altas.',
			'settings.dvConversionMode' => 'Conversão Dolby Vision',
			'settings.dvConversionModeDescription' => 'Escolha como os arquivos Dolby Vision Profile 7 são tratados.',
			'settings.dvConversionAuto' => 'Automático',
			'settings.dvConversionNative' => 'Nativo / desativado',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Usar a detecção de recursos do dispositivo e o comportamento alternativo padrão',
			'settings.dvConversionNativeDescription' => 'Forçar DV7 nativo e impedir uma nova tentativa de conversão de DV',
			'settings.dvConversionDv81Description' => 'Forçar a conversão RPU integrada para Dolby Vision perfil 8.1',
			'settings.dvConversionHevcStripDescription' => 'Remover as camadas RPU/EL do Dolby Vision e apresentar HEVC sem Dolby Vision',
			'settings.experimentalDolbyVision' => 'Dolby Vision experimental',
			'settings.experimentalDolbyVisionDescription' => 'Usar o renderizador FEL experimental na próxima reprodução. Requer uma compilação separada do motor.',
			'settings.dvExperimentUnavailableDescription' => 'Este experimento está disponível apenas no Linux por enquanto.',
			'settings.dvCompatibilityFallback' => 'Alternativa de compatibilidade',
			'settings.dvCompatibilityFallbackDescription' => 'Usar o renderizador padrão se o experimento não iniciar. Os dados FEL podem ser perdidos.',
			'settings.dvExperimentDiagnostics' => 'Registro do experimento de vídeo',
			'settings.dvExperimentDiagnosticsDescription' => 'Ativar registros detalhados do reprodutor na próxima reprodução.',
			'settings.disableDolbyVision' => 'Desativar Dolby Vision',
			'settings.disableDolbyVisionDescription' => 'Reproduzir a camada HDR10 ou HLG do arquivo em vez de Dolby Vision, quando houver',
			'settings.hdrSdrConversion' => 'Conversão de HDR para SDR',
			'settings.hdrSdrConversionDescription' => 'Escolha o que converte vídeos HDR quando a tela não consegue exibir HDR.',
			_ => null,
		} ?? switch (path) {
			'settings.hdrSdrConversionAuto' => 'Automático',
			'settings.hdrSdrConversionAutoDescription' => 'Dispositivo no Android 9 ou posterior, reprodutor em versões anteriores',
			'settings.hdrSdrConversionDevice' => 'Dispositivo',
			'settings.hdrSdrConversionDeviceDescription' => 'O hardware de vídeo do dispositivo faz a conversão. Mais rápido, mas as cores dependem do dispositivo',
			'settings.hdrSdrConversionPlayer' => 'Reprodutor',
			'settings.hdrSdrConversionPlayerDescription' => 'O reprodutor faz a conversão. Cores consistentes, mas o 4K pode travar em TV boxes mais simples',
			'settings.deinterlace' => 'Desentrelaçamento',
			'settings.deinterlaceDescription' => 'Remover artefatos de pente de vídeo entrelaçado (apenas no reprodutor mpv)',
			'settings.deinterlaceOff' => 'Desativado',
			'settings.deinterlaceOffDescription' => 'Exibir o vídeo entrelaçado como é decodificado',
			'settings.deinterlaceVideo' => 'Vídeo',
			'settings.deinterlaceVideoDescription' => 'Transformar cada campo em um quadro completo. Para vídeos gravados para TV, como esportes, noticiários e shows',
			'settings.deinterlaceFilm' => 'Filme',
			'settings.deinterlaceFilmDescription' => 'Restaurar os quadros originais de filmes e animações convertidos por telecine para 29,97 fps, comum em DVDs NTSC. Vídeos gravados para TV travam. A TV ao vivo usa Vídeo',
			'settings.requireProfileSelectionOnOpen' => 'Pedir perfil ao abrir o app',
			'settings.requireProfileSelectionOnOpenDescription' => 'Mostrar a seleção de perfil sempre que o app for aberto',
			'settings.forceTvMode' => 'Forçar modo TV',
			'settings.forceTvModeDescription' => 'Forçar o layout de TV em dispositivos sem detecção automática. Requer reiniciar o app.',
			'settings.startInFullscreen' => 'Iniciar em tela cheia',
			'settings.startInFullscreenDescription' => 'Abrir o PlezyNG em modo de tela cheia ao iniciar',
			'settings.exitFullscreenOnPlayerClose' => 'Sair da tela cheia ao fechar o reprodutor',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Sair automaticamente da tela cheia ao fechar o reprodutor de vídeo',
			'settings.autoHidePerformanceOverlay' => 'Ocultar automaticamente o painel de desempenho',
			'settings.autoHidePerformanceOverlayDescription' => 'Esmaecer o painel de desempenho junto com os controles de reprodução',
			'settings.showNavBarLabels' => 'Mostrar Rótulos da Barra de Navegação',
			'settings.showNavBarLabelsDescription' => 'Exibir rótulos de texto sob os ícones da barra de navegação',
			'settings.startupSection' => 'Seção inicial',
			'settings.preferredServer' => 'Preferido servidor',
			'settings.preferredServerDescription' => 'Priorize os resultados deste servidor, mantendo todos os servidores conectados disponíveis.',
			'settings.preferredServerAutomatic' => 'Automático',
			'settings.showExploreTab' => 'Mostrar aba Explorar',
			'settings.showExploreTabDescription' => 'Exibir a aba Explorar com conteúdo do Plex Discover e dos rastreadores conectados',
			'settings.hideEmptyLibraries' => 'Esconde bibliotecas vazias',
			'settings.hideEmptyLibrariesDescription' => 'Remova bibliotecas com um número de itens reportados pelo servidor de zero da navegação.',
			'settings.liveTvDefaultFavorites' => 'Canais favoritos por padrão',
			'settings.liveTvDefaultFavoritesDescription' => 'Mostrar apenas os canais favoritos ao abrir a TV ao vivo',
			'settings.general' => 'Geral',
			'settings.generalDescription' => 'Idioma, inicialização e comportamento da janela',
			'settings.languageAndRegion' => 'Idioma e Região',
			'settings.startup' => 'Inicialização',
			'settings.display' => 'Tela',
			'settings.libraryAndCards' => 'Biblioteca e Cards',
			'settings.homeScreen' => 'Tela inicial',
			'settings.navigation' => 'Navegação',
			'settings.window' => 'Janela',
			'settings.liveTv' => 'TV ao Vivo',
			'settings.player' => 'Reprodutor',
			'settings.videoAndDisplay' => 'Vídeo e Tela',
			'settings.audio' => 'Áudio',
			'settings.quality' => 'Qualidade',
			'settings.subtitles' => 'Legendas',
			'settings.seekAndTiming' => 'Busca e tempo',
			'settings.behavior' => 'Comportamento',
			'settings.gestures' => 'Gestos',
			'settings.gestureBrightnessSwipe' => 'Deslize para brilho',
			'settings.gestureBrightnessSwipeDescription' => 'Deslize para cima ou para baixo na borda esquerda para ajustar o brilho',
			'settings.gestureVolumeSwipe' => 'Deslize para volume',
			'settings.gestureVolumeSwipeDescription' => 'Deslize para cima ou para baixo na borda direita para ajustar o volume',
			'settings.gesturePinchToZoom' => 'Pinça para zoom',
			'settings.gesturePinchToZoomDescription' => 'Pince o vídeo para ampliar ou reduzir',
			'settings.gestureSeekSwipe' => 'Busca de Swipe',
			'settings.gestureSeekSwipeDescription' => 'Desligue para a esquerda ou para a direita em qualquer lugar no vídeo para procurar; liberar para saltar',
			'settings.rememberBrightnessLevel' => 'Lembrar Nível de Brilho',
			'settings.rememberBrightnessLevelDescription' => 'Iniciar a reprodução com o brilho definido pelo último deslize',
			'settings.controls' => 'Controles',
			'settings.rememberPlayerChanges' => 'Lembrar alterações do reprodutor',
			'settings.rememberPlayerChangesDescription' => 'Onde uma alteração feita durante a reprodução é salva e reaplicada',
			'settings.scopePlaybackSpeed' => 'Velocidade de reprodução',
			'settings.scopeShaderPreset' => 'Predefinição de shader',
			'settings.scopeAspectRatio' => 'Proporção da tela',
			'settings.scopeSyncOffsets' => 'Sincronização de áudio e legendas',
			'settings.playerScopeOff' => 'Não salvar',
			'settings.playerScopeGlobal' => 'Em todos os lugares',
			'settings.playerScopeLibrary' => 'Por biblioteca',
			'settings.playerScopeTitle' => 'Por série ou filme',
			'settings.exportDialogTitle' => 'Exportar configurações do PlezyNG',
			'settings.followSystem' => 'Seguir o sistema',
			'settings.followAppLanguage' => 'Igual ao idioma da interface',
			'settings.regionFormat' => 'Formatos regionais',
			'settings.regionFormatDescription' => 'Escolha como as datas, os números e as unidades de medida são apresentados.',
			'settings.metadataLanguage' => 'Idioma dos metadados',
			'settings.metadataLanguageDescription' => 'Idioma preferido para títulos e descrições quando o servidor o suportar. As preferências de áudio e legendas são definidas separadamente.',
			'settings.enterFullscreenOnPlaybackStart' => 'Insira a tela completa quando o playback começa',
			'settings.enterFullscreenOnPlaybackStartDescription' => 'Abre vídeo de desktop em tela completa quando o playback começa',
			'settings.extendVideoIntoDisplayCutout' => 'Extender vídeo para exibição cutout',
			'settings.extendVideoIntoDisplayCutoutDescription' => 'Deixe o vídeo de tela completa usar a câmera cutout em telefones Android',
			'settings.languageDescription' => 'Escolha a língua utilizada para os controles e mensagens do PlezyNG. Seguindo o sistema rastreia o idioma do seu dispositivo.',
			'settings.themeDescription' => 'Escolha as cores e contraste utilizados em toda a aplicação.',
			'settings.libraryDensityDescription' => 'Mude o número de cartões da biblioteca em cada linha.',
			'settings.displayScaleDescription' => 'Recupere a interface nesta tela do carro sem alterar o tamanho de texto em todo o seu dispositivo.',
			'settings.themeSongVolumeDescription' => 'Defina o volume de músicas temáticas em relação a outros áudio.',
			'settings.viewModeDescription' => 'Escolha se os itens da biblioteca aparecem como posters em uma rede ou como uma lista compacta.',
			'settings.gridViewDescription' => 'Arranje itens da biblioteca em linhas e colunas de posters.',
			'settings.listViewDescription' => 'Mostrar itens da biblioteca em uma lista vertical com mais texto por item.',
			'settings.gridSpacingDescription' => 'Coloque a lacuna entre os cartazes nas redes da biblioteca.',
			'settings.gridSpacingTightDescription' => 'Faça mais posters em todo o ecrã com pequenas lacunas.',
			'settings.gridSpacingNormalDescription' => 'Use a diferença padrão entre os cartões.',
			'settings.gridSpacingSpaciousDescription' => 'Adicione maiores lacunas entre os posters para mais separação.',
			'settings.episodePosterModeDescription' => 'Escolha qual obra de arte aparece nas cartas de episódio.',
			'settings.seriesPosterDescription' => 'Use o poster da série do show para cada episódio.',
			'settings.seasonPosterDescription' => 'Use o poster de temporada para cada episódio quando disponível.',
			'settings.episodeThumbnailDescription' => 'Use um quadro do episódio quando disponível.',
			'settings.continueWatchingActionDescription' => 'Escolha o que acontece quando você ativar um cartão de acompanhamento contínuo.',
			'settings.continueWatchingPlayDescription' => 'Comece o filme ou episódio imediatamente.',
			'settings.continueWatchingDetailsDescription' => 'Abra a página de título primeiro para que você possa revisar os detalhes e escolher uma ação.',
			'settings.episodeActionDescription' => 'Escolha o que acontece quando você ativar um cartão de episódio.',
			'settings.episodePlayDescription' => 'Comece o episódio imediatamente.',
			'settings.episodeDetailsDescription' => 'Abra a página de episódio antes do playback.',
			'settings.contentScreensaverDelayDescription' => 'Escolha quanto tempo PlezyNG espera sem entrada antes de mostrar obras de arte.',
			'settings.continueWatchingRowSizeDescription' => 'Escolha o tamanho das cartas na linha Continuing Watching.',
			'settings.rowSizeCompactDescription' => 'Mostrar cartões menores para que mais itens se encaixem em toda a linha.',
			'settings.rowSizeStandardDescription' => 'Use o tamanho de cartão padrão.',
			'settings.rowSizeLargeDescription' => 'Mostrar cartas maiores com mais detalhes de arte.',
			'settings.visualEffectsDescription' => 'Escolha o orçamento de animação e efeitos artísticos para este dispositivo.',
			'settings.visualEffectsFullDescription' => 'Use os efeitos de animação e arte em todos os dispositivos.',
			'settings.startupSectionDescription' => 'Escolha qual seção abre quando PlezyNG começa.',
			'settings.startupSectionOptions.discover' => 'Abre recomendações e itens de fontes de descoberta conectadas.',
			'settings.startupSectionOptions.libraries' => 'Abra suas bibliotecas de mídia conectadas.',
			'settings.startupSectionOptions.liveTv' => 'Abra a TV ao vivo quando um servidor o fornece; caso contrário, a startup cai de volta para o Home.',
			'settings.startupSectionOptions.search' => 'Pesquisa de mídia aberta.',
			'settings.smallSkipDurationDescription' => 'Defina a distância movida pela curta direção traseira e para frente busca controles.',
			'settings.largeSkipDurationDescription' => 'Defina a distância movida pelo longo traseiro e para frente procura controlos.',
			'settings.rewindOnResumeDescription' => 'Move o playback de volta por essa quantia quando retoma um vídeo.',
			'settings.defaultSleepTimerDescription' => 'Defina a duração inicial utilizada quando você começa o horário de sono.',
			'settings.playNextCountdownDescription' => 'Aguarde muito antes de começar o próximo episódio.Set para 0 para começar imediatamente.',
			'settings.autoSkipDelaySettingDescription' => 'Aplica-se quando um intro, crédito ou anúncio é configurado para exceder automaticamente.',
			'settings.downmixCenterBoostDescription' => 'Aumente o diálogo no canal central quando o áudio circundante é misturado para baixo em estereó.',
			'settings.displaySwitchDelayDescription' => 'Aguarde antes de alterar o modo de exibição para que a TV ou receptor possa terminar seu switch anterior.',
			'settings.playerBackendDescription' => 'Escolha qual motor de reprodução decode e retrata vídeo neste dispositivo.',
			'settings.exoPlayerDescription' => 'Use o jogador nativo do Android baseado no Media3 e as vias de hardware suportadas.',
			'settings.mpvDescription' => 'Use mpv, que expõe controles adicionais de reprodução, subtítulos e processamento de vídeo.',
			'settings.scopeOffDescription' => 'Mantenha as alterações apenas para a sessão de reprodução atual.',
			'settings.scopeGlobalDescription' => 'Reutilizar o mesmo valor para cada biblioteca e título.',
			'settings.scopeLibraryDescription' => 'Lembre-se de um valor separado para cada biblioteca.',
			'settings.scopeTitleDescription' => 'Lembre-se de um valor separado para cada show ou filme.',
			'settings.specialsOrderingServerDescription' => 'Mantenha a ordem do episódio fornecida pelo servidor de mídia.',
			'settings.specialsOrderingAirDateDescription' => 'Coloque especiais entre episódios regulares pela sua data de ar.',
			'settings.specialsOrderingLastDescription' => 'Colocar cada especial após as estações regulares.',
			'settings.skipIntroModeDescription' => 'Escolha se os marcadores intro jogam normalmente, mostram um botão de escape ou escapam automaticamente.',
			'settings.skipCreditsModeDescription' => 'Escolha se os créditos jogam normalmente, exibe um botão de escape ou escape automaticamente.',
			'settings.skipAdsModeDescription' => 'Escolha se os anúncios detectados jogam normalmente, mostram um botão de escape ou escapam automaticamente.',
			'settings.playbackBufferAutoDescription' => 'Deixe o jogador ativo escolher seu tamanho de buffer normal.',
			'settings.playbackBufferLargeDescription' => 'Mantenha mais mídia pronta antes do playback; isso usa mais memória.',
			'settings.playbackBufferExtraLargeDescription' => 'Mantenha o maior buffer de leitura; isso usa a maioria da memória.',
			'settings.defaultQualityDescription' => 'Configurar a resolução de vídeo padrão e bitrate o telhado para os fluxos que o servidor transcoda.',
			'settings.cellularQualityDescription' => 'Override Qualidade padrão quando o dispositivo está usando uma conexão celular-somente.',
			'settings.remoteQualityDescription' => 'Override Default Quality quando se conecta a um servidor através de uma conexão remota.',
			'settings.qualityPresetOriginalDescription' => 'Jogue a fonte à sua qualidade disponível sem pedir ao servidor que o transcode.',
			'settings.qualityPresetTranscodeOptionDescription' => 'Peça ao servidor para um fluxo convertido usando a resolução e bitrate mostrados acima.',
			'settings.qualityPresetSameAsDefaultDescription' => 'Utilize a qualidade selecionada em Qualidade padrão.',
			'settings.musicQualityDescription' => 'Configure a taxa de áudio máxima solicitada do servidor; O original mantém o fluxo fonte.',
			'settings.musicQualityOriginalDescription' => 'Jogue o áudio de origem sem um transcódigo capped com bitrate.',
			'settings.musicQualityTranscodeOptionDescription' => 'Solicite um transcódigo de servidor capped perto da taxa de bit mostrada acima; a saída real pode variar.',
			'settings.maxVolumeInputLabel' => 'Volume máximo (%)',
			'settings.checkForUpdatesDescription' => 'Verifique agora se uma versão mais recente do PlezyNG está disponível.',
			'settings.appearanceDescription' => 'Escolha o tema do aplicativo e ajuste os cartões da biblioteca, as linhas domésticas e a navegação.',
			'settings.prerollLibraryDescription' => 'Escolha a biblioteca que contém os clipes disponíveis como pre-rolls do filme.',
			'settings.prerollSelectionDescription' => 'Escolha quais clipes da biblioteca selecionada podem ser jogados antes dos filmes.',
			'settings.contentScreensaverDelayOptionDescription' => 'Aguarde muitos minutos sem entrada antes de mostrar o trabalho artístico do monitor.',
			'settings.videoCodecOptionDescription' => 'Permitir reprodução direta para este codec quando suportado. codecs não verificados são transcodados pelo servidor de mídia.',
			'themeEditor.builtIn' => 'Integrados',
			'themeEditor.presets' => 'Predefinidos',
			'themeEditor.custom' => 'Personalizado',
			'themeEditor.customEmpty' => 'Ainda não criado',
			'themeEditor.editCustom' => 'Editar tema personalizado',
			'themeEditor.editCustomDescription' => 'Escolha você mesmo cada cor',
			'themeEditor.locked' => 'Acesso ao tempo necessário',
			'themeEditor.savedLocked' => 'Salvo - disponível com acesso ao tempo todo',
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
			'themeEditor.discardMessage' => 'Suas alterações de cor não salvas serão perdidas.',
			'themeEditor.discard' => 'Descartar',
			'themeEditor.previewCardTitle' => ({required Object number}) => 'Episódio ${number}',
			'themeEditor.previewCardSubtitle' => ({required Object minutes}) => '${minutes} min restantes',
			'themeEditor.previewSwitch' => 'Reprodução automática',
			'themeEditor.previewMutedText' => 'O texto secundário fica assim',
			'themeEditor.themeSystemDescription' => 'Siga a aparência do seu dispositivo e mude entre luz e escuro automaticamente.',
			'themeEditor.themeLightDescription' => 'Use um fundo brilhante com texto escuro.',
			'themeEditor.themeDarkDescription' => 'Use um fundo escuro com texto claro.',
			'themeEditor.themeOledDescription' => 'Use superfícies preto que reduzem a luz nas telas OLED.',
			'themeEditor.themeEmberDescription' => 'Use cores de acento amarelo e vermelho quente.',
			'themeEditor.themeGlacierDescription' => 'Use cores de acento azul fresco.',
			'themeEditor.themeForestDescription' => 'Use cores de acento verde e natural.',
			'themeEditor.themePlumDescription' => 'Use cores de acento violeta e pluma.',
			'themeEditor.themePaperDescription' => 'Use superfícies de papel quentes e cores inspiradas em tinta.',
			'themeEditor.themeCustomDescription' => 'Use a paleta de cores que você criou no editor de tema personalizado.',
			'themeEditor.editorDescription' => 'Escolha uma cor de paleta, ajuste a sua soma, saturação, brilho ou opacidade e veja a atualização prévia antes de economizar.',
			'search.hint' => 'Buscar filmes, séries, músicas...',
			'search.tryDifferentTerm' => 'Tente um termo de busca diferente',
			'search.searchYourMedia' => 'Buscar suas mídias',
			'search.enterTitleActorOrKeyword' => 'Insira um título, ator ou palavra-chave',
			'search.people' => 'Pessoas',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'Definir Atalho para ${actionName}',
			'hotkeys.clearShortcut' => 'Limpar atalho',
			'hotkeys.noShortcutSet' => 'Nenhum atalho definido',
			'hotkeys.currentShortcut' => 'Atalho atual:',
			'hotkeys.pressToRecord' => 'Selecionar para gravar um atalho',
			'hotkeys.recordingShortcut' => 'Pressione o atalho agora',
			'hotkeys.actions.playPause' => 'Reproduzir/Pausar',
			'hotkeys.actions.volumeUp' => 'Aumentar Volume',
			'hotkeys.actions.volumeDown' => 'Diminuir Volume',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'Avançar (${seconds}s)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'Retroceder (${seconds}s)',
			'hotkeys.actions.fullscreenToggle' => 'Alternar Tela Cheia',
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
			'hotkeys.actions.speedReset' => 'Redefinir Velocidade',
			'hotkeys.actions.zoomIn' => 'Aumentar zoom',
			'hotkeys.actions.zoomOut' => 'Diminuir zoom',
			'hotkeys.actions.zoomReset' => 'Redefinir zoom',
			'hotkeys.actions.subSeekNext' => 'Ir para Próxima Legenda',
			'hotkeys.actions.subSeekPrev' => 'Ir para Legenda Anterior',
			'hotkeys.actions.subtitleDelayIncrease' => 'Atrasar Legendas',
			'hotkeys.actions.subtitleDelayDecrease' => 'Adiantar Legendas',
			'hotkeys.actions.shaderToggle' => 'Alternar Shaders',
			'hotkeys.actions.skipMarker' => 'Pular introdução/créditos',
			'hotkeys.actions.screenshot' => 'Capturar tela',
			'hotkeys.actions.framePrevious' => 'Anterior Frame',
			'hotkeys.actions.frameNext' => 'Próximo Frame',
			'fileInfo.title' => 'Informações do arquivo',
			'fileInfo.overview' => 'Visão geral',
			'fileInfo.video' => 'Vídeo',
			'fileInfo.audio' => 'Áudio',
			'fileInfo.subtitles' => 'Legendas',
			'fileInfo.images' => 'Imagens incorporadas',
			'fileInfo.dataStreams' => 'Fluxos de dados',
			'fileInfo.lyrics' => 'Letras',
			'fileInfo.file' => 'Arquivo',
			'fileInfo.attachments' => 'Anexos',
			'fileInfo.delivery' => 'Entrega',
			'fileInfo.versionCounter' => ({required Object index, required Object count}) => 'Versão ${index} de ${count}',
			'fileInfo.fileCounter' => ({required Object index, required Object count}) => 'Arquivo ${index} de ${count}',
			'fileInfo.noStreams' => 'O servidor não relatou fluxos para este arquivo.',
			'fileInfo.copyPath' => 'Copiar caminho',
			'fileInfo.pathCopied' => 'Caminho do arquivo copiado',
			'fileInfo.codec' => 'Codec',
			'fileInfo.codecTag' => 'Tag do codec',
			'fileInfo.resolution' => 'Resolução',
			'fileInfo.codedResolution' => 'Resolução codificada',
			'fileInfo.bitrate' => 'Taxa de bits',
			'fileInfo.frameRate' => 'Taxa de Quadros',
			'fileInfo.rotation' => 'Rotação',
			'fileInfo.comment' => 'Comentário',
			'fileInfo.audioDescription' => 'Descrição de áudio',
			'fileInfo.headerCompression' => 'Compactação de cabeçalho',
			'fileInfo.sidecarFile' => 'Arquivo sidecar',
			'fileInfo.transportTimestamp' => 'Carimbo de transporte',
			'fileInfo.displayOffset' => 'Deslocamento de exibição',
			'fileInfo.previewFailureCode' => 'Código de falha da pré-visualização',
			'fileInfo.previewRetries' => 'Tentativas da pré-visualização',
			'fileInfo.aspectRatio' => 'Proporção',
			'fileInfo.pixelAspectRatio' => 'Proporção de aspecto de pixel',
			'fileInfo.profile' => 'Perfil',
			'fileInfo.level' => 'Nível',
			'fileInfo.bitDepth' => 'Profundidade de bits',
			'fileInfo.pixelFormat' => 'Formato de pixel',
			'fileInfo.colorSpace' => 'Espaço de Cor',
			'fileInfo.colorRange' => 'Faixa de Cor',
			'fileInfo.colorPrimaries' => 'Primárias de Cor',
			'fileInfo.colorTransfer' => 'Transferência de cor',
			'fileInfo.chromaSubsampling' => 'Subamostragem de Croma',
			'fileInfo.chromaLocation' => 'Localização do croma',
			'fileInfo.scanType' => 'Tipo de varredura',
			'fileInfo.interlaced' => 'Entrelaçado',
			'fileInfo.anamorphic' => 'Anamórfico',
			'fileInfo.referenceFrames' => 'Quadros de referência',
			'fileInfo.dynamicRange' => 'Faixa dinâmica',
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
			'fileInfo.provider' => 'Provedor',
			'fileInfo.matchScore' => 'Pontuação de correspondência',
			'fileInfo.externalDelivery' => 'Pode ser servido separadamente',
			'fileInfo.sidecarPath' => 'Caminho do sidecar',
			'fileInfo.sourceStream' => 'Copiado de',
			'fileInfo.temporary' => 'Temporário',
			'fileInfo.timeBase' => 'Base de tempo',
			'fileInfo.overallBitrate' => 'Taxa de bits total',
			'fileInfo.path' => 'Caminho',
			'fileInfo.fileName' => 'Nome do arquivo',
			'fileInfo.size' => 'Tamanho',
			'fileInfo.totalSize' => 'Tamanho total',
			'fileInfo.container' => 'Contêiner',
			'fileInfo.duration' => 'Duração',
			'fileInfo.previewThumbnails' => 'Miniaturas de pré-visualização',
			'fileInfo.previewIndex' => 'Índice de pré-visualização',
			'fileInfo.packetLength' => 'Tamanho do pacote',
			'fileInfo.filePresent' => 'Arquivo presente',
			'fileInfo.fileReadable' => 'Legível pelo servidor',
			'fileInfo.streamPath' => 'Caminho do fluxo',
			'fileInfo.optimizedForStreaming' => 'Otimizado para transmissão',
			'fileInfo.has64bitOffsets' => 'Deslocamentos de 64 bits',
			'fileInfo.protocol' => 'Protocolo',
			'fileInfo.mediaType' => 'Tipo de mídia',
			'fileInfo.sourceKind' => 'Tipo de origem',
			'fileInfo.optimizedVersion' => 'Versão otimizada',
			'fileInfo.optimizationTarget' => 'Alvo de otimização',
			'fileInfo.deletedAt' => 'Excluído',
			'fileInfo.remoteSource' => 'Origem remota',
			'fileInfo.infiniteStream' => 'Fluxo infinito',
			'fileInfo.directPlay' => 'Reprodução direta',
			'fileInfo.directStream' => 'Fluxo direto',
			'fileInfo.transcoding' => 'Transcodificação',
			'fileInfo.etag' => 'ETag',
			'fileInfo.versionId' => 'ID da versão',
			'fileInfo.fileId' => 'ID do arquivo',
			'fileInfo.defaultAudioTrack' => 'Faixa de áudio padrão',
			'fileInfo.defaultSubtitleTrack' => 'Faixa de legenda padrão',
			'fileInfo.subtitlesOff' => 'Desativadas',
			'fileInfo.flagDefault' => 'Padrão',
			'fileInfo.flagForced' => 'Forçada',
			'fileInfo.flagSelected' => 'Selecionada',
			'fileInfo.flagExternal' => 'Externa',
			'fileInfo.flagHearingImpaired' => 'Deficiência auditiva',
			'fileInfo.flagDub' => 'Dublada',
			'fileInfo.flagOriginal' => 'Original',
			'fileInfo.channelsMono' => 'Mono',
			'fileInfo.dolbyVisionProfile' => ({required Object profile}) => 'Perfil ${profile}',
			'mediaMenu.markAsWatched' => 'Marcar como Assistido',
			'mediaMenu.markAsUnwatched' => 'Marcar como Não Assistido',
			'mediaMenu.removeFromContinueWatching' => 'Remover de Continuar Assistindo',
			'mediaMenu.viewDetails' => 'Ver detalhes',
			'mediaMenu.goToSeries' => 'Ir para a série',
			'mediaMenu.shufflePlay' => 'Reprodução Aleatória',
			'mediaMenu.shuffleNotAvailableOffline' => 'Reprodução aleatória indisponível offline',
			'mediaMenu.fileInfo' => 'Informações do arquivo',
			'mediaMenu.deleteEpisodeFromServer' => 'Excluir episódio do servidor',
			'mediaMenu.deleteSeasonFromServer' => 'Excluir temporada do servidor',
			'mediaMenu.deleteShowFromServer' => 'Excluir série do servidor',
			'mediaMenu.deleteMovieFromServer' => 'Excluir filme do servidor',
			'mediaMenu.deleteEpisodeTitle' => 'Excluir este episódio?',
			'mediaMenu.deleteSeasonTitle' => 'Excluir esta temporada?',
			'mediaMenu.deleteShowTitle' => 'Excluir esta série?',
			'mediaMenu.deleteMovieTitle' => 'Excluir este filme?',
			'mediaMenu.deleteEpisodeConfirm' => 'Excluir episódio',
			'mediaMenu.deleteSeasonConfirm' => 'Excluir temporada',
			'mediaMenu.deleteShowConfirm' => 'Excluir série',
			'mediaMenu.deleteMovieConfirm' => 'Excluir filme',
			'mediaMenu.deleteAnyway' => 'Excluir mesmo assim',
			'mediaMenu.confirmDeleteTarget' => ({required Object title}) => 'Excluir permanentemente ${title} do seu servidor?',
			'mediaMenu.deleteMultipleWarning' => 'Isso inclui todos os episódios e seus arquivos.',
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: 'Isso exclui o ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episódio e o arquivo dele.', other: 'Isso exclui todos os ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episódios e os arquivos deles.', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: 'Este item está armazenado como ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} arquivo, que será excluído.', other: 'Este item está armazenado em ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} arquivos, e todos eles serão excluídos.', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: 'Mais ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episódio está armazenado no mesmo arquivo e também será excluído:', other: 'Mais ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episódios estão armazenados no mesmo arquivo e também serão excluídos:', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'O PlezyNG não conseguiu verificar quais arquivos serão removidos, então pode excluir mais do que o item acima. Cancele e tente novamente, ou exclua mesmo assim.',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'Seu servidor não forneceu detalhes do arquivo para este item, então o PlezyNG não pode verificar quais arquivos serão removidos. Pode excluir mais do que o item acima.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Item de mídia excluído com sucesso',
			'mediaMenu.mediaFailedToDelete' => 'Falha ao excluir item de mídia',
			'mediaMenu.rate' => 'Avaliar',
			'mediaMenu.playFromBeginning' => 'Reproduzir do início',
			'mediaMenu.playVersion' => 'Reproduzir versão...',
			'rateSheet.title' => 'Avaliar',
			'rateSheet.server' => 'Servidor',
			'rateSheet.favorite' => 'Favorito',
			'rateSheet.favorited' => 'Adicionado aos favoritos',
			'rateSheet.saved' => 'Salvo',
			'rateSheet.notAvailable' => 'Nenhuma correspondência encontrada',
			'rateSheet.noConnectedServices' => 'Conecte um serviço nas Configurações para avaliar por lá.',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, filme',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, série de TV',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'assistido',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} por cento assistido',
			'accessibility.mediaCardUnwatched' => 'não assistido',
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
			'accessibility.autoScrollPlay' => 'Iniciar rolagem automática',
			'accessibility.autoScrollPause' => 'Pausar rolagem automática',
			'accessibility.hueShort' => 'M',
			'accessibility.saturationShort' => 'S',
			'accessibility.valueShort' => 'V',
			'accessibility.red' => 'vermelho',
			'accessibility.green' => 'Verde',
			'accessibility.blue' => 'azul',
			'accessibility.redShort' => 'R',
			'accessibility.greenShort' => 'G',
			'accessibility.blueShort' => 'B',
			'accessibility.colorModeHsv' => 'HSV',
			'accessibility.colorModeRgb' => 'RGB',
			'accessibility.title' => 'Acessibilidade',
			'accessibility.summary' => 'Texto, contraste, movimento e controlos',
			'accessibility.systemHint' => 'As configurações de acessibilidade do seu dispositivo sempre se aplicam. Estas opções adicionam ajustes ao longo de PlezyNG.',
			'accessibility.readability' => 'Leitura e visibilidade',
			'accessibility.textSize' => 'Tamanho de texto adicional',
			'accessibility.preview' => 'Encontre sua próxima história. leia, ouça e assiste a seu próprio ritmo.',
			'accessibility.boldText' => 'Interface de texto',
			'accessibility.highContrast' => 'Contraste elevado',
			'accessibility.highContrastHint' => 'Texto mais forte, desenhos e indicadores de foco em superfícies claras ou escuras.',
			'accessibility.interaction' => 'Moção e Interação',
			'accessibility.reduceMotion' => 'Reduzir a movimentação',
			'accessibility.reduceMotionHint' => 'Parar as animações do indicador de foco, as transições de página e os efeitos decorativos.',
			'accessibility.largeTargets' => 'Objetivos de toque mais grandes',
			'accessibility.largeTargetsHint' => 'Dê controles compartilhados mais espaço para toque e navegação assistiva.',
			'accessibility.navigationHint' => 'Use Tab e Shift+Tab para navegar entre os controles, Enter ou a barra de espaço para ativar e Escape ou Voltar para fechar. O zoom e as preferências de leitura ficam disponíveis quando um livro está aberto.',
			'accessibility.textSizeDescription' => 'Escala o texto de interface em PlezyNG, além da configuração do tamanho de texto do sistema do seu dispositivo.',
			'accessibility.boldTextHint' => 'Use um peso mais pesado para etiquetas de interface e mensagens para torná-los mais fáceis de distinguir.',
			'tooltips.shufflePlay' => 'Reprodução aleatória',
			'tooltips.playTrailer' => 'Reproduzir trailer',
			'tooltips.markAsWatched' => 'Marcar como assistido',
			'tooltips.markAsUnwatched' => 'Marcar como não assistido',
			'audioTracks.track' => ({required Object n}) => 'Faixa de áudio ${n}',
			'videoControls.audioLabel' => 'Áudio',
			'videoControls.subtitlesLabel' => 'Legendas',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.letterbox' => 'Letterbox',
			'videoControls.fillScreen' => 'Preencher tela',
			'videoControls.stretch' => 'Esticar',
			'videoControls.lockRotation' => 'Travar rotação',
			'videoControls.unlockRotation' => 'Destravar rotação',
			'videoControls.timerActive' => 'Temporizador ativo',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'A reprodução pausará em ${duration}',
			'videoControls.sleepTimerEndOfVideo' => 'Fim do vídeo atual',
			'videoControls.sleepTimerStopAtHeader' => 'Parar em',
			'videoControls.sleepTimerDurationHeader' => 'Temporizador',
			'videoControls.playbackWillPauseAtEnd' => 'A reprodução pausará no final deste vídeo',
			'videoControls.stillWatching' => 'Ainda assistindo?',
			'videoControls.pausingIn' => ({required Object seconds}) => 'Pausando em ${seconds}s',
			'videoControls.continueWatching' => 'Continuar',
			'videoControls.autoPlayNext' => 'Reproduzir Próximo Automaticamente',
			'videoControls.playNext' => 'Reproduzir Próximo',
			'videoControls.playButton' => 'Reproduzir',
			'videoControls.pauseButton' => 'Pausar',
			'videoControls.playbackPaused' => 'Pausado',
			'videoControls.playbackResumed' => 'Reproduzindo',
			'videoControls.loadingVideo' => 'Carregando vídeo',
			'videoControls.showPlaybackControls' => 'Mostrar controles de reprodução',
			'videoControls.hidePlaybackControls' => 'Ocultar controles de reprodução',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'Retroceder ${seconds} segundos',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'Avançar ${seconds} segundos',
			'videoControls.previousButton' => 'Episódio anterior',
			'videoControls.nextButton' => 'Próximo episódio',
			'videoControls.previousChapterButton' => 'Capítulo anterior',
			'videoControls.nextChapterButton' => 'Próximo capítulo',
			'videoControls.muteButton' => 'Silenciar',
			'videoControls.unmuteButton' => 'Ativar som',
			'videoControls.settingsButton' => 'Configurações de reprodução',
			'videoControls.tracksButton' => 'Áudio e legendas',
			'videoControls.chaptersButton' => 'Capítulos',
			'videoControls.segmentLoopHelp' => 'Faça uma seção durante este playback. Configura A, depois confira B mais tarde na linha de tempo.',
			'videoControls.setLoopStart' => 'Começando com o gênero (A)',
			'videoControls.setLoopEnd' => 'Coloque o fim do loop (B)',
			'videoControls.clearSegmentLoop' => 'Clareamento de segmento',
			'videoControls.setLoopStartFirst' => 'Coloque o início (A) antes do fim (B).',
			'videoControls.loopEndAfterStart' => 'O final da curva deve ser mais tarde do que o início.',
			'videoControls.segmentLoopUnavailable' => 'Segment looping não está disponível para este playback.',
			'videoControls.loopPointNotSet' => 'Não estabelece',
			'videoControls.bookmarksHelp' => 'As notas são salvas neste dispositivo. selecione uma para ir a esse tempo.',
			'videoControls.bookmarksButton' => 'Bookmarcação',
			'videoControls.chaptersAndBookmarks' => 'Capítulos e Bookmarks',
			'videoControls.segmentLoop' => 'Segmentação Loop',
			'videoControls.addBookmark' => 'Adicionar Bookmark',
			'videoControls.bookmarkName' => 'Nome do Bookmark',
			_ => null,
		} ?? switch (path) {
			'videoControls.bookmarkNameHint' => 'Por exemplo, a cena de abertura',
			'videoControls.bookmarkDefaultName' => ({required Object n}) => 'Bookmarcação ${n}',
			'videoControls.bookmarkNameRequired' => 'Digite um nome para este livro.',
			'videoControls.deleteBookmark' => 'Eliminar o Bookmark',
			'videoControls.bookmarkLimitReached' => 'Este item já tem 100 bookmarks.',
			'videoControls.bookmarkUnavailable' => 'Não podia salvar ou remover este bookmark.',
			'videoControls.bookmarkSaved' => 'Bookmark foi salvo.',
			'videoControls.bookmarkDeleted' => 'Bookmark foi apagado.',
			'videoControls.loopPointSet' => ({required Object point, required Object time}) => 'Ponto de Loop ${point} Estabelecendo em ${time}.',
			'videoControls.noChaptersOrBookmarks' => 'Não há capítulos ou livros disponíveis.',
			'videoControls.versionQualityButton' => 'Versão e qualidade',
			'videoControls.versionColumnHeader' => 'Versão',
			'videoControls.qualityColumnHeader' => 'Qualidade',
			'videoControls.qualityOriginal' => 'Original',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => 'Transcodificação indisponível — reproduzindo qualidade original',
			'videoControls.subtitleUnavailableFallback' => 'Não foi possível carregar as legendas selecionadas — a reprodução continuará sem legendas',
			'videoControls.pipButton' => 'Modo Picture-in-Picture',
			'videoControls.aspectRatioButton' => 'Proporção',
			'videoControls.ambientLighting' => 'Iluminação ambiente',
			'videoControls.fullscreenButton' => 'Entrar em tela cheia',
			'videoControls.exitFullscreenButton' => 'Sair da tela cheia',
			'videoControls.alwaysOnTopButton' => 'Sempre no topo',
			'videoControls.rotationLockButton' => 'Travar rotação',
			'videoControls.lockScreen' => 'Travar tela',
			'videoControls.screenLockButton' => 'Travar tela',
			'videoControls.timelineSlider' => 'Linha do tempo do vídeo',
			'videoControls.volumeSlider' => 'Nível de volume',
			'videoControls.endsAt' => ({required Object time}) => 'Termina às ${time}',
			'videoControls.pipActive' => 'Reproduzindo em Picture-in-Picture',
			'videoControls.pipFailed' => 'Falha ao iniciar picture-in-picture',
			'videoControls.screenshotSaved' => 'Captura de tela salva',
			'videoControls.screenshotFailed' => 'Não foi possível fazer a captura de tela',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Zoom ${percent}%',
			'videoControls.volumePercent' => ({required Object percent}) => 'Volume ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'Requer Android 8.0 ou superior',
			'videoControls.pipErrors.iosVersion' => 'Requer iOS 15.0 ou superior',
			'videoControls.pipErrors.permissionDisabled' => 'Picture-in-picture está desativado. Ative nas configurações do sistema.',
			'videoControls.pipErrors.notSupported' => 'O dispositivo não suporta modo picture-in-picture',
			'videoControls.pipErrors.voSwitchFailed' => 'Falha ao trocar saída de vídeo para picture-in-picture',
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
			'videoControls.subtitleDownloaded' => 'Legenda baixada',
			'videoControls.subtitleDownloadedNotApplied' => 'A legenda foi baixada, mas não foi possível selecioná-la',
			'videoControls.subtitleDownloadFailed' => 'Falha ao baixar legenda',
			'videoControls.searchLanguages' => 'Pesquisar idiomas...',
			'videoControls.skipIntro' => 'Pular abertura',
			'videoControls.skipCredits' => 'Pular créditos',
			'videoControls.nextEpisode' => 'Próximo episódio',
			'videoControls.subtitleTrack' => ({required Object n}) => 'Faixa ${n}',
			'videoControls.subtitleFile' => ({required Object name}) => 'Legenda ${name}',
			'videoControls.forcedTrack' => ({required Object label}) => '${label} (Forçada)',
			'videoControls.osdSubtitlesOff' => 'Legendas: desativadas',
			'videoControls.osdSubtitles' => ({required Object track}) => 'Legendas: ${track}',
			'videoControls.osdAudio' => ({required Object track}) => 'Áudio: ${track}',
			'videoControls.frameCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Conexão', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} quadros', ), 
			'videoControls.trackSelectionTitle' => 'Escolha as faixas antes do playback',
			'videoControls.trackSelectionAuto' => 'Seleção automática',
			'videoControls.openMiniPlayer' => 'Descrição do Mini Player',
			'videoControls.returnToFullPlayer' => 'Voltar para o jogador completo',
			'videoControls.loadSubtitleFile' => 'Carregar o arquivo subtítulo...',
			'videoControls.subtitleLoadFailed' => 'Não conseguiu carregar o arquivo subtítulo',
			'videoControls.skipAds' => 'Escape de anúncios',
			'videoControls.tapToUnlock' => 'Toque para desbloquear',
			'videoControls.tapAgainToUnlock' => 'Toque novamente para desbloquear',
			'messages.markedAsWatched' => 'Marcado como assistido',
			'messages.markedAsUnwatched' => 'Marcado como não assistido',
			'messages.markedAsWatchedOffline' => 'Marcado como assistido (será sincronizado quando online)',
			'messages.markedAsUnwatchedOffline' => 'Marcado como não assistido (será sincronizado quando online)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Removido automaticamente: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: 'Removido automaticamente ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} download assistido', other: 'Removidos automaticamente ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} downloads assistidos', ), 
			'messages.removedFromContinueWatching' => 'Removido de Continuar assistindo',
			'messages.errorLoading' => ({required Object error}) => 'Erro: ${error}',
			'messages.searchPartialResults' => 'Alguns servidores de mídia não puderam ser pesquisados. Exibindo os resultados disponíveis.',
			'messages.streamInterrupted' => 'A transmissão foi interrompida. Pressione reproduzir ou avance para tentar novamente.',
			'messages.liveStreamInterrupted' => 'A transmissão ao vivo foi interrompida. Pressione reproduzir para tentar novamente.',
			'messages.fileInfoNotAvailable' => 'Informações do arquivo não disponíveis',
			'messages.playbackAuthenticationRequired' => 'Entre novamente no servidor de mídia para reproduzir este item.',
			'messages.playbackServerUnavailable' => 'O servidor de mídia está indisponível. Tente novamente mais tarde.',
			'messages.playbackDataInvalid' => 'O servidor retornou informações de reprodução inválidas.',
			'messages.playbackCancelled' => 'A reprodução foi cancelada.',
			'messages.playbackFailed' => 'Não foi possível iniciar a reprodução.',
			'messages.playbackFailedDetail' => ({required Object error}) => 'Não foi possível iniciar a reprodução: ${error}',
			'messages.audioOutputFailed' => 'A saída de áudio parou de responder. Verifique a conexão de áudio da TV ou do receptor; se outros aplicativos também estiverem sem som, reinicie o dispositivo.',
			'messages.mediaUnavailable' => 'Este conteúdo não está mais disponível.',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Erro ao carregar as informações do arquivo: ${error}',
			'messages.errorLoadingSeries' => 'Erro ao carregar série',
			'messages.musicNotSupported' => 'A reprodução de música ainda não é compatível',
			'messages.noDescriptionAvailable' => 'Nenhuma descrição disponível',
			'messages.noProfilesAvailable' => 'Nenhum perfil disponível',
			'messages.contactAdminForProfiles' => 'Entre em contato com o administrador do servidor para adicionar perfis',
			'messages.unableToDetermineLibrarySection' => 'Não foi possível determinar a seção da biblioteca deste item',
			'messages.logsCleared' => 'Logs limpos',
			'messages.logsCopied' => 'Logs copiados para a área de transferência',
			'messages.noLogsAvailable' => 'Nenhum log disponível',
			'messages.libraryScanning' => ({required Object title}) => 'Escaneando "${title}"...',
			'messages.libraryScanStarted' => ({required Object title}) => 'Escaneamento da biblioteca iniciado para "${title}"',
			'messages.libraryScanFailed' => ({required Object error}) => 'Falha ao escanear biblioteca: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => 'Atualizando metadados de "${title}"...',
			'messages.metadataRefreshStarted' => ({required Object title}) => 'Atualização de metadados iniciada para "${title}"',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'Falha ao atualizar metadados: ${error}',
			'messages.logoutConfirm' => 'Tem certeza de que deseja sair?',
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
			'messages.switchingToCompatiblePlayer' => 'Alternando para um reprodutor compatível...',
			'messages.serverLimitTitle' => 'Falha na reprodução',
			'messages.serverLimitBody' => 'Erro do servidor (HTTP 500). Um limite de largura de banda ou transcodificação provavelmente rejeitou esta sessão. Peça ao proprietário do servidor para ajustá-lo.',
			'messages.mediaUnreadableTitle' => 'Arquivo indisponível',
			'messages.mediaUnreadableBody' => 'O servidor encontrou este item, mas não conseguiu ler o arquivo (HTTP 404). O arquivo provavelmente foi movido, excluído ou o armazenamento está offline. Peça ao responsável pelo servidor para verificar o arquivo e reexaminar a biblioteca.',
			'messages.serverBusyTitle' => 'Transmissão indisponível',
			'messages.serverBusyBody' => 'O servidor continuou se recusando a transmitir este arquivo (HTTP 503). Ele pode estar reiniciando ou ocupado, ou o armazenamento do arquivo pode estar offline. Tente novamente em instantes — se isso continuar acontecendo, peça ao proprietário do servidor para verificar o servidor e o armazenamento do arquivo.',
			'messages.playbackNotAllowedTitle' => 'Reprodução não permitida',
			'messages.playbackNotAllowedBody' => 'O servidor se recusou a transmitir este item (HTTP 403). Sua conta pode não ter permissão para reproduzi-lo, ou o servidor pode permitir a reprodução apenas na própria rede local.',
			'messages.logsUploaded' => 'Logs enviados',
			'messages.logsUploadFailed' => 'Falha ao enviar logs',
			'messages.logId' => 'ID do log',
			'messages.burnedSubtitlesUseMenu' => 'As legendas estão incorporadas a esta transmissão. Altere-as no menu de legendas.',
			'messages.noVideoUrl' => 'Nenhuma URL de vídeo disponível',
			'messages.playbackNoMediaSources' => 'O servidor não retornou nenhuma fonte de mídia reproduzível',
			'messages.playbackDataNotPrepared' => 'A reprodução foi iniciada antes que os dados estivessem prontos',
			'messages.streamSelectionUnavailable' => 'A seleção de fluxos não está disponível para esta fonte',
			'messages.streamSelectionFailed' => 'Não foi possível aplicar os fluxos selecionados',
			'messages.trackSelectionNotRemembered' => 'Esta escolha de faixa se aplica apenas à reprodução atual.',
			'messages.serverUnavailableForProfile' => 'Nenhum servidor está disponível para o perfil ativo',
			'subtitlingStyling.previewSample' => 'O rápido fogo marrão salta sobre o cão louco',
			'subtitlingStyling.text' => 'Texto',
			'subtitlingStyling.border' => 'Borda',
			'subtitlingStyling.background' => 'Fundo',
			'subtitlingStyling.fontSize' => 'Tamanho da Fonte',
			'subtitlingStyling.textColor' => 'Cor do Texto',
			'subtitlingStyling.borderSize' => 'Tamanho da Borda',
			'subtitlingStyling.borderColor' => 'Cor da Borda',
			'subtitlingStyling.backgroundOpacity' => 'Opacidade do Fundo',
			'subtitlingStyling.backgroundColor' => 'Cor de Fundo',
			'subtitlingStyling.position' => 'Posição',
			'subtitlingStyling.assOverride' => 'Substituição ASS',
			'subtitlingStyling.overrideScale' => 'Dimensionar',
			'subtitlingStyling.overrideForce' => 'Forçar',
			'subtitlingStyling.overrideStrip' => 'Remover estilo',
			'subtitlingStyling.positionTop' => 'Superior',
			'subtitlingStyling.positionBottom' => 'Inferior',
			'subtitlingStyling.useMargins' => 'Usar margens',
			'subtitlingStyling.useMarginsDescription' => 'Permitir legendas de texto no espaço fora do vídeo. Legendas estilizadas podem manter sua posição original.',
			'subtitlingStyling.anchorToScreen' => 'Ancorar à tela',
			'subtitlingStyling.anchorToScreenDescription' => 'Exibir as legendas de texto nas faixas pretas abaixo de vídeos em tela ampla',
			'subtitlingStyling.bold' => 'Negrito',
			'subtitlingStyling.italic' => 'Itálico',
			'subtitlingStyling.renderResolution' => 'Resolução de renderização',
			'subtitlingStyling.renderResolutionScreen' => 'Resolução da tela',
			'subtitlingStyling.renderResolutionVideo' => 'Resolução do vídeo',
			'subtitlingStyling.fontSizeDescription' => 'Configurar o tamanho do texto subtítulo neste dispositivo.',
			'subtitlingStyling.textColorDescription' => 'Escolha a cor utilizada para o texto subtítulo.',
			'subtitlingStyling.borderSizeDescription' => 'Defina a espessura do outline em torno do texto subtítulo.',
			'subtitlingStyling.borderColorDescription' => 'Escolha a cor utilizada para o subtítulo.',
			'subtitlingStyling.backgroundColorDescription' => 'Escolha a cor por trás do texto subjetivo.',
			'subtitlingStyling.backgroundOpacityDescription' => 'Defina o quão transparente é o fundo do subtítulo: 0% é claro e 100% sólido.',
			'subtitlingStyling.positionDescription' => 'Move os subtítulos verticalmente. 0% é o topo do vídeo e 100% é o fundo.',
			'subtitlingStyling.assOverrideDescription' => 'Escolha se o jogador segue, ajusta, substitui ou remove estilos incorporados em subtítulos ASS.',
			'subtitlingStyling.assOverrideOptions.no' => 'Mantenha as letras, cores, tamanhos e colocações escritas no arquivo subtítulo.',
			'subtitlingStyling.assOverrideOptions.yes' => 'Permitir que as configurações de estilo do subtitulo do jogador ajustem os subtitulos ASS.',
			'subtitlingStyling.assOverrideOptions.scale' => 'Aplique o estilo do jogador e a escala de tamanhos incorporados para corresponder às dimensões do vídeo.',
			'subtitlingStyling.assOverrideOptions.force' => 'Substituir os estilos ASS incorporados com o estilo subtítulo do jogador.',
			'subtitlingStyling.assOverrideOptions.strip' => 'Remova o formato ASS incorporado e faça o texto sub-título claramente.',
			'subtitlingStyling.renderResolutionDescription' => 'Escolha a resolução usada para rasterizar imagens e subtítulos ASS. Escalas Android inferiores podem reduzir o trabalho de renderização, mas parecem mais suaves.',
			'subtitlingStyling.renderResolutionOptions.screen' => 'Render na resolução de superfície da tela completa para o resultado mais agudo.',
			'subtitlingStyling.renderResolutionOptions.video' => 'Render usando a resolução de vídeo como referência, o que pode reduzir o trabalho em telas de alta resolução.',
			'subtitlingStyling.renderResolutionOptions.threeQuarter' => 'Render em 75% da resolução de superfície do ecrã para uma poupança modesta de desempenho.',
			'subtitlingStyling.renderResolutionOptions.half' => 'Render a 50% da resolução de superfície do ecrã para reduzir o trabalho, com bordas mais suaves.',
			'subtitlingStyling.renderResolutionOptions.third' => 'Render em um terço da resolução de superfície do ecrã para reduzir o trabalho, com bordas mais suaves.',
			'subtitlingStyling.renderResolutionOptions.quarter' => 'Render a um quarto da resolução de superfície do ecrã para reduzir o trabalho, com o resultado mais suave.',
			'subtitlingStyling.boldDescription' => 'Desenhe texto subtítulo em um peso mais pesado.',
			'subtitlingStyling.italicDescription' => 'Desenho de subtitulo em italiano.',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => 'Configurações avançadas do reprodutor de vídeo',
			'mpvConfig.presets' => 'Predefinições',
			'mpvConfig.noPresets' => 'Nenhuma predefinição salva',
			'mpvConfig.saveAsPreset' => 'Salvar como Predefinição...',
			'mpvConfig.presetName' => 'Nome da Predefinição',
			'mpvConfig.presetNameHint' => 'Insira um nome para esta predefinição',
			'mpvConfig.loadPreset' => 'Carregar',
			'mpvConfig.deletePreset' => 'Excluir',
			'mpvConfig.presetSaved' => 'Predefinição salva',
			'mpvConfig.presetLoaded' => 'Predefinição carregada',
			'mpvConfig.presetDeleted' => 'Predefinição excluída',
			'mpvConfig.confirmDeletePreset' => 'Tem certeza de que deseja excluir esta predefinição?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan\nhwdec=auto\n# comment',
			'mpvConfig.lineHint' => 'option=value',
			'mpvConfig.addLine' => 'Adicionar linha',
			'mpvConfig.removeLine' => 'Remover linha',
			'mpvConfig.embeddedVoHint' => 'vo, gpu-context e gpu-api são ignorados no Linux: o vídeo incorporado é sempre renderizado via vo=libmpv no plano de vídeo, e gpu-next (necessário para shaders de computação como ArtCNN) não pode ser executado incorporado.',
			'dialog.confirmAction' => 'Confirmar Ação',
			'profiles.addPlezyProfile' => 'Adicionar perfil PlezyNG',
			'profiles.switchingProfile' => 'Mudando perfil…',
			'profiles.deleteThisProfileTitle' => 'Excluir este perfil?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => 'Remover ${displayName}. As conexões não serão afetadas.',
			'profiles.active' => 'Ativo',
			'profiles.manage' => 'Gerenciar',
			'profiles.delete' => 'Excluir',
			'profiles.signOut' => 'Sair',
			'profiles.signOutPlexTitle' => 'Sair do Plex?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => 'Remover ${displayName} e todos os usuários do Plex Home? Você pode entrar novamente quando quiser.',
			'profiles.signOutPlexDeleteDownloads' => 'Também excluir downloads',
			'profiles.signOutPlexDeleteDownloadsDescription' => 'Caso contrário, eles permanecem neste dispositivo e voltam quando você entrar novamente nesta conta.',
			'profiles.signedOutPlex' => 'Saiu do Plex.',
			'profiles.signOutFailed' => 'Falha ao sair.',
			'profiles.sectionTitle' => 'Perfis',
			'profiles.summarySingle' => 'Adicione perfis para combinar usuários gerenciados e identidades locais',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} perfis · ativo: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} perfis',
			'profiles.removeConnectionTitle' => 'Remover conexão?',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => 'Remover acesso de ${displayName} a ${connectionLabel}. Outros perfis mantêm o acesso.',
			'profiles.deleteProfileTitle' => 'Excluir perfil?',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => 'Remover ${displayName} e suas conexões. Servidores continuam disponíveis.',
			'profiles.profileNameLabel' => 'Nome do perfil',
			'profiles.pinProtectionLabel' => 'Proteção por PIN',
			'profiles.copyAutomationLink' => 'Copia Android link de automação',
			'profiles.copyAutomationLinkDescription' => 'Selecione este perfil de uma intenção ou automação Android. verificações de PIN do perfil ainda se aplicam.',
			'profiles.automationLinkCopied' => 'O link de automação do perfil é copiado.',
			'profiles.pinManagedByPlex' => 'PIN gerenciado pelo Plex. Edite em plex.tv.',
			'profiles.noPinSetEditOnPlex' => 'Nenhum PIN definido. Para exigir um, edite o usuário do Plex Home em plex.tv.',
			'profiles.setPin' => 'Definir PIN',
			'profiles.setPinTitle' => 'Definir PIN',
			'profiles.confirmPinTitle' => 'Confirmar PIN',
			'profiles.pinSet' => 'PIN definido',
			'profiles.changePin' => 'Alterar',
			'profiles.removePin' => 'Remover',
			'profiles.connectionsLabel' => 'Conexões',
			'profiles.add' => 'Adicionar',
			'profiles.deleteProfileButton' => 'Excluir perfil',
			'profiles.noConnectionsHint' => 'Sem conexões — adicione uma para usar este perfil.',
			'profiles.noConnections' => 'Sem conexões',
			'profiles.plexHomeAccount' => 'Conta Plex Home',
			'profiles.plexAccountChip' => ({required Object account}) => 'Conta Plex: ${account}',
			'profiles.plexAccountUserChip' => ({required Object user, required Object account}) => '${user} via ${account}',
			'profiles.connectionDefault' => 'Padrão',
			'profiles.connectionAs' => ({required Object displayName}) => 'como ${displayName}',
			'profiles.makeDefault' => 'Definir como padrão',
			'profiles.removeConnection' => 'Remover',
			'profiles.profileRenamed' => 'Perfil renomeado.',
			'profiles.borrowAddTo' => ({required Object displayName}) => 'Adicionar a ${displayName}',
			'profiles.borrowExplain' => 'Use a conexão de outro perfil. Perfis protegidos por PIN exigem PIN.',
			'profiles.borrowEmpty' => 'Nenhuma conexão disponível ainda.',
			'profiles.borrowEmptySubtitle' => 'Conecte Plex, Jellyfin ou Emby a outro perfil primeiro.',
			'profiles.borrowLoadFailed' => 'Não foi possível carregar as conexões disponíveis. Tente novamente.',
			'profiles.borrowFromProfile' => ({required Object displayName}) => 'De ${displayName}',
			'profiles.borrowConnectionBorrowed' => 'Conexão adicionada ao perfil.',
			'profiles.borrowFailed' => 'Não foi possível adicionar a conexão.',
			'profiles.incorrectPin' => 'PIN incorreto.',
			'profiles.incorrectPinTryAgain' => 'PIN incorreto. Tente novamente.',
			'profiles.sourceProfileMissingParentAccount' => 'O perfil de origem não tem a conta principal.',
			'profiles.failedToLoadHomeUsers' => 'Não foi possível carregar os usuários do Plex Home. Verifique sua conexão e tente novamente.',
			'profiles.failedToVerifyPin' => 'Não foi possível verificar o PIN.',
			'profiles.newProfile' => 'Novo perfil',
			'profiles.profileNameHint' => 'Ex.: Visitantes, Crianças, Sala de família',
			'profiles.pinProtectionOptional' => 'Proteção por PIN (opcional)',
			'profiles.pinExplain' => 'PIN de 4 dígitos necessário para trocar perfis.',
			'profiles.continueButton' => 'Continuar',
			'profiles.pinsDontMatch' => 'Os PINs não correspondem',
			'profiles.tokenIdentityMismatch' => 'O token do perfil do Plex foi associado a um servidor inesperado',
			'profiles.settingsLocked' => 'As configurações estão bloqueadas para este perfil.',
			'profiles.unlockSettings' => 'Desbloquear configurações',
			'profiles.showExploreForProfile' => 'Mostrar Explore para este perfil',
			'profiles.showExploreForProfileDescription' => 'Desligue para remover Explore da navegação deste perfil.',
			'connections.sectionTitle' => 'Conexões',
			'connections.addConnection' => 'Adicionar conexão',
			'connections.addConnectionSubtitleNoProfile' => 'Entre com Plex ou conecte um servidor Jellyfin ou Emby',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'Adicionar a ${displayName}: Plex, Jellyfin, Emby ou outra conexão de perfil',
			'connections.sessionExpiredOne' => ({required Object name}) => 'Sessão de ${name} expirada',
			'connections.sessionExpiredMany' => ({required Object count}) => 'Sessões expiradas em ${count} servidores',
			'connections.accessDeniedOne' => ({required Object name}) => '${name} negou acesso a esta conta',
			'connections.accessDeniedMany' => ({required Object count}) => '${count} servidores negaram acesso a esta conta',
			'connections.signInAgain' => 'Entrar novamente',
			'connections.editMediaBrowserTitle' => ({required Object product}) => 'Editar conexão do ${product}',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => 'Adicione ou remova URLs para ${serverName}. O PlezyNG usará a URL acessível com menor latência.',
			'accountPreferences.sectionTitle' => 'Preferências da conta',
			'accountPreferences.hubSubtitleSingle' => ({required Object account}) => 'Opções de áudio, legendas e biblioteca salvas em ${account}',
			'accountPreferences.hubSubtitleMultiple' => ({required Object count}) => 'Opções de áudio, legendas e biblioteca salvas em ${count} contas',
			'accountPreferences.pickAccount' => 'Cada conta armazena suas próprias preferências. Escolha a que deseja editar.',
			'accountPreferences.storedOnAccount' => 'Estas opções são salvas na própria conta, então todos os apps conectados a ela as utilizam — inclusive o PlezyNG nos seus outros dispositivos.',
			'accountPreferences.noAccounts' => 'Nenhuma conta para configurar',
			'accountPreferences.noAccountsHint' => 'Entre no Plex ou conecte um servidor Jellyfin ou Emby, e as preferências armazenadas nessa conta aparecerão aqui.',
			'accountPreferences.unavailable' => 'Não foi possível acessar esta conta',
			'accountPreferences.loadFailed' => 'Não foi possível carregar estas preferências',
			'accountPreferences.noPreference' => 'Sem preferência',
			'accountPreferences.notSet' => 'Não definido',
			'accountPreferences.groups.audioAndSubtitles' => 'Áudio e legendas',
			'accountPreferences.groups.libraryDisplay' => 'Biblioteca',
			'accountPreferences.groups.personalMedia' => 'Mídia pessoal',
			'accountPreferences.preferredAudioLanguage' => 'Idioma de áudio preferido',
			'accountPreferences.autoSelectAudio' => 'Escolher áudio pelo idioma',
			'accountPreferences.autoSelectAudioDescription' => 'Desativado mantém a faixa de áudio que o arquivo marca como padrão.',
			'accountPreferences.preferredSubtitleLanguage' => 'Idioma de legenda preferido',
			'accountPreferences.subtitleMode' => 'Ativar legendas',
			'accountPreferences.subtitleModes.none' => 'Seleção manual',
			'accountPreferences.subtitleModes.noneDescription' => 'Nunca ativar legendas por conta própria.',
			'accountPreferences.subtitleModes.defaultMode' => 'Seguir as marcações da faixa',
			'accountPreferences.subtitleModes.defaultModeDescription' => 'Usar as marcações padrão e forçada armazenadas em cada faixa de legenda.',
			'accountPreferences.subtitleModes.always' => 'Sempre ativado',
			'accountPreferences.subtitleModes.alwaysDescription' => 'Ativar uma faixa de legenda no idioma preferido sempre que houver uma.',
			'accountPreferences.subtitleModes.onlyForced' => 'Apenas legendas forçadas',
			'accountPreferences.subtitleModes.onlyForcedDescription' => 'Carregar apenas as faixas marcadas como forçadas.',
			'accountPreferences.subtitleModes.smart' => 'Exibir com áudio estrangeiro',
			'accountPreferences.subtitleModes.smartDescription' => 'Ativar legendas apenas quando o áudio estiver em outro idioma.',
			'accountPreferences.subtitleAccessibility' => 'Legendas SDH',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdh' => 'Preferir legendas não SDH',
			'accountPreferences.subtitleAccessibilityOptions.preferSdh' => 'Preferir legendas SDH',
			'accountPreferences.subtitleAccessibilityOptions.onlySdh' => 'Apenas legendas SDH',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdh' => 'Apenas legendas não SDH',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdhDescription' => 'Preferir subtitulos padrão quando as versões padrão e SDH estão disponíveis.',
			'accountPreferences.subtitleAccessibilityOptions.preferSdhDescription' => 'Prefira subtitulos SDH quando disponíveis, mas permite subtitulares padrão como um retrocesso.',
			'accountPreferences.subtitleAccessibilityOptions.onlySdhDescription' => 'Use apenas subtítulos SDH; não caia de volta aos subtitulos padrão.',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdhDescription' => 'Use apenas subtítulos padrão; exclui subtítos SDH.',
			'accountPreferences.forcedSubtitles' => 'Legendas forçadas',
			'accountPreferences.forcedSubtitleOptions.preferNonForced' => 'Preferir legendas não forçadas',
			'accountPreferences.forcedSubtitleOptions.preferForced' => 'Preferir legendas forçadas',
			'accountPreferences.forcedSubtitleOptions.onlyForced' => 'Apenas legendas forçadas',
			'accountPreferences.forcedSubtitleOptions.onlyNonForced' => 'Apenas legendas não forçadas',
			'accountPreferences.forcedSubtitleOptions.preferNonForcedDescription' => 'Prefere subtitulos regulares, mas permite pistas forçadas como uma queda.',
			'accountPreferences.forcedSubtitleOptions.preferForcedDescription' => 'Prefere pistas forçadas quando disponíveis, mas permite subtitulos regulares como uma queda.',
			'accountPreferences.forcedSubtitleOptions.onlyForcedDescription' => 'Utilize apenas traços marcados como forçados.',
			'accountPreferences.forcedSubtitleOptions.onlyNonForcedDescription' => 'Exclude os traços marcados como forçados.',
			'accountPreferences.displayMissingEpisodes' => 'Mostrar episódios ausentes',
			'accountPreferences.displayMissingEpisodesDescription' => 'Listar episódios que o servidor conhece, mas para os quais não há arquivo.',
			'accountPreferences.hidePlayedInLatest' => 'Ocultar itens assistidos em Recentes',
			'accountPreferences.hidePlayedInLatestDescription' => 'Manter fora das linhas Recentes do servidor os itens que você já assistiu.',
			'accountPreferences.displayCollectionsView' => 'Mostrar a visualização de Coleções',
			'accountPreferences.displayCollectionsViewDescription' => 'Oferecer a visualização de Coleções do servidor junto às suas bibliotecas.',
			'accountPreferences.rewatchingInNextUp' => 'Manter séries reassistidas em A seguir',
			'accountPreferences.rewatchingInNextUpDescription' => 'Ao terminar uma série, comece a assistir de novo e A seguir acompanha a reexibição em vez de remover a série.',
			'accountPreferences.watchedIndicator' => 'Indicadores de assistido',
			'accountPreferences.watchedIndicatorOptions.none' => 'Nunca',
			'accountPreferences.watchedIndicatorOptions.moviesAndShows' => 'Filmes e séries de TV',
			'accountPreferences.watchedIndicatorOptions.movies' => 'Apenas filmes',
			'accountPreferences.watchedIndicatorOptions.shows' => 'Apenas séries de TV',
			'accountPreferences.watchedIndicatorOptions.noneDescription' => 'Não mostre sinais de verificação observados.',
			'accountPreferences.watchedIndicatorOptions.moviesAndShowsDescription' => 'Mostrar marcadores assistidos para filmes e programas de TV.',
			'accountPreferences.watchedIndicatorOptions.moviesDescription' => 'Mostrar marcadores assistidos apenas para filmes.',
			'accountPreferences.watchedIndicatorOptions.showsDescription' => 'Mostrar checkmarks assistidos apenas para programas de TV.',
			'accountPreferences.mediaReviewsVisibility' => 'Avaliações e resenhas',
			'accountPreferences.mediaReviewsOptions.usersAndCritics' => 'Usuários e críticos',
			'accountPreferences.mediaReviewsOptions.usersOnly' => 'Apenas usuários',
			'accountPreferences.mediaReviewsOptions.criticsOnly' => 'Apenas críticos',
			'accountPreferences.mediaReviewsOptions.nobody' => 'Oculto',
			'accountPreferences.mediaReviewsOptions.usersAndCriticsDescription' => 'Mostre as avaliações dos usuários e as classificações críticas.',
			'accountPreferences.mediaReviewsOptions.usersOnlyDescription' => 'Mostrar classificações e avaliações apresentadas pelos usuários.',
			'accountPreferences.mediaReviewsOptions.criticsOnlyDescription' => 'Mostrar avaliações críticas e comentários.',
			'accountPreferences.mediaReviewsOptions.nobodyDescription' => 'Esconde classificações e avaliações.',
			'accountPreferences.preferredAudioLanguageDescription' => 'Preferir as faixas de áudio neste idioma quando o servidor ou jogador seleciona automaticamente uma faixa.',
			'accountPreferences.preferredSubtitleLanguageDescription' => 'Prefira rastrear subtítulos neste idioma quando os subtitulos são selecionados automaticamente.',
			'accountPreferences.subtitleAccessibilityDescription' => 'Escolha se as capções SDH são preferidas ou necessárias durante a seleção automática de subtitulos.',
			'accountPreferences.forcedSubtitleDescription' => 'Escolha se as faixas forçadas são preferidas ou necessárias durante a seleção automática.',
			'accountPreferences.watchedIndicatorDescription' => 'Escolha quais tipos de mídia recebem um checkmark observado na interface do servidor.',
			'accountPreferences.mediaReviewsVisibilityDescription' => 'Escolha qual audiência e classificações críticas o servidor mostra nas páginas de mídia.',
			'accountPreferences.subtitleModeDescription' => 'Escolha quando os subtítulos se ativam automaticamente para esta conta do servidor.',
			'accountPreferences.hubDescription' => 'Estas preferências são armazenadas na sua conta de servidor de mídia e podem aplicar-se também a outros clientes.',
			'discover.title' => 'Descobrir',
			'discover.noContentAvailable' => 'Nenhum conteúdo disponível',
			'discover.addMediaToLibraries' => 'Adicione mídias às suas bibliotecas',
			'discover.continueWatching' => 'Continuar Assistindo',
			'discover.continueWatchingIn' => ({required Object library}) => 'Continuar assistindo em ${library}',
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
			'discover.findNext.title' => 'Descubra seu próximo favorito',
			'discover.findNext.open' => 'Descubra seu próximo favorito',
			'discover.findNext.anyTime' => 'Sem limite de tempo',
			'discover.findNext.timeAvailable' => 'Quanto tempo você tem?',
			'discover.findNext.filters' => 'Escolha para este momento',
			'discover.findNext.watch' => 'Assistir',
			'discover.findNext.listen' => 'Ouvir',
			'discover.findNext.read' => 'Ler',
			'discover.findNext.finishable' => ({required Object duration}) => 'Dá para terminar em ${duration}',
			'discover.findNext.aboutDuration' => ({required Object duration}) => 'Cerca de ${duration}',
			'discover.findNext.nextUnit' => ({required Object duration}) => 'Próximo capítulo · ${duration}',
			'discover.findNext.totalDuration' => ({required Object duration}) => '${duration} no total',
			'discover.findNext.timingVaries' => 'A duração pode variar',
			'discover.findNext.notNow' => 'Agora não',
			'discover.findNext.swipeHint' => 'Deslize a capa na direção de uma seta ou use os botões abaixo.',
			'discover.findNext.saved' => 'Sugestões salvas',
			'discover.findNext.savedCount' => ({required Object count}) => 'Sugestões salvas · ${count}',
			'discover.findNext.undo' => 'Desfazer',
			'discover.findNext.details' => 'Detalhes',
			'discover.findNext.noPicks' => 'Ainda não há opções',
			'discover.findNext.noPicksHint' => 'Conecte uma biblioteca ou adicione uma fonte de mídia para começar.',
			'discover.findNext.noMatches' => 'Nada combina com este momento',
			'discover.findNext.noMatchesHint' => 'Experimente outro tipo de conteúdo ou reserve mais tempo.',
			'discover.findNext.allDone' => 'Você já viu todas as sugestões',
			'discover.findNext.allDoneHint' => 'Comece uma nova seleção para ver essas opções novamente.',
			'discover.findNext.refresh' => 'Buscar outra seleção',
			'discover.findNext.sourceReason' => ({required Object source}) => 'De ${source}',
			'discover.findNext.libraryReason' => ({required Object library}) => 'De ${library}',
			'discover.findNext.ownedReason' => 'Da sua biblioteca',
			'discover.findNext.liveNow' => 'No ar agora',
			'discover.findNext.watchLive' => 'Assistir ao vivo',
			'discover.findNext.filterAnything' => 'Qualquer tipo',
			'discover.findNext.filterWatch' => 'Assistir',
			'discover.findNext.filterListen' => 'Ouvir',
			'discover.findNext.filterRead' => 'Ler',
			'discover.findNext.twentyMinutes' => '20 min',
			'discover.findNext.fortyFiveMinutes' => '45 min',
			'discover.findNext.ninetyMinutes' => '90 min',
			'discover.findNext.apply' => 'Aplicar',
			'discover.findNext.openFailed' => 'Esta opção não está mais disponível. Atualize para verificar novamente.',
			'discover.findNext.changeFailed' => 'Não foi possível salvar a alteração. Tente novamente.',
			'discover.findNext.savedLimit' => 'A lista de sugestões salvas está cheia. Remova uma sugestão para salvar outra.',
			'discover.findNext.chooseHint' => 'Abra um título, guarde-o para mais tarde ou passe ao seguinte.',
			'discover.findNext.howItWorks' => 'Como funciona',
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
			'discover.extras' => 'Trailers e extras',
			'discover.studio' => 'Estúdio',
			'discover.rating' => 'Avaliação',
			'discover.director' => 'Diretor',
			'discover.directors' => 'Diretores',
			'discover.movie' => 'Filme',
			'discover.tvShow' => 'Série de TV',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} min restantes',
			'discover.moreLikeThis' => 'Títulos semelhantes',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} título', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} títulos', ), 
			'discover.person.born' => 'Nascimento',
			'discover.person.died' => 'Falecimento',
			'discover.person.birthplace' => 'Local de nascimento',
			'discover.person.dateWithAge' => ({required Object date, required Object age}) => '${date} (${age} anos)',
			'discover.person.dateWithAgeAtDeath' => ({required Object date, required Object age}) => '${date} (aos ${age} anos)',
			'errors.searchFailed' => ({required Object error}) => 'Falha na busca: ${error}',
			'errors.searchUnavailable' => 'A busca não conseguiu alcançar nenhum servidor de mídia.',
			'errors.connectionTimeout' => ({required Object context}) => 'Tempo de conexão esgotado ao carregar ${context}',
			'errors.connectionFailed' => 'Não foi possível conectar ao servidor de mídia',
			'errors.unableToLoad' => ({required Object context}) => 'Não foi possível carregar ${context}. Tente novamente.',
			'errors.noClientAvailable' => 'Nenhum cliente disponível',
			'errors.pleaseEnterToken' => 'Insira um token',
			'errors.invalidToken' => 'Token inválido',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Falha ao verificar token: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Falha ao trocar para ${displayName}',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => 'Falha ao excluir ${displayName}',
			'errors.failedToRate' => 'Não foi possível atualizar a classificação',
			'errors.reasonTimedOut' => 'o tempo de conexão se esgotou',
			'errors.reasonUnreachable' => 'não foi possível alcançar o servidor',
			'errors.reasonRefused' => 'o servidor recusou a solicitação',
			'errors.reasonNotFound' => 'o item não está mais no servidor',
			'errors.reasonServerError' => 'o servidor relatou um erro',
			'errors.reasonCancelled' => 'a solicitação foi cancelada',
			'errors.reasonUnexpected' => 'ocorreu um erro inesperado',
			'libraries.playRandomMovie' => 'Jogue um filme aleatório',
			'libraries.randomPickFailed' => 'Não podia escolher um filme aleatório desta biblioteca.',
			'libraries.title' => 'Bibliotecas',
			'libraries.fallbackTitle' => 'Biblioteca',
			'libraries.scanLibraryFiles' => 'Escanear Arquivos da Biblioteca',
			'libraries.scanLibrary' => 'Escanear Biblioteca',
			'libraries.analyze' => 'Analisar',
			'libraries.analyzeLibrary' => 'Analisar Biblioteca',
			'libraries.refreshMetadata' => 'Atualizar Metadados',
			'libraries.emptyTrash' => 'Esvaziar Lixeira',
			'libraries.emptyingTrash' => ({required Object title}) => 'Esvaziando lixeira de "${title}"...',
			'libraries.trashEmptied' => ({required Object title}) => 'Lixeira esvaziada de "${title}"',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'Falha ao esvaziar lixeira: ${error}',
			'libraries.analyzing' => ({required Object title}) => 'Analisando "${title}"...',
			'libraries.analysisStarted' => ({required Object title}) => 'Análise iniciada para "${title}"',
			'libraries.failedToAnalyze' => ({required Object error}) => 'Falha ao analisar biblioteca: ${error}',
			'libraries.noLibrariesFound' => 'Nenhuma biblioteca encontrada',
			'libraries.allLibrariesHidden' => 'Todas as bibliotecas estão ocultas',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'Bibliotecas ocultas (${count})',
			'libraries.thisLibraryIsEmpty' => 'Esta biblioteca está vazia',
			'libraries.noItemsMatchFilters' => 'Nenhum item corresponde aos filtros ativos',
			'libraries.resetFilters' => 'Redefinir filtros',
			'libraries.all' => 'Todos',
			'libraries.clearAll' => 'Limpar tudo',
			'libraries.scanLibraryConfirm' => ({required Object title}) => 'Tem certeza de que deseja escanear "${title}"?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => 'Tem certeza de que deseja analisar "${title}"?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => 'Tem certeza de que deseja atualizar os metadados de "${title}"?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => 'Tem certeza de que deseja esvaziar a lixeira de "${title}"?',
			'libraries.manageLibraries' => 'Gerenciar Bibliotecas',
			'libraries.sort' => 'Ordenar',
			'libraries.sortBy' => 'Ordenar por',
			'libraries.filters' => 'Filtros',
			'libraries.confirmActionMessage' => 'Tem certeza de que deseja realizar esta ação?',
			'libraries.showLibrary' => 'Mostrar biblioteca',
			'libraries.hideLibrary' => 'Ocultar biblioteca',
			'libraries.libraryOptions' => 'Opções da biblioteca',
			'libraries.content' => 'conteúdo da biblioteca',
			_ => null,
		} ?? switch (path) {
			'libraries.selectLibrary' => 'Selecionar biblioteca',
			'libraries.filtersWithCount' => ({required Object count}) => 'Filtros (${count})',
			'libraries.noRecommendations' => 'Nenhuma recomendação disponível',
			'libraries.noCollections' => 'Nenhuma coleção nesta biblioteca',
			'libraries.noFoldersFound' => 'Nenhuma pasta encontrada',
			'libraries.folders' => 'pastas',
			'libraries.tabs.recommended' => 'Recomendados',
			'libraries.tabs.browse' => 'Navegar',
			'libraries.tabs.collections' => 'Coleções',
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
			'libraries.filterCategories.genre' => 'Gênero',
			'libraries.filterCategories.year' => 'Ano',
			'libraries.filterCategories.contentRating' => 'Classificação indicativa',
			'libraries.filterCategories.tag' => 'Tag',
			'libraries.filterCategories.unwatched' => 'Não assistidos',
			'libraries.filterCategories.unplayed' => 'Não reproduzidos',
			'libraries.filterCategories.favorites' => 'Favoritos',
			'libraries.filterCategories.filePath' => 'Caminho do arquivo',
			'libraries.sortLabels.title' => 'Título',
			'libraries.sortLabels.dateAdded' => 'Data de adição',
			'libraries.sortLabels.releaseDate' => 'Data de lançamento',
			'libraries.sortLabels.rating' => 'Avaliação',
			'libraries.sortLabels.communityRating' => 'Avaliação da comunidade',
			'libraries.sortLabels.criticRating' => 'Avaliação da crítica',
			'libraries.sortLabels.userRating' => 'Avaliação do usuário',
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
			'libraries.sortLabels.dateShared' => 'Data de compartilhamento',
			'libraries.sortLabels.latestEpisodeAirDate' => 'Última data de exibição do episódio',
			'libraries.sortLabels.lastEpisodeDateAdded' => 'Data de adição do último episódio',
			'libraries.sortLabels.dateDownloaded' => 'Data de download',
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
			'libraries.advancedFilters.searchValues' => 'Buscar valores',
			'libraries.advancedFilters.noValues' => 'Nenhum valor',
			'libraries.advancedFilters.matchContains' => 'Contém',
			'libraries.advancedFilters.matchNotContains' => 'Não contém',
			'libraries.advancedFilters.matchIs' => 'É',
			'libraries.advancedFilters.matchIsNot' => 'Não é',
			'libraries.advancedFilters.matchBeginsWith' => 'Começa com',
			'libraries.advancedFilters.matchEndsWith' => 'Termina com',
			'libraries.advancedFilters.textHint' => 'Digite para filtrar',
			'libraries.advancedFilters.from' => 'De',
			'libraries.advancedFilters.to' => 'Até',
			'libraries.advancedFilters.range' => ({required Object from, required Object to}) => '${from} a ${to}',
			'libraries.advancedFilters.atLeast' => ({required Object value}) => '${value} ou mais',
			'libraries.advancedFilters.atMost' => ({required Object value}) => 'Até ${value}',
			'libraries.advancedFilters.dateLastDays' => ({required Object count}) => 'Últimos ${count} dias',
			'libraries.advancedFilters.dateLastYear' => 'Último ano',
			'libraries.advancedFilters.dateOlderThanDays' => ({required Object count}) => 'Há mais de ${count} dias',
			'libraries.advancedFilters.dateOlderThanYear' => 'Há mais de um ano',
			'libraries.selection.selectItems' => 'Selecione Itens',
			'libraries.selection.selectedCount' => ({required Object count}) => '${count} selecionados',
			'libraries.selection.actions' => 'Ações de Selecção',
			'libraries.selection.confirmDescendants' => 'Isso muda todos os episódios nos shows e estações selecionados.',
			'libraries.selection.confirmUnwatched' => 'Isso também apaga o progresso de reprodução dos itens selecionados.',
			'libraries.selection.confirmCount' => ({required Object count}) => 'Produtos selecionados: ${count}.',
			'libraries.selection.completed' => ({required Object count}) => 'Artigos atualizados: ${count}.',
			'libraries.selection.partialFailure' => ({required Object succeeded, required Object failed}) => 'Atualização ${succeeded}; falha ${failed}. item falha permanece selecionado.',
			'about.title' => 'Sobre',
			'about.openSourceLicenses' => 'Licenças de código aberto',
			'about.versionLabel' => ({required Object version}) => 'Versão ${version}',
			'about.appDescription' => 'Um belo cliente de Plex, Jellyfin e Emby feito com Flutter',
			'about.viewLicensesDescription' => 'Ver as licenças de bibliotecas de terceiros',
			'about.privacyPolicy' => 'Política de Privacidade',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'Nenhum servidor encontrado para ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Falha ao carregar servidores: ${error}',
			'serverSelection.noValidServers' => 'Nenhum servidor utilizável foi encontrado nesta conta',
			'hubDetail.title' => 'Título',
			'hubDetail.releaseYear' => 'Ano de Lançamento',
			'hubDetail.dateAdded' => 'Data de Adição',
			'hubDetail.rating' => 'Avaliação',
			'hubDetail.noItemsFound' => 'Nenhum item encontrado',
			'logs.clearLogs' => 'Limpar Logs',
			'logs.copyLogs' => 'Copiar Logs',
			'logs.uploadLogs' => 'Enviar Logs',
			'logs.saveLogs' => 'Salve logs para arquivos',
			'logs.logsSaved' => ({required Object path}) => 'Registo salvo para ${path}',
			'logs.saveLogsFailed' => 'Não consegui salvar o arquivo de log.',
			'startup.failedTitle' => 'O PlezyNG não conseguiu iniciar',
			'startup.failedBody' => 'Algo deu errado durante a inicialização. Os detalhes abaixo identificam o que falhou.',
			'startup.failedBodyRepairable' => 'O arquivo de configurações salvo do PlezyNG está danificado e precisa ser reconstruído antes que o PlezyNG possa iniciar. Tentar novamente não vai ajudar — escolha Reparar armazenamento.',
			'startup.phaseLabel' => 'Etapa',
			'startup.showDetails' => 'Mostrar detalhes',
			'startup.hideDetails' => 'Ocultar detalhes',
			'startup.copyDetails' => 'Copiar detalhes',
			'startup.detailsCopied' => 'Detalhes copiados para a área de transferência',
			'startup.uploadDetails' => 'Enviar detalhes',
			'startup.repairStorage' => 'Reparar armazenamento',
			'startup.repairTitle' => 'Reparar dados armazenados?',
			'startup.repairBodyCommon' => 'O arquivo de configurações do PlezyNG está danificado e não pode ser lido. Reparar redefine todas as configurações para o padrão.',
			'startup.repairBodyOneCredential' => 'Um login salvo está danificado e não pode ser lido. Reparar remove apenas ele; suas outras configurações permanecem intactas.',
			'startup.repairBodySignInsKept' => 'Seus servidores e perfis devem permanecer conectados.',
			'startup.repairBodySignInsLost' => 'A chave que protege seus logins salvos não pode ser recuperada deste arquivo, então você terá que entrar novamente em todos os servidores e perfis. Nada no seu servidor de mídia é afetado.',
			'startup.repairBodySessionsUncertain' => 'Os rastreadores (MAL, AniList, Simkl, Trakt) e o Seerr são armazenados separadamente e podem ou não ser preservados. O PlezyNG informará exatamente o que foi mantido.',
			'startup.repairConfirm' => 'Reparar',
			'startup.repairSucceeded' => 'Armazenamento reparado',
			'startup.repairNeedsRestart' => 'Armazenamento reparado — reinício necessário',
			'startup.restartRequiredBody' => 'Seus dados foram reparados, mas o PlezyNG precisa iniciar do zero antes de usá-los. Feche o PlezyNG e abra-o novamente.',
			'startup.quitPlezy' => 'Sair do PlezyNG',
			'startup.repairFailed' => 'Falha no reparo',
			'startup.repairKeptSignIns' => 'Seus servidores e perfis ainda estão conectados.',
			'startup.repairLostSignIns' => 'A chave que protege seus logins salvos não pôde ser recuperada. Você terá que entrar novamente em todos os servidores e perfis.',
			'startup.repairLostSessions' => 'Pelo menos uma conexão de rastreador ou do Seerr foi perdida e precisa ser reconectada.',
			'startup.backupTitle' => 'Uma cópia do arquivo danificado foi mantida',
			'startup.backupWarning' => 'Ele contém suas credenciais de login. Não envie nem compartilhe.',
			'startup.deleteBackup' => 'Excluir cópia',
			'startup.backupDeleted' => 'Cópia excluída.',
			'startup.previousFailureTitle' => 'O PlezyNG falhou ao iniciar da última vez',
			'licenses.relatedPackages' => 'Pacotes Relacionados',
			'licenses.license' => 'Licença',
			'licenses.licenseNumber' => ({required Object number}) => 'Licença ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} licenças',
			'navigation.libraries' => 'Bibliotecas',
			'navigation.downloads' => 'Downloads',
			'navigation.liveTv' => 'TV ao Vivo',
			'navigation.explore' => 'Explorar',
			'explore.mdblistShelves.manage' => 'Gerenciamento Explore as placas',
			'explore.mdblistShelves.manageDescription' => 'Escolha e arregle listas da sua conta MDBList',
			'explore.mdblistShelves.description' => 'Escolha listas de filmes e TV públicos da sua conta MDBList. crie ou copie listas em MDBList, e depois refresque.',
			'explore.mdblistShelves.selected' => 'Cadeiras selecionadas',
			'explore.mdblistShelves.available' => 'Lista de contas disponíveis',
			'explore.mdblistShelves.noLists' => 'Não há filmes públicos ou listas de TV devolvidas. crie ou copie uma lista no MDBList, e depois refresque.',
			'explore.mdblistShelves.displayName' => 'Nome de exibição Shelf',
			'explore.mdblistShelves.nameHint' => 'Deixe o nome branco para usar o nome da lista de fontes.',
			'explore.mdblistShelves.add' => 'Adicionar Shelf',
			'explore.mdblistShelves.save' => 'Salva as cadeiras',
			'explore.mdblistShelves.moveUp' => ({required Object title}) => 'Move ${title} para cima',
			'explore.mdblistShelves.moveDown' => ({required Object title}) => 'Move ${title} para baixo',
			'explore.mdblistShelves.unavailable' => 'Esta lista não está disponível. retire ou remova a sua armadilha em configurações.',
			'explore.mdblistShelves.rateLimited' => 'MDBList limite de solicitação alcançado. por favor retire mais tarde.',
			'explore.mdblistShelves.loadFailed' => 'Não pode carregar as placas. verificar a sua conexão e retiro.',
			'explore.mdblistShelves.saveFailed' => 'Não posso salvar as cadeiras, por favor, retire.',
			'explore.mdblistShelves.accountChanged' => 'A conta ou perfil mudou. reabre essas configurações.',
			'explore.mdblistShelves.settingsUnreadable' => 'As folhas salvas não podem ser lidas. selecione suas listas novamente para substituir essas configurações.',
			'explore.title' => 'Explorar',
			'explore.selectSource' => 'Selecionar fonte',
			'explore.rows.watchlist' => 'Lista para assistir',
			'explore.rows.recommendedMovies' => 'Filmes recomendados',
			'explore.rows.recommendedShows' => 'Séries recomendadas',
			'explore.rows.trendingMovies' => 'Filmes em alta',
			'explore.rows.trendingShows' => 'Séries em alta',
			'explore.rows.popularMovies' => 'Filmes populares',
			'explore.rows.popularShows' => 'Séries populares',
			'explore.rows.trendingAnime' => 'Anime em alta',
			'explore.rows.suggestedAnime' => 'Anime sugerido',
			'explore.rows.airingAnime' => 'Melhores animes em exibição',
			'explore.rows.popularAnime' => 'Anime mais popular',
			'explore.rows.trending' => 'Em alta',
			'explore.rows.upcomingMovies' => 'Próximos filmes',
			'explore.rows.upcomingShows' => 'Próximas séries',
			'explore.status.airing' => 'Em exibição',
			'explore.status.ended' => 'Finalizada',
			'explore.status.canceled' => 'Cancelada',
			'explore.status.upcoming' => 'Em breve',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episódio', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episódios', ), 
			'explore.cast' => 'Elenco',
			'explore.characters' => 'Personagens',
			'explore.addToWatchlist' => 'Adicionar à lista para assistir',
			'explore.removeFromWatchlist' => 'Remover da lista para assistir',
			'explore.addedToWatchlist' => 'Adicionado à lista de interesses',
			'explore.removedFromWatchlist' => 'Removido da lista de interesses',
			'explore.watchlistUpdateFailed' => 'Não foi possível atualizar a lista para assistir',
			'explore.watchlistNoMatch' => 'Não foi possível associar este item a uma lista de interesses',
			'explore.notInLibrary' => 'Não está na sua biblioteca',
			'explore.inTheseLibraries' => 'Nestas bibliotecas',
			'explore.checkingLibrary' => 'Verificando sua biblioteca...',
			'explore.libraryCheckFailed' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: 'Não foi possível verificar ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} servidor', other: 'Não foi possível verificar ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} servidores', ), 
			'explore.emptyTitle' => 'Ainda não há nada aqui',
			'explore.emptyMessage' => ({required Object source}) => 'As linhas de ${source} aparecerão aqui quando tiverem conteúdo.',
			'explore.searchHint' => ({required Object source}) => 'Buscar em ${source}',
			'explore.searchEmpty' => ({required Object query}) => 'Nenhum resultado para "${query}"',
			'explore.searchPrompt' => ({required Object source}) => 'Busque filmes e séries em ${source}.',
			'explore.searchFailed' => 'Falha na busca. Verifique sua conexão e tente novamente.',
			'explore.badge.rankPopular' => ({required Object n}) => '#${n} popular',
			'explore.badge.rankAiring' => ({required Object n}) => '#${n} no ar',
			'explore.badge.rankRated' => ({required Object n}) => '#${n} avaliado',
			'explore.badge.rankTrending' => ({required Object n}) => '#${n} em alta',
			'explore.badge.rankSeasonal' => ({required Object n, required Object season}) => '#${n} em ${season}',
			'explore.badge.watchingNow' => ({required Object n}) => '${n} assistindo',
			'explore.badge.available' => 'Disponível',
			'explore.badge.partiallyAvailable' => 'Parcialmente disponível',
			'explore.badge.availableIn4k' => '4K disponível',
			'explore.badge.requested' => 'Solicitado',
			'explore.badge.pendingApproval' => 'Aguardando aprovação',
			'explore.badge.processing' => 'Processando',
			'explore.badge.declined' => 'Recusado',
			'explore.badge.requestFailed' => 'Falha na solicitação',
			'explore.badge.requested4k' => '4K solicitado',
			'explore.badge.seasonsAvailable' => ({required Object available, required Object total}) => '${available}/${total} temporadas',
			'explore.badge.nextEpisodeIn' => ({required Object episode, required Object duration}) => 'Ep ${episode} em ${duration}',
			'explore.badge.nextAiringIn' => ({required Object duration}) => 'Próximo em ${duration}',
			'explore.badge.episodesShort' => ({required Object n}) => '${n} epps',
			'explore.badge.minutesPerEpisode' => ({required Object n}) => '${n} min/ep',
			'explore.badge.adult' => '18+',
			'explore.stats.listed' => ({required Object n}) => '${n} listados',
			'explore.stats.viewersDay' => ({required Object n}) => '${n} assistiram hoje',
			'explore.stats.viewersWeek' => ({required Object n}) => '${n} assistiram esta semana',
			'explore.stats.viewersMonth' => ({required Object n}) => '${n} assistiram este mês',
			'explore.stats.viewersYear' => ({required Object n}) => '${n} assistiram este ano',
			'explore.stats.viewersAllTime' => ({required Object n}) => '${n} espectadores',
			'explore.stats.planning' => ({required Object n}) => '${n} pretendem assistir',
			'explore.stats.favorited' => ({required Object n}) => '${n} favoritos',
			'explore.stats.dropRate' => ({required Object percent}) => '${percent} abandonaram',
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} comentário', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} comentários', ), 
			'explore.stats.votes' => ({required Object n}) => '${n} votos',
			'explore.stats.watching' => ({required Object n}) => '${n} assistindo',
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
			'explore.sourceMaterial.manga' => 'Mangá',
			'explore.sourceMaterial.lightNovel' => 'Light novel',
			'explore.sourceMaterial.novel' => 'Romance',
			'explore.sourceMaterial.visualNovel' => 'Visual novel',
			'explore.sourceMaterial.game' => 'Jogo',
			'explore.sourceMaterial.webComic' => 'Webcomic',
			'explore.sourceMaterial.musicRelease' => 'Música',
			'explore.sourceMaterial.otherMedia' => 'Outro',
			'explore.creditRole.actor' => 'Ator',
			'explore.creditRole.director' => 'Diretor',
			'explore.creditRole.writer' => 'Roteirista',
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
			'explore.broadcast' => ({required Object day, required Object time}) => 'Vai ao ar ${day} às ${time}',
			'explore.broadcastWithZone' => ({required Object day, required Object time, required Object timezone}) => 'Vai ao ar ${day} às ${time} ${timezone}',
			'explore.detail.originalTitle' => 'Título original',
			'explore.detail.alsoKnownAs' => 'Também conhecido como',
			'explore.detail.studios' => 'Estúdios',
			'explore.detail.country' => 'País',
			'explore.detail.language' => 'Idioma',
			'explore.detail.released' => 'Lançado',
			'explore.detail.physicalRelease' => 'Em disco',
			'explore.detail.ended' => 'Encerrado',
			'explore.detail.addedOn' => ({required Object date}) => 'Adicionado em ${date}',
			'explore.detail.yourRating' => 'Sua avaliação',
			'explore.detail.budget' => 'Orçamento',
			'explore.detail.revenue' => 'Bilheteria',
			'explore.detail.contentAdvisory' => 'Classificação indicativa',
			'explore.detail.tags' => 'Tags',
			'explore.detail.revealSpoilerTags' => 'Mostrar tags de spoiler',
			'explore.detail.links' => 'Links',
			'explore.detail.watchOn' => 'Assistir em',
			'explore.detail.watchTrailer' => 'Ver trailer',
			'explore.detail.openOn' => ({required Object site}) => 'Abrir em ${site}',
			'explore.detail.crew' => 'Equipe',
			'explore.detail.ratings' => 'Avaliações',
			'explore.detail.schedule' => 'Programação',
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: 'Recomendado por ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} usuário', other: 'Recomendado por ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} usuários', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => 'Recomendado por ${who}',
			'explore.detail.favoritedBy' => ({required Object who}) => 'Favoritado por ${who}',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '${n} ainda não exibidos',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => 'Recomendado por ${percent} dos espectadores',
			'explore.detail.relatedTitles' => 'Títulos relacionados',
			'explore.detail.background' => 'Contexto',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} resultado', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} resultados', ), 
			'liveTv.title' => 'TV ao Vivo',
			'liveTv.guide' => 'Guia',
			'liveTv.noChannels' => 'Nenhum canal disponível',
			'liveTv.noDvr' => 'Nenhum DVR configurado em nenhum servidor',
			'liveTv.serverUnavailable' => 'O servidor de TV ao vivo não está disponível.',
			'liveTv.serverNotConnected' => 'O servidor de TV ao vivo não está conectado.',
			'liveTv.noPrograms' => 'Nenhum dado de programação disponível',
			'liveTv.liveStreamFailed' => 'Falha na transmissão ao vivo',
			'liveTv.unknownProgram' => 'Programa desconhecido',
			'liveTv.timelineLiveProgram' => 'Programa ao vivo (a reprodução pode estar fora deste programa)',
			'liveTv.timelineBuffer' => 'Timelã de Buffer',
			'liveTv.timelineUnavailable' => 'Horário inacessível',
			'liveTv.timelineEstimated' => 'Otimização do playback',
			'liveTv.timelinePending' => 'Encontendo a busca',
			'liveTv.timelineStale' => 'O calendário pode ser obsoleto',
			'liveTv.unknownHub' => 'Desconhecido',
			'liveTv.unknownError' => 'Erro desconhecido',
			'liveTv.channelNumber' => ({required Object number}) => 'Canal ${number}',
			'liveTv.unknownChannel' => 'Canal desconhecido',
			'liveTv.live' => 'AO VIVO',
			'liveTv.premiereBadge' => 'Nova',
			'liveTv.reloadGuide' => 'Recarregar Guia',
			'liveTv.searchGuide' => 'Buscar no guia',
			'liveTv.searchHint' => 'Buscar canais e programas',
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
			'liveTv.whatsOn' => 'O que está passando',
			'liveTv.watchChannel' => 'Assistir ao canal',
			'liveTv.favorites' => 'Favoritos',
			'liveTv.reorderFavorites' => 'Reordenar favoritos',
			'liveTv.noFavoriteChannels' => 'Nenhum canal favorito',
			'liveTv.noFavoriteChannelsHint' => 'Mostre todos os canais e mantenha um canal pressionado para adicioná-lo aos favoritos.',
			'liveTv.showAllChannels' => 'Mostrar todos os canais',
			'liveTv.favoritesLoadFailed' => 'Não foi possível carregar os favoritos. Verifique sua conexão e tente novamente.',
			'liveTv.favoritesUpdateFailed' => 'Não foi possível atualizar os favoritos. Verifique sua conexão e tente novamente.',
			'liveTv.joinSession' => 'Entrar na sessão em andamento',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'Assistir do início (${minutes} min atrás)',
			'liveTv.watchLive' => 'Assistir ao vivo',
			'liveTv.goToLive' => 'Ir para o ponto ao vivo',
			'liveTv.record' => 'Gravar',
			'liveTv.recordEpisode' => 'Gravar episódio',
			'liveTv.recordSeries' => 'Gravar série',
			'liveTv.recordOptions' => 'Opções de gravação',
			'liveTv.saveTo' => 'Salvar em',
			'liveTv.recordings' => 'Gravações',
			'liveTv.scheduledRecordings' => 'Agendadas',
			'liveTv.recordingRules' => 'Regras de gravação',
			'liveTv.noScheduledRecordings' => 'Sem gravações agendadas',
			'liveTv.manageRecording' => 'Gerenciar gravação',
			'liveTv.cancelRecording' => 'Cancelar gravação',
			'liveTv.cancelRecordingTitle' => 'Cancelar esta gravação?',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '${title} não será mais gravado.',
			'liveTv.deleteRule' => 'Excluir regra',
			'liveTv.deleteRuleTitle' => 'Excluir regra de gravação?',
			'liveTv.deleteRuleMessage' => ({required Object title}) => 'Episódios futuros de ${title} não serão gravados.',
			'liveTv.recordingScheduled' => 'Gravação agendada',
			'liveTv.alreadyScheduled' => 'Este programa já está agendado',
			'liveTv.dvrAdminRequired' => 'As configurações de DVR exigem uma conta de administrador',
			'liveTv.recordingFailed' => 'Não foi possível agendar a gravação',
			'liveTv.recordingTargetMissing' => 'Não foi possível determinar a biblioteca de gravação',
			'liveTv.recordNotAvailable' => 'Gravação indisponível para este programa',
			'liveTv.recordingCancelled' => 'Gravação cancelada',
			'liveTv.recordingRuleDeleted' => 'Regra de gravação excluída',
			'liveTv.processRecordingRules' => 'Reavaliar regras',
			'liveTv.recordingInProgress' => 'Gravando agora',
			'liveTv.recordingsCount' => ({required Object count}) => '${count} agendadas',
			'liveTv.editRule' => 'Editar regra',
			'liveTv.editRuleAction' => 'Editar',
			'liveTv.recordingRuleUpdated' => 'Regra de gravação atualizada',
			'liveTv.guideReloadRequested' => 'Atualização do guia solicitada',
			'liveTv.guideReloadFailed' => 'Não foi possível atualizar o guia',
			'liveTv.rulesProcessRequested' => 'Reavaliação de regras solicitada',
			'liveTv.rulesProcessFailed' => 'Não foi possível reavaliar as regras de gravação',
			'liveTv.recordShow' => 'Gravar programa',
			'liveTv.recordSettings.startEarly' => 'Começar antes (segundos)',
			'liveTv.recordSettings.endLate' => 'Terminar depois (segundos)',
			'liveTv.recordSettings.newOnly' => 'Apenas episódios novos',
			'liveTv.recordSettings.anyChannel' => 'Gravar em qualquer canal',
			'liveTv.recordSettings.anyTime' => 'Gravar a qualquer hora',
			'liveTv.recordSettings.skipInLibrary' => 'Ignorar episódios que já estão na biblioteca',
			'liveTv.recordSettings.keepUpTo' => 'Episódios a manter',
			'liveTv.recordSettings.keepUpToHint' => '0 mantém todos os episódios',
			'liveTv.startingInMinutes' => ({required Object minutes}) => 'Começa em ${minutes} min',
			'liveTv.dayAtTime' => ({required Object day, required Object time}) => '${day} às ${time}',
			'liveTv.invalidPlaybackData' => ({required Object product}) => '${product} retornou dados inválidos de reprodução de TV ao Vivo',
			'liveTv.failedToStartChannel' => 'Não foi possível iniciar o canal ao vivo',
			'liveTv.failedToBuildStreamUrl' => 'Não foi possível gerar a URL da transmissão',
			'liveTv.playbackStartFailed' => ({required Object reason}) => 'Não foi possível iniciar o canal: ${reason}',
			'liveTv.channelSwitchFailed' => ({required Object reason}) => 'Não foi possível trocar de canal: ${reason}',
			'collections.title' => 'Coleções',
			'collections.collection' => 'Coleção',
			'collections.empty' => 'A coleção está vazia',
			'collections.deleteCollection' => 'Excluir Coleção',
			'collections.deleteConfirm' => ({required Object title}) => 'Excluir "${title}"? Não pode ser desfeito.',
			'collections.deleted' => 'Coleção excluída',
			'collections.deleteFailed' => 'Falha ao excluir coleção',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Falha ao excluir coleção: ${error}',
			'collections.selectCollection' => 'Selecionar Coleção',
			'collections.collectionName' => 'Nome da Coleção',
			'collections.enterCollectionName' => 'Insira o nome da coleção',
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
			'playlists.create' => 'Criar Playlist',
			'playlists.playlistName' => 'Nome da Playlist',
			'playlists.enterPlaylistName' => 'Insira o nome da playlist',
			'playlists.delete' => 'Excluir Playlist',
			'playlists.removeItem' => 'Remover da Playlist',
			'playlists.smartPlaylist' => 'Playlist Inteligente',
			'playlists.itemCount' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} item', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} itens', ), 
			'playlists.emptyPlaylist' => 'Esta playlist está vazia',
			'playlists.deleteConfirm' => 'Excluir Playlist?',
			'playlists.deleteMessage' => ({required Object name}) => 'Tem certeza de que deseja excluir "${name}"?',
			'playlists.created' => 'Playlist criada',
			'playlists.deleted' => 'Playlist excluída',
			'playlists.itemAdded' => 'Adicionado à playlist',
			'playlists.itemRemoved' => 'Removido da playlist',
			'playlists.selectPlaylist' => 'Selecionar Playlist',
			'playlists.searchPlaylists' => 'Pesquisar playlists...',
			'playlists.errorCreating' => 'Falha ao criar playlist',
			'playlists.errorDeleting' => 'Falha ao excluir playlist',
			'playlists.errorLoading' => 'Falha ao carregar playlists',
			'playlists.errorAdding' => 'Falha ao adicionar à playlist',
			'playlists.errorReordering' => 'Falha ao reordenar item da playlist',
			'playlists.errorRemoving' => 'Falha ao remover da playlist',
			'music.goToAlbum' => 'Ir para o álbum',
			'music.goToArtist' => 'Ir para o artista',
			'music.instantMix' => 'Mix instantâneo',
			'music.playNext' => 'Reproduzir a seguir',
			'music.addToQueue' => 'Adicionar à fila',
			'music.discNumber' => ({required Object n}) => 'Disco ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} faixa', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} faixas', ), 
			'music.nowPlaying' => 'Reproduzindo agora',
			'music.playingFrom' => ({required Object title}) => 'Reproduzindo de ${title}',
			'music.queue' => 'Fila',
			'music.clearQueue' => 'Limpar fila',
			'music.lyrics' => 'Letra',
			'music.visualizer' => 'Visualizador',
			'music.visualizerProfileLoading' => 'Leia a análise de traços...',
			'music.visualizerAmbientMotion' => 'MOVIMENTO Ambiental',
			'music.visualizerPlexLoudness' => 'Plex ruído',
			'music.visualizerPreviousPreset' => 'Estilo visual anterior',
			'music.visualizerNextPreset' => 'Próximo Estilo Visual',
			'music.visualizerPresetAurora' => 'Aurora',
			'music.visualizerPresetBloom' => 'Blumão',
			'music.visualizerPresetOrbitals' => 'Orbitários',
			'music.visualizerPresetPrism' => 'Prism',
			'music.visualizerPresetTunnel' => 'Túnel',
			'music.visualizerPresetTrackMap' => 'Track mapa',
			'music.noLyrics' => 'Nenhuma letra disponível',
			'music.sleepTimer' => 'Temporizador de suspensão',
			'music.sleepTimerEndOfTrack' => 'Fim da faixa',
			'music.sleepTimerMinutes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minuto', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minutos', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minutos', ), 
			'music.stopPlayback' => 'Parar reprodução',
			'music.previousTrack' => 'Faixa anterior',
			'music.nextTrack' => 'Próxima faixa',
			'music.repeat' => 'Repetir',
			'music.repeatAll' => 'Repetir tudo',
			'music.repeatOne' => 'Repetir uma faixa',
			'music.instantMixNoServer' => 'Nenhum servidor está disponível para uma mistura instantânea',
			'music.instantMixFailed' => 'Falha ao carregar o mix instantâneo',
			'music.instantMixEmpty' => 'O mix instantâneo não retornou nenhuma faixa',
			'music.noAudioUrl' => ({required Object track}) => 'Nenhuma URL de áudio está disponível para ${track}',
			'music.discography.singlesAndEps' => 'Singles e EPs',
			'music.discography.live' => 'Ao vivo',
			'music.discography.compilations' => 'Compilações',
			'watchTogether.title' => 'Assistir Juntos',
			'watchTogether.description' => 'Assista a conteúdos sincronizados com amigos e familiares',
			'watchTogether.createRoom' => 'Criar sala',
			'watchTogether.creatingRoom' => 'Criando sala...',
			'watchTogether.joinRoom' => 'Entrar na sala',
			'watchTogether.joiningRoom' => 'Entrando na sala...',
			'watchTogether.connecting' => 'Conectando...',
			'watchTogether.relayPublic' => 'As salas usam os servidores de retransmissão públicos do Open Watch Party.',
			'watchTogether.relayCustom' => ({required Object url}) => 'As salas usam seu servidor de retransmissão em ${url}.',
			'watchTogether.recentRooms' => 'Salas recentes',
			'watchTogether.roomActions' => 'Ações da sala',
			'watchTogether.renameRoom' => 'Renomear sala',
			'watchTogether.removeRoom' => 'Remover',
			'watchTogether.enterRoomCode' => 'Insira o código de 6 caracteres do anfitrião.',
			'watchTogether.roomCode' => 'Código da sala',
			'watchTogether.paste' => 'Colar',
			'watchTogether.noCodeInClipboard' => 'A área de transferência não contém um código de sala',
			'watchTogether.copyCode' => 'Copiar código',
			'watchTogether.codeCopied' => 'Código da sala copiado',
			'watchTogether.shareInvite' => 'Compartilhar convite',
			'watchTogether.inviteCopied' => 'Convite copiado. Cole-o em uma mensagem.',
			'watchTogether.inviteMessage' => ({required Object code}) => 'Entre na minha sala do Assistir Juntos no PlezyNG: abra "Assistir Juntos", escolha "Entrar na sala" e insira ${code}.',
			_ => null,
		} ?? switch (path) {
			'watchTogether.openSessionControls' => 'Abrir os controles da sessão Assistir Juntos',
			'watchTogether.reconnecting' => 'Reconectando...',
			'watchTogether.reconnectingDescription' => 'A conexão caiu. Você voltará à sala automaticamente.',
			'watchTogether.connected' => 'Conectado',
			'watchTogether.disconnected' => 'Desconectado',
			'watchTogether.youAreHost' => 'Você é o anfitrião',
			'watchTogether.hostedBy' => ({required Object name}) => 'Anfitrião: ${name}',
			'watchTogether.hostControlsPlayback' => 'O anfitrião controla a reprodução',
			'watchTogether.anyoneCanControl' => 'Qualquer pessoa pode controlar a reprodução',
			'watchTogether.roomLocked' => 'Sala bloqueada',
			'watchTogether.nowPlaying' => 'Reproduzindo agora',
			'watchTogether.nothingPlaying' => 'Nada em reprodução',
			'watchTogether.nothingPlayingHost' => 'Reproduza algo de qualquer biblioteca para compartilhar com a sala.',
			'watchTogether.nothingPlayingGuest' => 'Quando o anfitrião reproduzir algo, o conteúdo será aberto aqui.',
			'watchTogether.notShareable' => 'Este vídeo não corresponde a nenhum item do catálogo, então apenas pessoas com acesso ao mesmo servidor podem reproduzi-lo.',
			'watchTogether.searching' => 'Procurando este vídeo nas suas bibliotecas...',
			'watchTogether.yourCopy' => 'Sua cópia',
			'watchTogether.sharingYourCopy' => 'Você está compartilhando sua cópia',
			'watchTogether.playingOtherLength' => ({required Object difference}) => 'Reproduzindo sua cópia, ${difference}',
			'watchTogether.mismatchTitle' => 'Sua cópia tem outra duração',
			'watchTogether.mismatchDescription' => ({required Object difference}) => 'Sua cópia mais próxima é ${difference} que o vídeo da sala. Pode ser outro corte ou outra versão.',
			'watchTogether.playAnyway' => 'Reproduzir mesmo assim',
			'watchTogether.chooseAnotherCopy' => 'Escolher outra cópia',
			'watchTogether.dontPlay' => 'Não reproduzir',
			'watchTogether.unavailableTitle' => 'Você não tem este vídeo',
			'watchTogether.unavailableDescription' => 'O PlezyNG não o encontrou nas suas bibliotecas. Escolha uma cópia manualmente ou busque novamente.',
			'watchTogether.chooseCopy' => 'Escolher uma cópia',
			'watchTogether.searchAgain' => 'Buscar novamente',
			'watchTogether.noCandidates' => 'Nenhuma cópia encontrada nas suas bibliotecas.',
			'watchTogether.choiceFailed' => 'Não foi possível reproduzir esta cópia para a sala',
			'watchTogether.lengthLonger' => ({required Object duration}) => '${duration} mais longa',
			'watchTogether.lengthShorter' => ({required Object duration}) => '${duration} mais curta',
			'watchTogether.lengthSame' => 'Mesma duração',
			'watchTogether.lengthUnknown' => 'Duração desconhecida',
			'watchTogether.joinCurrentPlayback' => 'Entrar na reprodução atual',
			'watchTogether.joinCurrentPlaybackDescription' => 'Voltar ao conteúdo que o anfitrião está assistindo agora',
			'watchTogether.stopMedia' => 'Parar o vídeo para todos',
			'watchTogether.syncOffset' => 'Ajuste de sincronia',
			'watchTogether.syncOffsetDescription' => 'Ajuste seu vídeo se ele estiver adiantado ou atrasado em relação à sala.',
			'watchTogether.offsetHint' => ({required Object difference}) => 'Sua cópia é ${difference} que o vídeo da sala.',
			'watchTogether.applyDifference' => ({required Object offset}) => 'Usar ${offset}',
			'watchTogether.offsetMinusSecond' => '-1 s',
			'watchTogether.offsetMinusTenth' => '-100 ms',
			'watchTogether.offsetPlusTenth' => '+100 ms',
			'watchTogether.offsetPlusSecond' => '+1 s',
			'watchTogether.participants' => 'Participantes',
			'watchTogether.participantCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} participante', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} participantes', ), 
			'watchTogether.hostBadge' => 'ANFITRIÃO',
			'watchTogether.nameYou' => ({required Object name}) => '${name} (você)',
			'watchTogether.playerIdle' => 'Ocioso',
			'watchTogether.playerLoading' => 'Carregando',
			'watchTogether.playerReady' => 'Pronto',
			'watchTogether.playerBuffering' => 'Em buffer',
			'watchTogether.matchSearching' => 'Procurando',
			'watchTogether.matchMatched' => 'Tem o vídeo',
			'watchTogether.matchMismatched' => 'Duração diferente',
			'watchTogether.matchUnavailable' => 'Não tem o vídeo',
			'watchTogether.participantOffset' => ({required Object offset}) => 'Ajuste ${offset}',
			'watchTogether.makeHost' => 'Tornar anfitrião',
			'watchTogether.makeHostQuestion' => 'Transferir anfitrião?',
			'watchTogether.makeHostConfirm' => ({required Object name}) => '${name} controlará a reprodução e conduzirá a sessão para todos.',
			'watchTogether.transfer' => 'Transferir',
			'watchTogether.removeParticipant' => 'Remover da sala',
			'watchTogether.removeParticipantQuestion' => ({required Object name}) => 'Remover ${name}?',
			'watchTogether.removeParticipantConfirm' => ({required Object name}) => '${name} sairá da sala. A pessoa poderá entrar novamente com o código, a menos que você bloqueie a sala.',
			'watchTogether.remove' => 'Remover',
			'watchTogether.roomSettings' => 'Configurações da sala',
			'watchTogether.letEveryoneControl' => 'Permitir que todos controlem a reprodução',
			'watchTogether.lockRoom' => 'Bloquear sala',
			'watchTogether.lockRoomDescription' => 'Ninguém novo pode entrar',
			'watchTogether.leaveRoom' => 'Sair da sala',
			'watchTogether.leaveRoomQuestion' => 'Sair da sala?',
			'watchTogether.leaveRoomConfirm' => 'Você pode entrar novamente com o código da sala.',
			'watchTogether.leave' => 'Sair',
			'watchTogether.endRoom' => 'Encerrar sala',
			'watchTogether.endRoomQuestion' => 'Encerrar sala?',
			'watchTogether.endRoomConfirm' => 'Isso encerra a sala para todos.',
			'watchTogether.end' => 'Encerrar',
			'watchTogether.playBlockedTitle' => 'A reprodução não começou',
			'watchTogether.playBlockedDescription' => 'Pressione reproduzir para começar a assistir com a sala.',
			'watchTogether.notices.pressedPlay' => ({required Object name}) => '${name} iniciou a reprodução',
			'watchTogether.notices.playbackStarted' => 'Reprodução iniciada',
			'watchTogether.notices.paused' => ({required Object name}) => '${name} pausou',
			'watchTogether.notices.playbackPaused' => 'Reprodução pausada',
			'watchTogether.notices.jumpedTo' => ({required Object name, required Object position}) => '${name} pulou para ${position}',
			'watchTogether.notices.roomJumpedTo' => ({required Object position}) => 'Pulou para ${position}',
			'watchTogether.notices.changedSpeed' => ({required Object name, required Object speed}) => '${name} definiu a velocidade para ${speed}',
			'watchTogether.notices.speedChanged' => ({required Object speed}) => 'Velocidade definida para ${speed}',
			'watchTogether.notices.startedMedia' => ({required Object name, required Object title}) => '${name} iniciou ${title}',
			'watchTogether.notices.mediaStarted' => ({required Object title}) => 'Reproduzindo agora: ${title}',
			'watchTogether.notices.stoppedMedia' => ({required Object name}) => '${name} parou o vídeo',
			'watchTogether.notices.mediaStopped' => 'O vídeo parou',
			'watchTogether.notices.waitingFor' => ({required Object name}) => 'Aguardando ${name}...',
			'watchTogether.notices.waitingForSomeone' => 'Aguardando alguém se sincronizar...',
			'watchTogether.notices.finished' => 'Concluído',
			'watchTogether.notices.hostChangedTo' => ({required Object name}) => '${name} agora é o anfitrião',
			'watchTogether.notices.youAreNowHost' => 'Agora você é o anfitrião',
			'watchTogether.notices.joined' => ({required Object name}) => '${name} entrou',
			'watchTogether.notices.left' => ({required Object name}) => '${name} saiu',
			'watchTogether.notices.controlRefused' => 'Apenas o anfitrião pode controlar a reprodução',
			'watchTogether.notices.searchFailed' => 'Não foi possível buscar o vídeo da sala em alguns servidores',
			'watchTogether.notices.playBlocked' => 'Pressione reproduzir para começar',
			'watchTogether.notices.shareFailed' => 'Não foi possível compartilhar este vídeo com a sala',
			'watchTogether.notices.downloadNotShared' => 'Os downloads não são compartilhados com a sala enquanto o servidor de origem estiver offline',
			'watchTogether.notices.openFailed' => 'Não foi possível abrir o vídeo da sala',
			'watchTogether.ended.ended' => 'O anfitrião encerrou a sala',
			'watchTogether.ended.kicked' => 'Você foi removido da sala',
			'watchTogether.ended.expired' => 'A sala expirou',
			'watchTogether.ended.replaced' => 'Você entrou nesta sala em outro dispositivo',
			'watchTogether.ended.lost' => 'A conexão com a sala foi perdida',
			'watchTogether.errors.invalidCode' => 'Isso não é um código de sala. Os códigos têm 6 letras e números, sem 0, 1, I, L ou O.',
			'watchTogether.errors.roomNotFound' => 'Nenhuma sala tem esse código. Ela pode ter sido encerrada.',
			'watchTogether.errors.roomFull' => 'Essa sala está cheia.',
			'watchTogether.errors.roomLocked' => 'O anfitrião bloqueou essa sala.',
			'watchTogether.errors.relayFull' => 'O Assistir Juntos está sobrecarregado no momento. Tente novamente mais tarde.',
			'watchTogether.errors.unreachable' => 'Não foi possível acessar o servidor de retransmissão do Assistir Juntos. Verifique sua conexão.',
			'watchTogether.errors.rateLimited' => 'Muitas tentativas. Aguarde um momento e tente novamente.',
			'watchTogether.errors.clientBlocked' => 'Esta versão do PlezyNG não pode usar o servidor de retransmissão. Atualize o app.',
			'watchTogether.errors.forbidden' => 'Apenas o anfitrião pode fazer isso.',
			'watchTogether.errors.notInRoom' => 'Você não está em uma sala.',
			'watchTogether.errors.alreadyInRoom' => 'Você já está em uma sala.',
			'watchTogether.errors.resumeFailed' => 'Não foi possível voltar à sala.',
			'watchTogether.errors.unsupported' => 'O servidor de retransmissão não é compatível com isso.',
			'watchTogether.errors.generic' => 'Algo deu errado. Tente novamente.',
			'watchTogether.untitledEpisode' => ({required Object number}) => 'Episódio ${number}',
			'downloads.title' => 'Downloads',
			'downloads.manage' => 'Gerenciar',
			'downloads.tvShows' => 'Séries de TV',
			'downloads.movies' => 'Filmes',
			'downloads.music' => 'Música',
			'downloads.tracksQueued' => ({required Object count}) => '${count} faixas na fila para download',
			'downloads.noDownloads' => 'Nenhum download ainda',
			'downloads.noDownloadsDescription' => 'O conteúdo baixado aparecerá aqui para assistir offline',
			'downloads.downloadNow' => 'Baixar',
			'downloads.deleteDownload' => 'Excluir download',
			'downloads.retryDownload' => 'Tentar download novamente',
			'downloads.downloadQueued' => 'Download na fila',
			'downloads.downloadResumed' => 'Download retomado',
			'downloads.serverErrorBitrate' => 'Erro do servidor: o arquivo pode exceder o limite remoto de taxa de bits',
			'downloads.storageFull' => 'Os downloads foram interrompidos para proteger o espaço disponível. Libere espaço ou escolha outro local de download e tente novamente.',
			'downloads.storageUnavailable' => 'Os downloads foram interrompidos porque não foi possível verificar o armazenamento disponível. Verifique o local de download e tente novamente.',
			'downloads.episodesQueued' => ({required Object count}) => '${count} episódios na fila de download',
			'downloads.downloadDeleted' => 'Download excluído',
			'downloads.deleteConfirm' => ({required Object title}) => 'Excluir "${title}" deste dispositivo?',
			'downloads.deleteCollectionDownloads' => 'Excluir downloads',
			'downloads.deleteCollectionDownloadsConfirm' => ({required Object title}) => 'Excluir todos os downloads de "${title}" deste dispositivo?',
			'downloads.collectionDownloadsDeleted' => 'Downloads excluídos',
			'downloads.cancelledDownloadTitle' => 'Download cancelado',
			'downloads.cancelledDownloadMessage' => 'Este download foi cancelado. O que você deseja fazer?',
			'downloads.allEpisodesAlreadyDownloaded' => 'Todos os episódios já foram baixados',
			'downloads.resumeDownload' => 'Retomar download',
			'downloads.cancelledDownload' => 'Download cancelado',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file} (sincronizando ${status})',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => '${file} baixado — clique para concluir',
			'downloads.partialDownloadClickToComplete' => 'Parcialmente baixado — clique para concluir',
			'downloads.deleting' => 'Excluindo...',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Excluindo ${title}... (${current} de ${total})',
			'downloads.queuedTooltip' => 'Na fila',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'Na fila: ${files}',
			'downloads.downloadingTooltip' => 'Baixando...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => 'Baixando ${files}',
			'downloads.noDownloadsTree' => 'Nenhum download',
			'downloads.pauseAll' => 'Pausar todos',
			'downloads.resumeAll' => 'Retomar todos',
			'downloads.retryAll' => 'Tentar todos novamente',
			'downloads.retryFailed' => 'Tentar novamente os downloads com falha',
			'downloads.deleteAll' => 'Excluir todos',
			'downloads.selectVersion' => 'Selecionar versão',
			'downloads.allEpisodes' => 'Todos os episódios',
			'downloads.unwatchedOnly' => 'Apenas não assistidos',
			'downloads.nextNUnwatched' => ({required Object count}) => 'Próximos ${count} episódios não assistidos',
			'downloads.customAmount' => 'Quantidade personalizada...',
			'downloads.customAmountAny' => 'Quanto a cada (todos)',
			'downloads.randomEpisodes' => 'Episódios Rados',
			'downloads.includeSpecials' => 'Incluir especiais',
			'downloads.howManyEpisodes' => 'Quantos episódios?',
			'downloads.invalidEpisodeCount' => 'Insira uma quantidade válida de episódios.',
			'downloads.keepSynced' => 'Manter sincronizado',
			'downloads.downloadOnce' => 'Baixar uma vez',
			'downloads.keepNUnwatched' => ({required Object count}) => 'Manter ${count} episódios não assistidos',
			'downloads.editSyncRule' => 'Editar regra de sincronização',
			'downloads.removeSyncRule' => 'Remover regra de sincronização',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => 'Parar de sincronizar "${title}"? Os episódios baixados serão mantidos.',
			'downloads.removeListSyncRuleConfirm' => ({required Object title}) => 'Parar a sincronização de "${title}"?',
			'downloads.deleteSyncRuleDownloads' => 'Também excluir downloads associados',
			'downloads.deleteSyncRuleDownloadsDescription' => 'Downloads usados por outra regra de sincronização ou perfil serão mantidos.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'Regra de sincronização criada — mantendo ${count} episódios não assistidos',
			'downloads.syncRuleUpdated' => 'Regra de sincronização atualizada',
			'downloads.syncRuleRemoved' => 'Regra de sincronização removida',
			'downloads.syncRuleAndDownloadsRemoved' => 'Regra de sincronização e downloads associados removidos',
			'downloads.syncRuleCleanupBusy' => 'As regras de sincronização estão sendo atualizadas. Tente novamente em instantes.',
			'downloads.syncRuleCleanupUnavailable' => 'Os downloads associados não puderam ser identificados com segurança. Reconecte o servidor e tente novamente, ou remova a regra sem excluir os downloads.',
			'downloads.syncedNewEpisodes' => ({required Object count, required Object title}) => '${count} novos episódios sincronizados para ${title}',
			'downloads.syncNow' => 'Síntese agora',
			'downloads.downloadsUpToDate' => 'As downloads estão atualizadas',
			'downloads.syncComplete' => ({required Object queued, required Object removed}) => 'Sínculo completo · ${queued} queued, ${removed} removido',
			'downloads.activeSyncRules' => 'Regras de sincronização',
			'downloads.reviewOrphanFiles' => 'Rever downloads sem registo',
			'downloads.orphanReviewTitle' => 'Rever downloads sem registo',
			'downloads.orphanReviewDescription' => 'Estes ficheiros etiquetados estão nas pastas predefinidas de downloads geridos pela aplicação PlezyNG, mas não têm um registo de download correspondente nem uma tarefa ativa. Verifique a lista antes de os eliminar.',
			'downloads.orphanReviewCount' => ({required Object count, required Object size}) => '${count} ficheiros · ${size}',
			'downloads.orphanDeleteFiles' => ({required Object count}) => 'Eliminar ${count} ficheiros',
			'downloads.orphanCleanupNone' => 'Não foram encontrados ficheiros de download sem registo',
			'downloads.orphanCleanupFailed' => 'PlezyNG não conseguiu analisar com segurança a pasta de downloads gerida. Nenhum ficheiro foi eliminado.',
			'downloads.orphanCleanupChanged' => 'A lista de downloads foi alterada durante a revisão. Reveja os ficheiros novamente antes de limpar.',
			'downloads.orphanCleanupComplete' => ({required Object count, required Object size}) => 'Eliminados ${count} ficheiros sem registo · libertado ${size}',
			'downloads.noSyncRules' => 'Nenhuma regra de sincronização',
			'downloads.manageSyncRule' => 'Gerenciar sincronização',
			'downloads.editEpisodeCount' => 'Número de episódios',
			'downloads.editSyncFilter' => 'Filtro de sincronização',
			'downloads.syncAllItems' => 'Sincronizando todos os itens',
			'downloads.syncUnwatchedItems' => 'Sincronizando itens não assistidos',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'Servidor: ${server} • ${status}',
			'downloads.syncRuleAvailable' => 'Disponível',
			'downloads.syncRuleOffline' => 'Offline',
			'downloads.syncRuleSignInRequired' => 'É necessário entrar',
			'downloads.syncRuleAccessDenied' => 'Acesso negado',
			'downloads.syncRuleNotAvailableForProfile' => 'Indisponível para o perfil atual',
			'downloads.syncRuleUnknownServer' => 'Servidor desconhecido',
			'downloads.syncRuleListCreated' => 'Regra de sincronização criada',
			'downloads.backgroundWarning.bannerBlocked' => 'Os downloads serão interrompidos ao sair do app',
			'downloads.backgroundWarning.bannerDegraded' => 'Os downloads em segundo plano podem ser limitados',
			'downloads.backgroundWarning.bannerAction' => 'Detalhes',
			'downloads.backgroundWarning.sheetTitle' => 'Os downloads em segundo plano estão bloqueados',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'Os downloads em segundo plano podem ser limitados',
			'downloads.backgroundWarning.sheetIntro' => 'O Android está impedindo que o PlezyNG faça downloads de forma confiável em segundo plano.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'Seu dispositivo está limitando quando o PlezyNG pode fazer downloads em segundo plano.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'O uso em segundo plano do PlezyNG está restrito. Defina o uso da bateria ou o uso em segundo plano como "Sem restrições".',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'O Android colocou o PlezyNG em um modo de espera restrito. Defina o uso da bateria como "Sem restrições".',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'As notificações de download estão desativadas; por isso, o progresso e os controles podem ficar indisponíveis.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'As notificações estão desativadas. No Android 13 ou mais recente, elas são necessárias para downloads longos em segundo plano.',
			'downloads.backgroundWarning.reasonDataSaver' => 'A Economia de dados está ativada e bloqueia downloads em segundo plano usando dados móveis. Os downloads ainda devem funcionar no Wi-Fi.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'Os downloads foram interrompidos várias vezes enquanto o PlezyNG estava em segundo plano. Verifique as configurações de bateria ou uso em segundo plano do PlezyNG.',
			'downloads.backgroundWarning.openSettings' => 'Abrir configurações',
			'downloads.backgroundWarning.stillNotWorking' => 'Ajuda específica para o dispositivo',
			'downloads.backgroundWarning.stillNotWorkingDescription' => 'Veja as instruções para seu dispositivo ou, se o problema persistir, envie um log em Configurações › Ver Logs.',
			'downloads.backgroundWarning.dialogTitle' => 'Os downloads podem não ser concluídos',
			'downloads.backgroundWarning.dialogDownloadAnyway' => 'Baixar mesmo assim',
			'downloads.backgroundWarning.dialogFixFirst' => 'Corrigir primeiro',
			'downloads.backgroundWarning.statusTile' => 'Downloads em segundo plano',
			'downloads.backgroundWarning.statusOk' => 'Execução em segundo plano permitida',
			'downloads.backgroundWarning.statusBlocked' => 'Bloqueado pelas configurações do sistema',
			'downloads.backgroundWarning.statusDegraded' => 'Limitado pelas configurações do sistema',
			'downloads.backgroundWarning.statusUnknown' => 'Ainda não verificado',
			'downloads.backgroundWarning.settingsUnavailable' => 'Não foi possível abrir as configurações do sistema neste dispositivo',
			'downloads.backgroundWarning.linkUnavailable' => 'Não foi possível abrir dontkillmyapp.com neste dispositivo',
			'downloads.options' => 'Opções de downloads',
			'downloads.groupings.library' => 'Biblioteca',
			'downloads.groupings.collections' => 'Coleções',
			'downloads.unknownLibrary' => 'Biblioteca desconhecida',
			'downloads.unknownShow' => 'Série desconhecida',
			'downloads.unknownSeason' => 'Temporada desconhecida',
			'downloads.unknownAlbum' => 'Álbum desconhecido',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '${completed}/${total} concluídos',
			'downloads.storageUsed' => ({required Object size}) => 'Armazém utilizado: ${size}',
			'downloads.downloadCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} transferência', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} transferências', ), 
			'downloads.showCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} apresentação', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} apresentações', ), 
			'downloads.movieCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} filme', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} filmes', ), 
			'downloads.albumCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} álbum', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} álbuns', ), 
			'downloads.errorFileNotFound' => 'Arquivo não encontrado (404)',
			'downloads.errorDownloadNotAllowed' => 'Download não permitido pelo servidor (403)',
			'downloads.errorDownloadFailed' => 'Falha no download',
			'downloads.errorDownloadFailedWithReason' => ({required Object reason}) => 'Falha no download: ${reason}',
			'downloads.convertingOnServer' => 'Conversão em servidor...',
			'downloads.convertingOnServerPercent' => ({required Object percent}) => 'Conversão em servidor · ${percent}%',
			'downloads.errorHttpStatus' => ({required Object status}) => 'Falha no download (HTTP ${status})',
			'downloads.errorPostProcessing' => ({required Object reason}) => 'Falha no pós-processamento: ${reason}',
			'downloads.reasonFileNotSaved' => 'não foi possível salvar o arquivo neste dispositivo',
			'downloads.reasonCannotResume' => 'não foi possível retomar o download parcial',
			'downloads.reasonDeviceStorageFull' => 'este dispositivo está sem espaço de armazenamento',
			'downloads.notificationDownloading' => 'Baixando...',
			'downloads.notificationComplete' => 'Download concluído',
			'downloads.notificationPaused' => 'Download pausado',
			'shaders.title' => 'Shaders',
			'shaders.noShaderDescription' => 'Sem aprimoramento de vídeo',
			'shaders.nvscalerDescription' => 'Dimensionamento de imagem da NVIDIA para vídeos mais nítidos',
			'shaders.artcnnVariantNeutral' => 'Neutro',
			'shaders.artcnnVariantDenoise' => 'Redução de ruído',
			'shaders.artcnnVariantDenoiseSharpen' => 'Redução de ruído + nitidez',
			'shaders.qualityFast' => 'Rápido',
			'shaders.qualityHQ' => 'Alta Qualidade',
			'shaders.mode' => 'Modo',
			'shaders.importShader' => 'Importar Shader',
			'shaders.customShaderDescription' => 'Shader GLSL personalizado',
			'shaders.shaderImported' => 'Shader importado',
			'shaders.shaderImportFailed' => 'Falha ao importar shader',
			'shaders.deleteShader' => 'Excluir Shader',
			'shaders.deleteShaderConfirm' => ({required Object name}) => 'Excluir "${name}"?',
			'companionRemote.title' => 'Controle remoto',
			'companionRemote.connectedTo' => ({required Object name}) => 'Conectado a ${name}',
			'companionRemote.unknownDevice' => 'Dispositivo desconhecido',
			'companionRemote.session.startingServer' => 'Iniciando servidor remoto...',
			'companionRemote.session.hostAddress' => 'Endereço do host',
			'companionRemote.session.connected' => 'Conectado',
			'companionRemote.session.serverRunning' => 'Servidor remoto ativo',
			'companionRemote.session.serverStopped' => 'Servidor remoto parado',
			'companionRemote.session.serverRunningDescription' => 'Dispositivos móveis na sua rede podem se conectar a este app',
			'companionRemote.session.serverStoppedDescription' => 'Inicie o servidor para permitir que dispositivos móveis se conectem',
			'companionRemote.session.usePhoneToControl' => 'Use seu dispositivo móvel para controlar este app',
			'companionRemote.session.startServer' => 'Iniciar servidor',
			'companionRemote.session.stopServer' => 'Parar servidor',
			'companionRemote.session.minimize' => 'Minimizar',
			'companionRemote.session.manualAddressHint' => 'Endereço de conexão manual:',
			'companionRemote.pairing.discoveryDescription' => 'Dispositivos PlezyNG com a mesma conta Plex aparecem aqui',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Conectando...',
			'companionRemote.pairing.searchingForDevices' => 'Procurando dispositivos...',
			'companionRemote.pairing.noDevicesFound' => 'Nenhum dispositivo encontrado na sua rede',
			'companionRemote.pairing.noDevicesHint' => 'Abra o PlezyNG no desktop e use a mesma rede Wi-Fi',
			'companionRemote.pairing.availableDevices' => 'Dispositivos disponíveis',
			'companionRemote.pairing.manualConnection' => 'Conexão manual',
			'companionRemote.pairing.cryptoInitFailed' => 'Não foi possível iniciar a conexão segura. Entre no Plex primeiro.',
			'companionRemote.pairing.validationHostRequired' => 'Insira o endereço do host',
			'companionRemote.pairing.validationHostFormat' => 'O formato deve ser IP:porta (ex.: 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'A conexão atingiu o tempo limite. Use a mesma rede nos dois dispositivos.',
			'companionRemote.pairing.sessionNotFound' => 'Dispositivo não encontrado. Verifique se o PlezyNG está em execução no host.',
			'companionRemote.pairing.authFailed' => 'Falha na autenticação. Ambos os dispositivos precisam da mesma conta Plex.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Falha ao conectar: ${error}',
			'companionRemote.pairing.codeTitle' => 'Código de par',
			'companionRemote.pairing.codeDescription' => 'Entre o código mostrado no Companion Remote no dispositivo host. Ambos os dispositivos devem usar uma versão que suporta paragem segura.',
			'companionRemote.pairing.codeInvalid' => 'Entre todas as 32 letras e números do código de hospedagem.',
			'companionRemote.pairing.updateRequired' => 'Atualize os dois dispositivos para uma versão que suporta paragem segura.',
			'companionRemote.pairing.hostDescription' => 'Mantenha-o privado: ele dá controle sobre este perfil.',
			'companionRemote.pairing.resetCode' => 'Resetando o código de par',
			'companionRemote.pairing.resetDescription' => 'Desconecte todos os remotos e crie um novo código. Cada remoto precisará se juntar novamente.',
			'companionRemote.remote.disconnectConfirm' => 'Deseja desconectar da sessão remota?',
			'companionRemote.remote.reconnecting' => 'Reconectando...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Tentativa ${current} de 5',
			'companionRemote.remote.retryNow' => 'Tentar agora',
			'companionRemote.remote.tabRemote' => 'Remoto',
			'companionRemote.remote.tabPlay' => 'Reproduzir',
			'companionRemote.remote.tabMore' => 'Mais',
			'companionRemote.remote.menu' => 'Menu',
			'companionRemote.remote.tabNavigation' => 'Navegação por abas',
			'companionRemote.remote.tabDiscover' => 'Descobrir',
			'companionRemote.remote.tabLibraries' => 'Bibliotecas',
			'companionRemote.remote.tabSearch' => 'Buscar',
			'companionRemote.remote.tabDownloads' => 'Downloads',
			'companionRemote.remote.tabSettings' => 'Configurações',
			'companionRemote.remote.previous' => 'Anterior',
			'companionRemote.remote.playPause' => 'Reproduzir/Pausar',
			'companionRemote.remote.next' => 'Próximo',
			'companionRemote.remote.seekBack' => 'Retroceder',
			'companionRemote.remote.stop' => 'Parar',
			'companionRemote.remote.seekForward' => 'Avançar',
			'companionRemote.remote.volume' => 'Volume',
			'companionRemote.remote.volumeDown' => 'Diminuir',
			'companionRemote.remote.volumeUp' => 'Aumentar',
			'companionRemote.remote.fullscreen' => 'Tela cheia',
			'companionRemote.remote.subtitles' => 'Legendas',
			'companionRemote.remote.audio' => 'Áudio',
			'companionRemote.remote.searchHint' => 'Buscar no desktop...',
			'companionRemote.errors.noNetworkInterface' => 'Nenhuma interface de rede encontrada',
			'companionRemote.errors.authenticationFailed' => 'Falha na autenticação',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'Falha ao iniciar o servidor remoto: ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'Falha ao enviar o comando remoto: ${error}',
			'companionRemote.errors.joinTimedOut' => 'Tempo esgotado ao entrar na sessão',
			'companionRemote.errors.failedToConnectAnyAddress' => 'Falha ao conectar a qualquer endereço',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => 'Conexão perdida após ${attempts} tentativas',
			'companionRemote.errors.connectionLost' => 'Conexão perdida',
			'companionRemote.closedBeforeAuth' => 'A conexão foi encerrada antes da autenticação',
			'videoSettings.playbackSpeed' => 'Velocidade de Reprodução',
			'videoSettings.normalSpeed' => 'Normal',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'Ativo (${duration})',
			'videoSettings.zoom' => 'Zoom',
			'videoSettings.sleepTimer' => 'Temporizador de suspensão',
			'videoSettings.audioSync' => 'Sincronia de áudio',
			'videoSettings.subtitleSync' => 'Sincronia de legendas',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.hdrUnsupported' => 'O HDR não está disponível aqui — este compositor da área de trabalho ou esta saída de vídeo não é compatível com ele.',
			'videoSettings.hdrToneMapping' => 'Mapeamento de tons HDR',
			'videoSettings.hdrToneMappingCompositor' => 'Compositor',
			'videoSettings.hdrToneMappingCompositorDescription' => 'Repassar os metadados HDR da fonte e deixar que o compositor da área de trabalho faça o mapeamento.',
			'videoSettings.hdrToneMappingPlayer' => 'Reprodutor',
			'videoSettings.hdrToneMappingPlayerDescription' => 'Mapear para o brilho máximo da tela no reprodutor e informar o resultado ao compositor.',
			'videoSettings.hdrToneMappingFailed' => 'Não foi possível alterar o mapeamento de tons HDR — o modo anterior continua ativo.',
			'videoSettings.audioOutput' => 'Saída de áudio',
			'videoSettings.videoTrack' => 'Faixa de vídeo',
			'videoSettings.videoTrackDescription' => 'Escolha qual fluxo de vídeo apresentar. Disponível na reprodução com MPV quando o ficheiro contém faixas de vídeo alternativas.',
			'videoSettings.videoTrackDefault' => 'Predefinida',
			'videoSettings.videoTrackUnavailable' => 'Não existem faixas de vídeo alternativas disponíveis.',
			'videoSettings.videoTrackFailed' => 'Não foi possível alterar a faixa de vídeo.',
			'videoSettings.videoTrackNumber' => ({required Object id}) => 'Faixa ${id}',
			'videoSettings.performanceOverlay' => 'Painel de desempenho',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'Surround',
			'videoSettings.audioOutputSpatial' => 'Áudio espacial',
			'videoSettings.audioOutputStereo' => 'Estéreo',
			'videoSettings.audioEqualizer' => 'Avaliação de áudio',
			'videoSettings.audioEqualizerDescription' => 'Equalizador de 10 bandas para MPVOs filtros de áudio usam áudio decodado e desligam passthrough.',
			'videoSettings.audioEqualizerFlat' => 'Neutro',
			'videoSettings.audioEqualizerActive' => 'Personalizado',
			'videoSettings.audioEqualizerSaveFailed' => 'Não poderia salvar as configurações do equalizador de áudio.',
			'videoSettings.audioEffectsDescription' => 'Os efeitos usam áudio descodificado, por isso o ajuste se desvia. ambiente de quarto e estereó ampliação dependem do MPV Construir e rastrear.',
			'videoSettings.audioStereoWidth' => 'Extensão Stereo',
			'videoSettings.audioSpatializer' => 'ambiente de quarto',
			'videoSettings.audioSpatializerDescription' => 'Adicione reflexões de sala tranquila.',
			'videoSettings.audioPitch' => 'Mudança de Pitch',
			'videoSettings.audioPitchDescription' => 'Mude a velocidade sem mudança de velocidade. MPV A construção deve incluir Rubber Band.',
			'videoSettings.audioEffectUnavailable' => 'Este efeito não está disponível para esta pista ou MPV Construção .',
			'videoSettings.backgroundVideoAudio' => 'Audio de vídeo de fundo',
			'videoSettings.backgroundVideoAudioDescription' => 'Mantenha o vídeo a tocar quando você sair do jogador; a imagem está escondida até que você retornar. Android usa uma notificação de reprodução de mídia.',
			'videoSettings.audioNormalization' => 'Normalizar intensidade sonora',
			'videoSettings.audioNormalizationDisablesPassthrough' => 'Decodifica o áudio para PCM; a passagem direta fica desativada enquanto esta opção estiver ativa',
			'performanceOverlay.color' => 'Cor',
			'performanceOverlay.performance' => 'Desempenho',
			'performanceOverlay.buffer' => 'Buffer',
			'performanceOverlay.app' => 'App',
			'performanceOverlay.decoder' => 'Decodificador',
			'performanceOverlay.rawDecoder' => 'Decodificador bruto',
			'performanceOverlay.tunneling' => 'Túnel',
			'performanceOverlay.passthrough' => 'Passagem direta',
			'performanceOverlay.aspect' => 'Aspecto',
			'performanceOverlay.rotation' => 'Rotação',
			'performanceOverlay.dvSource' => 'Fonte DV',
			'performanceOverlay.dvPath' => 'Caminho DV',
			'performanceOverlay.dvRouteDecoder' => 'Decodificador Dolby Vision',
			'performanceOverlay.dvRouteDecoderP81' => 'Decodificador Dolby Vision (P7→8.1)',
			'performanceOverlay.dvRouteBaseLayer' => 'Camada base',
			'performanceOverlay.dvRouteBaseLayerHdr10' => 'Camada base HDR10',
			'performanceOverlay.dvRouteBaseLayerHlg' => 'Camada base HLG',
			'performanceOverlay.dvRouteBaseLayerSdr' => 'Camada base SDR',
			'performanceOverlay.dvRouteReshaped' => 'Remodelagem RPU (gpu-next)',
			'performanceOverlay.dvRouteFelGraphActive' => 'P7 FEL gráfico experimental (não qualificado)',
			'performanceOverlay.p7Conversion' => 'Conv. P7',
			'performanceOverlay.sampleRate' => 'Taxa de amostragem',
			'performanceOverlay.pixelFormat' => 'Formato de pixel',
			'performanceOverlay.hwFormat' => 'Formato HW',
			'performanceOverlay.matrix' => 'Matriz',
			'performanceOverlay.primaries' => 'Primárias',
			'performanceOverlay.transfer' => 'Transferência',
			'performanceOverlay.renderFps' => 'FPS de renderização',
			'performanceOverlay.displayFps' => 'FPS da tela',
			'performanceOverlay.avSync' => 'Sincronia A/V',
			'performanceOverlay.dropped' => 'Descartados',
			'performanceOverlay.dvRpus' => 'DV RPUs',
			'performanceOverlay.dvRpuAverage' => 'Média DV RPU',
			'performanceOverlay.dvSampleAverage' => 'Média amostra DV',
			'performanceOverlay.maxLuma' => 'Luma máx.',
			'performanceOverlay.minLuma' => 'Luma mín.',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => 'Cache usado',
			'performanceOverlay.cacheLimit' => 'Limite do cache',
			'performanceOverlay.speed' => 'Velocidade',
			'performanceOverlay.player' => 'Reprodutor',
			'performanceOverlay.playMethod' => 'Jogo Método',
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
			'externalPlayer.useExternalPlayerDescription' => 'Abrir vídeos em outro app',
			'externalPlayer.selectPlayer' => 'Selecionar reprodutor',
			'externalPlayer.customPlayers' => 'Reprodutores personalizados',
			'externalPlayer.systemDefault' => 'Padrão do sistema',
			'externalPlayer.addCustomPlayer' => 'Adicionar reprodutor personalizado',
			'externalPlayer.playerName' => 'Nome do reprodutor',
			'externalPlayer.playerNameHint' => 'Meu reprodutor',
			'externalPlayer.playerCommand' => 'Comando',
			'externalPlayer.playerPackage' => 'Nome do pacote',
			'externalPlayer.playerUrlScheme' => 'Esquema de URL',
			'externalPlayer.off' => 'Desativado',
			'externalPlayer.launchFailed' => 'Falha ao abrir o reprodutor externo',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} não está instalado',
			'externalPlayer.playInExternalPlayer' => 'Reproduzir no reprodutor externo',
			'externalPlayer.description' => 'Escolha outro aplicativo para abrir vídeos em. Os jogadores disponíveis dependem do seu dispositivo e das aplicações instaladas.',
			'externalPlayer.systemDefaultDescription' => 'Deixe o sistema operacional abrir o vídeo com sua aplicação padrão.',
			'externalPlayer.playerOptionDescription' => ({required Object player}) => 'Abra vídeos com ${player}.',
			'externalPlayer.playerNameDescription' => 'O rótulo mostrado na lista de jogadores.',
			'externalPlayer.playerPackageDescription' => 'Insira o nome do pacote Android da aplicação de jogador, como com.example.player.',
			'externalPlayer.playerCommandDescription' => 'Entre o comando do jogador instalado ou a estrada executável para este dispositivo.',
			'externalPlayer.playerUrlSchemeDescription' => 'Introduza o esquema URL e o modelo de URL opcional usado para lançar o jogador.',
			'metadataEdit.editMetadata' => 'Editar...',
			'metadataEdit.screenTitle' => 'Editar Metadados',
			'metadataEdit.basicInfo' => 'Informações Básicas',
			'metadataEdit.artwork' => 'Arte',
			'metadataEdit.advancedSettings' => 'Configurações Avançadas',
			'metadataEdit.title' => 'Título',
			'metadataEdit.sortTitle' => 'Título para Ordenação',
			'metadataEdit.originalTitle' => 'Título Original',
			'metadataEdit.releaseDate' => 'Data de Lançamento',
			'metadataEdit.contentRating' => 'Classificação Indicativa',
			'metadataEdit.studio' => 'Estúdio',
			'metadataEdit.tagline' => 'Slogan',
			'metadataEdit.summary' => 'Sinopse',
			'metadataEdit.poster' => 'Pôster',
			'metadataEdit.background' => 'Plano de Fundo',
			'metadataEdit.logo' => 'Logo',
			'metadataEdit.squareArt' => 'Imagem Quadrada',
			'metadataEdit.selectPoster' => 'Selecionar pôster',
			'metadataEdit.selectBackground' => 'Selecionar Plano de Fundo',
			'metadataEdit.selectLogo' => 'Selecionar Logo',
			'metadataEdit.selectSquareArt' => 'Selecionar Imagem Quadrada',
			'metadataEdit.fromUrl' => 'Da URL',
			'metadataEdit.uploadFile' => 'Enviar Arquivo',
			'metadataEdit.enterImageUrl' => 'Insira a URL da imagem',
			'metadataEdit.imageUrl' => 'URL da Imagem',
			'metadataEdit.metadataUpdated' => 'Metadados atualizados',
			'metadataEdit.metadataUpdateFailed' => 'Falha ao atualizar metadados',
			'metadataEdit.artworkUpdated' => 'Arte atualizada',
			'metadataEdit.artworkUpdateFailed' => 'Falha ao atualizar arte',
			_ => null,
		} ?? switch (path) {
			'metadataEdit.noArtworkAvailable' => 'Nenhuma arte disponível',
			'metadataEdit.artworkOption' => ({required Object index}) => 'Opção de arte ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => 'Opção de arte ${index}, selecionada',
			'metadataEdit.notSet' => 'Não definido',
			'metadataEdit.libraryDefault' => 'Padrão da biblioteca',
			'metadataEdit.accountDefault' => 'Padrão da conta',
			'metadataEdit.seriesDefault' => 'Padrão da série',
			'metadataEdit.episodeSorting' => 'Ordenação de Episódios',
			'metadataEdit.oldestFirst' => 'Mais antigos primeiro',
			'metadataEdit.newestFirst' => 'Mais recentes primeiro',
			'metadataEdit.keep' => 'Manter',
			'metadataEdit.allEpisodes' => 'Todos os episódios',
			'metadataEdit.latestEpisodes' => ({required Object count}) => '${count} episódios mais recentes',
			'metadataEdit.latestEpisode' => 'Episódio mais recente',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => 'Episódios adicionados nos últimos ${count} dias',
			'metadataEdit.deleteAfterPlaying' => 'Excluir Episódios Após Reproduzir',
			'metadataEdit.never' => 'Nunca',
			'metadataEdit.afterADay' => 'Após um dia',
			'metadataEdit.afterAWeek' => 'Após uma semana',
			'metadataEdit.afterAMonth' => 'Após um mês',
			'metadataEdit.onNextRefresh' => 'Na próxima atualização',
			'metadataEdit.seasons' => 'Temporadas',
			'metadataEdit.show' => 'Mostrar',
			'metadataEdit.hide' => 'Ocultar',
			'metadataEdit.episodeOrdering' => 'Ordenação de Episódios',
			'metadataEdit.tmdbAiring' => 'The Movie Database (Exibição)',
			'metadataEdit.tvdbAiring' => 'TheTVDB (Exibição)',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB (Absoluto)',
			'metadataEdit.metadataLanguage' => 'Idioma dos Metadados',
			'metadataEdit.useOriginalTitle' => 'Usar Título Original',
			'metadataEdit.preferredAudioLanguage' => 'Idioma de Áudio Preferido',
			'metadataEdit.preferredSubtitleLanguage' => 'Idioma de Legenda Preferido',
			'metadataEdit.subtitleMode' => 'Modo de Seleção Automática de Legendas',
			'metadataEdit.manuallySelected' => 'Seleção manual',
			'metadataEdit.shownWithForeignAudio' => 'Exibir com áudio estrangeiro',
			'metadataEdit.alwaysEnabled' => 'Sempre ativado',
			'metadataEdit.tags' => 'Tags',
			'metadataEdit.addTag' => 'Adicionar tag',
			'metadataEdit.genre' => 'Gênero',
			'metadataEdit.director' => 'Diretor',
			'metadataEdit.writer' => 'Roteirista',
			'metadataEdit.producer' => 'Produtor',
			'metadataEdit.country' => 'País',
			'metadataEdit.collection' => 'Coleção',
			'metadataEdit.label' => 'Rótulo',
			'metadataEdit.quickTag' => 'Tag rápida...',
			'matchScreen.match' => 'Associar...',
			'matchScreen.fixMatch' => 'Corrigir correspondência...',
			'matchScreen.unmatch' => 'Desassociar',
			'matchScreen.unmatchConfirm' => 'Limpar esta correspondência? Plex tratará como sem correspondência até refazer.',
			'matchScreen.unmatchSuccess' => 'Item desassociado',
			'matchScreen.unmatchFailed' => 'Falha ao desassociar item',
			'matchScreen.matchApplied' => 'Correspondência aplicada',
			'matchScreen.matchFailed' => 'Falha ao aplicar correspondência',
			'matchScreen.titleHint' => 'Título',
			'matchScreen.yearHint' => 'Ano',
			'matchScreen.search' => 'Pesquisar',
			'matchScreen.noMatchesFound' => 'Nenhuma correspondência encontrada',
			'serverTasks.title' => 'Tarefas do servidor',
			'serverTasks.failedToLoad' => 'Falha ao carregar tarefas',
			'serverTasks.noTasks' => 'Nenhuma tarefa em execução',
			'trakt.title' => 'Trakt',
			'trakt.connected' => 'Conectado',
			'trakt.connectedAs' => ({required Object username}) => 'Conectado como @${username}',
			'trakt.disconnectConfirm' => 'Desconectar a conta do Trakt?',
			'trakt.disconnectConfirmBody' => 'O PlezyNG deixará de enviar eventos ao Trakt. Você pode reconectar quando quiser.',
			'trakt.scrobble' => 'Scrobbling em tempo real',
			'trakt.scrobbleDescription' => 'Envia eventos de reprodução, pausa e parada ao Trakt durante a exibição.',
			'trakt.watchedSync' => 'Sincronizar status de assistido',
			'trakt.watchedSyncDescription' => 'Ao marcar itens como assistidos no PlezyNG, eles também serão marcados no Trakt.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Conectar ao Seerr',
			'seerr.serverUrl' => 'URL do servidor',
			'seerr.serverUrlHelper' => 'O endereço da sua instância do Seerr',
			'seerr.checkServer' => 'Continuar',
			'seerr.signInWithJellyfin' => 'Entrar com Jellyfin',
			'seerr.signInWithEmby' => 'Entrar com Emby',
			'seerr.signInWithLocal' => 'Usar uma conta local',
			'seerr.email' => 'E-mail',
			'seerr.noSignInMethods' => 'Esta instância do Seerr não oferece nenhum método de acesso compatível com o PlezyNG.',
			'seerr.instance' => 'Instância',
			'seerr.disconnectConfirm' => 'Desconectar Seerr?',
			'seerr.disconnectConfirmBody' => 'O PlezyNG esquecerá esta instância do Seerr. Reconecte quando quiser.',
			'seerr.request' => 'Solicitar',
			'seerr.request4k' => 'Solicitar em 4K',
			'seerr.seasons' => 'Temporadas',
			'seerr.allSeasons' => 'Todas as temporadas',
			'seerr.advancedOptions' => 'Avançado',
			'seerr.destinationServer' => 'Servidor de destino',
			'seerr.qualityProfile' => 'Perfil de qualidade',
			'seerr.rootFolder' => 'Pasta raiz',
			'seerr.languageProfile' => 'Perfil de idioma',
			'seerr.tags' => 'Etiquetas',
			'seerr.noTags' => 'Sem etiquetas',
			'seerr.defaultOption' => ({required Object name}) => '${name} (padrão)',
			'seerr.animeNote' => 'Esta série é um anime.',
			'seerr.requestSubmitted' => 'Solicitação enviada',
			'seerr.requestFailed' => ({required Object error}) => 'Falha na solicitação: ${error}',
			'seerr.requestsLoadFailed' => 'Não foi possível carregar as opções de solicitação',
			'seerr.nothingToRequest' => 'Tudo já está disponível ou solicitado.',
			'seerr.statusAvailable' => 'Disponível',
			'seerr.statusPartiallyAvailable' => 'Parcialmente disponível',
			'seerr.statusRequested' => 'Solicitado',
			'seerr.statusProcessing' => 'Processando',
			'seerr.statusBlocklisted' => 'Na lista de bloqueio',
			'seerr.couldNotReach' => ({required Object url, required Object error}) => 'Não foi possível acessar ${url}: ${error}',
			'seerr.noInstanceAtUrl' => ({required Object url, required Object status}) => 'Nenhuma instância do Seerr em ${url} (HTTP ${status})',
			'seerr.behindAuthProxy' => 'Um proxy reverso com autenticação (SSO ou autenticação HTTP) respondeu no lugar do Seerr. O PlezyNG não consegue entrar através dele: permita que o caminho /api/v1 do Seerr ignore o proxy para este aplicativo, ou use um endereço que alcance o Seerr diretamente.',
			'seerr.invalidUrl' => 'Insira um endereço de servidor como https://seerr.example.com',
			'seerr.quickConnectUnsupported' => 'Esta instância do Seerr não oferece suporte a Quick Connect. Ela precisa do Seerr 3.4 ou mais recente.',
			'seerr.notInitialized' => 'Esta instância do Seerr não concluiu a configuração inicial',
			'seerr.noPlexTokenForReauth' => 'Nenhum token do Plex está disponível para entrar novamente',
			'seerr.noStoredCredentials' => 'Nenhuma credencial armazenada está disponível para entrar novamente',
			'seerr.signInRejected' => 'A entrada foi rejeitada',
			'seerr.noSessionCookie' => 'O Seerr não forneceu um cookie de sessão',
			'seerr.freshCookieRejected' => 'O Seerr rejeitou o novo cookie de sessão',
			'seerr.noUserInformation' => 'O Seerr não retornou informações do usuário',
			'seerr.sessionRejectedAfterReauth' => 'A sessão foi rejeitada após entrar novamente',
			'seerr.permissionDenied' => 'O Seerr negou esta ação: sua conta não tem mais a permissão necessária',
			'seerr.permissionRevoked' => 'Você não tem mais permissão para solicitar isso',
			'services.title' => 'Serviços',
			'services.hubSubtitle' => 'Sincronize o progresso de exibição e solicite novos títulos.',
			'services.integrations' => 'Integrações',
			'services.notConnected' => 'Não conectado',
			'services.connectedAs' => ({required Object username}) => 'Conectado como @${username}',
			'services.scrobble' => 'Registrar progresso automaticamente',
			'services.scrobbleDescription' => 'Atualiza sua lista quando você termina um episódio ou filme.',
			'services.disconnectConfirm' => ({required Object service}) => 'Desconectar ${service}?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'O PlezyNG deixará de atualizar ${service}. Reconecte quando quiser.',
			'services.connectFailed' => ({required Object service}) => 'Não foi possível conectar ao ${service}. Tente novamente.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.simklReconnect.title' => 'Reconectar o Simkl',
			'services.simklReconnect.subtitle' => 'O Simkl está desativando o método de acesso usado por esta conexão. Ao reconectar, o simkl.com será aberto para aprovar o PlezyNG — o PlezyNG nunca vê sua senha. Seu histórico de exibição continua no Simkl.',
			'services.deviceCode.title' => ({required Object service}) => 'Ativar o PlezyNG no ${service}',
			'services.deviceCode.instructions' => 'Leia o código QR ou acesse o endereço abaixo e insira este código:',
			'services.deviceCode.openToActivate' => ({required Object service}) => 'Abrir ${service} para ativar',
			'services.deviceCode.copyCode' => 'Copiar código de ativação',
			'services.deviceCode.waitingForAuthorization' => 'Aguardando autorização…',
			'services.deviceCode.codeCopied' => 'Código copiado',
			'services.oauthProxy.title' => ({required Object service}) => 'Entrar no ${service}',
			'services.oauthProxy.body' => 'Leia este código QR ou abra a URL em qualquer dispositivo.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => 'Abrir ${service} para entrar',
			'services.pendingAuth.copyUrl' => 'Copiar URL de acesso',
			'services.pendingAuth.urlCopied' => 'URL copiada',
			'services.libraryFilter.title' => 'Filtro de bibliotecas',
			'services.libraryFilter.subtitleAllSyncing' => 'Sincronizando todas as bibliotecas',
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
			'services.libraryFilter.modeDescription' => 'Escolha se as bibliotecas verificadas estão bloqueadas de sincronizar ou são as únicas bibliotecas que sincronizam.',
			'services.seerrDescription' => 'Conecte-se a Seerr ou Overseerr para pesquisar títulos e enviar pedidos de mídia.',
			'services.trackerDescriptions.trakt' => 'Sincronize episódios e filmes assistidos com sua conta Trakt.',
			'services.trackerDescriptions.mal' => 'Sincronize listas de anime e veja o progresso com MyAnimeList.',
			'services.trackerDescriptions.anilist' => 'Sincronize listas de anime e veja o progresso com AniList.',
			'services.trackerDescriptions.simkl' => 'Sync assistiu filmes, shows de TV e anime com Simkl.',
			'services.trackerDescriptions.mdblist' => 'Mostrar classificações e listas do MDBList em recomendações e Explore.',
			'addServer.addMediaBrowserTitle' => ({required Object product}) => 'Adicionar servidor ${product}',
			'addServer.serverUrls' => 'URLs do servidor',
			'addServer.serverUrlsHelper' => 'Várias URLs são permitidas, separadas por vírgulas.',
			'addServer.findServer' => 'Encontrar servidor',
			'addServer.searchingLocalMediaBrowserServers' => ({required Object product}) => 'Procurando servidores ${product} locais...',
			'addServer.localMediaBrowserServers' => ({required Object product}) => 'Servidores ${product} locais',
			'addServer.username' => 'Usuário',
			'addServer.password' => 'Senha',
			'addServer.signIn' => 'Entrar',
			'addServer.change' => 'Alterar',
			'addServer.required' => 'Obrigatório',
			'addServer.couldNotReachServer' => ({required Object error}) => 'Não foi possível conectar ao servidor: ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'Falha ao entrar: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Quick Connect falhou: ${error}',
			'addServer.addPlexTitle' => 'Entrar com Plex',
			'addServer.pinExpired' => 'O PIN expirou antes de entrar. Tente novamente.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'Falha ao registrar a conta: ${error}',
			'addServer.enterMediaBrowserUrlError' => ({required Object product}) => 'Digite a URL do seu servidor ${product}',
			'addServer.addConnectionTitle' => 'Adicionar conexão',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => 'Adicionar a ${name}',
			'addServer.signInWithPlexCard' => 'Entrar com Plex',
			'addServer.signInWithPlexCardSubtitle' => 'Autorize este dispositivo. Servidores compartilhados são adicionados.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Autorize uma conta Plex. Os usuários do Plex Home se tornam perfis.',
			'addServer.connectToMediaBrowserCard' => ({required Object product}) => 'Conectar ao ${product}',
			'addServer.connectToMediaBrowserCardSubtitle' => 'Digite a URL do servidor, o nome de usuário e a senha.',
			'addServer.connectToMediaBrowserCardSubtitleScoped' => ({required Object product, required Object name}) => 'Entre no seu servidor ${product}. Vinculado a ${name}.',
			'addServer.borrowFromAnotherProfile' => 'Pegar emprestado de outro perfil',
			'addServer.borrowFromAnotherProfileSubtitle' => 'Reutilize a conexão de outro perfil. Perfis protegidos por PIN exigem PIN.',
			'addServer.invalidCredentials' => 'Usuário ou senha inválidos',
			'addServer.authResponseNotJson' => 'A resposta de autenticação não era um JSON válido',
			'addServer.authResponseIncomplete' => 'A resposta de login do servidor estava incompleta',
			'addServer.quickConnectRejected' => 'O Quick Connect foi rejeitado pelo servidor',
			'addServer.quickConnectNotJson' => 'A resposta do Quick Connect não era um JSON válido',
			'addServer.quickConnectMissingFields' => 'A resposta do Quick Connect não contém um código ou segredo',
			'addServer.quickConnectPollRejected' => 'A consulta do Quick Connect foi rejeitada pelo servidor',
			'addServer.serverTimedOut' => 'O servidor não respondeu a tempo',
			'addServer.responseNotJson' => 'A resposta do servidor não era um JSON válido',
			'addServer.responseMissingIdentity' => ({required Object product}) => 'A resposta não contém um ID ou nome de servidor — este é um servidor ${product}?',
			'addServer.probeFailed' => ({required Object error}) => 'Não foi possível conectar ao servidor: ${error}',
			'addServer.enterAtLeastOneUrl' => ({required Object product}) => 'Insira pelo menos uma URL de servidor ${product}',
			'addServer.noReachableServer' => ({required Object product}) => 'Nenhum servidor ${product} acessível foi encontrado',
			'addServer.urlsPointToDifferentServers' => ({required Object product}) => 'Estas URLs apontam para servidores ${product} diferentes',
			'addServer.urlDoesNotMatchServer' => ({required Object product}) => 'Esta URL não corresponde ao servidor ${product}',
			'addServer.redirectUnsupported' => 'O servidor redirecionou para uma URL não compatível',
			'addServer.redirectDifferentHost' => ({required Object product}) => 'O servidor redirecionou para outro host. Insira diretamente a URL final do ${product}.',
			'addServer.redirectInsecure' => 'O servidor redirecionou de HTTPS para uma URL insegura',
			'addServer.redirectUnsupportedEnterFinal' => ({required Object product}) => 'O servidor redirecionou para uma URL não compatível. Insira diretamente a URL final do ${product}.',
			'addServer.directPlexServerUrl' => 'URL do servidor Plex',
			'addServer.directPlexServerUrlHelper' => 'Entre o IP local e o portão do seu Plex Media Server.',
			'addServer.directPlexServerUrlHint' => 'http://192.168.1.100:32400',
			'addServer.plexToken' => 'Plex Token (opcional)',
			'addServer.plexTokenHelper' => 'Deixe o acesso branco se o acesso sem auth for permitido neste servidor.',
			'addServer.plexTokenRequired' => 'Verificação requerida. por favor, entre seu token Plex (X-Plex-Token).',
			'addServer.connectDirectPlexCard' => 'Plex Serviço de Mídia (Direito / Local)',
			'addServer.connectDirectPlexCardSubtitle' => 'Conecte-se diretamente usando IP local ou URL sem conta plex.tv.',
			'addServer.connectDirectPlexCardSubtitleScoped' => ({required Object name}) => 'Conecte-se diretamente usando o IP local ou URL. Conecte-o a ${name}.',
			'addServer.insecureTitle' => 'conexão não criptografada',
			'addServer.insecureDescription' => ({required Object url}) => '${url} utiliza HTTP. Outras pessoas na rede podem ler ou alterar a sua palavra-passe, os seus tokens e os seus conteúdos multimédia. Utilize HTTPS quando estiver disponível. Continue apenas se confiar nesta rede e aceitar o risco.',
			'addServer.allowHttp' => 'Permitir HTTP',
			'addServer.httpsRequired' => 'Use HTTPS ou permita expressamente uma conexão não criptografada.',
			'cast.chooseDevice' => 'Caminhar para um dispositivo',
			'cast.searching' => 'Buscando por dispositivos de cast...',
			'cast.connectedTo' => ({required Object device}) => 'Conectado a ${device}',
			'cast.device' => 'CAST DEFINITOR',
			'cast.readyToCast' => 'Pronto para jogar',
			'cast.subtitle' => 'Legendas',
			'cast.serverNotAvailable' => 'O servidor de mídia não está disponível.',
			'cast.stopCasting' => 'Parar de casting',
			'cast.castToDevice' => 'Capa para o dispositivo',
			'cast.noEpisodeAvailable' => 'Não há episódio disponível para ser lançado.',
			'cast.startFailed' => 'Não pode começar a casting. verificar o servidor e tentar novamente.',
			'automation.noActivePlayback' => 'Não há sessão de vídeo ativa para controlar.',
			'notifications.newEpisodeTitle' => 'Novo episódio',
			'notifications.newEpisodeBody' => ({required Object show, required Object episode}) => '${show} · ${episode}',
			'appAccess.title' => 'Tente todos os recursos grátis por 7 dias',
			'appAccess.description' => 'Comece um teste de sete dias com acesso completo a cada funcionalidade PlezyNG. não há taxa durante o teste e não há assinatura. Após o teste, uma compra de vida no preço da sua loja desbloqueia PlezyNG para a vida.',
			'appAccess.trialEndedDescription' => 'Desbloquear cada funcionalidade em PlezyNG para a vida com uma compra ao preço da sua loja.',
			'appAccess.startTrial' => 'Começa o meu teste gratuito de 7 dias',
			'appAccess.trialActive' => 'Seu teste de 7 dias de função completa está ativo.',
			'appAccess.trialEnded' => 'Seu julgamento de 7 dias terminou',
			'appAccess.trialStartFailed' => 'Não consigo salvar o teste neste dispositivo. por favor tente novamente.',
			'appAccess.lifetimeTitle' => 'PlezyNG desbloqueado para a vida',
			'appAccess.lifetimeBody' => 'Você tem acesso ao tempo todo a cada funcionalidade PlezyNG.',
			'appAccess.manageTitle' => 'PlezyNG acesso ao tempo de vida',
			'appAccess.manageDescription' => 'Tente cada recurso gratuito por 7 dias, depois desbloquee tudo para a vida com um pagamento ao preço da sua loja.',
			'appAccess.buy' => ({required Object price}) => 'Desbloquear todas as funcionalidades para ${price}',
			'appAccess.loadingPrice' => 'Preço de Loading Store...',
			'appAccess.retryPrice' => 'Retorno do preço Lookup',
			'appAccess.restore' => 'Restaurar a compra de vida',
			'appAccess.pending' => 'Sua compra está à espera de pagamento ou aprovação. acesso ao tempo integral desbloqueia assim que a loja o concluir.',
			'appAccess.storeUnavailable' => 'Verifique se você está assinado na loja e as compras são permitidas neste dispositivo.',
			'appAccess.productNotFound' => 'O PlezyNG de desbloqueio de vida ainda não está disponível neste lote.',
			'appAccess.productQueryFailed' => 'Não podia carregar o preço da loja. Verifique a sua conexão e tente novamente.',
			'appAccess.purchaseFailed' => 'A compra não passou, tente novamente.',
			'appAccess.restoreFailed' => 'Não poderia chegar à loja para restaurar a sua compra. tente novamente.',
			'appAccess.nothingToRestore' => 'No PlezyNG compra de vida foi encontrado para esta conta da loja.',
			'detail.endsAt' => ({required Object time}) => 'Termina às ${time}',
			'watchLink.serverUnavailable' => 'Não poderia chegar a um servidor Plex para este link.',
			'watchLink.notFound' => 'Não poderia encontrar este show ou filme em seus servidores Plex.',
			'watchLink.ambiguous' => 'Este link se encaixa com itens em mais de um servidor.Add a server to the link.',
			'watchLink.plexOnly' => 'Os links de visualização atualmente só suportam Plex servidores.',
			'watchLink.unsupportedItem' => 'Veja links só pode abrir um show ou um filme.',
			'watchLink.menuItem' => 'Veja o link',
			'watchLink.dialogTitle' => 'Veja o link',
			'watchLink.dialogShowHint' => 'Ao abrir este link, o próximo episódio é jogado.Add &mode=shuffle para o final para jogar o show no shuffle.',
			'watchLink.dialogMovieHint' => 'Ao abrir este link, o filme é jogado.',
			'watchLink.copy' => 'Copia',
			'watchLink.copied' => 'Link copiado',
			'homeLayout.title' => 'Home Layout',
			'homeLayout.resetToast' => 'Home Reset para o layout original Plezy herói',
			'homeLayout.resetHeroTitle' => 'Resetando o layout do herói para a estoque Plezy?',
			'homeLayout.resetHeroBody' => 'Desligue a configuração de herói de cada linha e retorna o único banner de rotação na parte superior da Casa, como antes que as linhas de herói existissem.',
			'homeLayout.removeRowTitle' => 'Remover a linha de casa?',
			'homeLayout.removeRowBody' => ({required Object title}) => '${title} será excluído. isto não pode ser negado.',
			'homeLayout.sync' => 'Síntese',
			'homeLayout.syncAccountTitle' => 'Sincronize layout com sua conta Plex',
			'homeLayout.syncAccountOn' => 'On: este dispositivo compartilha ordem de linha, linhas, Hero e Auto-slide com os outros dispositivos.',
			'homeLayout.syncAccountOff' => 'Desligado: este dispositivo mantém o seu próprio layout.',
			'homeLayout.syncNow' => 'Síntese agora',
			'homeLayout.plexHomeManager' => 'Plex Gestor de casa',
			'homeLayout.managePlexRows' => 'Gestão Plex linhas em Plezy',
			'homeLayout.managePlexRowsDescription' => 'Abre para organizar as linhas selecionadas em casa',
			'homeLayout.organizeHomeRows' => 'Organize as linhas domésticas',
			'homeLayout.organizeHomeRowsDescription' => ({required Object n}) => '${n} linhas: movimento, herói, auto-slide, remover',
			'homeLayout.organizeLibraryRows' => ({required Object library}) => 'Organize ${library} linhas',
			'homeLayout.organizeLibraryRowsDescription' => ({required Object n}) => 'Continue a assistir + ${n} linhas: movimento, Biblioteca, Home, Hero, Auto-slide',
			'homeLayout.renderAsHero' => 'Render como um cartão de herói',
			'homeLayout.heroOnlySingleCollection' => 'Disponível somente quando esta linha resolve os títulos reais de uma coleção única',
			'homeLayout.hero' => 'Herói',
			'homeLayout.autoSlide' => 'Auto-Slide',
			'homeLayout.autoSlideDescription' => 'As entradas (PC) e o d-pad (TV) sempre funcionam e reiniciar o timer.',
			'homeLayout.autoSlideEditDescription' => 'Também desliza por conta própria a cada alguns segundos. desligado: só se move quando você clicar em uma bala (PC) ou pressionar esquerda/direita no remoto (TV).',
			'homeLayout.enableHeroFirst' => 'Primeiro, o herói',
			'homeLayout.showOnHome' => 'Mostrando em Home Screen',
			'homeLayout.home' => 'Início',
			'homeLayout.removeFromHome' => 'Remover de casa',
			'homeLayout.selectRowsFirst' => 'Selecione as linhas de casa abaixo primeiro.',
			'homeLayout.plexManagedRows' => ({required Object n}) => '${n} Plex linhas gerenciadas',
			'homeLayout.continueWatching' => 'Continuar Assistindo',
			'homeLayout.continueWatchingLibraryDescription' => 'A própria linha de progresso da biblioteca',
			'homeLayout.continueWatchingHomeDescription' => 'A linha de progressão de recesso mostrada em Home',
			'homeLayout.nextUpHomeDescription' => 'A próxima sequência de episódios não observados mostrada separadamente em Home',
			'homeLayout.library' => 'Biblioteca',
			'homeLayout.showInRecommended' => 'Exposição em Biblioteca Recomendada',
			'homeLayout.customPlexRow' => 'Cadeia de Cadeia Plex',
			'homeLayout.heroNeedsLibrary' => 'Veja a Biblioteca primeiro – Hero precisa de algum lugar para mostrar',
			'homeLayout.heroNeedsSurface' => 'Veja a Biblioteca ou a Casa primeiro — Hero precisa de algum lugar para mostrar',
			'homeLayout.removeHub' => 'Remover o Hub',
			'homeLayout.noPlexRows' => 'No Plex linhas gerenciadas retornou para esta biblioteca.',
			'homeLayout.openDetails' => 'Detalhes abertos',
			'homeLayout.heroCards' => 'Cartões de herói',
			'homeLayout.tapHeroCard' => 'Tapeando um cartão de herói',
			'homeLayout.tvPlayFocus' => 'TV remoto: botão de gravação',
			'homeLayout.tvPlayFocusDescription' => 'O D-pad para baixo parou no botão Play antes de se mover para a próxima linha.',
			'homeLayout.tvWrap' => 'TV remoto: cartões de heroína de loop',
			'homeLayout.tvWrapDescription' => 'Direito no último cartão vai para o primeiro. off paradas no último cartões. esquerda no primeiro cartão sempre vai para a barra lateral.',
			'homeLayout.castOnHero' => 'Apresentação de Banner Hero',
			'homeLayout.castOnHeroDescription' => 'Mostra o cast along the bottom of a hero banner. Off mantém apenas o título e resumo.',
			'homeLayout.customRows' => 'Roda personalizada',
			'homeLayout.loading' => 'Apresentação de layout...',
			'homeLayout.noCustomRows' => 'Não há rodas de costume ainda',
			'homeLayout.addRowHint' => 'Use Acesso à linha de casa para criar uma.',
			'homeLayout.addHomeRow' => 'Adicionar Home Rue',
			'homeLayout.addHomeRowDescription' => 'Escolha uma categoria; a nova linha é adicionada ao Organizador automaticamente',
			'homeLayout.removeRow' => 'Remover a linha',
			'homeLayout.recentlyAdded' => 'Adicionados recentemente',
			'homeLayout.recentlyReleased' => 'Recentemente liberado',
			'homeLayout.movieCollections' => 'Filmes Colecções',
			'homeLayout.showCollections' => 'Mostrar coleções',
			'homeLayout.rowTitle' => 'RODO Título',
			'homeLayout.content' => 'Conteúdo',
			'homeLayout.showThisRowIn' => 'Mostre esta linha em:',
			'homeLayout.libraryRecommended' => 'Biblioteca recomendada',
			'homeLayout.heroCard' => 'Cartão de herói',
			'homeLayout.heroCardDescription' => 'Mostra como uma cartão de rotação de largura completa em vez de um poster shelf.',
			'homeLayout.heroUnavailableDescription' => 'Disponível apenas quando esta linha resolve os títulos reais de uma coleção única – com mais de uma colecionada selecionada não há nenhum título para girar.',
			'homeLayout.librariesSelection' => 'Livrarias (deixe todas as bibliotecas não verificadas para incluir todas as bibliotecarias)',
			'homeLayout.librariesMergedDescription' => 'Cada biblioteca que você assistir aqui é misturada nesta linha.',
			'homeLayout.movieCollectionsSelection' => 'Colecções de filmes (deixe todos não verificados para cada biblioteca selecionada)',
			'homeLayout.showCollectionsSelection' => 'Mostrar coleções (deixe todas as bibliotecas não verificadas para cada biblioteca selecionada)',
			'homeLayout.collectionRowsDescription' => 'Se exatamente uma coleção se encaixa, seus títulos se mostram diretamente na linha.Se mais de uma coleção encaixa e cada coleção se mostra como um único poster, clique em ela para abrir essa coleção.',
			'homeLayout.allCollections' => 'Todas as coleções',
			'homeLayout.noRowsHere' => 'Não há linhas aqui ainda.',
			'homeLayout.hideWatchedRows' => 'Esconde itens observados em linhas',
			'homeLayout.hideWatchedRowsDescription' => 'Títulos totalmente assistidos deixam Casa e biblioteca Sinais recomendados.',
			'homeLayout.untitledCollection' => 'Colecção sem título',
			'homeLayout.moveRowHint' => 'Up/Down: mover a linha · Selecione: desligue aqui · Retorno: cancelar',
			'homeLayout.organizeRowsHint' => 'Selecione uma linha (ou mantenha Selecione): mova-a · esquerda/direita: opções de linha · Volta: feito',
			'homeLayout.layoutNavDescription' => 'Escolha linhas, bibliotecas e categorias de coleção',
			'homeLayout.editHomeRow' => 'Edit Home Roda',
			'homeLayout.resetHeroButton' => 'Resetar layout de herói para stock Plezy',
			'homeLayout.reorderingUnlocked' => 'Reorganização desbloqueada',
			'homeLayout.reorderingLocked' => 'Reorganização fechada',
			'homeLayout.rowsCanBeDragged' => 'As cordas podem ser tiradas — toque no fechamento para evitar que',
			'homeLayout.tapLockToDrag' => 'Tire o fechamento para traçar as linhas',
			'homeLayout.customRowLabel' => ({required Object title}) => 'Cadeia: ${title}',
			'homeLayout.libraryHubLabel' => ({required Object library, required Object hub}) => '${library}: ${hub}',
			'homeLayout.hide' => 'Ocultar',
			'homeLayout.remove' => 'Remover',
			'homeLayout.libraryResumeRow' => 'A Biblioteca de Resumo',
			'homeLayout.pressAgainToDelete' => 'Pressione novamente para apagar',
			'homeLayout.actionState' => ({required Object action, required Object state}) => '${action}: ${state}',
			'homeLayout.on' => 'em',
			'homeLayout.resetHeroButtonDescription' => 'Retorna a configuração do herói de cada linha e traz o único banner de rotação para cima, como antes que as linhas de herói existiam.',
			'homeLayout.tapHeroCardDescription' => 'Escolha se tapando ou selecionando um cartão Hero começa a reproduzir ou abre seus detalhes.',
			'homeLayout.heroTapPlayDescription' => 'Comece o item selecionado imediatamente.',
			'homeLayout.heroTapDetailsDescription' => 'Abra os detalhes do item selecionado antes de escolher uma ação.',
			'platform.localNetworkPermission' => 'PlezyNG conecta-se aos seus servidores de mídia e dispositivos de reprodução na sua rede local.',
			'platform.locationPermission' => 'PlezyNG usa o acesso à localização quando o iOS o exige para detectar sua rede local e conectar-se aos seus servidores de mídia.',
			'platform.photoLibraryPermission' => 'Escolha imagens da sua biblioteca de fotos para usar como capas e ilustrações dos arquivos de mídia.',
			'platform.cameraPermission' => 'Escanear códigos QR para combinar um Companion Remote.',
			'universalMedia.title' => 'Mídia aberta',
			'universalMedia.shortcutHelp' => 'Jogue um link, playlist ou arquivo para esta sessão.',
			'universalMedia.intro' => 'Abra um link, playlist ou arquivo. o Playback usa o jogador padrão do PlezyNG e não adiciona história à sua biblioteca.',
			'universalMedia.openWhat' => 'O que você gostaria de abrir?',
			'universalMedia.stream' => 'Endereço de Stream',
			'universalMedia.playlist' => 'Playlist',
			'universalMedia.files' => 'Arquivos de dispositivos',
			'universalMedia.favorites' => 'Redução dos favoritos',
			'universalMedia.address' => 'Endereço de mídia',
			'universalMedia.addressHelp' => 'URLs com parâmetros de autenticação ou assinatura reconhecidos são usados apenas para esta sessão e não podem ser salvos como favoritos.',
			'universalMedia.displayName' => 'Nome de exibição (opcional)',
			'universalMedia.displayNameHelp' => 'Escolha um nome curto para o jogador e controles de mídia do sistema.',
			'universalMedia.allowHttp' => 'Permitir uma conexão HTTP não criptografada',
			'universalMedia.allowHttpHelp' => 'O HTTP não criptografará a conexão. permita-a apenas em uma rede confiável. Use o HTTPS quando possível.',
			'universalMedia.advancedProtocols' => 'MPV somente: introduza um endereço RTSP, RTMP/RTMPS, UDP ou RTP. Esses endereços não podem ser salvos como favoritos.',
			'universalMedia.liveStream' => 'Tratar como vivo',
			'universalMedia.liveStreamHelp' => 'Use isso para vídeo ou rádio ao vivo.A aplicação esconde a barra de tempo, botões de escape e opção go-to-time.',
			'universalMedia.privateSession' => 'Apenas esta reprodução usa o endereço.Save a favor de um fluxo elegível para mantê-lo neste perfil.',
			'universalMedia.saveFavorite' => 'Salve o favorito',
			'universalMedia.playNow' => 'Jogue agora',
			'universalMedia.favoriteSaved' => 'Stream favorito salvo para este perfil',
			'universalMedia.skippedEntries' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: 'Escapou ${count} entrada de playlist não suportada ou insegura.', many: 'Escapou ${count} entradas de lista de reprodução não suportadas ou inseguras.', other: 'Escapou ${count} entradas de lista de reprodução não suportadas ou inseguras.', ), 
			'universalMedia.playlistAddress' => 'Endereço Playlist',
			'universalMedia.playlistAddressHelp' => 'Abra uma lista de reprodução M3U, M3u8, ou PLS a partir de um endereço web. links de streaming direto não salvam a lista.',
			'universalMedia.choosePlaylist' => 'Escolha o arquivo de playlist',
			'universalMedia.openPlaylist' => 'Playlist aberta',
			'universalMedia.playlistFormatsHelp' => 'Uma lista de reprodução pode conter até 1.000 itens e 2 MB. HLS manifesta-se aberta como fluxos para que o jogador possa escolher uma qualidade.',
			'universalMedia.saveQueuePlaylist' => 'Guardar fila como lista de reprodução',
			'universalMedia.queuePlaylistSaved' => 'A lista de reprodução foi guardada junto aos ficheiros multimédia.',
			'universalMedia.queuePlaylistUnavailable' => 'Esta fila não pode ser guardada como uma lista local reutilizável.',
			'universalMedia.queuePlaylistFolderRequired' => 'Escolha uma localização na mesma pasta dos ficheiros da fila.',
			'universalMedia.noFavorites' => 'Não foram salvos favoritos ainda. favoritos permanecem neste perfil.',
			'universalMedia.removeFavorite' => 'Remover streaming favorito',
			'universalMedia.filesHelp' => 'Escolha arquivos de áudio, vídeo ou ISO para uma quebra temporária. arquivos e URLs não são adicionados ao histórico da biblioteca.',
			'universalMedia.chooseFiles' => 'Escolha arquivos',
			'universalMedia.fileQueue' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '1 arquivo selecionado', many: '${count} arquivos selecionados', other: '${count} arquivos selecionados', ), 
			'universalMedia.wifiTransfer' => 'Enviar arquivos por Wi-Fi',
			'universalMedia.wifiTransferHelp' => 'Transferir arquivos suportados de um navegador na mesma rede confiável.',
			'universalMedia.wifiTransferIntro' => 'Abra este endereço num navegador em outro dispositivo. selecione arquivos para adicioná-los à biblioteca de Arquivos e Livros deste dispositivo.',
			'universalMedia.wifiTransferPrivacy' => 'Este dispositivo recebe arquivos através da sua rede local. Qualquer pessoa que conhece este endereço pode enviar arquivos até você parar a transferência ou o endereçamento expira após 15 minutos. Máximo: 100 arquivos, 4 GiB por arquivo, 10 GiB total.',
			'universalMedia.wifiTransferStarting' => 'Preparação de uma transferência privada, limitada ao tempo...',
			'universalMedia.wifiTransferUnavailable' => 'Não pode iniciar a transferência. Verifique o acesso da rede local e tente novamente.',
			'universalMedia.openThisAddress' => 'Abra um desses endereços no dispositivo de envio',
			'universalMedia.copyAddress' => 'Cópia do endereço de transferência',
			'universalMedia.addressCopied' => 'Endereço de transferência copiado',
			'universalMedia.transferExpires' => ({required Object time}) => 'Este endereço expira em ${time}.',
			'universalMedia.uploadCount' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: 'arquivo ${count} recebido', many: 'arquivos ${count} recebidos', other: 'arquivos ${count} recebidos', ), 
			'universalMedia.uploadedData' => ({required Object size}) => 'Recebido ${size}',
			'universalMedia.stopTransfer' => 'Cessar transferência e invalidar endereço',
			'universalMedia.startTransfer' => 'Início Transferência',
			'universalMedia.wifiImportedFiles' => 'Transferência Wi-Fi',
			'universalMedia.wifiBrowserTitle' => 'Enviar arquivos para PlezyNG',
			'universalMedia.wifiBrowserIntro' => 'Escolha arquivos de áudio, vídeo, ebook ou comédia para enviar. Os arquivos são salvos na biblioteca dos arquivos e livros deste dispositivo. Máximo: 100 arquivos, 4 GiB por arquivo, 10 GiB total.',
			'universalMedia.uploadFilesLabel' => 'Arquivos para enviar',
			'universalMedia.uploadSelected' => 'Carregar arquivos selecionados',
			'universalMedia.uploadSelectFirst' => 'Escolha um ou mais arquivos primeiro.',
			'universalMedia.uploading' => 'Envio',
			'universalMedia.uploadComplete' => 'Arquivo adicionado para PlezyNG.',
			'universalMedia.uploadFailed' => 'O arquivo não pode ser adicionado.Mantenha esta página aberta e tente novamente.',
			'universalMedia.liveCue' => 'Viva',
			'universalMedia.liveSession' => 'Streaming ao vivo',
			'universalMedia.liveCueHelp' => 'Para vídeo ou rádio ao vivo, o aplicativo esconde a barra de tempo e escapa os botões.',
			'universalMedia.sessionOnly' => 'Este playback é apenas sessão',
			'universalMedia.sessionOnlyHelp' => 'Playback nunca salva progresso ou história. Salve o fluxo como um favorito para mantê-lo neste perfil se é elegível.',
			'universalMedia.pictureAdjustments' => 'Adaptação de imagem',
			'universalMedia.pictureHelp' => 'Essas mudanças de imagem afetam apenas este playback. eles se resistem quando o playback termina.',
			'universalMedia.resetPicture' => 'Resetando a imagem',
			'universalMedia.brightness' => 'brilho',
			'universalMedia.contrast' => 'Contraste',
			'universalMedia.gamma' => 'Gama',
			'universalMedia.hue' => 'Hue',
			'universalMedia.saturation' => 'Saturno',
			'universalMedia.view360' => 'Vista plana para 360° de vídeo',
			'universalMedia.view360Help' => 'Use isso para o vídeo 360° equirectangular. MPV precisa do filtro v360 da FFmpeg para esta visualização.',
			'universalMedia.view360Unavailable' => 'Esta configuração mpv não poderia aplicar o filtro de 360°.',
			'universalMedia.view360Yaw' => 'Visão Horizontal',
			'universalMedia.view360Pitch' => 'Visão Vertical',
			'universalMedia.view360FieldOfView' => 'Campo de Visão',
			'universalMedia.recordStream' => 'Recordes de streaming ao vivo',
			'universalMedia.stopRecording' => 'Parar e salvar a gravação',
			'universalMedia.recordingStarted' => 'A gravação é ativa. deixando o playback parou e salva a gravación.',
			'universalMedia.recordingSaved' => 'A gravação foi concluída e salvada.',
			'universalMedia.recordingActive' => 'Deixe o playback parar e salve.',
			'universalMedia.recordingFormatHelp' => 'Para vídeo, selecione MKV ou MPEG-TS. Para áudio, escolha MKA ou MKV.',
			'universalMedia.replaceRecordingTitle' => 'Substitui essa gravação?',
			'universalMedia.replaceRecordingHelp' => 'O PlezyNG recupera o arquivo existente durante a gravação.Se não consegue salvar o novo registro, o plezyNG restaura o backup.',
			'universalMedia.replaceRecording' => 'Substituição de arquivo',
			'universalMedia.discHelp' => 'Abra um disco no disco óptico deste computador. Você também pode abrir uma imagem ISO dos arquivos de dispositivo.',
			'universalMedia.discs' => 'Discos ópticos',
			'universalMedia.editionOrTitle' => 'Edição ou título do disco',
			'universalMedia.dvd' => 'DVD',
			'universalMedia.bluray' => 'Blu-ray em',
			'universalMedia.audioCd' => 'CD de áudio',
			'universalMedia.discAvailability' => 'A reprodução de discos precisa de um edifício MPV compatível, disco suportado e permissão do sistema operacional.',
			'universalMedia.converterTitle' => 'Converter um arquivo de mídia local',
			'universalMedia.converterHelp' => 'Converter um arquivo local ou remuque-o com FFmpeg.',
			'universalMedia.converterIntro' => 'Converter um arquivo de áudio ou vídeo local para um formato que funciona em vários dispositivos.',
			'universalMedia.converterPrivacy' => 'FFmpeg deve ser instalado neste computador. conversão lê apenas arquivos locais. não descarga fluxos ou remove DRM.',
			'universalMedia.converterChooseInput' => 'Escolha um arquivo de mídia local',
			'universalMedia.converterFormat' => 'Formato de saída',
			'universalMedia.converterMp4' => 'MP4 · H.264 e AAC',
			'universalMedia.converterM4a' => 'M4A - Áudio AAC',
			'universalMedia.converterMp3' => 'MP3 - Áudio',
			'universalMedia.allowFtp' => 'Permitir FTP',
			'universalMedia.allowFtpHelp' => 'FTP envia mídias sem criptografia. Use apenas em redes confiáveis.',
			'universalMedia.converterSaveAs' => 'Mídia convertida como',
			'universalMedia.converterExtensionMismatch' => 'Escolha um nome de arquivo com a extensão de saída selecionada.',
			'universalMedia.converterUnsupportedInput' => 'Escolha um arquivo de áudio ou vídeo.',
			'universalMedia.converterLocalOnly' => 'O arquivo selecionado não está disponível como um caminho de dispositivo local.',
			'universalMedia.converterReplaceTitle' => 'Substitui esse arquivo?',
			'universalMedia.converterReplaceHelp' => 'PlezyNG recupera o arquivo existente até que a cópia convertida seja salvida.',
			'universalMedia.converterStarting' => 'Começando com FFmpeg...',
			'universalMedia.converterProgress' => 'Converter para esse computador...',
			'universalMedia.converterComplete' => 'Conversão completa. o novo arquivo está pronto.',
			'universalMedia.converterFfmpegMissing' => 'FFmpeg está faltando ou não suporta este formato.',
			'universalMedia.converterFailed' => 'Verifique se o arquivo fonte pode ser lido e o destino tem espaço livre suficiente.',
			'universalMedia.converterCancelled' => 'A conversão foi cancelada. a saída incompleta foi removida.',
			'universalMedia.converterDesktopOnly' => 'A conversão local está disponível em computadores de desktop com FFmpeg instalado.',
			'universalMedia.converterStart' => 'Conversão de arquivos',
			'universalMedia.mediaToolsTitle' => 'Ferramentas de mídia',
			'universalMedia.mediaToolsShortcut' => 'Capturar ou compartilhar mídia, adicionar extensões de pesquisa, ou usar a linha de comando.',
			'universalMedia.mediaToolsIntro' => 'Escolha uma ferramenta focada. capturar e stream-out usar FFmpeg instalado neste desktop. extensões e comandos CLI usar pedidos HTTPS limitados e o fluxo Open media existente.',
			'universalMedia.mediaToolsAccessibility' => 'As opções de ferramentas e controles funcionam com o toque, indicador, teclado e foco D-pad. As mudanças no status de gravação, compartilhamento e pesquisa são anunciadas.',
			'universalMedia.mediaTool' => 'Ferramentas de mídia',
			'universalMedia.captureIntro' => 'Recorde a sua tela ou uma câmera para um arquivo MP4 neste computador. FFmpeg deve ser instalado e incluir o codificador H.264.',
			'universalMedia.captureNoDevices' => 'Não foi encontrado nenhum ecrã ou câmera. Verifique o suporte de captura da FFmpeg e permissões de privacidade do sistema operacional.',
			'universalMedia.captureSource' => 'tela ou câmera',
			'universalMedia.captureScreen' => 'ecrã',
			'universalMedia.captureAudioSource' => 'Introdução de áudio (opcional)',
			'universalMedia.captureAudioHelp' => 'Adicione áudio a partir de um microfone ou entrada disponível. as escolhas do dispositivo dependem da FFmpeg e das permissões do sistema.',
			'universalMedia.captureAudioNone' => 'Não há áudio',
			'universalMedia.captureDefaultAudio' => 'Introdução de áudio',
			'universalMedia.captureWaylandHelp' => 'Wayland limita esta captura XWayland para o X display. Windows fora XWayland pode não aparecer.',
			'universalMedia.captureFrameRate' => 'Rápido de gravação',
			_ => null,
		} ?? switch (path) {
			'universalMedia.capturePrivacy' => 'A gravação é salvida apenas para o arquivo que você escolher. captura de microfone é opcional. PlezyNG não carrega a gravação.',
			'universalMedia.captureSaveAs' => 'Salve a gravação de tela como',
			'universalMedia.captureExtensionMismatch' => 'Escolha um nome de arquivo que termina em .mp4.',
			'universalMedia.captureFfmpegMissing' => 'FFmpeg ou o codificador de vídeo H.264 não está disponível. instale um edifício FFmpeg suportado, então tente novamente.',
			'universalMedia.captureFailed' => 'Verifique permissão do dispositivo, armazenamento disponível e suporte FFmpeg.',
			'universalMedia.captureSaved' => 'A gravação de tela foi salvida.',
			'universalMedia.captureElapsedLabel' => 'Tempo de gravação',
			'universalMedia.captureStart' => 'Começa a gravação',
			'universalMedia.capturePreview' => 'Pré-visualizar no leitor',
			'universalMedia.capturePreviewHelp' => 'Pré-visualize a origem selecionada no leitor padrão. A pré-visualização só dura nesta sessão e não guarda uma gravação. O suporte dos dispositivos e as permissões dependem do MPV e do sistema operativo. A pré-visualização usa apenas vídeo; as gravações guardadas podem incluir áudio opcional.',
			'universalMedia.capturePreviewActive' => 'Pré-visualização em direto · sem gravação',
			'universalMedia.captureStop' => 'Parar e salvar',
			'universalMedia.captureMode' => 'captura',
			'universalMedia.shareMode' => 'Compartilhar',
			'universalMedia.shareIntro' => 'Envie um arquivo de mídia local para outro dispositivo em sua rede privada. PlezyNG cria um fluxo temporário HLS.',
			'universalMedia.sharePrivacy' => 'Qualquer pessoa na sua rede local que recebe o link privado pode assistir enquanto estiver ativo. o link expira após 60 minutos. parar de compartilhar para fechar o servidor e invalidar o link.',
			'universalMedia.shareChooseFile' => 'Escolha o arquivo de mídia',
			'universalMedia.shareChooseHelp' => 'Selecione um arquivo local de áudio ou vídeo. o arquivo permanece neste computador.',
			'universalMedia.shareFfmpegMissing' => 'FFmpeg ou os codificadores H.264/AAC não estão disponíveis. instalar FFmpeg com o suporte de codificação H.264 e AAC.',
			'universalMedia.shareFailed' => 'O fluxo não podia começar ou parar inesperadamente. verificar FFmpeg e acesso à rede.',
			'universalMedia.shareActive' => 'O fluxo está pronto na sua rede privada.',
			'universalMedia.shareEnded' => 'A mídia chegou ao fim e já não é compartilhada.',
			'universalMedia.shareStopped' => 'O link temporário já não é válido.',
			'universalMedia.shareUrlCopied' => 'Endereço de transmissão copiado.',
			'universalMedia.shareOpenUrl' => 'Abra este endereço em um jogador no outro dispositivo',
			'universalMedia.shareQrLabel' => 'Código QR para o endereço de fluxo temporário',
			'universalMedia.shareQrHelp' => 'Escanear com um jogador compatível conectado à mesma rede privada.',
			'universalMedia.shareHttpHint' => 'Este fluxo usa HTTP não criptografado. em PlezyNG, permita HTTP antes de abri-lo.',
			'universalMedia.shareCopyUrl' => 'Cópia de endereço de fluxo',
			'universalMedia.shareExpiresLabel' => 'O link expira em',
			'universalMedia.shareStarting' => 'Preparando o fluxo...',
			'universalMedia.shareStart' => 'Comece a compartilhar',
			'universalMedia.shareStop' => 'Pare de compartilhar',
			'universalMedia.extensionsMode' => 'Extensões e CLI',
			'universalMedia.extensionsIntro' => 'Adicione uma extensão de pesquisa de dados apenas para encontrar mídias. Escolha um resultado para carregá-lo no formulário familiar Open media.',
			'universalMedia.extensionsPrivacy' => 'Um manifesto pode definir um HTTPS endpoint de pesquisa e campos de resposta de mapa. não pode executar código, adicionar cabeçalhos de solicitação, ler arquivos, ou lançar comandos de shell.',
			'universalMedia.extensionImport' => 'Adicionar extensão manifesto',
			'universalMedia.extensionEmpty' => 'Não há serviços de pesquisa ainda. Escolha um arquivo manifesto confiável JSON para adicionar um.',
			'universalMedia.extensionChoose' => 'Serviço de busca',
			'universalMedia.extensionSearchConsent' => 'Cada pesquisa envia suas palavras para este serviço HTTPS. Os resultados só se abrem depois de você selecionar um.',
			'universalMedia.extensionSearchLabel' => 'Pesquisa de mídia',
			'universalMedia.extensionSearch' => 'Pesquisa',
			'universalMedia.extensionSearching' => 'Buscando...',
			'universalMedia.extensionNoResults' => 'Não foram retornados resultados de mídia segura. tente outra pesquisa.',
			'universalMedia.extensionInstallTitle' => 'Adicione este serviço de busca?',
			'universalMedia.extensionReplaceTitle' => 'Actualiza este serviço de busca?',
			'universalMedia.extensionService' => 'Serviço',
			'universalMedia.extensionEndpoint' => 'HTTPS ponto final',
			'universalMedia.extensionConsent' => 'Seu texto de busca é enviado para este serviço. o manifesto não contém código executável. Continue apenas se você confiar neste ponto final.',
			'universalMedia.extensionInstall' => 'Adicionar serviço',
			'universalMedia.extensionReplace' => 'Serviço de atualização',
			'universalMedia.extensionRemoveTitle' => 'Remover este serviço de busca?',
			'universalMedia.extensionRemoveHelp' => 'Isso remove o serviço deste perfil. a PlezyNG não se comunica com o seu ponto final.',
			'universalMedia.extensionRemove' => 'Remover Serviço',
			'universalMedia.extensionInvalidManifest' => 'Este arquivo não é um manifesto de extensão suportado. ver o guia Open media para o formato.',
			'universalMedia.extensionSaveFailed' => 'A extensão não poderia ser salvida para o perfil ativo.',
			'universalMedia.extensionSearchFailed' => 'O serviço de busca não devolveu uma resposta válida. verificar o ponto final e tentar novamente.',
			'universalMedia.cliTitle' => 'Linha de comando',
			'universalMedia.cliHelp' => 'Use o guia plezyctl para validar um manifesto ou pesquisar a mesma extensão. Revise seu serviço HTTPS antes de cada pesquisa. Resultados abrem no formulário de mídia existente; selecione o botão de reprodução para começar.',
			'universalMedia.cliCopyExample' => 'Exemplo de comando de cópia',
			'universalMedia.cliCopied' => 'Exemplo de comando copiado.',
			'fileSources.title' => 'Arquivos e livros',
			'fileSources.subtitle' => 'Leia, ouça e veja de seus próprios arquivos.',
			'fileSources.add' => 'Adicionar fonte',
			'fileSources.importFiles' => 'Importação de arquivos',
			'fileSources.localFiles' => 'Neste dispositivo',
			'fileSources.source' => 'Fonte',
			'fileSources.name' => 'Nome',
			'fileSources.endpoint' => 'URL do servidor',
			'fileSources.smbEndpointHint' => 'Exemplo: smb://nas/Movies',
			'fileSources.smbEndpointInvalid' => 'Introduza um servidor SMB e uma pasta partilhada.',
			'fileSources.root' => 'Fólio ou Prefixo',
			'fileSources.smbFolderHelp' => 'Deixe em branco para usar toda a pasta partilhada ou introduza uma pasta dentro dela.',
			'fileSources.username' => 'Usuário',
			'fileSources.smbDomain' => 'Domínio (opcional)',
			'fileSources.password' => 'Senha',
			'fileSources.token' => 'API Tópico',
			'fileSources.accessKey' => 'ID de acesso',
			'fileSources.secretKey' => 'A chave de acesso',
			'fileSources.sessionToken' => 'Sessão de sessão (opcional)',
			'fileSources.region' => 'Região',
			'fileSources.clientId' => 'ID do cliente OAuth',
			'fileSources.clientSecret' => 'OAuth Client Secret (só no Google Desktop)',
			'fileSources.allowHttp' => 'Permitir HTTP sem encriptação numa rede de confiança',
			'fileSources.smbEncryption' => 'Encriptar a ligação SMB3',
			'fileSources.smbEncryptionHint' => 'Usar encriptação SMB3 quando o NAS a suportar.',
			'fileSources.connect' => 'Conectar',
			'fileSources.cancel' => 'Cancelar',
			'fileSources.save' => 'Salvar',
			'fileSources.close' => 'Fechar',
			'fileSources.removeSource' => 'Fonte desconectado',
			'fileSources.disconnectMessage' => 'Desconectar esta fonte? Os arquivos baixados e seu histórico de leitura e audição permanecerão neste dispositivo.',
			'fileSources.localFolder' => 'Escolha o Folheto',
			'fileSources.empty' => 'Ainda não há nada aqui',
			'fileSources.emptyHint' => 'Adicione uma fonte ou importar um livro, audiobook, música ou vídeo.',
			'fileSources.search' => 'Procure esta pasta',
			'fileSources.searchCached' => 'Busca de biblioteca salvo',
			'fileSources.refresh' => 'Atualizar',
			'fileSources.loadMore' => 'Carregar mais',
			'fileSources.offline' => 'Disponível offline',
			'fileSources.download' => 'Mantenha offline',
			'fileSources.removeDownload' => 'Remover cópia offline',
			'fileSources.continueReading' => 'Continue a ler',
			'fileSources.continueListening' => 'Continue a ouvir',
			'fileSources.continueWatching' => 'Continue a observar',
			'fileSources.read' => 'Leia',
			'fileSources.listen' => 'ouvir',
			'fileSources.play' => 'Reproduzir',
			'fileSources.pause' => 'Pausar',
			'fileSources.stop' => 'Parar',
			'fileSources.startOver' => 'Comece por',
			'fileSources.finished' => 'Concluído',
			'fileSources.markFinished' => 'Marcão terminou',
			'fileSources.markUnfinished' => 'Marcadores Infinitos',
			'fileSources.editions' => 'Edições e arquivos',
			'fileSources.chapters' => 'Capítulos',
			'fileSources.bookmarks' => 'Bookmarks e Notas',
			'fileSources.bookmark' => 'Adicionar Bookmark',
			'fileSources.highlight' => 'Alevado',
			'fileSources.note' => 'Notícia',
			'fileSources.delete' => 'Excluir',
			'fileSources.export' => 'Notas de Exportação',
			'fileSources.exported' => 'Notas exportadas',
			'fileSources.sync' => 'Síntese de progresso',
			'fileSources.synced' => 'Progresso Síntese',
			'fileSources.conflict' => 'Outro dispositivo tem uma posição diferente. escolha onde continuar.',
			'fileSources.useLocal' => 'Use esse dispositivo',
			'fileSources.useRemote' => 'Use outros dispositivos',
			'fileSources.history' => 'História da posição',
			'fileSources.groupAudio' => 'Ouça como um livro de audição',
			'fileSources.groupHint' => 'Combine os arquivos de áudio atualmente carregados nesta pasta. carregar todas as páginas primeiro.',
			'fileSources.order' => 'Arquivo Ordem',
			'fileSources.moveUp' => 'Move em cima',
			'fileSources.moveDown' => 'Move abaixo',
			'fileSources.speed' => 'Velocidade do Playback',
			'fileSources.sleep' => 'Temporizador de suspensão',
			'fileSources.sleepOff' => 'Desativado',
			'fileSources.endChapter' => 'Fim do capítulo',
			'fileSources.minutes' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minuto', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minutos', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minutos', ), 
			'fileSources.skipBack' => 'Escape de volta',
			'fileSources.skipForward' => 'Escape em frente',
			'fileSources.smartRewind' => 'Atualidade após uma pausa',
			'fileSources.playbackOptions' => 'Escolhendo opções',
			'fileSources.remaining' => ({required Object time}) => '${time} restante',
			'fileSources.contents' => 'Conteúdo',
			'fileSources.readerSettings' => 'Leia as definições',
			'fileSources.fontSize' => 'tamanho de texto',
			'fileSources.lineHeight' => 'Linha de espaço',
			'fileSources.margin' => 'Margens',
			'fileSources.font' => 'Tipo de Face',
			'fileSources.serif' => 'Séries',
			'fileSources.sans' => 'Sem serifismo',
			'fileSources.mono' => 'Monopóstico',
			'fileSources.columns' => 'Colunas',
			'fileSources.scroll' => 'Escrever verticalmente',
			'fileSources.justify' => 'Justificando o texto',
			'fileSources.readerTheme' => 'Aparência da página',
			'fileSources.appTheme' => 'Siga o tema do app',
			'fileSources.paper' => 'Papel',
			'fileSources.sepia' => 'Sepia',
			'fileSources.night' => 'Noite',
			'fileSources.readAloud' => 'Ler esta página em voz alta',
			'fileSources.readAlong' => 'Leia em conjunto',
			'fileSources.stopReading' => 'Parar a narrativa',
			'fileSources.searchBook' => 'Busca em livro',
			'fileSources.noMatches' => 'Não há jogos',
			'fileSources.previousPage' => 'Página anterior',
			'fileSources.nextPage' => 'Próximo Página',
			'fileSources.page' => ({required Object number}) => 'Página ${number}',
			'fileSources.externalBlocked' => 'Os links externos do livro estão desativados no leitor.',
			'fileSources.loading' => 'Abertura...',
			'fileSources.narrator' => 'narração',
			'fileSources.audio' => 'Áudio',
			'fileSources.video' => 'Vídeo',
			'fileSources.ebooks' => 'Ebooks',
			'fileSources.all' => 'Todos',
			'fileSources.downloads' => 'Arquivos Offline',
			'fileSources.confirmDelete' => 'Remova a cópia offline selecionada? sua posição e notas permanecerão.',
			'fileSources.errorAuthentication' => 'Inscreva-se novamente para reconectar essa fonte.',
			'fileSources.errorPermission' => 'Esta fonte não concedeu acesso ao arquivo solicitado.',
			'fileSources.errorUnavailable' => 'A fonte não está disponível. tente novamente, ou abra uma cópia offline.',
			'fileSources.errorUnsupported' => 'Este formato ou conexão não é suportado neste dispositivo. verifique o guia de configuração de fonte.',
			'fileSources.errorInvalidData' => 'Este arquivo ou resposta do servidor não pode ser lido de forma segura.',
			'fileSources.errorCancelled' => 'A operação foi cancelada.',
			'fileSources.errorConflict' => 'A posição mudou em outra sessão. reabre o item para selecionar uma posição.',
			'fileSources.signIn' => 'Entrar',
			'fileSources.reconnect' => 'Reconectar',
			'fileSources.folderHelp' => 'Deixe branco para começar na raiz fonte. URLs S3 incluem o bucket.',
			'fileSources.preferences' => 'Preferências',
			'fileSources.timePosition' => 'Posição',
			'fileSources.audioTrack' => 'Audio Track',
			'fileSources.subtitleTrack' => 'Subtítulo Track',
			'fileSources.none' => 'Nenhuma',
			'fileSources.fullscreen' => 'Ecrã completa',
			'fileSources.syncLocation' => 'Folha de sincronização de progresso (opcional)',
			'fileSources.syncLocationHint' => 'Um folder dedicado WebDAV para PlezyNG estado. usa escritos condicionais; os meios de comunicação permanecem inalterados.',
			'fileSources.audiobooks' => 'Audiolivros',
			'fileSources.comics' => 'Banda desenhada',
			'fileSources.scan' => 'Escaneamento de livros e mídia',
			'fileSources.browserReader' => 'Leitor aberto',
			'fileSources.browserReaderHelp' => 'O leitor está aberto no seu navegador.Mantenha o PlezyNG aberto para salvar seu lugar e notas.',
			'fileSources.on' => 'em',
			'fileSources.advancedSetup' => 'App Registro',
			'fileSources.microsoftSignIn' => 'Inscreva-se com a Microsoft',
			'fileSources.zoomIn' => 'Zoom em',
			'fileSources.zoomOut' => 'Zoom em Out',
			'fileSources.fitPage' => 'Página FIT',
			'fileSources.fitWidth' => 'Ficou em largura',
			'fileSources.actualSize' => 'Tamanho atual',
			'fileSources.goToPage' => 'Ir para página',
			'fileSources.goToSection' => 'Vá para o capítulo',
			'fileSources.pageRange' => ({required Object count}) => 'Entre um número de 1 para ${count}',
			'fileSources.pageLayout' => 'Página Layout',
			'fileSources.automatic' => 'Automático',
			'fileSources.singlePage' => 'Página única',
			'fileSources.twoPages' => 'Duas páginas',
			'fileSources.readingDirection' => 'Leitura Direção',
			'fileSources.leftToRight' => 'De esquerda para direita',
			'fileSources.rightToLeft' => 'Da direita para a esquerda',
			'fileSources.letterSpacing' => 'Carta de espaço',
			'fileSources.wordSpacing' => 'Palavra espaçado',
			'fileSources.readerControlsHelp' => 'Afaste dois dedos ou use os controles de zoom para ampliar as páginas. Arraste para mover a página. Ctrl/⌘ com + ou − ajusta o zoom; Ctrl/⌘ com 0 o redefine. Page Up e Page Down mudam de página.',
			'fileSources.imagePage' => 'Página de banda desenhada',
			'fileSources.resetReader' => 'Resetando as preferências de leitura',
			'fileSources.zoom' => 'Zoom',
			'fileSources.useFiles' => 'Use arquivos e livros',
			'fileSources.cancelScan' => 'Cancelar o scan',
			'fileSources.googleDrive' => 'Google Drive',
			'fileSources.offlineQuota' => 'Limite de download Offline',
			'fileSources.offlineQuotaHelp' => 'Defina o espaço máximo usado por cópias offline, arquivos importados e downloads qued. A redução do limite não remove cópios existentes.',
			'fileSources.offlineStorageUsage' => 'armazenamento offline',
			'fileSources.reservedStorage' => 'Reservação',
			'fileSources.downloadQueue' => 'Descarregar Queue',
			'fileSources.downloadRunning' => 'Baixe',
			'fileSources.downloadQueued' => 'Aguardando',
			'fileSources.downloadPaused' => 'Pausa',
			'fileSources.downloadFailed' => 'Necessidade de retiro',
			'fileSources.importing' => 'Importação',
			'fileSources.importInterrupted' => 'Importação interrompida · remover para limpar',
			'fileSources.errorQuotaExceeded' => 'O limite de armazenamento offline foi alcançado. elevar o limite ou remover uma cópia descarregada.',
			'fileSources.errorStorageLow' => 'Não há armazenamento gratuito suficiente para manter a reserva protegida.',
			'fileSources.errorStorageUnavailable' => 'PlezyNG não podia verificar o armazenamento do dispositivo gratuito, então a escrita foi interrompida.',
			'fileSources.removeDownloadJob' => 'Remover download',
			'fileSources.downloadAlreadyComplete' => 'Este download terminou antes que pudesse ser removido. o item está agora disponível offline.',
			'fileSources.confirmRemoveDownloadJob' => 'Remova este download e desligue quaisquer dados partialmente baixados? sua posição e notas permanecerão.',
			'lending.title' => 'Bibliotecas Públicas',
			'lending.add' => 'Adicione uma biblioteca',
			'lending.other' => 'Outra biblioteca',
			'lending.libraryName' => 'Nome da Biblioteca',
			'lending.libraryUrl' => 'Site da Biblioteca',
			'lending.libraryUrlHint' => 'Use o catálogo da sua biblioteca ou página de assinatura.',
			'lending.intro' => 'Empréstimo da sua biblioteca.Mantenha seus livros fechados.',
			'lending.handoff' => 'Inscreva-se, empreste e leia com segurança com o serviço da sua biblioteca.',
			'lending.openService' => 'Biblioteca aberta',
			'lending.findLibrary' => 'Encontre uma biblioteca',
			'lending.search' => 'Busca de livros e autores',
			'lending.catalogue' => 'Catálogo',
			'lending.loans' => 'Empréstimos',
			'lending.holds' => 'Reservas',
			'lending.signIn' => 'Inscreva-se com a sua biblioteca',
			'lending.waiting' => 'Finalize a assinatura no seu navegador e, em seguida, volte aqui.',
			'lending.cancel' => 'Cancelar',
			'lending.disconnect' => 'Remover a biblioteca',
			'lending.disconnectMessage' => 'Remover esta biblioteca deste perfil? Seus empréstimos e reservas continuarão registrados na biblioteca.',
			'lending.getBook' => 'Obtenha Livro',
			'lending.checkAvailability' => 'Verifique a disponibilidade',
			'lending.available' => 'Disponível para empréstimo',
			'lending.unavailable' => 'Atualmente não disponível',
			'lending.borrow' => 'Pegar emprestado',
			'lending.placeHold' => 'Reservar',
			'lending.returnBook' => 'Retorno cedo',
			'lending.cancelHold' => 'Cancelar reserva',
			'lending.confirmBorrow' => 'Você empresta esse título da sua biblioteca?',
			'lending.confirmReturn' => 'Devolver este título agora? Talvez seja necessário pegá-lo emprestado novamente para continuar.',
			'lending.confirmCancelHold' => 'Cancelar sua reserva deste título?',
			'lending.email' => 'Mantenha o email de notificação',
			'lending.due' => ({required Object date}) => 'Duração ${date}',
			'lending.queue' => ({required Object position}) => 'Posição ${position} em linha',
			'lending.empty' => 'Não há títulos aqui ainda.',
			'lending.openLibraryNote' => 'Explore o catálogo da Open Library. Opções de leitura e empréstimo são exibidas na página de cada título.',
			'lending.more' => 'Carregar mais',
			'lending.gateway' => 'Biblioteca de inscrição em serviço',
			'lending.gatewayHint' => 'Fornecido pela sua biblioteca ou pelo administrador PlezyNG.',
			'lending.advanced' => 'Integração da Biblioteca',
			'lending.loadLibraries' => 'Escolha sua biblioteca',
			'lending.expired' => 'O empréstimo já expirou.',
			'lending.updated' => 'Biblioteca atualizada',
			'lending.continueService' => 'Continuar em serviço',
			'lending.comingSoon' => 'Empréstimo em app · Vem em breve',
			'lending.comingSoonDescription' => 'Você pode usar sua biblioteca em Libby enquanto terminamos conectando-a.',
			'lending.suspendHold' => 'Suspensão de manutenção',
			'lending.resumeHold' => 'Resumo de Manutenção',
			'lending.suspendMessage' => 'Manter seu lugar na fila e deixar o próximo leitor pegar esta cópia emprestada? Você poderá retomar a reserva mais tarde.',
			'lending.resumeMessage' => 'Retomar esta reserva para que a biblioteca possa oferecer a próxima cópia disponível?',
			'lending.editEmail' => 'Mudança de notificação de email',
			'audiobook.syncTitle' => 'Leitura e escuta sincronização',
			'audiobook.syncHelp' => 'Mantenha as posições de leitura, as posições de escuta, o estado de conclusão, as notas e as notas em todos os seus dispositivos. Escolha uma conta de armazenamento anexada e use o mesmo código de sincronização em cada dispositivo. Ler e ouvir permanecem separados.',
			'audiobook.addSyncSource' => 'Adicione o Google Drive, o OneDrive, o Dropbox, o WebDAV ou o S3 em Arquivos e Livros primeiro.',
			'audiobook.syncDestination' => 'Conta de armazenamento de sincronização',
			'audiobook.syncFolder' => 'Sincronização de folha ou prefixo',
			'audiobook.syncFolderHelp' => 'Use uma pasta existente separada dentro da sua fonte WebDAV, ou um prefixo dedicado S3.',
			'audiobook.syncCode' => 'Código de sincronização',
			'audiobook.syncCodeHelp' => 'Crie um código em seu primeiro dispositivo e, em seguida, introduza esse código em seus outros dispositivos.Mantenha uma cópia privada: é a chave para o seu estado criptografado.Utiliza um código diferente para cada pessoa.',
			'audiobook.showCode' => 'Mostrar ou esconder o código de sincronização',
			'audiobook.newSyncCode' => 'Crie um novo código de sincronização',
			'audiobook.saveSync' => 'Save e Sincronize',
			'audiobook.disableSync' => 'Desligue a sincronização neste dispositivo',
			'audiobook.syncSourceDisconnect' => 'Remover esta fonte irá desativar a leitura e a escuta de sincronização aqui. arquivos de sincronização criptografados permanecerão no provedor.',
			'audiobook.syncReconnect' => 'Reconectar a conta de armazenamento',
			'audiobook.lastSynced' => ({required Object time}) => 'Última sincronização em ${time}',
			'audiobook.syncPrivacy' => 'Somente progressos e notas criptografados são armazenados. arquivos de áudio e ebook, tokens de conta e senhas não são carregados. Google Drive e OneDrive usa armazenamento de aplicativos; Dropbox usa PlezyNG Sync. A habilitação de sincronização pode solicitar acesso adicional de escrita. Enquanto ativado, este destino possui sincronização de progresso; o progresso do servidor permanece separado.',
			'audiobook.syncConflicts' => 'Escolha onde reencontrar',
			'audiobook.conflictHelp' => 'Essas alterações foram feitas de forma independente. escolha a posição ou a versão de marcador para manter. Um tempo mais tarde ou uma porcentagem mais alta não ganha automaticamente.',
			'audiobook.syncDevice' => ({required Object device}) => 'Atividade ${device}',
			'audiobook.syncUnknownDevice' => 'Dispositivo desconhecido',
			'audiobook.deletedBookmark' => 'Livro eliminado',
			'audiobook.finished' => 'Finalizado',
			'audiobook.readingPosition' => ({required Object percent}) => 'Ler · ${percent}%',
			'audiobook.chapterTimeline' => 'Capítulo Progresso',
			'audiobook.bookTimeline' => 'Livro completo Progresso',
			'audiobook.bookRemaining' => ({required Object time}) => 'Tempo restante neste livro: ${time}',
			'audiobook.chapterRemaining' => ({required Object time}) => 'Tempo restante neste capítulo: ${time}',
			'audiobook.unknownRemaining' => 'Tempo total disponível enquanto as partes são jogadas',
			'audiobook.undoSeek' => 'Última busca',
			'audiobook.customSpeed' => 'Velocidade Custom Playback',
			'audiobook.speedHelp' => 'Escolha uma velocidade de 0,25× a 4×.',
			'audiobook.apply' => 'Aplique',
			'audiobook.customSleep' => 'Tempo de sono personalizado',
			'audiobook.sleepMinutes' => 'Minutos (1 a 1440)',
			'audiobook.sleepChapters' => ({required Object count}) => 'Parar após ${count} capítulos',
			'audiobook.extendSleep' => 'Adicionar 5 minutos',
			'audiobook.sleepRemaining' => ({required Object time}) => 'Tempo de sono: ${time}',
			'audiobook.useDefaults' => 'Use esses controles de escuta para novos livros',
			'audiobook.librarySort' => 'Livros Sorte',
			'audiobook.sortTitle' => 'Título',
			'audiobook.sortAuthor' => 'Autor',
			'audiobook.sortNarrator' => 'narração',
			'audiobook.sortSeries' => 'Série Ordem',
			'audiobook.sortRecent' => 'Recentemente aberta',
			'audiobook.statusFilter' => 'Status de leitura',
			'audiobook.statusAll' => 'Todos os livros',
			'audiobook.statusNew' => 'Não começou',
			'audiobook.statusProgress' => 'em progresso',
			'audiobook.statusFinished' => 'Finalizado',
			'audiobook.goToTime' => 'Vá ao tempo',
			'audiobook.timeHelp' => 'Horas: minutos: segundos ou minutos: segundos',
			'audiobook.recoveryHelp' => 'Exportar uma cópia recentemente criptografada antes de mover ou reparar dados de sincronização. Importações se misturam com o estado atual; eles nunca substituem a história local da sincronización.',
			'audiobook.recoveryExport' => 'Exportação de arquivos de recuperação criptografados',
			'audiobook.recoveryImport' => 'Importar arquivo de recuperação criptografado',
			'audiobook.recoveryImportConfirm' => 'Combine este arquivo de recuperação criptografado com as posições e notas de leitura atuais? História existente será mantida. bibliotecas compartilhadas e IDs de itens não são incluídos; definir IDs correspondentes em cada dispositivo antes da importação.',
			'audiobook.recoveryExported' => 'arquivo de recuperação criptografado salvo.',
			'audiobook.recoveryImported' => 'Dados de recuperação combinados.',
			'sourceSetup.savedCertificate' => 'Certificado do servidor salvo',
			'sourceSetup.nfsEndpointInvalid' => 'Digite uma URL NFS, como nfs://nas:2049/export.',
			'sourceSetup.dlnaNone' => 'Nenhum servidor DLNA encontrado. Digite manualmente a URL de descrição do dispositivo.',
			'sourceSetup.dlnaServers' => 'Servidores de mídia DLNA',
			'sourceSetup.dlnaUnavailable' => 'A descoberta DLNA não está disponível nesta rede. Digite manualmente a URL de descrição do dispositivo.',
			'sourceSetup.dlnaSearching' => 'Procurando servidores DLNA na rede local',
			'sourceSetup.networkSearching' => 'Pesquisando na rede local…',
			'sourceSetup.dlnaDiscover' => 'Descobrir servidores DLNA',
			'sourceSetup.dlnaHelp' => 'A descoberta depende de multicast na rede local. Se nenhum servidor aparecer, digite acima a URL de descrição do dispositivo dele.',
			'sourceSetup.dlnaRoot' => 'ID do objeto DLNA; deixe em branco para usar a raiz do dispositivo.',
			'sourceSetup.passwordOrKey' => 'Digite uma senha ou adicione uma chave privada abaixo.',
			'sourceSetup.sshFingerprint' => 'Impressão digital SHA256 da chave de host SSH',
			'sourceSetup.sshFingerprintHelp' => 'Verifique com o administrador do servidor. No servidor, execute ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub e use o valor SHA256.',
			'sourceSetup.sshFingerprintKeep' => 'Deixe em branco para manter a impressão digital fixada atual ou digite uma nova impressão digital do servidor.',
			'sourceSetup.sshAuthentication' => 'Autenticação SSH por chave pública',
			'sourceSetup.sshAuthenticationHelp' => 'Opcional; a autenticação por senha também é aceita.',
			'sourceSetup.privateKey' => 'Chave privada (formato PEM ou OpenSSH)',
			'sourceSetup.privateKeyPassphrase' => 'Frase secreta da chave privada',
			'sourceSetup.nfsMountPort' => 'Porta TCP do serviço de montagem NFS',
			'sourceSetup.nfsMountPortHelp' => 'Padrão: 20048',
			'sourceSetup.nfsUserId' => 'ID de usuário NFS (AUTH_SYS)',
			'sourceSetup.nfsUserIdHelp' => 'Padrão: 1000. Use o ID permitido pelo compartilhamento NFS do NAS.',
			'sourceSetup.nfsGroupId' => 'ID de grupo NFS (AUTH_SYS)',
			'sourceSetup.nfsGroupIdHelp' => 'Padrão: 1000. Use o ID de grupo permitido pelo compartilhamento NFS do NAS.',
			'sourceSetup.nfsEncryption' => 'Exigir NFS criptografado (RPC-with-TLS)',
			'sourceSetup.nfsEncryptionHelp' => 'Exigir TLS 1.3 para NFS e o serviço de montagem. Se o NAS não oferecer suporte, a conexão será recusada.',
			'sourceSetup.nfsTrustCertificate' => 'CA NFS personalizada ou certificado do servidor (PEM, opcional)',
			'sourceSetup.nfsTrustHelp' => 'Deixe em branco para usar certificados confiáveis para este dispositivo. Se necessário, adicione um certificado de uma CA privada ou um certificado de servidor autoassinado; os nomes devem corresponder ao host da URL NFS.',
			'sourceSetup.nfsTrustInvalid' => 'Use um certificado de CA ou de servidor no formato PEM. Não inclua uma chave privada.',
			'sourceSetup.addTrustCertificate' => 'Adicionar certificado de confiança personalizado',
			'sourceSetup.replaceTrustCertificate' => 'Substituir o certificado personalizado salvo',
			'sourceSetup.nfsTlsHelp' => 'RPC-with-TLS usa as portas habituais de NFS e do serviço de montagem e exige que o NAS ofereça suporte a RFC 9289. TLS 1.3 é obrigatório. O nome do host ou o IP deve corresponder ao certificado. Os UID/GID de AUTH_SYS continuam valendo no canal criptografado.',
			'sourceSetup.clientCertificate' => 'Certificado do cliente (opcional)',
			'sourceSetup.clientCertificateHelp' => 'Permite que o NAS autentique este cliente; os IDs de AUTH_SYS continuam sujeitos à política do compartilhamento NFS do NAS.',
			'sourceSetup.savedIdentity' => 'Será usada uma identidade de cliente salva.',
			'sourceSetup.replaceIdentity' => 'Substituir a identidade de cliente salva',
			'sourceSetup.chooseIdentity' => 'Escolher identidade de cliente PKCS#12',
			'sourceSetup.identityPassphrase' => 'Frase secreta da identidade de cliente',
			'sourceSetup.identityPassphraseHelp' => 'Deixe em branco se o arquivo não tiver uma frase secreta.',
			'sourceSetup.removeIdentity' => 'Remover qualquer identidade de cliente salva',
			'sourceSetup.identityStorageHelp' => 'As identidades de cliente são salvas no armazenamento criptografado de credenciais da fonte. Mantenha esta seção inalterada para conservar a identidade salva.',
			'sourceSetup.nfsLimitations' => 'NFSv3 somente leitura sobre TCP. Sem RPC-with-TLS, o tráfego NFS não é criptografado. O NAS deve permitir os IDs de AUTH_SYS selecionados e portas de cliente não privilegiadas (geralmente pela opção de exportação “insecure”). NFSv4 e UDP não são compatíveis.',
			'sourceSetup.nfsSetupHelp' => 'Ajuda para configurar NFS',
			'sourceSetup.nfsSetupHint' => 'Confira estas configurações se a conexão não for estabelecida.',
			'sourceSetup.nfsSetupDetails' => 'Use um compartilhamento NFSv3 sobre TCP. Quando a criptografia for obrigatória, os serviços NFS e de montagem devem oferecer suporte a RPC-with-TLS. Deixe o certificado personalizado em branco para usar um certificado de servidor confiável para este dispositivo, ou adicione o certificado de CA ou autoassinado do NAS. O nome no certificado deve corresponder ao host do endpoint. Se o NAS exigir TLS mútuo, adicione sua identidade de cliente PKCS#12. Por fim, confirme que o compartilhamento permite os UID/GID de AUTH_SYS configurados e a política de portas do cliente.',
			'sourceSetup.ftpHelp' => 'FTP usa modo passivo. Use ftp:// para FTP sem criptografia, ftpes:// para TLS explícito ou ftps:// para TLS (implícito na porta 990; explícito nas outras portas).',
			'sourceSetup.openSubtitles' => 'OpenSubtitles',
			'sourceSetup.subtitleSetup' => 'Busca opcional de legendas para vídeos independentes.',
			'sourceSetup.apiKey' => 'Chave API',
			'sourceSetup.optionalUsername' => 'Nome de usuário da conta (opcional)',
			'sourceSetup.optionalPassword' => 'Senha da conta (opcional)',
			'sourceSetup.subtitlePrivacy' => 'Obtenha uma chave API em opensubtitles.com. A busca envia o título do vídeo e os IDs de IMDb/TMDB disponíveis, nunca o arquivo de vídeo. A chave e as credenciais opcionais da conta são criptografadas junto com esta fonte.',
			'sourceSetup.automaticMetadata' => 'Metadados de vídeo online automáticos',
			'sourceSetup.metadataPrivacy' => 'Envia apenas título/ano do nome do arquivo e números dos episódios, ou um ID NFO; nunca envia mídia ou credenciais. Os campos NFO mantêm a prioridade.',
			'sourceSetup.nfsEncryptionFailure' => 'Para NFS criptografado, verifique o suporte a RFC 9289 e TLS 1.3 nos dois serviços do NAS, o nome no certificado e os UID/GID do compartilhamento. PlezyNG não tentará esta conexão novamente sem criptografia.',
			'sourceSetup.sourceConnecting' => 'Conectando à fonte',
			'sourceSetup.metadataSearchPrivacy' => 'Esta busca de títulos é enviada ao Trakt. Ela envia o título digitado, não o vídeo nem as credenciais da fonte.',
			'sourceSetup.chooseMatch' => 'Escolher uma correspondência',
			'sourceSetup.metadataMatchHelp' => 'Confira o título e o ano antes de escolher. O Trakt recebe o título pesquisado; o vídeo permanece na fonte.',
			'sourceSetup.metadataNoMatches' => 'Nenhum título correspondente encontrado online. Tente outro título.',
			'sourceSetup.metadataSearch' => 'Buscar metadados online',
			'sourceSetup.metadataLoading' => 'Buscando detalhes de filmes e séries online…',
			'sourceSetup.metadataFromTrakt' => 'Metadados online do Trakt',
			'sourceSetup.metadataNoAutomaticMatch' => 'Nenhuma correspondência automática encontrada para o título. Pesquise o título para escolher uma correspondência.',
			'sourceSetup.metadataFailed' => 'Não foi possível carregar os metadados online. A reprodução e os detalhes locais continuam disponíveis.',
			'sourceSetup.videoDetailsLoading' => 'Carregando detalhes do vídeo',
			'sourceSetup.subtitleKeyRequired' => 'É necessária uma chave API do OpenSubtitles',
			'sourceSetup.subtitleKeyHelp' => 'Edite esta fonte de arquivos e adicione uma chave API do OpenSubtitles nas configurações opcionais de legendas.',
			'sourceSetup.subtitleSearchFailed' => 'A busca de legendas falhou. Confira a chave API, a conexão e o acesso ao serviço.',
			'sourceSetup.subtitleApplyFailed' => 'Não foi possível baixar ou aplicar esta legenda. Confira a conexão e tente outro resultado.',
			'sourceSetup.subtitleSearch' => 'Buscar no OpenSubtitles',
			'sourceSetup.subtitleSearchPrivacy' => 'A busca usa o título e os IDs de IMDb/TMDB disponíveis. O arquivo de vídeo permanece na fonte. Antes de escolher, confira o idioma, as indicações de legendas forçadas ou para pessoas com deficiência auditiva e a avaliação.',
			'sourceSetup.movieOrShow' => 'Filme ou série',
			'sourceSetup.subtitleTitleHint' => 'Digite um título para refinar os resultados',
			'sourceSetup.subtitleLanguage' => 'Idioma das legendas',
			'sourceSetup.subtitleSearching' => 'Buscando no OpenSubtitles',
			'sourceSetup.subtitleNoMatches' => 'Nenhuma legenda correspondente encontrada. Tente outro título ou idioma.',
			'sourceSetup.downloadSubtitle' => 'Baixar legenda',
			'sourceSetup.subtitle' => 'Legenda',
			'sourceSetup.nfsTlsRequired' => 'RPC-with-TLS obrigatório',
			'sourceSetup.nfsUnencrypted' => 'NFS sem criptografia',
			'sourceSetup.tlsEncrypted' => 'Criptografado com TLS',
			'sourceSetup.ftpPlain' => 'FTP sem criptografia',
			'sourceSetup.sshPinned' => 'SSH criptografado · chave de host fixada',
			'sourceSetup.smbEncrypted' => 'Criptografia SMB3 ativada',
			'sourceSetup.smbUnencrypted' => 'Criptografia SMB3 desativada',
			'sourceSetup.httpUnencrypted' => 'HTTP sem criptografia de transporte',
			'sourceSetup.checkEndpointSecurity' => 'Verificar a segurança do endpoint',
			'sourceSetup.fieldRequired' => ({required Object label}) => 'Campo obrigatório: ${label}.',
			'sourceSetup.integerRange' => ({required Object label, required Object min, required Object max}) => 'Digite ${label} de ${min} a ${max}.',
			'sourceSetup.replaceFile' => ({required Object name}) => 'Substituir ${name}',
			'sourceSetup.selectedIdentity' => ({required Object name}) => 'Identidade de cliente selecionada: ${name}',
			'sourceSetup.subtitleRating' => ({required Object rating}) => 'Avaliação ${rating}',
			'sourceSetup.subtitleDownloading' => ({required Object title}) => 'Baixando legenda: ${title}',
			'sourceSetup.sharedEntryPair' => 'Pair este item',
			'sourceSetup.sharedEntryPairHelp' => 'Digite o mesmo ID para este item em cada dispositivo. Use um identificador compartilhado estável ou gerar um e copiá-lo para o item correspondente. Progress pares apenas quando os tipos de arquivo da edição, tamanhos e ordens correspondem. Blank remove esse mapeamento.',
			'sourceSetup.sharedEntryId' => 'ID do item compartilhado',
			'sourceSetup.generateSharedEntryId' => 'Identificar o item compartilhado',
			'sourceSetup.sharedLibraryId' => 'ID de biblioteca compartilhada (opcional)',
			'sourceSetup.sharedLibraryHelp' => 'Use o mesmo ID em dispositivos que abrem a mesma biblioteca.Este ID público ajuda a acompanhar os progressos de leitura e notas através de diferentes conexões fonte; não é uma senha.Quando os provedores usam diferentes IDs de item, pares esses itens das suas pantallas detalhadas.',
			'sourceSetup.sharedLibraryInvalid' => 'Use 8 a 100 letras, números, pontos, subscores ou hyphens.',
			'sourceSetup.generateSharedLibraryId' => 'Crie um ID de biblioteca compartilhado',
			'sourceSetup.nfsReadAhead' => 'Requisitos de read-ahead da NFS',
			'sourceSetup.nfsReadAheadHelp' => 'Mais leituras paralelas podem melhorar a passagem em uma NAS rápida ou rede. Use 1 se o servidor limitar pedidos concorrentes.',
			'sourceSetup.nfsReadTest' => 'Medir o desempenho da leitura NFS',
			'sourceSetup.nfsReadTestHelp' => 'Leia até 64 MiB do maior arquivo para medir esta conexão NAS. Isso usa a largura de banda da rede.',
			'sourceSetup.nfsQualificationResult' => 'NFS Leia a medição',
			'sourceSetup.nfsReadBytes' => 'Dados de leitura',
			'sourceSetup.nfsReadSpeed' => 'Velocidade Medida',
			'sourceSetup.nfsReadRequests' => 'Leia pedidos',
			'sourceSetup.sharedEntryConflict' => 'Este ID de item compartilhado já está em parceria com outro item nesta biblioteca.',
			'comics.fitHeight' => 'Ajustar à altura',
			'comics.readingMode' => 'Modo de leitura',
			'comics.paged' => 'Páginas',
			'comics.webtoon' => 'Deslocamento contínuo',
			'comics.coverAlone' => 'Mostrar a capa sozinha',
			'comics.splitWide' => 'Dividir páginas largas',
			'comics.splitWideHelp' => 'Mostra cada metade separadamente, na ordem de leitura. A apresentação de duas páginas lado a lado fica suspensa enquanto esta opção estiver ativa.',
			'comics.thumbnails' => 'Miniaturas das páginas',
			'comics.controlsHelp' => 'Deslize para mudar de página. Toque duas vezes para alterar o ajuste. No deslocamento contínuo, deslize na vertical ou use Page Up e Page Down.',
			'comics.savedForComic' => 'As definições de apresentação são guardadas para esta banda desenhada neste perfil.',
			'comics.readLists' => 'Listas de leitura',
			'comics.collections' => 'Coleções',
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
			'deepLinks.invalid' => 'Este link Plezy não é válido.',
			'deepLinks.profileNotFound' => ({required Object profile}) => 'Nenhum perfil corresponde a "${profile}".',
			'deepLinks.serverUnavailable' => 'Não podia chegar ao servidor para este link.',
			'deepLinks.notFound' => 'Não podia encontrar esse título em suas bibliotecas.',
			'deepLinks.unsupportedItem' => 'Este link não pode ser jogado.',
			'deepLinks.noLiveTv' => 'Nenhum servidor de TV ao vivo está disponível para este link.',
			'deepLinks.channelNotFound' => ({required Object channel}) => 'Não podia encontrar o canal "${channel}".',
			'deepLinks.showLink' => 'Mostrar link',
			'deepLinks.showProfileLink' => 'Mostrar perfil link',
			'deepLinks.dialogTitle' => 'Link',
			'deepLinks.showHint' => 'Abra este link joga o próximo episódio. Adicione &mode=shuffle para jogar o show no shuffle.',
			'deepLinks.movieHint' => 'Ao abrir este link, o filme é jogado.',
			'deepLinks.episodeHint' => 'A abertura deste link joga este episódio.',
			'deepLinks.profileHint' => 'Abre este link switch para esse perfil.',
			'deepLinks.openAsProfile' => ({required Object name}) => 'Abra como ${name}',
			'deepLinks.copy' => 'Copia',
			'deepLinks.copied' => 'Link copiado',
			_ => null,
		};
	}
}
