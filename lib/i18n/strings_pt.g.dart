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
	@override late final _Translations$app$pt app = _Translations$app$pt._(_root);
	@override late final _Translations$auth$pt auth = _Translations$auth$pt._(_root);
	@override late final _Translations$common$pt common = _Translations$common$pt._(_root);
	@override late final _Translations$screens$pt screens = _Translations$screens$pt._(_root);
	@override late final _Translations$update$pt update = _Translations$update$pt._(_root);
	@override late final _Translations$settings$pt settings = _Translations$settings$pt._(_root);
	@override late final _Translations$search$pt search = _Translations$search$pt._(_root);
	@override late final _Translations$hotkeys$pt hotkeys = _Translations$hotkeys$pt._(_root);
	@override late final _Translations$fileInfo$pt fileInfo = _Translations$fileInfo$pt._(_root);
	@override late final _Translations$mediaMenu$pt mediaMenu = _Translations$mediaMenu$pt._(_root);
	@override late final _Translations$rateSheet$pt rateSheet = _Translations$rateSheet$pt._(_root);
	@override late final _Translations$accessibility$pt accessibility = _Translations$accessibility$pt._(_root);
	@override late final _Translations$tooltips$pt tooltips = _Translations$tooltips$pt._(_root);
	@override late final _Translations$audioTracks$pt audioTracks = _Translations$audioTracks$pt._(_root);
	@override late final _Translations$videoControls$pt videoControls = _Translations$videoControls$pt._(_root);
	@override late final _Translations$messages$pt messages = _Translations$messages$pt._(_root);
	@override late final _Translations$subtitlingStyling$pt subtitlingStyling = _Translations$subtitlingStyling$pt._(_root);
	@override late final _Translations$mpvConfig$pt mpvConfig = _Translations$mpvConfig$pt._(_root);
	@override late final _Translations$dialog$pt dialog = _Translations$dialog$pt._(_root);
	@override late final _Translations$profiles$pt profiles = _Translations$profiles$pt._(_root);
	@override late final _Translations$connections$pt connections = _Translations$connections$pt._(_root);
	@override late final _Translations$discover$pt discover = _Translations$discover$pt._(_root);
	@override late final _Translations$errors$pt errors = _Translations$errors$pt._(_root);
	@override late final _Translations$libraries$pt libraries = _Translations$libraries$pt._(_root);
	@override late final _Translations$about$pt about = _Translations$about$pt._(_root);
	@override late final _Translations$serverSelection$pt serverSelection = _Translations$serverSelection$pt._(_root);
	@override late final _Translations$hubDetail$pt hubDetail = _Translations$hubDetail$pt._(_root);
	@override late final _Translations$logs$pt logs = _Translations$logs$pt._(_root);
	@override late final _Translations$startup$pt startup = _Translations$startup$pt._(_root);
	@override late final _Translations$licenses$pt licenses = _Translations$licenses$pt._(_root);
	@override late final _Translations$navigation$pt navigation = _Translations$navigation$pt._(_root);
	@override late final _Translations$explore$pt explore = _Translations$explore$pt._(_root);
	@override late final _Translations$liveTv$pt liveTv = _Translations$liveTv$pt._(_root);
	@override late final _Translations$collections$pt collections = _Translations$collections$pt._(_root);
	@override late final _Translations$playlists$pt playlists = _Translations$playlists$pt._(_root);
	@override late final _Translations$music$pt music = _Translations$music$pt._(_root);
	@override late final _Translations$watchTogether$pt watchTogether = _Translations$watchTogether$pt._(_root);
	@override late final _Translations$downloads$pt downloads = _Translations$downloads$pt._(_root);
	@override late final _Translations$shaders$pt shaders = _Translations$shaders$pt._(_root);
	@override late final _Translations$companionRemote$pt companionRemote = _Translations$companionRemote$pt._(_root);
	@override late final _Translations$videoSettings$pt videoSettings = _Translations$videoSettings$pt._(_root);
	@override late final _Translations$performanceOverlay$pt performanceOverlay = _Translations$performanceOverlay$pt._(_root);
	@override late final _Translations$externalPlayer$pt externalPlayer = _Translations$externalPlayer$pt._(_root);
	@override late final _Translations$metadataEdit$pt metadataEdit = _Translations$metadataEdit$pt._(_root);
	@override late final _Translations$matchScreen$pt matchScreen = _Translations$matchScreen$pt._(_root);
	@override late final _Translations$serverTasks$pt serverTasks = _Translations$serverTasks$pt._(_root);
	@override late final _Translations$trakt$pt trakt = _Translations$trakt$pt._(_root);
	@override late final _Translations$seerr$pt seerr = _Translations$seerr$pt._(_root);
	@override late final _Translations$services$pt services = _Translations$services$pt._(_root);
	@override late final _Translations$addServer$pt addServer = _Translations$addServer$pt._(_root);
}

// Path: app
class _Translations$app$pt extends Translations$app$en {
	_Translations$app$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
}

// Path: auth
class _Translations$auth$pt extends Translations$auth$en {
	_Translations$auth$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
	@override String get useQuickConnect => 'Usar Quick Connect';
	@override String get quickConnectInstructions => 'Abra o Quick Connect no Jellyfin e insira este código.';
	@override String get quickConnectWaiting => 'Aguardando aprovação…';
	@override String get quickConnectCancel => 'Cancelar';
	@override String get quickConnectExpired => 'Quick Connect expirou. Tente novamente.';
	@override String get localDataRecoveryRequired => 'O Plezy não conseguiu recuperar com segurança os dados locais de acesso e de reproduções pendentes. Entre novamente.';
	@override String get pinCheckRejected => 'A verificação do PIN do Plex foi rejeitada';
}

// Path: common
class _Translations$common$pt extends Translations$common$en {
	_Translations$common$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Cancelar';
	@override String get save => 'Salvar';
	@override String get close => 'Fechar';
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
	@override late final _Translations$common$ratingSource$pt ratingSource = _Translations$common$ratingSource$pt._(_root);
	@override String get notAvailable => 'N/D';
	@override String get url => 'URL';
	@override String get letterKeys => 'ABC';
	@override late final _Translations$common$mediaKind$pt mediaKind = _Translations$common$mediaKind$pt._(_root);
}

// Path: screens
class _Translations$screens$pt extends Translations$screens$en {
	_Translations$screens$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Licenças';
	@override String get switchProfile => 'Trocar Perfil';
	@override String get subtitleStyling => 'Estilo de Legendas';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Logs';
}

// Path: update
class _Translations$update$pt extends Translations$update$en {
	_Translations$update$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
class _Translations$settings$pt extends Translations$settings$en {
	_Translations$settings$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Configurações';
	@override String get supportDeveloper => 'Apoie o Plezy';
	@override String get supportDeveloperDescription => 'Doe via Liberapay para financiar o desenvolvimento';
	@override String get language => 'Idioma';
	@override String get theme => 'Tema';
	@override String get appearance => 'Aparência';
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
	@override String get libraryDensity => 'Densidade da Biblioteca';
	@override String get displayScale => 'Escala de exibição';
	@override String get compact => 'Compacto';
	@override String get comfortable => 'Confortável';
	@override String get tvCornerSpotlightBackdrop => 'Imagem de destaque no canto';
	@override String get tvCornerSpotlightBackdropDescription => 'Mostrar a imagem de destaque no canto superior direito em vez de preencher a tela';
	@override String get viewMode => 'Modo de Visualização';
	@override String get gridView => 'Grade';
	@override String get listView => 'Lista';
	@override String get showHeroSection => 'Mostrar Seção de Destaque';
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
	@override String get bufferSize => 'Tamanho do Buffer';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get bufferSizeAuto => 'Automático (Recomendado)';
	@override String bufferSizeWarning({required Object heap, required Object size}) => '${heap}MB de memória disponível. Um buffer de ${size}MB pode afetar a reprodução.';
	@override String get playbackBuffer => 'Buffer de reprodução';
	@override String get playbackBufferAuto => 'Automático (recomendado)';
	@override String get playbackBufferLarge => 'Grande';
	@override String get playbackBufferExtraLarge => 'Extra grande';
	@override String get playbackBufferDescription => 'Faz buffer extra contra conexões instáveis. Também limitado pelo tamanho do buffer.';
	@override String get defaultQualityTitle => 'Qualidade padrão';
	@override String get musicQualityTitle => 'Qualidade da música';
	@override String get subtitleStyling => 'Estilo de Legendas';
	@override String get subtitleStylingDescription => 'Personalizar aparência das legendas';
	@override String get smallSkipDuration => 'Duração do Avanço Curto';
	@override String get largeSkipDuration => 'Duração do Avanço Longo';
	@override String get rewindOnResume => 'Rebobinar ao retomar';
	@override String secondsUnit({required Object seconds}) => '${seconds} segundos';
	@override String get defaultSleepTimer => 'Temporizador de suspensão padrão';
	@override String minutesUnit({required Object minutes}) => '${minutes} minutos';
	@override String get rememberTrackSelections => 'Lembrar seleção de faixas por série/filme';
	@override String get rememberTrackSelectionsDescription => 'Lembrar escolhas de áudio e legendas por título';
	@override String get followServerTrackSelections => 'Usar a seleção de faixas do servidor por episódio';
	@override String get followServerTrackSelectionsDescription => 'Ao mudar de episódio, aplicar o áudio e as legendas selecionados no servidor em vez de manter a escolha atual';
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
	@override String get watchTogetherRelayDescription => 'Definir um servidor de retransmissão personalizado. Todos devem usar o mesmo servidor.';
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
	@override String get importSettingsInvalidFile => 'Este arquivo não é uma exportação válida do Plezy';
	@override String get importSettingsNoUser => 'Entre na conta antes de importar as configurações';
	@override String get shortcutsReset => 'Atalhos redefinidos para o padrão';
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
	@override String get autoSkip => 'Pular automaticamente';
	@override String get autoSkipIntro => 'Pular introdução automaticamente';
	@override String get autoSkipIntroDescription => 'Pular marcadores de introdução automaticamente após alguns segundos';
	@override String get autoSkipCredits => 'Pular créditos automaticamente';
	@override String get autoSkipCreditsDescription => 'Pular os créditos automaticamente e reproduzir o próximo episódio';
	@override String get forceSkipMarkerFallback => 'Forçar marcadores alternativos';
	@override String get forceSkipMarkerFallbackDescription => 'Usar padrões de títulos de capítulos mesmo quando o Plex tiver marcadores';
	@override String get autoSkipDelay => 'Atraso para pular automaticamente';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Aguardar ${seconds} segundos antes de pular automaticamente';
	@override String get introPattern => 'Padrão do marcador de introdução';
	@override String get introPatternDescription => 'Expressão regular que identifica marcadores de introdução nos títulos dos capítulos';
	@override String get creditsPattern => 'Padrão do marcador de créditos';
	@override String get creditsPatternDescription => 'Expressão regular que identifica marcadores de créditos nos títulos dos capítulos';
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
	@override String get tunneledPlaybackDescription => 'Usar o tunelamento de vídeo. Desative se o vídeo ficar preto ao reproduzir em HDR.';
	@override String get audioPassthrough => 'Passagem direta de áudio';
	@override String get audioPassthroughDescription => 'Enviar o áudio Dolby/DTS ao receptor ou à TV sem recodificação, preservando o som surround. Desative se não houver som.';
	@override String get audioPassthroughDescriptionAppleTv => 'Usar o decodificador Dolby nativo da Apple para Dolby Digital Plus, incluindo Atmos. DTS e TrueHD continuam sendo reproduzidos como PCM multicanal. Desative se não houver som.';
	@override String get audioDownmix => 'Conversão para estéreo';
	@override String get audioDownmixDescription => 'Converter o áudio surround em dois canais para alto-falantes estéreo ou fones de ouvido';
	@override String get downmixCenterBoost => 'Reforço do canal central';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'Reforço (dB)';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => 'Normalizar volume na conversão para estéreo';
	@override String get audioDownmixNormalizeDescription => 'Reduzir o volume da mixagem para evitar saturação. Desative para manter o volume original, que pode distorcer em cenas muito altas.';
	@override String get dvConversionMode => 'Conversão Dolby Vision';
	@override String get dvConversionModeDescription => 'Escolha como o ExoPlayer lida com arquivos Dolby Vision Profile 7.';
	@override String get dvConversionAuto => 'Automático';
	@override String get dvConversionNative => 'Nativo / desativado';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Usar a detecção de recursos do dispositivo e o comportamento alternativo padrão';
	@override String get dvConversionNativeDescription => 'Forçar DV7 nativo e impedir uma nova tentativa de conversão de DV';
	@override String get dvConversionDv81Description => 'Forçar a conversão RPU integrada para Dolby Vision perfil 8.1';
	@override String get dvConversionHevcStripDescription => 'Remover as camadas RPU/EL do Dolby Vision e apresentar HEVC sem Dolby Vision';
	@override String get demuxer => 'Demuxer de contêiner';
	@override String get demuxerDescription => 'Qual demuxer processa os arquivos reproduzidos diretamente. Mude para media3 se algum arquivo apresentar problemas.';
	@override String get demuxerFfmpeg => 'FFmpeg (recomendado)';
	@override String get demuxerMedia3 => 'media3';
	@override String get requireProfileSelectionOnOpen => 'Pedir perfil ao abrir o app';
	@override String get requireProfileSelectionOnOpenDescription => 'Mostrar a seleção de perfil sempre que o app for aberto';
	@override String get forceTvMode => 'Forçar modo TV';
	@override String get forceTvModeDescription => 'Forçar o layout de TV em dispositivos sem detecção automática. Requer reiniciar o app.';
	@override String get startInFullscreen => 'Iniciar em tela cheia';
	@override String get startInFullscreenDescription => 'Abrir o Plezy em modo de tela cheia ao iniciar';
	@override String get exitFullscreenOnPlayerClose => 'Sair da tela cheia ao fechar o reprodutor';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Sair automaticamente da tela cheia ao fechar o reprodutor de vídeo';
	@override String get autoHidePerformanceOverlay => 'Ocultar automaticamente o painel de desempenho';
	@override String get autoHidePerformanceOverlayDescription => 'Esmaecer o painel de desempenho junto com os controles de reprodução';
	@override String get showNavBarLabels => 'Mostrar Rótulos da Barra de Navegação';
	@override String get showNavBarLabelsDescription => 'Exibir rótulos de texto sob os ícones da barra de navegação';
	@override String get startupSection => 'Seção inicial';
	@override String get showExploreTab => 'Mostrar aba Explorar';
	@override String get showExploreTabDescription => 'Exibir a aba Explorar com conteúdo do Plex Discover e dos rastreadores conectados';
	@override String get liveTvDefaultFavorites => 'Canais favoritos por padrão';
	@override String get liveTvDefaultFavoritesDescription => 'Mostrar apenas os canais favoritos ao abrir a TV ao vivo';
	@override String get display => 'Tela';
	@override String get homeScreen => 'Tela inicial';
	@override String get navigation => 'Navegação';
	@override String get window => 'Janela';
	@override String get content => 'Conteúdo';
	@override String get player => 'Reprodutor';
	@override String get subtitlesAndConfig => 'Legendas e configuração';
	@override String get seekAndTiming => 'Busca e tempo';
	@override String get behavior => 'Comportamento';
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
	@override String get exportDialogTitle => 'Exportar configurações do Plezy';
}

// Path: search
class _Translations$search$pt extends Translations$search$en {
	_Translations$search$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Buscar filmes, séries, músicas...';
	@override String get tryDifferentTerm => 'Tente um termo de busca diferente';
	@override String get searchYourMedia => 'Buscar suas mídias';
	@override String get enterTitleActorOrKeyword => 'Insira um título, ator ou palavra-chave';
}

// Path: hotkeys
class _Translations$hotkeys$pt extends Translations$hotkeys$en {
	_Translations$hotkeys$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Definir Atalho para ${actionName}';
	@override String get clearShortcut => 'Limpar atalho';
	@override String get noShortcutSet => 'Nenhum atalho definido';
	@override String get currentShortcut => 'Atalho atual:';
	@override String get pressToRecord => 'Selecionar para gravar um atalho';
	@override String get recordingShortcut => 'Pressione o atalho agora';
	@override late final _Translations$hotkeys$actions$pt actions = _Translations$hotkeys$actions$pt._(_root);
}

// Path: fileInfo
class _Translations$fileInfo$pt extends Translations$fileInfo$en {
	_Translations$fileInfo$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
class _Translations$mediaMenu$pt extends Translations$mediaMenu$en {
	_Translations$mediaMenu$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
		one: 'Isso exclui o ${n} episódio e o arquivo dele.',
		other: 'Isso exclui todos os ${n} episódios e os arquivos deles.',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: 'Este item está armazenado como ${n} arquivo, que será excluído.',
		other: 'Este item está armazenado em ${n} arquivos, e todos eles serão excluídos.',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: 'Mais ${n} episódio está armazenado no mesmo arquivo e também será excluído:',
		other: 'Mais ${n} episódios estão armazenados no mesmo arquivo e também serão excluídos:',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'O Plezy não conseguiu verificar quais arquivos serão removidos, então pode excluir mais do que o item acima. Cancele e tente novamente, ou exclua mesmo assim.';
	@override String get deleteScopeUnverifiedNoFileInfo => 'Seu servidor não forneceu detalhes do arquivo para este item, então o Plezy não pode verificar quais arquivos serão removidos. Pode excluir mais do que o item acima.';
	@override String get mediaDeletedSuccessfully => 'Item de mídia excluído com sucesso';
	@override String get mediaFailedToDelete => 'Falha ao excluir item de mídia';
	@override String get rate => 'Avaliar';
	@override String get playFromBeginning => 'Reproduzir do início';
	@override String get playVersion => 'Reproduzir versão...';
}

// Path: rateSheet
class _Translations$rateSheet$pt extends Translations$rateSheet$en {
	_Translations$rateSheet$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
class _Translations$accessibility$pt extends Translations$accessibility$en {
	_Translations$accessibility$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
}

// Path: tooltips
class _Translations$tooltips$pt extends Translations$tooltips$en {
	_Translations$tooltips$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Reprodução aleatória';
	@override String get playTrailer => 'Reproduzir trailer';
	@override String get markAsWatched => 'Marcar como assistido';
	@override String get markAsUnwatched => 'Marcar como não assistido';
}

// Path: audioTracks
class _Translations$audioTracks$pt extends Translations$audioTracks$en {
	_Translations$audioTracks$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => 'Faixa de áudio ${n}';
}

// Path: videoControls
class _Translations$videoControls$pt extends Translations$videoControls$en {
	_Translations$videoControls$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
	@override String get longPressToUnlock => 'Pressione e segure para destravar';
	@override String get timelineSlider => 'Linha do tempo do vídeo';
	@override String get volumeSlider => 'Nível de volume';
	@override String endsAt({required Object time}) => 'Termina às ${time}';
	@override String get pipActive => 'Reproduzindo em Picture-in-Picture';
	@override String get pipFailed => 'Falha ao iniciar picture-in-picture';
	@override String get screenshotSaved => 'Captura de tela salva';
	@override String zoomPercent({required Object percent}) => 'Zoom ${percent}%';
	@override late final _Translations$videoControls$pipErrors$pt pipErrors = _Translations$videoControls$pipErrors$pt._(_root);
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
}

// Path: messages
class _Translations$messages$pt extends Translations$messages$en {
	_Translations$messages$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Marcado como assistido';
	@override String get markedAsUnwatched => 'Marcado como não assistido';
	@override String get markedAsWatchedOffline => 'Marcado como assistido (será sincronizado quando online)';
	@override String get markedAsUnwatchedOffline => 'Marcado como não assistido (será sincronizado quando online)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'Removido automaticamente: ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: 'Removido automaticamente ${n} download assistido',
		other: 'Removidos automaticamente ${n} downloads assistidos',
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
	@override String get logsUploaded => 'Logs enviados';
	@override String get logsUploadFailed => 'Falha ao enviar logs';
	@override String get logId => 'ID do log';
	@override String get burnedSubtitlesUseMenu => 'As legendas estão incorporadas a esta transmissão. Altere-as no menu de legendas.';
	@override String get noVideoUrl => 'Nenhuma URL de vídeo disponível';
	@override String get playbackNoMediaSources => 'O servidor não retornou nenhuma fonte de mídia reproduzível';
	@override String get playbackDataNotPrepared => 'A reprodução foi iniciada antes que os dados estivessem prontos';
	@override String get streamSelectionUnavailable => 'A seleção de fluxos não está disponível para esta fonte';
	@override String get streamSelectionFailed => 'Não foi possível aplicar os fluxos selecionados';
	@override String get serverUnavailableForProfile => 'Nenhum servidor está disponível para o perfil ativo';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$pt extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
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
	@override String get anchorToScreen => 'Ancorar à tela';
	@override String get anchorToScreenDescription => 'Exibir as legendas de texto nas faixas pretas abaixo de vídeos em tela ampla';
	@override String get bold => 'Negrito';
	@override String get italic => 'Itálico';
	@override String get renderResolution => 'Resolução de renderização';
	@override String get renderResolutionScreen => 'Resolução da tela';
	@override String get renderResolutionVideo => 'Resolução do vídeo';
}

// Path: mpvConfig
class _Translations$mpvConfig$pt extends Translations$mpvConfig$en {
	_Translations$mpvConfig$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
	@override String get embeddedVoHint => 'vo, gpu-context e gpu-api são ignorados no Linux: o vídeo incorporado é sempre renderizado via vo=libmpv no plano de vídeo, e gpu-next (necessário para shaders de computação como ArtCNN) não pode ser executado incorporado.';
}

// Path: dialog
class _Translations$dialog$pt extends Translations$dialog$en {
	_Translations$dialog$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Confirmar Ação';
}

// Path: profiles
class _Translations$profiles$pt extends Translations$profiles$en {
	_Translations$profiles$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'Adicionar perfil Plezy';
	@override String get switchingProfile => 'Mudando perfil…';
	@override String get deleteThisProfileTitle => 'Excluir este perfil?';
	@override String deleteThisProfileMessage({required Object displayName}) => 'Remover ${displayName}. As conexões não serão afetadas.';
	@override String get active => 'Ativo';
	@override String get manage => 'Gerenciar';
	@override String get delete => 'Excluir';
	@override String get signOut => 'Sair';
	@override String get signOutPlexTitle => 'Sair do Plex?';
	@override String signOutPlexMessage({required Object displayName}) => 'Remover ${displayName} e todos os usuários do Plex Home? Você pode entrar novamente quando quiser.';
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
	@override String get borrowEmptySubtitle => 'Conecte Plex ou Jellyfin a outro perfil primeiro.';
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
}

// Path: connections
class _Translations$connections$pt extends Translations$connections$en {
	_Translations$connections$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Conexões';
	@override String get addConnection => 'Adicionar conexão';
	@override String get addConnectionSubtitleNoProfile => 'Entre com Plex ou conecte um servidor Jellyfin';
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'Adicionar a ${displayName}: Plex, Jellyfin ou outra conexão de perfil';
	@override String sessionExpiredOne({required Object name}) => 'Sessão de ${name} expirada';
	@override String sessionExpiredMany({required Object count}) => 'Sessões expiradas em ${count} servidores';
	@override String get signInAgain => 'Entrar novamente';
	@override String editMediaBrowserTitle({required Object product}) => 'Editar conexão do ${product}';
	@override String editMediaBrowserIntro({required Object serverName}) => 'Adicione ou remova URLs para ${serverName}. O Plezy usará a URL acessível com menor latência.';
}

// Path: discover
class _Translations$discover$pt extends Translations$discover$en {
	_Translations$discover$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
		one: '${n} título',
		other: '${n} títulos',
	);
}

// Path: errors
class _Translations$errors$pt extends Translations$errors$en {
	_Translations$errors$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
}

// Path: libraries
class _Translations$libraries$pt extends Translations$libraries$en {
	_Translations$libraries$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
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
	@override late final _Translations$libraries$tabs$pt tabs = _Translations$libraries$tabs$pt._(_root);
	@override late final _Translations$libraries$groupings$pt groupings = _Translations$libraries$groupings$pt._(_root);
	@override late final _Translations$libraries$filterCategories$pt filterCategories = _Translations$libraries$filterCategories$pt._(_root);
	@override late final _Translations$libraries$sortLabels$pt sortLabels = _Translations$libraries$sortLabels$pt._(_root);
}

// Path: about
class _Translations$about$pt extends Translations$about$en {
	_Translations$about$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Sobre';
	@override String get openSourceLicenses => 'Licenças de código aberto';
	@override String versionLabel({required Object version}) => 'Versão ${version}';
	@override String get appDescription => 'Um belo cliente de Plex e Jellyfin feito com Flutter';
	@override String get viewLicensesDescription => 'Ver as licenças de bibliotecas de terceiros';
}

// Path: serverSelection
class _Translations$serverSelection$pt extends Translations$serverSelection$en {
	_Translations$serverSelection$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Nenhum servidor encontrado para ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Falha ao carregar servidores: ${error}';
	@override String get noValidServers => 'Nenhum servidor utilizável foi encontrado nesta conta';
}

// Path: hubDetail
class _Translations$hubDetail$pt extends Translations$hubDetail$en {
	_Translations$hubDetail$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Título';
	@override String get releaseYear => 'Ano de Lançamento';
	@override String get dateAdded => 'Data de Adição';
	@override String get rating => 'Avaliação';
	@override String get noItemsFound => 'Nenhum item encontrado';
}

// Path: logs
class _Translations$logs$pt extends Translations$logs$en {
	_Translations$logs$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Limpar Logs';
	@override String get copyLogs => 'Copiar Logs';
	@override String get uploadLogs => 'Enviar Logs';
}

// Path: startup
class _Translations$startup$pt extends Translations$startup$en {
	_Translations$startup$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'O Plezy não conseguiu iniciar';
	@override String get failedBody => 'Algo deu errado durante a inicialização. Os detalhes abaixo identificam o que falhou.';
	@override String get failedBodyRepairable => 'O arquivo de configurações salvo do Plezy está danificado e precisa ser reconstruído antes que o Plezy possa iniciar. Tentar novamente não vai ajudar — escolha Reparar armazenamento.';
	@override String get phaseLabel => 'Etapa';
	@override String get showDetails => 'Mostrar detalhes';
	@override String get hideDetails => 'Ocultar detalhes';
	@override String get copyDetails => 'Copiar detalhes';
	@override String get detailsCopied => 'Detalhes copiados para a área de transferência';
	@override String get uploadDetails => 'Enviar detalhes';
	@override String get repairStorage => 'Reparar armazenamento';
	@override String get repairTitle => 'Reparar dados armazenados?';
	@override String get repairBodyCommon => 'O arquivo de configurações do Plezy está danificado e não pode ser lido. Reparar redefine todas as configurações para o padrão.';
	@override String get repairBodyOneCredential => 'Um login salvo está danificado e não pode ser lido. Reparar remove apenas ele; suas outras configurações permanecem intactas.';
	@override String get repairBodySignInsKept => 'Seus servidores e perfis devem permanecer conectados.';
	@override String get repairBodySignInsLost => 'A chave que protege seus logins salvos não pode ser recuperada deste arquivo, então você terá que entrar novamente em todos os servidores e perfis. Nada no seu servidor de mídia é afetado.';
	@override String get repairBodySessionsUncertain => 'Os rastreadores (MAL, AniList, Simkl, Trakt) e o Seerr são armazenados separadamente e podem ou não ser preservados. O Plezy informará exatamente o que foi mantido.';
	@override String get repairConfirm => 'Reparar';
	@override String get repairSucceeded => 'Armazenamento reparado';
	@override String get repairNeedsRestart => 'Armazenamento reparado — reinício necessário';
	@override String get restartRequiredBody => 'Seus dados foram reparados, mas o Plezy precisa iniciar do zero antes de usá-los. Feche o Plezy e abra-o novamente.';
	@override String get quitPlezy => 'Sair do Plezy';
	@override String get repairFailed => 'Falha no reparo';
	@override String get repairKeptSignIns => 'Seus servidores e perfis ainda estão conectados.';
	@override String get repairLostSignIns => 'A chave que protege seus logins salvos não pôde ser recuperada. Você terá que entrar novamente em todos os servidores e perfis.';
	@override String get repairLostSessions => 'Pelo menos uma conexão de rastreador ou do Seerr foi perdida e precisa ser reconectada.';
	@override String get backupTitle => 'Uma cópia do arquivo danificado foi mantida';
	@override String get backupWarning => 'Ele contém suas credenciais de login. Não envie nem compartilhe.';
	@override String get deleteBackup => 'Excluir cópia';
	@override String get backupDeleted => 'Cópia excluída.';
	@override String get previousFailureTitle => 'O Plezy falhou ao iniciar da última vez';
}

// Path: licenses
class _Translations$licenses$pt extends Translations$licenses$en {
	_Translations$licenses$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Pacotes Relacionados';
	@override String get license => 'Licença';
	@override String licenseNumber({required Object number}) => 'Licença ${number}';
	@override String licensesCount({required Object count}) => '${count} licenças';
}

// Path: navigation
class _Translations$navigation$pt extends Translations$navigation$en {
	_Translations$navigation$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Bibliotecas';
	@override String get downloads => 'Downloads';
	@override String get liveTv => 'TV ao Vivo';
	@override String get explore => 'Explorar';
}

// Path: explore
class _Translations$explore$pt extends Translations$explore$en {
	_Translations$explore$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Explorar';
	@override String get selectSource => 'Selecionar fonte';
	@override late final _Translations$explore$rows$pt rows = _Translations$explore$rows$pt._(_root);
	@override late final _Translations$explore$status$pt status = _Translations$explore$status$pt._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '${n} episódio',
		other: '${n} episódios',
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
	@override String get emptyTitle => 'Ainda não há nada aqui';
	@override String emptyMessage({required Object source}) => 'As linhas de ${source} aparecerão aqui quando tiverem conteúdo.';
	@override String searchHint({required Object source}) => 'Buscar em ${source}';
	@override String searchEmpty({required Object query}) => 'Nenhum resultado para "${query}"';
	@override String searchPrompt({required Object source}) => 'Busque filmes e séries em ${source}.';
	@override String get searchFailed => 'Falha na busca. Verifique sua conexão e tente novamente.';
	@override late final _Translations$explore$badge$pt badge = _Translations$explore$badge$pt._(_root);
	@override late final _Translations$explore$stats$pt stats = _Translations$explore$stats$pt._(_root);
	@override late final _Translations$explore$season$pt season = _Translations$explore$season$pt._(_root);
	@override late final _Translations$explore$format$pt format = _Translations$explore$format$pt._(_root);
	@override late final _Translations$explore$sourceMaterial$pt sourceMaterial = _Translations$explore$sourceMaterial$pt._(_root);
	@override late final _Translations$explore$creditRole$pt creditRole = _Translations$explore$creditRole$pt._(_root);
	@override late final _Translations$explore$relation$pt relation = _Translations$explore$relation$pt._(_root);
	@override String broadcast({required Object day, required Object time}) => 'Vai ao ar ${day} às ${time}';
	@override String broadcastWithZone({required Object day, required Object time, required Object timezone}) => 'Vai ao ar ${day} às ${time} ${timezone}';
	@override late final _Translations$explore$detail$pt detail = _Translations$explore$detail$pt._(_root);
	@override String totalResults({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '${n} resultado',
		other: '${n} resultados',
	);
}

// Path: liveTv
class _Translations$liveTv$pt extends Translations$liveTv$en {
	_Translations$liveTv$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
	@override String get unknownHub => 'Desconhecido';
	@override String get unknownError => 'Erro desconhecido';
	@override String channelNumber({required Object number}) => 'Canal ${number}';
	@override String get unknownChannel => 'Canal desconhecido';
	@override String get live => 'AO VIVO';
	@override String get reloadGuide => 'Recarregar Guia';
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
	@override String get rulesProcessRequested => 'Reavaliação de regras solicitada';
	@override String get recordShow => 'Gravar programa';
	@override late final _Translations$liveTv$recordSettings$pt recordSettings = _Translations$liveTv$recordSettings$pt._(_root);
	@override String startingInMinutes({required Object minutes}) => 'Começa em ${minutes} min';
	@override String dayAtTime({required Object day, required Object time}) => '${day} às ${time}';
	@override String invalidPlaybackData({required Object product}) => '${product} retornou dados inválidos de reprodução de TV ao Vivo';
	@override String get failedToStartChannel => 'Não foi possível iniciar o canal ao vivo';
	@override String get failedToBuildStreamUrl => 'Não foi possível gerar a URL da transmissão';
}

// Path: collections
class _Translations$collections$pt extends Translations$collections$en {
	_Translations$collections$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
class _Translations$playlists$pt extends Translations$playlists$en {
	_Translations$playlists$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
	@override String itemCount({required Object count}) => '${count} itens';
	@override String get oneItem => '1 item';
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
class _Translations$music$pt extends Translations$music$en {
	_Translations$music$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

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
	@override String get nowPlaying => 'Reproduzindo agora';
	@override String playingFrom({required Object title}) => 'Reproduzindo de ${title}';
	@override String get queue => 'Fila';
	@override String get clearQueue => 'Limpar fila';
	@override String get lyrics => 'Letra';
	@override String get noLyrics => 'Nenhuma letra disponível';
	@override String get sleepTimer => 'Temporizador de suspensão';
	@override String get sleepTimerEndOfTrack => 'Fim da faixa';
	@override String sleepTimerMinutes({required Object n}) => '${n} minutos';
	@override String get stopPlayback => 'Parar reprodução';
	@override String get previousTrack => 'Faixa anterior';
	@override String get nextTrack => 'Próxima faixa';
	@override String get repeat => 'Repetir';
	@override String get repeatAll => 'Repetir tudo';
	@override String get repeatOne => 'Repetir uma faixa';
	@override String get instantMixNoServer => 'Nenhum servidor está disponível para uma mistura instantânea';
	@override String noAudioUrl({required Object track}) => 'Nenhuma URL de áudio está disponível para ${track}';
	@override late final _Translations$music$discography$pt discography = _Translations$music$discography$pt._(_root);
}

// Path: watchTogether
class _Translations$watchTogether$pt extends Translations$watchTogether$en {
	_Translations$watchTogether$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Assistir Juntos';
	@override String get description => 'Assista a conteúdos sincronizados com amigos e familiares';
	@override String get createSession => 'Criar sessão';
	@override String get creating => 'Criando...';
	@override String get joinSession => 'Entrar na sessão';
	@override String get joining => 'Entrando...';
	@override String get controlMode => 'Modo de controle';
	@override String get controlModeQuestion => 'Quem pode controlar a reprodução?';
	@override String get hostOnly => 'Apenas o anfitrião';
	@override String get anyone => 'Qualquer pessoa';
	@override String get hostingSession => 'Hospedando uma sessão';
	@override String get inSession => 'Em uma sessão';
	@override String get sessionCode => 'Código da sessão';
	@override String get openSessionControls => 'Abrir os controles da sessão Assistir Juntos';
	@override String get copySessionCode => 'Copiar código da sessão';
	@override String get hostControlsPlayback => 'O anfitrião controla a reprodução';
	@override String get anyoneCanControl => 'Qualquer pessoa pode controlar a reprodução';
	@override String get hostControls => 'Controle do anfitrião';
	@override String get anyoneControls => 'Controle por qualquer pessoa';
	@override String get participants => 'Participantes';
	@override String get host => 'Anfitrião';
	@override String get hostBadge => 'ANFITRIÃO';
	@override String get youAreHost => 'Você é o anfitrião';
	@override String get watchingWithOthers => 'Assistindo com outras pessoas';
	@override String get endSession => 'Encerrar sessão';
	@override String get leaveSession => 'Sair da sessão';
	@override String get endSessionQuestion => 'Encerrar sessão?';
	@override String get leaveSessionQuestion => 'Sair da sessão?';
	@override String get endSessionConfirm => 'Isso encerrará a sessão para todos os participantes.';
	@override String get leaveSessionConfirm => 'Você será removido da sessão.';
	@override String get endSessionConfirmOverlay => 'Isso encerrará a sessão do Assistir Juntos para todos os participantes.';
	@override String get leaveSessionConfirmOverlay => 'Você será desconectado da sessão do Assistir Juntos.';
	@override String get end => 'Encerrar';
	@override String get leave => 'Sair';
	@override String get syncing => 'Sincronizando...';
	@override String get joinWatchSession => 'Entrar na sessão';
	@override String get enterCodeHint => 'Insira o código de 5 caracteres';
	@override String get pasteFromClipboard => 'Colar da área de transferência';
	@override String get pleaseEnterCode => 'Insira um código de sessão';
	@override String get codeMustBe5Chars => 'O código da sessão deve ter 5 caracteres';
	@override String get joinInstructions => 'Insira o código de sessão do anfitrião para entrar.';
	@override String get failedToCreate => 'Falha ao criar sessão';
	@override String get failedToJoin => 'Falha ao entrar na sessão';
	@override String get sessionCodeCopied => 'Código da sessão copiado para a área de transferência';
	@override String get relayUnreachable => 'Servidor de retransmissão inacessível. O bloqueio pelo provedor de internet pode impedir o uso do Assistir Juntos.';
	@override String get reconnectingToHost => 'Reconectando ao anfitrião...';
	@override String get currentPlayback => 'Reprodução atual';
	@override String get joinCurrentPlayback => 'Entrar na reprodução atual';
	@override String get joinCurrentPlaybackDescription => 'Voltar ao conteúdo que o anfitrião está assistindo agora';
	@override String get failedToOpenCurrentPlayback => 'Falha ao abrir a reprodução atual';
	@override String participantJoined({required Object name}) => '${name} entrou';
	@override String participantLeft({required Object name}) => '${name} saiu';
	@override String participantPaused({required Object name}) => '${name} pausou';
	@override String participantResumed({required Object name}) => '${name} retomou';
	@override String participantSeeked({required Object name}) => '${name} mudou a posição da reprodução';
	@override String participantBuffering({required Object name}) => '${name} está aguardando o carregamento';
	@override String participantNeedsUpdate({required Object name}) => '${name} está usando uma versão mais antiga do app — sincronização indisponível';
	@override String resumingWithout({required Object name}) => 'Retomando sem ${name}';
	@override String get waitingForParticipants => 'Aguardando o carregamento dos outros participantes...';
	@override String waitingForName({required Object name}) => 'Aguardando ${name}...';
	@override String get recentRooms => 'Salas recentes';
	@override String get renameRoom => 'Renomear sala';
	@override String get removeRoom => 'Remover';
	@override String get guestSwitchUnavailable => 'Não foi possível trocar — servidor indisponível para sincronização';
	@override String get guestSwitchFailed => 'Não foi possível trocar — conteúdo não encontrado neste servidor';
	@override String get defaultDisplayName => 'Usuário';
	@override late final _Translations$watchTogether$errors$pt errors = _Translations$watchTogether$errors$pt._(_root);
}

// Path: downloads
class _Translations$downloads$pt extends Translations$downloads$en {
	_Translations$downloads$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
	@override String get storageFull => 'Os downloads foram interrompidos porque o armazenamento do dispositivo está cheio. Libere espaço e tente novamente.';
	@override String episodesQueued({required Object count}) => '${count} episódios na fila de download';
	@override String get downloadDeleted => 'Download excluído';
	@override String deleteConfirm({required Object title}) => 'Excluir "${title}" deste dispositivo?';
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
	@override String get deleteAll => 'Excluir todos';
	@override String get selectVersion => 'Selecionar versão';
	@override String get allEpisodes => 'Todos os episódios';
	@override String get unwatchedOnly => 'Apenas não assistidos';
	@override String nextNUnwatched({required Object count}) => 'Próximos ${count} episódios não assistidos';
	@override String get customAmount => 'Quantidade personalizada...';
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
	@override String get activeSyncRules => 'Regras de sincronização';
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
	@override String get syncRuleNotAvailableForProfile => 'Indisponível para o perfil atual';
	@override String get syncRuleUnknownServer => 'Servidor desconhecido';
	@override String get syncRuleListCreated => 'Regra de sincronização criada';
	@override late final _Translations$downloads$backgroundWarning$pt backgroundWarning = _Translations$downloads$backgroundWarning$pt._(_root);
	@override String get unknownShow => 'Série desconhecida';
	@override String get unknownSeason => 'Temporada desconhecida';
	@override String get unknownAlbum => 'Álbum desconhecido';
	@override String completedOfTotal({required Object completed, required Object total}) => '${completed}/${total} concluídos';
	@override String get errorFileNotFound => 'Arquivo não encontrado (404)';
	@override String get errorDownloadFailed => 'Falha no download';
	@override String errorPostProcessing({required Object error}) => 'Falha no pós-processamento: ${error}';
	@override String get notificationDownloading => 'Baixando...';
	@override String get notificationComplete => 'Download concluído';
	@override String get notificationPaused => 'Download pausado';
}

// Path: shaders
class _Translations$shaders$pt extends Translations$shaders$en {
	_Translations$shaders$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
class _Translations$companionRemote$pt extends Translations$companionRemote$en {
	_Translations$companionRemote$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Controle remoto';
	@override String connectedTo({required Object name}) => 'Conectado a ${name}';
	@override String get unknownDevice => 'Dispositivo desconhecido';
	@override String playSentToDevice({required Object device}) => 'Sent to ${device}';
	@override late final _Translations$companionRemote$session$pt session = _Translations$companionRemote$session$pt._(_root);
	@override late final _Translations$companionRemote$pairing$pt pairing = _Translations$companionRemote$pairing$pt._(_root);
	@override late final _Translations$companionRemote$remote$pt remote = _Translations$companionRemote$remote$pt._(_root);
	@override late final _Translations$companionRemote$errors$pt errors = _Translations$companionRemote$errors$pt._(_root);
	@override String get closedBeforeAuth => 'A conexão foi encerrada antes da autenticação';
}

// Path: videoSettings
class _Translations$videoSettings$pt extends Translations$videoSettings$en {
	_Translations$videoSettings$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
	@override String get performanceOverlay => 'Painel de desempenho';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'Surround';
	@override String get audioOutputSpatial => 'Áudio espacial';
	@override String get audioOutputStereo => 'Estéreo';
	@override String get audioNormalization => 'Normalizar intensidade sonora';
	@override String get audioDownmix => 'Conversão para estéreo';
}

// Path: performanceOverlay
class _Translations$performanceOverlay$pt extends Translations$performanceOverlay$en {
	_Translations$performanceOverlay$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
class _Translations$externalPlayer$pt extends Translations$externalPlayer$en {
	_Translations$externalPlayer$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
}

// Path: metadataEdit
class _Translations$metadataEdit$pt extends Translations$metadataEdit$en {
	_Translations$metadataEdit$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
}

// Path: matchScreen
class _Translations$matchScreen$pt extends Translations$matchScreen$en {
	_Translations$matchScreen$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
class _Translations$serverTasks$pt extends Translations$serverTasks$en {
	_Translations$serverTasks$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tarefas do servidor';
	@override String get failedToLoad => 'Falha ao carregar tarefas';
	@override String get noTasks => 'Nenhuma tarefa em execução';
}

// Path: trakt
class _Translations$trakt$pt extends Translations$trakt$en {
	_Translations$trakt$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'Conectado';
	@override String connectedAs({required Object username}) => 'Conectado como @${username}';
	@override String get disconnectConfirm => 'Desconectar a conta do Trakt?';
	@override String get disconnectConfirmBody => 'O Plezy deixará de enviar eventos ao Trakt. Você pode reconectar quando quiser.';
	@override String get scrobble => 'Scrobbling em tempo real';
	@override String get scrobbleDescription => 'Envia eventos de reprodução, pausa e parada ao Trakt durante a exibição.';
	@override String get watchedSync => 'Sincronizar status de assistido';
	@override String get watchedSyncDescription => 'Ao marcar itens como assistidos no Plezy, eles também serão marcados no Trakt.';
}

// Path: seerr
class _Translations$seerr$pt extends Translations$seerr$en {
	_Translations$seerr$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
	@override String get noSignInMethods => 'Esta instância do Seerr não oferece nenhum método de acesso compatível com o Plezy.';
	@override String get instance => 'Instância';
	@override String get disconnectConfirm => 'Desconectar Seerr?';
	@override String get disconnectConfirmBody => 'O Plezy esquecerá esta instância do Seerr. Reconecte quando quiser.';
	@override String get request => 'Solicitar';
	@override String get request4k => 'Solicitar em 4K';
	@override String get seasons => 'Temporadas';
	@override String get allSeasons => 'Todas as temporadas';
	@override String get advancedOptions => 'Avançado';
	@override String get destinationServer => 'Servidor de destino';
	@override String get qualityProfile => 'Perfil de qualidade';
	@override String get rootFolder => 'Pasta raiz';
	@override String get languageProfile => 'Perfil de idioma';
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
	@override String get notInitialized => 'Esta instância do Seerr não concluiu a configuração inicial';
	@override String get noPlexTokenForReauth => 'Nenhum token do Plex está disponível para entrar novamente';
	@override String get noStoredCredentials => 'Nenhuma credencial armazenada está disponível para entrar novamente';
	@override String get signInRejected => 'A entrada foi rejeitada';
	@override String get noSessionCookie => 'O Seerr não forneceu um cookie de sessão';
	@override String get freshCookieRejected => 'O Seerr rejeitou o novo cookie de sessão';
	@override String get noUserInformation => 'O Seerr não retornou informações do usuário';
	@override String get sessionRejectedAfterReauth => 'A sessão foi rejeitada após entrar novamente';
}

// Path: services
class _Translations$services$pt extends Translations$services$en {
	_Translations$services$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Serviços';
	@override String get hubSubtitle => 'Sincronize o progresso de exibição e solicite novos títulos.';
	@override String get notConnected => 'Não conectado';
	@override String connectedAs({required Object username}) => 'Conectado como @${username}';
	@override String get scrobble => 'Registrar progresso automaticamente';
	@override String get scrobbleDescription => 'Atualiza sua lista quando você termina um episódio ou filme.';
	@override String disconnectConfirm({required Object service}) => 'Desconectar ${service}?';
	@override String disconnectConfirmBody({required Object service}) => 'O Plezy deixará de atualizar ${service}. Reconecte quando quiser.';
	@override String connectFailed({required Object service}) => 'Não foi possível conectar ao ${service}. Tente novamente.';
	@override late final _Translations$services$names$pt names = _Translations$services$names$pt._(_root);
	@override late final _Translations$services$deviceCode$pt deviceCode = _Translations$services$deviceCode$pt._(_root);
	@override late final _Translations$services$oauthProxy$pt oauthProxy = _Translations$services$oauthProxy$pt._(_root);
	@override late final _Translations$services$pendingAuth$pt pendingAuth = _Translations$services$pendingAuth$pt._(_root);
	@override late final _Translations$services$libraryFilter$pt libraryFilter = _Translations$services$libraryFilter$pt._(_root);
}

// Path: addServer
class _Translations$addServer$pt extends Translations$addServer$en {
	_Translations$addServer$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
}

// Path: common.ratingSource
class _Translations$common$ratingSource$pt extends Translations$common$ratingSource$en {
	_Translations$common$ratingSource$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

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
}

// Path: common.mediaKind
class _Translations$common$mediaKind$pt extends Translations$common$mediaKind$en {
	_Translations$common$mediaKind$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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

// Path: hotkeys.actions
class _Translations$hotkeys$actions$pt extends Translations$hotkeys$actions$en {
	_Translations$hotkeys$actions$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
	@override String get shaderToggle => 'Alternar Shaders';
	@override String get skipMarker => 'Pular introdução/créditos';
	@override String get screenshot => 'Capturar tela';
}

// Path: videoControls.pipErrors
class _Translations$videoControls$pipErrors$pt extends Translations$videoControls$pipErrors$en {
	_Translations$videoControls$pipErrors$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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

// Path: libraries.tabs
class _Translations$libraries$tabs$pt extends Translations$libraries$tabs$en {
	_Translations$libraries$tabs$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Recomendados';
	@override String get browse => 'Navegar';
	@override String get collections => 'Coleções';
	@override String get playlists => 'Playlists';
}

// Path: libraries.groupings
class _Translations$libraries$groupings$pt extends Translations$libraries$groupings$en {
	_Translations$libraries$groupings$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
class _Translations$libraries$filterCategories$pt extends Translations$libraries$filterCategories$en {
	_Translations$libraries$filterCategories$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get genre => 'Gênero';
	@override String get year => 'Ano';
	@override String get contentRating => 'Classificação indicativa';
	@override String get tag => 'Tag';
	@override String get unwatched => 'Não assistidos';
	@override String get unplayed => 'Não reproduzidos';
	@override String get favorites => 'Favoritos';
}

// Path: libraries.sortLabels
class _Translations$libraries$sortLabels$pt extends Translations$libraries$sortLabels$en {
	_Translations$libraries$sortLabels$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
}

// Path: explore.rows
class _Translations$explore$rows$pt extends Translations$explore$rows$en {
	_Translations$explore$rows$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
class _Translations$explore$status$pt extends Translations$explore$status$en {
	_Translations$explore$status$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get airing => 'Em exibição';
	@override String get ended => 'Finalizada';
	@override String get canceled => 'Cancelada';
	@override String get upcoming => 'Em breve';
}

// Path: explore.badge
class _Translations$explore$badge$pt extends Translations$explore$badge$en {
	_Translations$explore$badge$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
class _Translations$explore$stats$pt extends Translations$explore$stats$en {
	_Translations$explore$stats$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
		one: '${n} comentário',
		other: '${n} comentários',
	);
	@override String votes({required Object n}) => '${n} votos';
	@override String watching({required Object n}) => '${n} assistindo';
	@override String completed({required Object n}) => '${n} concluíram';
	@override String onHold({required Object n}) => '${n} em pausa';
	@override String dropped({required Object n}) => '${n} abandonaram';
}

// Path: explore.season
class _Translations$explore$season$pt extends Translations$explore$season$en {
	_Translations$explore$season$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get winter => 'Inverno';
	@override String get spring => 'Primavera';
	@override String get summer => 'Verão';
	@override String get fall => 'Outono';
	@override String withYear({required Object season, required Object year}) => '${season} ${year}';
}

// Path: explore.format
class _Translations$explore$format$pt extends Translations$explore$format$en {
	_Translations$explore$format$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
class _Translations$explore$sourceMaterial$pt extends Translations$explore$sourceMaterial$en {
	_Translations$explore$sourceMaterial$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
class _Translations$explore$creditRole$pt extends Translations$explore$creditRole$en {
	_Translations$explore$creditRole$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get director => 'Diretor';
	@override String get writer => 'Roteirista';
	@override String get producer => 'Produtor';
	@override String get creator => 'Criador';
	@override String get composer => 'Compositor';
}

// Path: explore.relation
class _Translations$explore$relation$pt extends Translations$explore$relation$en {
	_Translations$explore$relation$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
class _Translations$explore$detail$pt extends Translations$explore$detail$en {
	_Translations$explore$detail$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
		one: 'Recomendado por ${n} usuário',
		other: 'Recomendado por ${n} usuários',
	);
	@override String recommendedBy({required Object who}) => 'Recomendado por ${who}';
	@override String favoritedBy({required Object who}) => 'Favoritado por ${who}';
	@override String unairedEpisodes({required Object n}) => '${n} ainda não exibidos';
	@override String recommendedByPercent({required Object percent}) => 'Recomendado por ${percent} dos espectadores';
	@override String get relatedTitles => 'Títulos relacionados';
	@override String get background => 'Contexto';
}

// Path: liveTv.recordSettings
class _Translations$liveTv$recordSettings$pt extends Translations$liveTv$recordSettings$en {
	_Translations$liveTv$recordSettings$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
class _Translations$music$discography$pt extends Translations$music$discography$en {
	_Translations$music$discography$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get singlesAndEps => 'Singles e EPs';
	@override String get live => 'Ao vivo';
	@override String get compilations => 'Compilações';
}

// Path: watchTogether.errors
class _Translations$watchTogether$errors$pt extends Translations$watchTogether$errors$en {
	_Translations$watchTogether$errors$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get timedOut => 'O servidor de retransmissão não respondeu a tempo';
	@override String get connectionLost => 'A conexão foi encerrada antes de a sessão ficar pronta';
	@override String get invalidRelayResponse => 'O servidor de retransmissão enviou uma resposta inesperada';
	@override String get sessionEnded => 'O anfitrião encerrou a sessão';
}

// Path: downloads.backgroundWarning
class _Translations$downloads$backgroundWarning$pt extends Translations$downloads$backgroundWarning$en {
	_Translations$downloads$backgroundWarning$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get bannerBlocked => 'Os downloads serão interrompidos ao sair do app';
	@override String get bannerDegraded => 'Os downloads em segundo plano podem ser limitados';
	@override String get bannerAction => 'Detalhes';
	@override String get sheetTitle => 'Os downloads em segundo plano estão bloqueados';
	@override String get sheetTitleDegraded => 'Os downloads em segundo plano podem ser limitados';
	@override String get sheetIntro => 'O Android está impedindo que o Plezy faça downloads de forma confiável em segundo plano.';
	@override String get sheetIntroDegraded => 'Seu dispositivo está limitando quando o Plezy pode fazer downloads em segundo plano.';
	@override String get reasonBackgroundRestricted => 'O uso em segundo plano do Plezy está restrito. Defina o uso da bateria ou o uso em segundo plano como "Sem restrições".';
	@override String get reasonStandbyRestricted => 'O Android colocou o Plezy em um modo de espera restrito. Defina o uso da bateria como "Sem restrições".';
	@override String get reasonDownloadChannelBlocked => 'As notificações de download estão desativadas; por isso, o progresso e os controles podem ficar indisponíveis.';
	@override String get reasonNotificationsDisabled => 'As notificações estão desativadas. No Android 13 ou mais recente, elas são necessárias para downloads longos em segundo plano.';
	@override String get reasonDataSaver => 'A Economia de dados está ativada e bloqueia downloads em segundo plano usando dados móveis. Os downloads ainda devem funcionar no Wi-Fi.';
	@override String get reasonOemUnknown => 'Os downloads foram interrompidos várias vezes enquanto o Plezy estava em segundo plano. Verifique as configurações de bateria ou uso em segundo plano do Plezy.';
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

// Path: companionRemote.session
class _Translations$companionRemote$session$pt extends Translations$companionRemote$session$en {
	_Translations$companionRemote$session$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
class _Translations$companionRemote$pairing$pt extends Translations$companionRemote$pairing$en {
	_Translations$companionRemote$pairing$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'Dispositivos Plezy com a mesma conta Plex aparecem aqui';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Conectando...';
	@override String get searchingForDevices => 'Procurando dispositivos...';
	@override String get noDevicesFound => 'Nenhum dispositivo encontrado na sua rede';
	@override String get noDevicesHint => 'Abra o Plezy no desktop e use a mesma rede Wi-Fi';
	@override String get availableDevices => 'Dispositivos disponíveis';
	@override String get manualConnection => 'Conexão manual';
	@override String get cryptoInitFailed => 'Não foi possível iniciar a conexão segura. Entre no Plex primeiro.';
	@override String get validationHostRequired => 'Insira o endereço do host';
	@override String get validationHostFormat => 'O formato deve ser IP:porta (ex.: 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'A conexão atingiu o tempo limite. Use a mesma rede nos dois dispositivos.';
	@override String get sessionNotFound => 'Dispositivo não encontrado. Verifique se o Plezy está em execução no host.';
	@override String get authFailed => 'Falha na autenticação. Ambos os dispositivos precisam da mesma conta Plex.';
	@override String failedToConnect({required Object error}) => 'Falha ao conectar: ${error}';
}

// Path: companionRemote.remote
class _Translations$companionRemote$remote$pt extends Translations$companionRemote$remote$en {
	_Translations$companionRemote$remote$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
	@override String get tabNavigation => 'Navegação';
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
class _Translations$companionRemote$errors$pt extends Translations$companionRemote$errors$en {
	_Translations$companionRemote$errors$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
class _Translations$services$names$pt extends Translations$services$names$en {
	_Translations$services$names$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
	@override String get mdblist => 'MDBList';
}

// Path: services.deviceCode
class _Translations$services$deviceCode$pt extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Ativar o Plezy no ${service}';
	@override String get instructions => 'Leia o código QR ou acesse o endereço abaixo e insira este código:';
	@override String openToActivate({required Object service}) => 'Abrir ${service} para ativar';
	@override String get copyCode => 'Copiar código de ativação';
	@override String get waitingForAuthorization => 'Aguardando autorização…';
	@override String get codeCopied => 'Código copiado';
}

// Path: services.oauthProxy
class _Translations$services$oauthProxy$pt extends Translations$services$oauthProxy$en {
	_Translations$services$oauthProxy$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Entrar no ${service}';
	@override String get body => 'Leia este código QR ou abra a URL em qualquer dispositivo.';
	@override String openToSignIn({required Object service}) => 'Abrir ${service} para entrar';
}

// Path: services.pendingAuth
class _Translations$services$pendingAuth$pt extends Translations$services$pendingAuth$en {
	_Translations$services$pendingAuth$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get copyUrl => 'Copiar URL de acesso';
	@override String get urlCopied => 'URL copiada';
}

// Path: services.libraryFilter
class _Translations$services$libraryFilter$pt extends Translations$services$libraryFilter$en {
	_Translations$services$libraryFilter$pt._(TranslationsPt root) : this._root = root, super.internal(root);

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
}

/// The flat map containing all translations for locale <pt>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsPt {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Plezy',
			'auth.signInWithPlex' => 'Entrar com Plex',
			'auth.showQRCode' => 'Mostrar código QR',
			'auth.authenticate' => 'Autenticar',
			'auth.authenticationTimeout' => 'A autenticação expirou. Tente novamente.',
			'auth.scanQRToSignIn' => 'Leia este código QR para entrar',
			'auth.waitingForAuth' => 'Aguardando autenticação...\nEntre pelo navegador.',
			'auth.useBrowser' => 'Usar navegador',
			'auth.or' => 'ou',
			'auth.connectToMediaBrowser' => ({required Object product}) => 'Conectar ao ${product}',
			'auth.useQuickConnect' => 'Usar Quick Connect',
			'auth.quickConnectInstructions' => 'Abra o Quick Connect no Jellyfin e insira este código.',
			'auth.quickConnectWaiting' => 'Aguardando aprovação…',
			'auth.quickConnectCancel' => 'Cancelar',
			'auth.quickConnectExpired' => 'Quick Connect expirou. Tente novamente.',
			'auth.localDataRecoveryRequired' => 'O Plezy não conseguiu recuperar com segurança os dados locais de acesso e de reproduções pendentes. Entre novamente.',
			'auth.pinCheckRejected' => 'A verificação do PIN do Plex foi rejeitada',
			'common.cancel' => 'Cancelar',
			'common.save' => 'Salvar',
			'common.close' => 'Fechar',
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
			'settings.supportDeveloper' => 'Apoie o Plezy',
			'settings.supportDeveloperDescription' => 'Doe via Liberapay para financiar o desenvolvimento',
			'settings.language' => 'Idioma',
			'settings.theme' => 'Tema',
			'settings.appearance' => 'Aparência',
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
			'settings.libraryDensity' => 'Densidade da Biblioteca',
			'settings.displayScale' => 'Escala de exibição',
			'settings.compact' => 'Compacto',
			'settings.comfortable' => 'Confortável',
			'settings.tvCornerSpotlightBackdrop' => 'Imagem de destaque no canto',
			'settings.tvCornerSpotlightBackdropDescription' => 'Mostrar a imagem de destaque no canto superior direito em vez de preencher a tela',
			'settings.viewMode' => 'Modo de Visualização',
			'settings.gridView' => 'Grade',
			'settings.listView' => 'Lista',
			'settings.showHeroSection' => 'Mostrar Seção de Destaque',
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
			'settings.bufferSize' => 'Tamanho do Buffer',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}MB',
			'settings.bufferSizeAuto' => 'Automático (Recomendado)',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => '${heap}MB de memória disponível. Um buffer de ${size}MB pode afetar a reprodução.',
			'settings.playbackBuffer' => 'Buffer de reprodução',
			'settings.playbackBufferAuto' => 'Automático (recomendado)',
			'settings.playbackBufferLarge' => 'Grande',
			'settings.playbackBufferExtraLarge' => 'Extra grande',
			'settings.playbackBufferDescription' => 'Faz buffer extra contra conexões instáveis. Também limitado pelo tamanho do buffer.',
			'settings.defaultQualityTitle' => 'Qualidade padrão',
			'settings.musicQualityTitle' => 'Qualidade da música',
			'settings.subtitleStyling' => 'Estilo de Legendas',
			'settings.subtitleStylingDescription' => 'Personalizar aparência das legendas',
			'settings.smallSkipDuration' => 'Duração do Avanço Curto',
			'settings.largeSkipDuration' => 'Duração do Avanço Longo',
			'settings.rewindOnResume' => 'Rebobinar ao retomar',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} segundos',
			'settings.defaultSleepTimer' => 'Temporizador de suspensão padrão',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} minutos',
			'settings.rememberTrackSelections' => 'Lembrar seleção de faixas por série/filme',
			'settings.rememberTrackSelectionsDescription' => 'Lembrar escolhas de áudio e legendas por título',
			'settings.followServerTrackSelections' => 'Usar a seleção de faixas do servidor por episódio',
			'settings.followServerTrackSelectionsDescription' => 'Ao mudar de episódio, aplicar o áudio e as legendas selecionados no servidor em vez de manter a escolha atual',
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
			'settings.watchTogetherRelayDescription' => 'Definir um servidor de retransmissão personalizado. Todos devem usar o mesmo servidor.',
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
			'settings.importSettingsInvalidFile' => 'Este arquivo não é uma exportação válida do Plezy',
			'settings.importSettingsNoUser' => 'Entre na conta antes de importar as configurações',
			'settings.shortcutsReset' => 'Atalhos redefinidos para o padrão',
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
			'settings.autoSkip' => 'Pular automaticamente',
			'settings.autoSkipIntro' => 'Pular introdução automaticamente',
			'settings.autoSkipIntroDescription' => 'Pular marcadores de introdução automaticamente após alguns segundos',
			'settings.autoSkipCredits' => 'Pular créditos automaticamente',
			'settings.autoSkipCreditsDescription' => 'Pular os créditos automaticamente e reproduzir o próximo episódio',
			'settings.forceSkipMarkerFallback' => 'Forçar marcadores alternativos',
			'settings.forceSkipMarkerFallbackDescription' => 'Usar padrões de títulos de capítulos mesmo quando o Plex tiver marcadores',
			'settings.autoSkipDelay' => 'Atraso para pular automaticamente',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Aguardar ${seconds} segundos antes de pular automaticamente',
			'settings.introPattern' => 'Padrão do marcador de introdução',
			'settings.introPatternDescription' => 'Expressão regular que identifica marcadores de introdução nos títulos dos capítulos',
			'settings.creditsPattern' => 'Padrão do marcador de créditos',
			'settings.creditsPatternDescription' => 'Expressão regular que identifica marcadores de créditos nos títulos dos capítulos',
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
			'settings.tunneledPlaybackDescription' => 'Usar o tunelamento de vídeo. Desative se o vídeo ficar preto ao reproduzir em HDR.',
			'settings.audioPassthrough' => 'Passagem direta de áudio',
			'settings.audioPassthroughDescription' => 'Enviar o áudio Dolby/DTS ao receptor ou à TV sem recodificação, preservando o som surround. Desative se não houver som.',
			'settings.audioPassthroughDescriptionAppleTv' => 'Usar o decodificador Dolby nativo da Apple para Dolby Digital Plus, incluindo Atmos. DTS e TrueHD continuam sendo reproduzidos como PCM multicanal. Desative se não houver som.',
			'settings.audioDownmix' => 'Conversão para estéreo',
			'settings.audioDownmixDescription' => 'Converter o áudio surround em dois canais para alto-falantes estéreo ou fones de ouvido',
			'settings.downmixCenterBoost' => 'Reforço do canal central',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'Reforço (dB)',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => 'Normalizar volume na conversão para estéreo',
			'settings.audioDownmixNormalizeDescription' => 'Reduzir o volume da mixagem para evitar saturação. Desative para manter o volume original, que pode distorcer em cenas muito altas.',
			'settings.dvConversionMode' => 'Conversão Dolby Vision',
			'settings.dvConversionModeDescription' => 'Escolha como o ExoPlayer lida com arquivos Dolby Vision Profile 7.',
			'settings.dvConversionAuto' => 'Automático',
			'settings.dvConversionNative' => 'Nativo / desativado',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Usar a detecção de recursos do dispositivo e o comportamento alternativo padrão',
			'settings.dvConversionNativeDescription' => 'Forçar DV7 nativo e impedir uma nova tentativa de conversão de DV',
			'settings.dvConversionDv81Description' => 'Forçar a conversão RPU integrada para Dolby Vision perfil 8.1',
			'settings.dvConversionHevcStripDescription' => 'Remover as camadas RPU/EL do Dolby Vision e apresentar HEVC sem Dolby Vision',
			'settings.demuxer' => 'Demuxer de contêiner',
			'settings.demuxerDescription' => 'Qual demuxer processa os arquivos reproduzidos diretamente. Mude para media3 se algum arquivo apresentar problemas.',
			'settings.demuxerFfmpeg' => 'FFmpeg (recomendado)',
			'settings.demuxerMedia3' => 'media3',
			'settings.requireProfileSelectionOnOpen' => 'Pedir perfil ao abrir o app',
			'settings.requireProfileSelectionOnOpenDescription' => 'Mostrar a seleção de perfil sempre que o app for aberto',
			'settings.forceTvMode' => 'Forçar modo TV',
			'settings.forceTvModeDescription' => 'Forçar o layout de TV em dispositivos sem detecção automática. Requer reiniciar o app.',
			'settings.startInFullscreen' => 'Iniciar em tela cheia',
			'settings.startInFullscreenDescription' => 'Abrir o Plezy em modo de tela cheia ao iniciar',
			'settings.exitFullscreenOnPlayerClose' => 'Sair da tela cheia ao fechar o reprodutor',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Sair automaticamente da tela cheia ao fechar o reprodutor de vídeo',
			'settings.autoHidePerformanceOverlay' => 'Ocultar automaticamente o painel de desempenho',
			'settings.autoHidePerformanceOverlayDescription' => 'Esmaecer o painel de desempenho junto com os controles de reprodução',
			'settings.showNavBarLabels' => 'Mostrar Rótulos da Barra de Navegação',
			'settings.showNavBarLabelsDescription' => 'Exibir rótulos de texto sob os ícones da barra de navegação',
			'settings.startupSection' => 'Seção inicial',
			'settings.showExploreTab' => 'Mostrar aba Explorar',
			'settings.showExploreTabDescription' => 'Exibir a aba Explorar com conteúdo do Plex Discover e dos rastreadores conectados',
			'settings.liveTvDefaultFavorites' => 'Canais favoritos por padrão',
			'settings.liveTvDefaultFavoritesDescription' => 'Mostrar apenas os canais favoritos ao abrir a TV ao vivo',
			'settings.display' => 'Tela',
			'settings.homeScreen' => 'Tela inicial',
			'settings.navigation' => 'Navegação',
			'settings.window' => 'Janela',
			'settings.content' => 'Conteúdo',
			'settings.player' => 'Reprodutor',
			'settings.subtitlesAndConfig' => 'Legendas e configuração',
			'settings.seekAndTiming' => 'Busca e tempo',
			'settings.behavior' => 'Comportamento',
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
			'settings.exportDialogTitle' => 'Exportar configurações do Plezy',
			'search.hint' => 'Buscar filmes, séries, músicas...',
			'search.tryDifferentTerm' => 'Tente um termo de busca diferente',
			'search.searchYourMedia' => 'Buscar suas mídias',
			'search.enterTitleActorOrKeyword' => 'Insira um título, ator ou palavra-chave',
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
			'hotkeys.actions.shaderToggle' => 'Alternar Shaders',
			'hotkeys.actions.skipMarker' => 'Pular introdução/créditos',
			'hotkeys.actions.screenshot' => 'Capturar tela',
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
			_ => null,
		} ?? switch (path) {
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
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: 'Isso exclui o ${n} episódio e o arquivo dele.', other: 'Isso exclui todos os ${n} episódios e os arquivos deles.', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: 'Este item está armazenado como ${n} arquivo, que será excluído.', other: 'Este item está armazenado em ${n} arquivos, e todos eles serão excluídos.', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: 'Mais ${n} episódio está armazenado no mesmo arquivo e também será excluído:', other: 'Mais ${n} episódios estão armazenados no mesmo arquivo e também serão excluídos:', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'O Plezy não conseguiu verificar quais arquivos serão removidos, então pode excluir mais do que o item acima. Cancele e tente novamente, ou exclua mesmo assim.',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'Seu servidor não forneceu detalhes do arquivo para este item, então o Plezy não pode verificar quais arquivos serão removidos. Pode excluir mais do que o item acima.',
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
			'videoControls.longPressToUnlock' => 'Pressione e segure para destravar',
			'videoControls.timelineSlider' => 'Linha do tempo do vídeo',
			'videoControls.volumeSlider' => 'Nível de volume',
			'videoControls.endsAt' => ({required Object time}) => 'Termina às ${time}',
			'videoControls.pipActive' => 'Reproduzindo em Picture-in-Picture',
			'videoControls.pipFailed' => 'Falha ao iniciar picture-in-picture',
			'videoControls.screenshotSaved' => 'Captura de tela salva',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Zoom ${percent}%',
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
			'messages.markedAsWatched' => 'Marcado como assistido',
			'messages.markedAsUnwatched' => 'Marcado como não assistido',
			'messages.markedAsWatchedOffline' => 'Marcado como assistido (será sincronizado quando online)',
			'messages.markedAsUnwatchedOffline' => 'Marcado como não assistido (será sincronizado quando online)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Removido automaticamente: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: 'Removido automaticamente ${n} download assistido', other: 'Removidos automaticamente ${n} downloads assistidos', ), 
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
			'messages.logsUploaded' => 'Logs enviados',
			'messages.logsUploadFailed' => 'Falha ao enviar logs',
			'messages.logId' => 'ID do log',
			'messages.burnedSubtitlesUseMenu' => 'As legendas estão incorporadas a esta transmissão. Altere-as no menu de legendas.',
			'messages.noVideoUrl' => 'Nenhuma URL de vídeo disponível',
			'messages.playbackNoMediaSources' => 'O servidor não retornou nenhuma fonte de mídia reproduzível',
			'messages.playbackDataNotPrepared' => 'A reprodução foi iniciada antes que os dados estivessem prontos',
			'messages.streamSelectionUnavailable' => 'A seleção de fluxos não está disponível para esta fonte',
			'messages.streamSelectionFailed' => 'Não foi possível aplicar os fluxos selecionados',
			'messages.serverUnavailableForProfile' => 'Nenhum servidor está disponível para o perfil ativo',
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
			'subtitlingStyling.anchorToScreen' => 'Ancorar à tela',
			'subtitlingStyling.anchorToScreenDescription' => 'Exibir as legendas de texto nas faixas pretas abaixo de vídeos em tela ampla',
			'subtitlingStyling.bold' => 'Negrito',
			'subtitlingStyling.italic' => 'Itálico',
			'subtitlingStyling.renderResolution' => 'Resolução de renderização',
			'subtitlingStyling.renderResolutionScreen' => 'Resolução da tela',
			'subtitlingStyling.renderResolutionVideo' => 'Resolução do vídeo',
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
			'mpvConfig.embeddedVoHint' => 'vo, gpu-context e gpu-api são ignorados no Linux: o vídeo incorporado é sempre renderizado via vo=libmpv no plano de vídeo, e gpu-next (necessário para shaders de computação como ArtCNN) não pode ser executado incorporado.',
			'dialog.confirmAction' => 'Confirmar Ação',
			'profiles.addPlezyProfile' => 'Adicionar perfil Plezy',
			'profiles.switchingProfile' => 'Mudando perfil…',
			'profiles.deleteThisProfileTitle' => 'Excluir este perfil?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => 'Remover ${displayName}. As conexões não serão afetadas.',
			'profiles.active' => 'Ativo',
			'profiles.manage' => 'Gerenciar',
			'profiles.delete' => 'Excluir',
			'profiles.signOut' => 'Sair',
			'profiles.signOutPlexTitle' => 'Sair do Plex?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => 'Remover ${displayName} e todos os usuários do Plex Home? Você pode entrar novamente quando quiser.',
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
			'profiles.borrowEmptySubtitle' => 'Conecte Plex ou Jellyfin a outro perfil primeiro.',
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
			'connections.sectionTitle' => 'Conexões',
			'connections.addConnection' => 'Adicionar conexão',
			'connections.addConnectionSubtitleNoProfile' => 'Entre com Plex ou conecte um servidor Jellyfin',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'Adicionar a ${displayName}: Plex, Jellyfin ou outra conexão de perfil',
			'connections.sessionExpiredOne' => ({required Object name}) => 'Sessão de ${name} expirada',
			'connections.sessionExpiredMany' => ({required Object count}) => 'Sessões expiradas em ${count} servidores',
			'connections.signInAgain' => 'Entrar novamente',
			'connections.editMediaBrowserTitle' => ({required Object product}) => 'Editar conexão do ${product}',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => 'Adicione ou remova URLs para ${serverName}. O Plezy usará a URL acessível com menor latência.',
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
			'discover.extras' => 'Trailers e extras',
			'discover.studio' => 'Estúdio',
			'discover.rating' => 'Avaliação',
			'discover.director' => 'Diretor',
			'discover.directors' => 'Diretores',
			'discover.movie' => 'Filme',
			'discover.tvShow' => 'Série de TV',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} min restantes',
			'discover.moreLikeThis' => 'Títulos semelhantes',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '${n} título', other: '${n} títulos', ), 
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
			'about.title' => 'Sobre',
			'about.openSourceLicenses' => 'Licenças de código aberto',
			'about.versionLabel' => ({required Object version}) => 'Versão ${version}',
			'about.appDescription' => 'Um belo cliente de Plex e Jellyfin feito com Flutter',
			'about.viewLicensesDescription' => 'Ver as licenças de bibliotecas de terceiros',
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
			'startup.failedTitle' => 'O Plezy não conseguiu iniciar',
			'startup.failedBody' => 'Algo deu errado durante a inicialização. Os detalhes abaixo identificam o que falhou.',
			'startup.failedBodyRepairable' => 'O arquivo de configurações salvo do Plezy está danificado e precisa ser reconstruído antes que o Plezy possa iniciar. Tentar novamente não vai ajudar — escolha Reparar armazenamento.',
			'startup.phaseLabel' => 'Etapa',
			'startup.showDetails' => 'Mostrar detalhes',
			'startup.hideDetails' => 'Ocultar detalhes',
			'startup.copyDetails' => 'Copiar detalhes',
			'startup.detailsCopied' => 'Detalhes copiados para a área de transferência',
			'startup.uploadDetails' => 'Enviar detalhes',
			'startup.repairStorage' => 'Reparar armazenamento',
			'startup.repairTitle' => 'Reparar dados armazenados?',
			'startup.repairBodyCommon' => 'O arquivo de configurações do Plezy está danificado e não pode ser lido. Reparar redefine todas as configurações para o padrão.',
			'startup.repairBodyOneCredential' => 'Um login salvo está danificado e não pode ser lido. Reparar remove apenas ele; suas outras configurações permanecem intactas.',
			'startup.repairBodySignInsKept' => 'Seus servidores e perfis devem permanecer conectados.',
			'startup.repairBodySignInsLost' => 'A chave que protege seus logins salvos não pode ser recuperada deste arquivo, então você terá que entrar novamente em todos os servidores e perfis. Nada no seu servidor de mídia é afetado.',
			'startup.repairBodySessionsUncertain' => 'Os rastreadores (MAL, AniList, Simkl, Trakt) e o Seerr são armazenados separadamente e podem ou não ser preservados. O Plezy informará exatamente o que foi mantido.',
			'startup.repairConfirm' => 'Reparar',
			'startup.repairSucceeded' => 'Armazenamento reparado',
			'startup.repairNeedsRestart' => 'Armazenamento reparado — reinício necessário',
			'startup.restartRequiredBody' => 'Seus dados foram reparados, mas o Plezy precisa iniciar do zero antes de usá-los. Feche o Plezy e abra-o novamente.',
			'startup.quitPlezy' => 'Sair do Plezy',
			'startup.repairFailed' => 'Falha no reparo',
			'startup.repairKeptSignIns' => 'Seus servidores e perfis ainda estão conectados.',
			'startup.repairLostSignIns' => 'A chave que protege seus logins salvos não pôde ser recuperada. Você terá que entrar novamente em todos os servidores e perfis.',
			'startup.repairLostSessions' => 'Pelo menos uma conexão de rastreador ou do Seerr foi perdida e precisa ser reconectada.',
			'startup.backupTitle' => 'Uma cópia do arquivo danificado foi mantida',
			'startup.backupWarning' => 'Ele contém suas credenciais de login. Não envie nem compartilhe.',
			'startup.deleteBackup' => 'Excluir cópia',
			'startup.backupDeleted' => 'Cópia excluída.',
			'startup.previousFailureTitle' => 'O Plezy falhou ao iniciar da última vez',
			'licenses.relatedPackages' => 'Pacotes Relacionados',
			'licenses.license' => 'Licença',
			'licenses.licenseNumber' => ({required Object number}) => 'Licença ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} licenças',
			'navigation.libraries' => 'Bibliotecas',
			'navigation.downloads' => 'Downloads',
			'navigation.liveTv' => 'TV ao Vivo',
			'navigation.explore' => 'Explorar',
			'explore.title' => 'Explorar',
			'explore.selectSource' => 'Selecionar fonte',
			'explore.rows.watchlist' => 'Lista para assistir',
			'explore.rows.recommendedMovies' => 'Filmes recomendados',
			'explore.rows.recommendedShows' => 'Séries recomendadas',
			_ => null,
		} ?? switch (path) {
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
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '${n} episódio', other: '${n} episódios', ), 
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
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '${n} comentário', other: '${n} comentários', ), 
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
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: 'Recomendado por ${n} usuário', other: 'Recomendado por ${n} usuários', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => 'Recomendado por ${who}',
			'explore.detail.favoritedBy' => ({required Object who}) => 'Favoritado por ${who}',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '${n} ainda não exibidos',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => 'Recomendado por ${percent} dos espectadores',
			'explore.detail.relatedTitles' => 'Títulos relacionados',
			'explore.detail.background' => 'Contexto',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '${n} resultado', other: '${n} resultados', ), 
			'liveTv.title' => 'TV ao Vivo',
			'liveTv.guide' => 'Guia',
			'liveTv.noChannels' => 'Nenhum canal disponível',
			'liveTv.noDvr' => 'Nenhum DVR configurado em nenhum servidor',
			'liveTv.serverUnavailable' => 'O servidor de TV ao vivo não está disponível.',
			'liveTv.serverNotConnected' => 'O servidor de TV ao vivo não está conectado.',
			'liveTv.noPrograms' => 'Nenhum dado de programação disponível',
			'liveTv.liveStreamFailed' => 'Falha na transmissão ao vivo',
			'liveTv.unknownProgram' => 'Programa desconhecido',
			'liveTv.unknownHub' => 'Desconhecido',
			'liveTv.unknownError' => 'Erro desconhecido',
			'liveTv.channelNumber' => ({required Object number}) => 'Canal ${number}',
			'liveTv.unknownChannel' => 'Canal desconhecido',
			'liveTv.live' => 'AO VIVO',
			'liveTv.reloadGuide' => 'Recarregar Guia',
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
			'liveTv.rulesProcessRequested' => 'Reavaliação de regras solicitada',
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
			'playlists.itemCount' => ({required Object count}) => '${count} itens',
			'playlists.oneItem' => '1 item',
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
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '${n} faixa', other: '${n} faixas', ), 
			'music.nowPlaying' => 'Reproduzindo agora',
			'music.playingFrom' => ({required Object title}) => 'Reproduzindo de ${title}',
			'music.queue' => 'Fila',
			'music.clearQueue' => 'Limpar fila',
			'music.lyrics' => 'Letra',
			'music.noLyrics' => 'Nenhuma letra disponível',
			'music.sleepTimer' => 'Temporizador de suspensão',
			'music.sleepTimerEndOfTrack' => 'Fim da faixa',
			'music.sleepTimerMinutes' => ({required Object n}) => '${n} minutos',
			'music.stopPlayback' => 'Parar reprodução',
			'music.previousTrack' => 'Faixa anterior',
			'music.nextTrack' => 'Próxima faixa',
			'music.repeat' => 'Repetir',
			'music.repeatAll' => 'Repetir tudo',
			'music.repeatOne' => 'Repetir uma faixa',
			'music.instantMixNoServer' => 'Nenhum servidor está disponível para uma mistura instantânea',
			'music.noAudioUrl' => ({required Object track}) => 'Nenhuma URL de áudio está disponível para ${track}',
			'music.discography.singlesAndEps' => 'Singles e EPs',
			'music.discography.live' => 'Ao vivo',
			'music.discography.compilations' => 'Compilações',
			'watchTogether.title' => 'Assistir Juntos',
			'watchTogether.description' => 'Assista a conteúdos sincronizados com amigos e familiares',
			'watchTogether.createSession' => 'Criar sessão',
			'watchTogether.creating' => 'Criando...',
			'watchTogether.joinSession' => 'Entrar na sessão',
			'watchTogether.joining' => 'Entrando...',
			'watchTogether.controlMode' => 'Modo de controle',
			'watchTogether.controlModeQuestion' => 'Quem pode controlar a reprodução?',
			'watchTogether.hostOnly' => 'Apenas o anfitrião',
			'watchTogether.anyone' => 'Qualquer pessoa',
			'watchTogether.hostingSession' => 'Hospedando uma sessão',
			'watchTogether.inSession' => 'Em uma sessão',
			'watchTogether.sessionCode' => 'Código da sessão',
			'watchTogether.openSessionControls' => 'Abrir os controles da sessão Assistir Juntos',
			'watchTogether.copySessionCode' => 'Copiar código da sessão',
			'watchTogether.hostControlsPlayback' => 'O anfitrião controla a reprodução',
			'watchTogether.anyoneCanControl' => 'Qualquer pessoa pode controlar a reprodução',
			'watchTogether.hostControls' => 'Controle do anfitrião',
			'watchTogether.anyoneControls' => 'Controle por qualquer pessoa',
			'watchTogether.participants' => 'Participantes',
			'watchTogether.host' => 'Anfitrião',
			'watchTogether.hostBadge' => 'ANFITRIÃO',
			'watchTogether.youAreHost' => 'Você é o anfitrião',
			'watchTogether.watchingWithOthers' => 'Assistindo com outras pessoas',
			'watchTogether.endSession' => 'Encerrar sessão',
			'watchTogether.leaveSession' => 'Sair da sessão',
			'watchTogether.endSessionQuestion' => 'Encerrar sessão?',
			'watchTogether.leaveSessionQuestion' => 'Sair da sessão?',
			'watchTogether.endSessionConfirm' => 'Isso encerrará a sessão para todos os participantes.',
			'watchTogether.leaveSessionConfirm' => 'Você será removido da sessão.',
			'watchTogether.endSessionConfirmOverlay' => 'Isso encerrará a sessão do Assistir Juntos para todos os participantes.',
			'watchTogether.leaveSessionConfirmOverlay' => 'Você será desconectado da sessão do Assistir Juntos.',
			'watchTogether.end' => 'Encerrar',
			'watchTogether.leave' => 'Sair',
			'watchTogether.syncing' => 'Sincronizando...',
			'watchTogether.joinWatchSession' => 'Entrar na sessão',
			'watchTogether.enterCodeHint' => 'Insira o código de 5 caracteres',
			'watchTogether.pasteFromClipboard' => 'Colar da área de transferência',
			'watchTogether.pleaseEnterCode' => 'Insira um código de sessão',
			'watchTogether.codeMustBe5Chars' => 'O código da sessão deve ter 5 caracteres',
			'watchTogether.joinInstructions' => 'Insira o código de sessão do anfitrião para entrar.',
			'watchTogether.failedToCreate' => 'Falha ao criar sessão',
			'watchTogether.failedToJoin' => 'Falha ao entrar na sessão',
			'watchTogether.sessionCodeCopied' => 'Código da sessão copiado para a área de transferência',
			'watchTogether.relayUnreachable' => 'Servidor de retransmissão inacessível. O bloqueio pelo provedor de internet pode impedir o uso do Assistir Juntos.',
			'watchTogether.reconnectingToHost' => 'Reconectando ao anfitrião...',
			'watchTogether.currentPlayback' => 'Reprodução atual',
			'watchTogether.joinCurrentPlayback' => 'Entrar na reprodução atual',
			'watchTogether.joinCurrentPlaybackDescription' => 'Voltar ao conteúdo que o anfitrião está assistindo agora',
			'watchTogether.failedToOpenCurrentPlayback' => 'Falha ao abrir a reprodução atual',
			'watchTogether.participantJoined' => ({required Object name}) => '${name} entrou',
			'watchTogether.participantLeft' => ({required Object name}) => '${name} saiu',
			'watchTogether.participantPaused' => ({required Object name}) => '${name} pausou',
			'watchTogether.participantResumed' => ({required Object name}) => '${name} retomou',
			'watchTogether.participantSeeked' => ({required Object name}) => '${name} mudou a posição da reprodução',
			'watchTogether.participantBuffering' => ({required Object name}) => '${name} está aguardando o carregamento',
			'watchTogether.participantNeedsUpdate' => ({required Object name}) => '${name} está usando uma versão mais antiga do app — sincronização indisponível',
			'watchTogether.resumingWithout' => ({required Object name}) => 'Retomando sem ${name}',
			'watchTogether.waitingForParticipants' => 'Aguardando o carregamento dos outros participantes...',
			'watchTogether.waitingForName' => ({required Object name}) => 'Aguardando ${name}...',
			'watchTogether.recentRooms' => 'Salas recentes',
			'watchTogether.renameRoom' => 'Renomear sala',
			'watchTogether.removeRoom' => 'Remover',
			'watchTogether.guestSwitchUnavailable' => 'Não foi possível trocar — servidor indisponível para sincronização',
			'watchTogether.guestSwitchFailed' => 'Não foi possível trocar — conteúdo não encontrado neste servidor',
			'watchTogether.defaultDisplayName' => 'Usuário',
			'watchTogether.errors.timedOut' => 'O servidor de retransmissão não respondeu a tempo',
			'watchTogether.errors.connectionLost' => 'A conexão foi encerrada antes de a sessão ficar pronta',
			'watchTogether.errors.invalidRelayResponse' => 'O servidor de retransmissão enviou uma resposta inesperada',
			'watchTogether.errors.sessionEnded' => 'O anfitrião encerrou a sessão',
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
			'downloads.storageFull' => 'Os downloads foram interrompidos porque o armazenamento do dispositivo está cheio. Libere espaço e tente novamente.',
			'downloads.episodesQueued' => ({required Object count}) => '${count} episódios na fila de download',
			'downloads.downloadDeleted' => 'Download excluído',
			'downloads.deleteConfirm' => ({required Object title}) => 'Excluir "${title}" deste dispositivo?',
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
			'downloads.deleteAll' => 'Excluir todos',
			'downloads.selectVersion' => 'Selecionar versão',
			'downloads.allEpisodes' => 'Todos os episódios',
			'downloads.unwatchedOnly' => 'Apenas não assistidos',
			'downloads.nextNUnwatched' => ({required Object count}) => 'Próximos ${count} episódios não assistidos',
			'downloads.customAmount' => 'Quantidade personalizada...',
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
			'downloads.activeSyncRules' => 'Regras de sincronização',
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
			'downloads.syncRuleNotAvailableForProfile' => 'Indisponível para o perfil atual',
			'downloads.syncRuleUnknownServer' => 'Servidor desconhecido',
			'downloads.syncRuleListCreated' => 'Regra de sincronização criada',
			'downloads.backgroundWarning.bannerBlocked' => 'Os downloads serão interrompidos ao sair do app',
			'downloads.backgroundWarning.bannerDegraded' => 'Os downloads em segundo plano podem ser limitados',
			'downloads.backgroundWarning.bannerAction' => 'Detalhes',
			'downloads.backgroundWarning.sheetTitle' => 'Os downloads em segundo plano estão bloqueados',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'Os downloads em segundo plano podem ser limitados',
			'downloads.backgroundWarning.sheetIntro' => 'O Android está impedindo que o Plezy faça downloads de forma confiável em segundo plano.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'Seu dispositivo está limitando quando o Plezy pode fazer downloads em segundo plano.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'O uso em segundo plano do Plezy está restrito. Defina o uso da bateria ou o uso em segundo plano como "Sem restrições".',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'O Android colocou o Plezy em um modo de espera restrito. Defina o uso da bateria como "Sem restrições".',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'As notificações de download estão desativadas; por isso, o progresso e os controles podem ficar indisponíveis.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'As notificações estão desativadas. No Android 13 ou mais recente, elas são necessárias para downloads longos em segundo plano.',
			'downloads.backgroundWarning.reasonDataSaver' => 'A Economia de dados está ativada e bloqueia downloads em segundo plano usando dados móveis. Os downloads ainda devem funcionar no Wi-Fi.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'Os downloads foram interrompidos várias vezes enquanto o Plezy estava em segundo plano. Verifique as configurações de bateria ou uso em segundo plano do Plezy.',
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
			'downloads.unknownShow' => 'Série desconhecida',
			'downloads.unknownSeason' => 'Temporada desconhecida',
			'downloads.unknownAlbum' => 'Álbum desconhecido',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '${completed}/${total} concluídos',
			'downloads.errorFileNotFound' => 'Arquivo não encontrado (404)',
			'downloads.errorDownloadFailed' => 'Falha no download',
			'downloads.errorPostProcessing' => ({required Object error}) => 'Falha no pós-processamento: ${error}',
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
			'companionRemote.playSentToDevice' => ({required Object device}) => 'Sent to ${device}',
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
			'companionRemote.pairing.discoveryDescription' => 'Dispositivos Plezy com a mesma conta Plex aparecem aqui',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Conectando...',
			'companionRemote.pairing.searchingForDevices' => 'Procurando dispositivos...',
			'companionRemote.pairing.noDevicesFound' => 'Nenhum dispositivo encontrado na sua rede',
			'companionRemote.pairing.noDevicesHint' => 'Abra o Plezy no desktop e use a mesma rede Wi-Fi',
			'companionRemote.pairing.availableDevices' => 'Dispositivos disponíveis',
			'companionRemote.pairing.manualConnection' => 'Conexão manual',
			_ => null,
		} ?? switch (path) {
			'companionRemote.pairing.cryptoInitFailed' => 'Não foi possível iniciar a conexão segura. Entre no Plex primeiro.',
			'companionRemote.pairing.validationHostRequired' => 'Insira o endereço do host',
			'companionRemote.pairing.validationHostFormat' => 'O formato deve ser IP:porta (ex.: 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'A conexão atingiu o tempo limite. Use a mesma rede nos dois dispositivos.',
			'companionRemote.pairing.sessionNotFound' => 'Dispositivo não encontrado. Verifique se o Plezy está em execução no host.',
			'companionRemote.pairing.authFailed' => 'Falha na autenticação. Ambos os dispositivos precisam da mesma conta Plex.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Falha ao conectar: ${error}',
			'companionRemote.remote.disconnectConfirm' => 'Deseja desconectar da sessão remota?',
			'companionRemote.remote.reconnecting' => 'Reconectando...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Tentativa ${current} de 5',
			'companionRemote.remote.retryNow' => 'Tentar agora',
			'companionRemote.remote.tabRemote' => 'Remoto',
			'companionRemote.remote.tabPlay' => 'Reproduzir',
			'companionRemote.remote.tabMore' => 'Mais',
			'companionRemote.remote.menu' => 'Menu',
			'companionRemote.remote.tabNavigation' => 'Navegação',
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
			'videoSettings.performanceOverlay' => 'Painel de desempenho',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'Surround',
			'videoSettings.audioOutputSpatial' => 'Áudio espacial',
			'videoSettings.audioOutputStereo' => 'Estéreo',
			'videoSettings.audioNormalization' => 'Normalizar intensidade sonora',
			'videoSettings.audioDownmix' => 'Conversão para estéreo',
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
			'trakt.disconnectConfirmBody' => 'O Plezy deixará de enviar eventos ao Trakt. Você pode reconectar quando quiser.',
			'trakt.scrobble' => 'Scrobbling em tempo real',
			'trakt.scrobbleDescription' => 'Envia eventos de reprodução, pausa e parada ao Trakt durante a exibição.',
			'trakt.watchedSync' => 'Sincronizar status de assistido',
			'trakt.watchedSyncDescription' => 'Ao marcar itens como assistidos no Plezy, eles também serão marcados no Trakt.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Conectar ao Seerr',
			'seerr.serverUrl' => 'URL do servidor',
			'seerr.serverUrlHelper' => 'O endereço da sua instância do Seerr',
			'seerr.checkServer' => 'Continuar',
			'seerr.signInWithJellyfin' => 'Entrar com Jellyfin',
			'seerr.signInWithEmby' => 'Entrar com Emby',
			'seerr.signInWithLocal' => 'Usar uma conta local',
			'seerr.email' => 'E-mail',
			'seerr.noSignInMethods' => 'Esta instância do Seerr não oferece nenhum método de acesso compatível com o Plezy.',
			'seerr.instance' => 'Instância',
			'seerr.disconnectConfirm' => 'Desconectar Seerr?',
			'seerr.disconnectConfirmBody' => 'O Plezy esquecerá esta instância do Seerr. Reconecte quando quiser.',
			'seerr.request' => 'Solicitar',
			'seerr.request4k' => 'Solicitar em 4K',
			'seerr.seasons' => 'Temporadas',
			'seerr.allSeasons' => 'Todas as temporadas',
			'seerr.advancedOptions' => 'Avançado',
			'seerr.destinationServer' => 'Servidor de destino',
			'seerr.qualityProfile' => 'Perfil de qualidade',
			'seerr.rootFolder' => 'Pasta raiz',
			'seerr.languageProfile' => 'Perfil de idioma',
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
			'seerr.notInitialized' => 'Esta instância do Seerr não concluiu a configuração inicial',
			'seerr.noPlexTokenForReauth' => 'Nenhum token do Plex está disponível para entrar novamente',
			'seerr.noStoredCredentials' => 'Nenhuma credencial armazenada está disponível para entrar novamente',
			'seerr.signInRejected' => 'A entrada foi rejeitada',
			'seerr.noSessionCookie' => 'O Seerr não forneceu um cookie de sessão',
			'seerr.freshCookieRejected' => 'O Seerr rejeitou o novo cookie de sessão',
			'seerr.noUserInformation' => 'O Seerr não retornou informações do usuário',
			'seerr.sessionRejectedAfterReauth' => 'A sessão foi rejeitada após entrar novamente',
			'services.title' => 'Serviços',
			'services.hubSubtitle' => 'Sincronize o progresso de exibição e solicite novos títulos.',
			'services.notConnected' => 'Não conectado',
			'services.connectedAs' => ({required Object username}) => 'Conectado como @${username}',
			'services.scrobble' => 'Registrar progresso automaticamente',
			'services.scrobbleDescription' => 'Atualiza sua lista quando você termina um episódio ou filme.',
			'services.disconnectConfirm' => ({required Object service}) => 'Desconectar ${service}?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'O Plezy deixará de atualizar ${service}. Reconecte quando quiser.',
			'services.connectFailed' => ({required Object service}) => 'Não foi possível conectar ao ${service}. Tente novamente.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.deviceCode.title' => ({required Object service}) => 'Ativar o Plezy no ${service}',
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
			_ => null,
		};
	}
}
