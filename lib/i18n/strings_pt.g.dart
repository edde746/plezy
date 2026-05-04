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
	@override late final _TranslationsAppPt app = _TranslationsAppPt._(_root);
	@override late final _TranslationsAuthPt auth = _TranslationsAuthPt._(_root);
	@override late final _TranslationsCommonPt common = _TranslationsCommonPt._(_root);
	@override late final _TranslationsScreensPt screens = _TranslationsScreensPt._(_root);
	@override late final _TranslationsUpdatePt update = _TranslationsUpdatePt._(_root);
	@override late final _TranslationsSettingsPt settings = _TranslationsSettingsPt._(_root);
	@override late final _TranslationsSearchPt search = _TranslationsSearchPt._(_root);
	@override late final _TranslationsHotkeysPt hotkeys = _TranslationsHotkeysPt._(_root);
	@override late final _TranslationsFileInfoPt fileInfo = _TranslationsFileInfoPt._(_root);
	@override late final _TranslationsMediaMenuPt mediaMenu = _TranslationsMediaMenuPt._(_root);
	@override late final _TranslationsAccessibilityPt accessibility = _TranslationsAccessibilityPt._(_root);
	@override late final _TranslationsTooltipsPt tooltips = _TranslationsTooltipsPt._(_root);
	@override late final _TranslationsVideoControlsPt videoControls = _TranslationsVideoControlsPt._(_root);
	@override late final _TranslationsUserStatusPt userStatus = _TranslationsUserStatusPt._(_root);
	@override late final _TranslationsMessagesPt messages = _TranslationsMessagesPt._(_root);
	@override late final _TranslationsSubtitlingStylingPt subtitlingStyling = _TranslationsSubtitlingStylingPt._(_root);
	@override late final _TranslationsMpvConfigPt mpvConfig = _TranslationsMpvConfigPt._(_root);
	@override late final _TranslationsDialogPt dialog = _TranslationsDialogPt._(_root);
	@override late final _TranslationsProfilesPt profiles = _TranslationsProfilesPt._(_root);
	@override late final _TranslationsConnectionsPt connections = _TranslationsConnectionsPt._(_root);
	@override late final _TranslationsDiscoverPt discover = _TranslationsDiscoverPt._(_root);
	@override late final _TranslationsErrorsPt errors = _TranslationsErrorsPt._(_root);
	@override late final _TranslationsLibrariesPt libraries = _TranslationsLibrariesPt._(_root);
	@override late final _TranslationsAboutPt about = _TranslationsAboutPt._(_root);
	@override late final _TranslationsServerSelectionPt serverSelection = _TranslationsServerSelectionPt._(_root);
	@override late final _TranslationsHubDetailPt hubDetail = _TranslationsHubDetailPt._(_root);
	@override late final _TranslationsLogsPt logs = _TranslationsLogsPt._(_root);
	@override late final _TranslationsLicensesPt licenses = _TranslationsLicensesPt._(_root);
	@override late final _TranslationsNavigationPt navigation = _TranslationsNavigationPt._(_root);
	@override late final _TranslationsLiveTvPt liveTv = _TranslationsLiveTvPt._(_root);
	@override late final _TranslationsCollectionsPt collections = _TranslationsCollectionsPt._(_root);
	@override late final _TranslationsPlaylistsPt playlists = _TranslationsPlaylistsPt._(_root);
	@override late final _TranslationsWatchTogetherPt watchTogether = _TranslationsWatchTogetherPt._(_root);
	@override late final _TranslationsDownloadsPt downloads = _TranslationsDownloadsPt._(_root);
	@override late final _TranslationsShadersPt shaders = _TranslationsShadersPt._(_root);
	@override late final _TranslationsCompanionRemotePt companionRemote = _TranslationsCompanionRemotePt._(_root);
	@override late final _TranslationsVideoSettingsPt videoSettings = _TranslationsVideoSettingsPt._(_root);
	@override late final _TranslationsExternalPlayerPt externalPlayer = _TranslationsExternalPlayerPt._(_root);
	@override late final _TranslationsMetadataEditPt metadataEdit = _TranslationsMetadataEditPt._(_root);
	@override late final _TranslationsMatchScreenPt matchScreen = _TranslationsMatchScreenPt._(_root);
	@override late final _TranslationsServerTasksPt serverTasks = _TranslationsServerTasksPt._(_root);
	@override late final _TranslationsTraktPt trakt = _TranslationsTraktPt._(_root);
	@override late final _TranslationsTrackersPt trackers = _TranslationsTrackersPt._(_root);
	@override late final _TranslationsAddServerPt addServer = _TranslationsAddServerPt._(_root);
}

// Path: app
class _TranslationsAppPt extends TranslationsAppEn {
	_TranslationsAppPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
}

// Path: auth
class _TranslationsAuthPt extends TranslationsAuthEn {
	_TranslationsAuthPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get signIn => 'Entrar';
	@override String get signInWithPlex => 'Entrar com Plex';
	@override String get showQRCode => 'Mostrar QR Code';
	@override String get authenticate => 'Autenticar';
	@override String get authenticationTimeout => 'A autenticação expirou. Tente novamente.';
	@override String get scanQRToSignIn => 'Escaneie este QR code para entrar';
	@override String get waitingForAuth => 'Aguardando autenticação...\nConclua o login no seu navegador.';
	@override String get useBrowser => 'Usar navegador';
	@override String get or => 'ou';
	@override String get connectToJellyfin => 'Conectar ao Jellyfin';
	@override String get useQuickConnect => 'Usar Quick Connect';
	@override String get quickConnectCode => 'Código do Quick Connect';
	@override String get quickConnectInstructions => 'Abra o seu servidor Jellyfin num navegador, inicie sessão e escolha Quick Connect no menu do utilizador. Insira este código para aprovar o início de sessão.';
	@override String get quickConnectWaiting => 'A aguardar aprovação…';
	@override String get quickConnectCancel => 'Cancelar';
	@override String get quickConnectExpired => 'O código do Quick Connect expirou antes da aprovação. Tente novamente.';
}

// Path: common
class _TranslationsCommonPt extends TranslationsCommonEn {
	_TranslationsCommonPt._(TranslationsPt root) : this._root = root, super.internal(root);

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
	@override String get reconnect => 'Reconectar';
	@override String get exitConfirmTitle => 'Sair do app?';
	@override String get exitConfirmMessage => 'Tem certeza que deseja sair?';
	@override String get dontAskAgain => 'Não perguntar novamente';
	@override String get exit => 'Sair';
	@override String get viewAll => 'Ver Tudo';
	@override String get checkingNetwork => 'Verificando rede...';
	@override String get refreshingServers => 'Atualizando servidores...';
	@override String get loadingServers => 'Carregando servidores...';
	@override String get connectingToServers => 'Conectando aos servidores...';
	@override String get startingOfflineMode => 'Iniciando modo offline...';
	@override String get loading => 'Carregando...';
	@override String get fullscreen => 'Tela cheia';
	@override String get exitFullscreen => 'Sair da tela cheia';
}

// Path: screens
class _TranslationsScreensPt extends TranslationsScreensEn {
	_TranslationsScreensPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Licenças';
	@override String get switchProfile => 'Trocar Perfil';
	@override String get subtitleStyling => 'Estilo de Legendas';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Logs';
}

// Path: update
class _TranslationsUpdatePt extends TranslationsUpdateEn {
	_TranslationsUpdatePt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get available => 'Atualização Disponível';
	@override String versionAvailable({required Object version}) => 'Versão ${version} está disponível';
	@override String currentVersion({required Object version}) => 'Atual: ${version}';
	@override String get skipVersion => 'Pular Esta Versão';
	@override String get viewRelease => 'Ver Lançamento';
	@override String get latestVersion => 'Você está na versão mais recente';
	@override String get checkFailed => 'Falha ao verificar atualizações';
}

// Path: settings
class _TranslationsSettingsPt extends TranslationsSettingsEn {
	_TranslationsSettingsPt._(TranslationsPt root) : this._root = root, super.internal(root);

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
	@override String get episodePosterMode => 'Estilo do Poster de Episódio';
	@override String get seriesPoster => 'Poster da Série';
	@override String get seasonPoster => 'Poster da Temporada';
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
	@override String get compact => 'Compacto';
	@override String get comfortable => 'Confortável';
	@override String get viewMode => 'Modo de Visualização';
	@override String get gridView => 'Grade';
	@override String get listView => 'Lista';
	@override String get showHeroSection => 'Mostrar Seção de Destaque';
	@override String get useGlobalHubs => 'Usar layout inicial';
	@override String get useGlobalHubsDescription => 'Mostra hubs da página inicial como o cliente oficial. Quando desligado, mostra recomendações por biblioteca.';
	@override String get showServerNameOnHubs => 'Mostrar Nome do Servidor nos Hubs';
	@override String get showServerNameOnHubsDescription => 'Sempre exibir o nome do servidor nos títulos dos hubs. Quando desativado, mostra apenas para nomes duplicados.';
	@override String get groupLibrariesByServer => 'Agrupar Bibliotecas por Servidor';
	@override String get groupLibrariesByServerDescription => 'Mostra um cabeçalho para cada servidor de mídia na barra lateral quando conectado a vários servidores.';
	@override String get alwaysKeepSidebarOpen => 'Manter Barra Lateral Sempre Aberta';
	@override String get alwaysKeepSidebarOpenDescription => 'A barra lateral fica expandida e a área de conteúdo se ajusta';
	@override String get showUnwatchedCount => 'Mostrar Contagem de Não Assistidos';
	@override String get showUnwatchedCountDescription => 'Exibir contagem de episódios não assistidos em séries e temporadas';
	@override String get showEpisodeNumberOnCards => 'Mostrar Número do Episódio nos Cards';
	@override String get showEpisodeNumberOnCardsDescription => 'Mostrar o número do episódio ao lado da temporada (ex. S2 E3) nos cards de episódios';
	@override String get showSeasonPostersOnTabs => 'Mostrar Pôsteres de Temporada nas Abas';
	@override String get showSeasonPostersOnTabsDescription => 'Exibe o pôster da temporada acima de cada aba de temporada na página de detalhes de uma série';
	@override String get hideSpoilers => 'Ocultar Spoilers de Episódios Não Assistidos';
	@override String get hideSpoilersDescription => 'Desfocar miniaturas e ocultar descrições de episódios que você ainda não assistiu';
	@override String get playerBackend => 'Backend do Player';
	@override String get exoPlayer => 'ExoPlayer (Recomendado)';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'Decodificação por Hardware';
	@override String get hardwareDecodingDescription => 'Usar aceleração por hardware quando disponível';
	@override String get bufferSize => 'Tamanho do Buffer';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get bufferSizeAuto => 'Automático (Recomendado)';
	@override String bufferSizeWarning({required Object heap, required Object size}) => 'Seu dispositivo tem ${heap}MB de memória. Um buffer de ${size}MB pode causar problemas de reprodução.';
	@override String get defaultQualityTitle => 'Qualidade padrão';
	@override String get defaultQualityDescription => 'Usado ao iniciar a reprodução. Valores menores reduzem a largura de banda.';
	@override String get subtitleStyling => 'Estilo de Legendas';
	@override String get subtitleStylingDescription => 'Personalizar aparência das legendas';
	@override String get smallSkipDuration => 'Duração do Avanço Curto';
	@override String get largeSkipDuration => 'Duração do Avanço Longo';
	@override String get rewindOnResume => 'Rebobinar ao retomar';
	@override String secondsUnit({required Object seconds}) => '${seconds} segundos';
	@override String get defaultSleepTimer => 'Timer de Sono Padrão';
	@override String minutesUnit({required Object minutes}) => '${minutes} minutos';
	@override String get rememberTrackSelections => 'Lembrar seleção de faixas por série/filme';
	@override String get rememberTrackSelectionsDescription => 'Salvar automaticamente preferências de idioma de áudio e legenda ao trocar faixas durante a reprodução';
	@override String get clickVideoTogglesPlayback => 'Clicar no vídeo para alternar reprodução/pausa';
	@override String get clickVideoTogglesPlaybackDescription => 'Se ativado, clicar no player reproduz/pausa o vídeo. Caso contrário, clicar mostra/oculta os controles.';
	@override String get videoPlayerControls => 'Controles do Player de Vídeo';
	@override String get keyboardShortcuts => 'Atalhos de Teclado';
	@override String get keyboardShortcutsDescription => 'Personalizar atalhos de teclado';
	@override String get videoPlayerNavigation => 'Navegação do Player de Vídeo';
	@override String get videoPlayerNavigationDescription => 'Usar teclas de seta para navegar nos controles do player';
	@override String get watchTogetherRelay => 'Relay do Assistir Juntos';
	@override String get watchTogetherRelayDescription => 'Definir um servidor relay personalizado para Assistir Juntos. Todos os participantes devem usar o mesmo servidor.';
	@override String get watchTogetherRelayHint => 'https://meu-relay.exemplo.com.br';
	@override String get crashReporting => 'Relatório de Erros';
	@override String get crashReportingDescription => 'Enviar relatórios de erros para ajudar a melhorar o app';
	@override String get debugLogging => 'Log de Depuração';
	@override String get debugLoggingDescription => 'Ativar log detalhado para solução de problemas';
	@override String get viewLogs => 'Ver Logs';
	@override String get viewLogsDescription => 'Ver logs do aplicativo';
	@override String get clearCache => 'Limpar Cache';
	@override String get clearCacheDescription => 'Isso limpará todas as imagens e dados em cache. O app pode demorar mais para carregar conteúdo após limpar o cache.';
	@override String get clearCacheSuccess => 'Cache limpo com sucesso';
	@override String get resetSettings => 'Redefinir Configurações';
	@override String get resetSettingsDescription => 'Isso redefinirá todas as configurações para os valores padrão. Esta ação não pode ser desfeita.';
	@override String get resetSettingsSuccess => 'Configurações redefinidas com sucesso';
	@override String get backup => 'Backup';
	@override String get exportSettings => 'Exportar Configurações';
	@override String get exportSettingsDescription => 'Salve suas preferências em um arquivo';
	@override String get exportSettingsSuccess => 'Configurações exportadas';
	@override String get exportSettingsFailed => 'Não foi possível exportar as configurações';
	@override String get importSettings => 'Importar Configurações';
	@override String get importSettingsDescription => 'Restaurar preferências a partir de um arquivo';
	@override String get importSettingsConfirm => 'Isso substituirá suas configurações atuais. Continuar?';
	@override String get importSettingsSuccess => 'Configurações importadas';
	@override String get importSettingsFailed => 'Não foi possível importar as configurações';
	@override String get importSettingsInvalidFile => 'Este arquivo não é uma exportação válida do Plezy';
	@override String get importSettingsNoUser => 'Entre na conta antes de importar as configurações';
	@override String get shortcutsReset => 'Atalhos redefinidos para o padrão';
	@override String get about => 'Sobre';
	@override String get aboutDescription => 'Informações do app e licenças';
	@override String get updates => 'Atualizações';
	@override String get updateAvailable => 'Atualização Disponível';
	@override String get checkForUpdates => 'Verificar Atualizações';
	@override String get autoCheckUpdatesOnStartup => 'Verificar atualizações automaticamente ao iniciar';
	@override String get autoCheckUpdatesOnStartupDescription => 'Mostrar uma notificação quando uma nova versão estiver disponível ao iniciar';
	@override String get validationErrorEnterNumber => 'Insira um número válido';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'A duração deve ser entre ${min} e ${max} ${unit}';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Atalho já atribuído a ${action}';
	@override String shortcutUpdated({required Object action}) => 'Atalho atualizado para ${action}';
	@override String get autoSkip => 'Pular Automaticamente';
	@override String get autoSkipIntro => 'Pular Intro Automaticamente';
	@override String get autoSkipIntroDescription => 'Pular marcadores de intro automaticamente após alguns segundos';
	@override String get autoSkipCredits => 'Pular Créditos Automaticamente';
	@override String get autoSkipCreditsDescription => 'Pular créditos automaticamente e reproduzir próximo episódio';
	@override String get forceSkipMarkerFallback => 'Forçar marcadores alternativos';
	@override String get forceSkipMarkerFallbackDescription => 'Usar padrões de títulos de capítulos para marcadores de pulo mesmo quando o Plex fornece marcadores nativos';
	@override String get autoSkipDelay => 'Atraso do Pulo Automático';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Aguardar ${seconds} segundos antes de pular automaticamente';
	@override String get introPattern => 'Padrão de marcador de intro';
	@override String get introPatternDescription => 'Expressão regular para corresponder marcadores de intro nos títulos dos capítulos';
	@override String get creditsPattern => 'Padrão de marcador de créditos';
	@override String get creditsPatternDescription => 'Expressão regular para corresponder marcadores de créditos nos títulos dos capítulos';
	@override String get invalidRegex => 'Expressão regular inválida';
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
	@override String get downloadLocationSelectError => 'Falha ao selecionar pasta';
	@override String get downloadOnWifiOnly => 'Baixar apenas no WiFi';
	@override String get downloadOnWifiOnlyDescription => 'Impedir downloads quando em dados móveis';
	@override String get autoRemoveWatchedDownloads => 'Remover downloads assistidos automaticamente';
	@override String get autoRemoveWatchedDownloadsDescription => 'Excluir automaticamente episódios e filmes baixados quando marcados como assistidos';
	@override String get cellularDownloadBlocked => 'Downloads estão desativados em dados móveis. Conecte ao WiFi ou altere a configuração.';
	@override String get maxVolume => 'Volume Máximo';
	@override String get maxVolumeDescription => 'Permitir aumento de volume acima de 100% para mídias silenciosas';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Mostrar o que você está assistindo no Discord';
	@override String get trakt => 'Trakt';
	@override String get traktDescription => 'Sincronizar histórico de exibição com Trakt';
	@override String get trackers => 'Rastreadores';
	@override String get trackersDescription => 'Sincronizar progresso com Trakt, MyAnimeList, AniList e Simkl';
	@override String get companionRemoteServer => 'Servidor de controlo remoto';
	@override String get companionRemoteServerDescription => 'Permitir que dispositivos móveis na sua rede controlem esta aplicação';
	@override String get autoPip => 'Picture-in-Picture Automático';
	@override String get autoPipDescription => 'Entrar automaticamente em picture-in-picture ao sair do app durante a reprodução';
	@override String get matchContentFrameRate => 'Corresponder Taxa de Quadros do Conteúdo';
	@override String get matchContentFrameRateDescription => 'Ajustar a taxa de atualização da tela para corresponder ao conteúdo de vídeo, reduzindo tremulação e economizando bateria';
	@override String get matchRefreshRate => 'Corresponder Taxa de Atualização';
	@override String get matchRefreshRateDescription => 'Alterar a taxa de atualização da tela para corresponder ao conteúdo de vídeo em tela cheia';
	@override String get matchDynamicRange => 'Corresponder Faixa Dinâmica';
	@override String get matchDynamicRangeDescription => 'Ativar automaticamente o HDR para conteúdo HDR e voltar ao SDR ao sair do reprodutor';
	@override String get displaySwitchDelay => 'Atraso na Troca de Tela';
	@override String get tunneledPlayback => 'Reprodução Tunelizada';
	@override String get tunneledPlaybackDescription => 'Usar tunelamento de vídeo acelerado por hardware. Desative se você vir uma tela preta com áudio em conteúdo HDR';
	@override String get requireProfileSelectionOnOpen => 'Pedir perfil ao abrir o app';
	@override String get requireProfileSelectionOnOpenDescription => 'Mostrar seleção de perfil toda vez que o app for aberto';
	@override String get confirmExitOnBack => 'Confirmar antes de sair';
	@override String get confirmExitOnBackDescription => 'Mostrar diálogo de confirmação ao pressionar voltar para sair do app';
	@override String get forceTvMode => 'Forçar modo TV';
	@override String get forceTvModeDescription => 'Usar o layout de TV independentemente da detecção automática. Útil em dispositivos Android TV que não reportam o recurso leanback. Reinicia o app ao alterar.';
	@override String get startInFullscreen => 'Iniciar em tela cheia';
	@override String get startInFullscreenDescription => 'Abrir o Plezy em modo de tela cheia ao iniciar';
	@override String get autoHidePerformanceOverlay => 'Ocultar overlay de desempenho automaticamente';
	@override String get autoHidePerformanceOverlayDescription => 'Desvanecer o overlay de desempenho com os controles de reprodução';
	@override String get showNavBarLabels => 'Mostrar Rótulos da Barra de Navegação';
	@override String get showNavBarLabelsDescription => 'Exibir rótulos de texto sob os ícones da barra de navegação';
	@override String get liveTvDefaultFavorites => 'Canais favoritos por padrão';
	@override String get liveTvDefaultFavoritesDescription => 'Mostrar apenas canais favoritos ao abrir TV ao vivo';
	@override String get display => 'Tela';
	@override String get homeScreen => 'Tela inicial';
	@override String get navigation => 'Navegação';
	@override String get window => 'Janela';
	@override String get content => 'Conteúdo';
	@override String get player => 'Reprodutor';
	@override String get subtitlesAndConfig => 'Legendas e configuração';
	@override String get seekAndTiming => 'Busca e tempo';
	@override String get behavior => 'Comportamento';
}

// Path: search
class _TranslationsSearchPt extends TranslationsSearchEn {
	_TranslationsSearchPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Buscar filmes, séries, músicas...';
	@override String get tryDifferentTerm => 'Tente um termo de busca diferente';
	@override String get searchYourMedia => 'Buscar suas mídias';
	@override String get enterTitleActorOrKeyword => 'Insira um título, ator ou palavra-chave';
}

// Path: hotkeys
class _TranslationsHotkeysPt extends TranslationsHotkeysEn {
	_TranslationsHotkeysPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Definir Atalho para ${actionName}';
	@override String get clearShortcut => 'Limpar atalho';
	@override late final _TranslationsHotkeysActionsPt actions = _TranslationsHotkeysActionsPt._(_root);
}

// Path: fileInfo
class _TranslationsFileInfoPt extends TranslationsFileInfoEn {
	_TranslationsFileInfoPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Info do Arquivo';
	@override String get video => 'Vídeo';
	@override String get audio => 'Áudio';
	@override String get file => 'Arquivo';
	@override String get advanced => 'Avançado';
	@override String get codec => 'Codec';
	@override String get resolution => 'Resolução';
	@override String get bitrate => 'Taxa de Bits';
	@override String get frameRate => 'Taxa de Quadros';
	@override String get aspectRatio => 'Proporção';
	@override String get profile => 'Perfil';
	@override String get bitDepth => 'Profundidade de Bits';
	@override String get colorSpace => 'Espaço de Cor';
	@override String get colorRange => 'Faixa de Cor';
	@override String get colorPrimaries => 'Primárias de Cor';
	@override String get chromaSubsampling => 'Subamostragem de Croma';
	@override String get channels => 'Canais';
	@override String get subtitles => 'Legendas';
	@override String get overallBitrate => 'Taxa de bits total';
	@override String get path => 'Caminho';
	@override String get size => 'Tamanho';
	@override String get container => 'Container';
	@override String get duration => 'Duração';
	@override String get optimizedForStreaming => 'Otimizado para Streaming';
	@override String get has64bitOffsets => 'Offsets de 64 bits';
}

// Path: mediaMenu
class _TranslationsMediaMenuPt extends TranslationsMediaMenuEn {
	_TranslationsMediaMenuPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Marcar como Assistido';
	@override String get markAsUnwatched => 'Marcar como Não Assistido';
	@override String get removeFromContinueWatching => 'Remover de Continuar Assistindo';
	@override String get goToSeries => 'Ir para a série';
	@override String get goToSeason => 'Ir para a temporada';
	@override String get shufflePlay => 'Reprodução Aleatória';
	@override String get fileInfo => 'Info do Arquivo';
	@override String get deleteFromServer => 'Excluir do servidor';
	@override String get confirmDelete => 'Isso excluirá permanentemente esta mídia e seus arquivos do seu servidor. Esta ação não pode ser desfeita.';
	@override String get deleteMultipleWarning => 'Isso inclui todos os episódios e seus arquivos.';
	@override String get mediaDeletedSuccessfully => 'Item de mídia excluído com sucesso';
	@override String get mediaFailedToDelete => 'Falha ao excluir item de mídia';
	@override String get rate => 'Avaliar';
	@override String get playFromBeginning => 'Reproduzir do início';
	@override String get playVersion => 'Reproduzir versão...';
}

// Path: accessibility
class _TranslationsAccessibilityPt extends TranslationsAccessibilityEn {
	_TranslationsAccessibilityPt._(TranslationsPt root) : this._root = root, super.internal(root);

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
}

// Path: tooltips
class _TranslationsTooltipsPt extends TranslationsTooltipsEn {
	_TranslationsTooltipsPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Reprodução aleatória';
	@override String get playTrailer => 'Reproduzir trailer';
	@override String get markAsWatched => 'Marcar como assistido';
	@override String get markAsUnwatched => 'Marcar como não assistido';
}

// Path: videoControls
class _TranslationsVideoControlsPt extends TranslationsVideoControlsEn {
	_TranslationsVideoControlsPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Áudio';
	@override String get subtitlesLabel => 'Legendas';
	@override String get resetToZero => 'Redefinir para 0ms';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String minusTime({required Object amount, required Object unit}) => '-${amount}${unit}';
	@override String playsLater({required Object label}) => '${label} reproduz depois';
	@override String playsEarlier({required Object label}) => '${label} reproduz antes';
	@override String get noOffset => 'Sem deslocamento';
	@override String get letterbox => 'Letterbox';
	@override String get fillScreen => 'Preencher tela';
	@override String get stretch => 'Esticar';
	@override String get lockRotation => 'Travar rotação';
	@override String get unlockRotation => 'Destravar rotação';
	@override String get timerActive => 'Timer Ativo';
	@override String playbackWillPauseIn({required Object duration}) => 'A reprodução pausará em ${duration}';
	@override String get stillWatching => 'Ainda assistindo?';
	@override String pausingIn({required Object seconds}) => 'Pausando em ${seconds}s';
	@override String get continueWatching => 'Continuar';
	@override String get autoPlayNext => 'Reproduzir Próximo Automaticamente';
	@override String get playNext => 'Reproduzir Próximo';
	@override String get playButton => 'Reproduzir';
	@override String get pauseButton => 'Pausar';
	@override String seekBackwardButton({required Object seconds}) => 'Retroceder ${seconds} segundos';
	@override String seekForwardButton({required Object seconds}) => 'Avançar ${seconds} segundos';
	@override String get previousButton => 'Episódio anterior';
	@override String get nextButton => 'Próximo episódio';
	@override String get previousChapterButton => 'Capítulo anterior';
	@override String get nextChapterButton => 'Próximo capítulo';
	@override String get muteButton => 'Silenciar';
	@override String get unmuteButton => 'Ativar som';
	@override String get settingsButton => 'Configurações de vídeo';
	@override String get tracksButton => 'Áudio e Legendas';
	@override String get chaptersButton => 'Capítulos';
	@override String get versionsButton => 'Versões do vídeo';
	@override String get versionQualityButton => 'Versão e qualidade';
	@override String get versionColumnHeader => 'Versão';
	@override String get qualityColumnHeader => 'Qualidade';
	@override String get qualityOriginal => 'Original';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String qualityBandwidthEstimate({required Object bitrate}) => '~${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => 'Transcodificação indisponível — reproduzindo qualidade original';
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
	@override late final _TranslationsVideoControlsPipErrorsPt pipErrors = _TranslationsVideoControlsPipErrorsPt._(_root);
	@override String get chapters => 'Capítulos';
	@override String get noChaptersAvailable => 'Nenhum capítulo disponível';
	@override String get queue => 'Fila';
	@override String get noQueueItems => 'Nenhum item na fila';
	@override String get searchSubtitles => 'Pesquisar legendas';
	@override String get language => 'Idioma';
	@override String get noSubtitlesFound => 'Nenhuma legenda encontrada';
	@override String get subtitleDownloaded => 'Legenda baixada';
	@override String get subtitleDownloadFailed => 'Falha ao baixar legenda';
	@override String get searchLanguages => 'Pesquisar idiomas...';
}

// Path: userStatus
class _TranslationsUserStatusPt extends TranslationsUserStatusEn {
	_TranslationsUserStatusPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get admin => 'Admin';
	@override String get restricted => 'Restrito';
	@override String get protected => 'Protegido';
	@override String get current => 'ATUAL';
}

// Path: messages
class _TranslationsMessagesPt extends TranslationsMessagesEn {
	_TranslationsMessagesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Marcado como assistido';
	@override String get markedAsUnwatched => 'Marcado como não assistido';
	@override String get markedAsWatchedOffline => 'Marcado como assistido (será sincronizado quando online)';
	@override String get markedAsUnwatchedOffline => 'Marcado como não assistido (será sincronizado quando online)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'Removido automaticamente: ${title}';
	@override String get removedFromContinueWatching => 'Removido de Continuar Assistindo';
	@override String errorLoading({required Object error}) => 'Erro: ${error}';
	@override String get fileInfoNotAvailable => 'Informações do arquivo não disponíveis';
	@override String errorLoadingFileInfo({required Object error}) => 'Erro ao carregar info do arquivo: ${error}';
	@override String get errorLoadingSeries => 'Erro ao carregar série';
	@override String get errorLoadingSeason => 'Erro ao carregar temporada';
	@override String get musicNotSupported => 'Reprodução de música ainda não é suportada';
	@override String get noDescriptionAvailable => 'Nenhuma descrição disponível';
	@override String get noProfilesAvailable => 'Nenhum perfil disponível';
	@override String get contactAdminForProfiles => 'Contate o administrador do servidor para adicionar perfis';
	@override String get unableToDetermineLibrarySection => 'Não é possível determinar a secção da biblioteca para este item';
	@override String get logsCleared => 'Logs limpos';
	@override String get logsCopied => 'Logs copiados para a área de transferência';
	@override String get noLogsAvailable => 'Nenhum log disponível';
	@override String libraryScanning({required Object title}) => 'Escaneando "${title}"...';
	@override String libraryScanStarted({required Object title}) => 'Escaneamento da biblioteca iniciado para "${title}"';
	@override String libraryScanFailed({required Object error}) => 'Falha ao escanear biblioteca: ${error}';
	@override String metadataRefreshing({required Object title}) => 'Atualizando metadados de "${title}"...';
	@override String metadataRefreshStarted({required Object title}) => 'Atualização de metadados iniciada para "${title}"';
	@override String metadataRefreshFailed({required Object error}) => 'Falha ao atualizar metadados: ${error}';
	@override String get logoutConfirm => 'Tem certeza que deseja sair?';
	@override String get noSeasonsFound => 'Nenhuma temporada encontrada';
	@override String get noEpisodesFound => 'Nenhum episódio encontrado na primeira temporada';
	@override String get noEpisodesFoundGeneral => 'Nenhum episódio encontrado';
	@override String get noResultsFound => 'Nenhum resultado encontrado';
	@override String sleepTimerSet({required Object label}) => 'Timer de sono definido para ${label}';
	@override String get noItemsAvailable => 'Nenhum item disponível';
	@override String get failedToCreatePlayQueueNoItems => 'Falha ao criar fila de reprodução - sem itens';
	@override String failedPlayback({required Object action, required Object error}) => 'Falha ao ${action}: ${error}';
	@override String get switchingToCompatiblePlayer => 'Alternando para player compatível...';
	@override String get serverLimitTitle => 'Falha na reprodução';
	@override String get serverLimitBody => 'O servidor retornou um erro (HTTP 500). Isso geralmente significa que o proprietário do servidor definiu um limite de largura de banda ou transcodificação que está rejeitando sua sessão. Não há nada a ser feito pelo cliente — o proprietário do servidor precisa ajustar as configurações.';
	@override String get logsUploaded => 'Logs enviados';
	@override String get logsUploadFailed => 'Falha ao enviar logs';
	@override String get logId => 'ID do Log';
}

// Path: subtitlingStyling
class _TranslationsSubtitlingStylingPt extends TranslationsSubtitlingStylingEn {
	_TranslationsSubtitlingStylingPt._(TranslationsPt root) : this._root = root, super.internal(root);

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
	@override String get bold => 'Negrito';
	@override String get italic => 'Itálico';
}

// Path: mpvConfig
class _TranslationsMpvConfigPt extends TranslationsMpvConfigEn {
	_TranslationsMpvConfigPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => 'Configurações avançadas do player de vídeo';
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
	@override String get confirmDeletePreset => 'Tem certeza que deseja excluir esta predefinição?';
	@override String get configPlaceholder => 'gpu-api=vulkan\nhwdec=auto\n# comment';
}

// Path: dialog
class _TranslationsDialogPt extends TranslationsDialogEn {
	_TranslationsDialogPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Confirmar Ação';
}

// Path: profiles
class _TranslationsProfilesPt extends TranslationsProfilesEn {
	_TranslationsProfilesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'Adicionar perfil Plezy';
	@override String get switchingProfile => 'Mudando perfil…';
	@override String get deleteThisProfileTitle => 'Excluir este perfil?';
	@override String deleteThisProfileMessage({required Object displayName}) => '${displayName} será removido. As conexões não serão afetadas.';
	@override String get active => 'Ativo';
	@override String get manage => 'Gerenciar';
	@override String get delete => 'Excluir';
	@override String get signOut => 'Sair';
	@override String get signOutPlexTitle => 'Sair do Plex?';
	@override String signOutPlexMessage({required Object displayName}) => '${displayName} e todos os usuários do Plex Home desta conta serão removidos deste dispositivo. Você pode entrar novamente a qualquer momento.';
	@override String get signedOutPlex => 'Saiu do Plex.';
	@override String get signOutFailed => 'Falha ao sair.';
	@override String get sectionTitle => 'Perfis';
	@override String get summarySingle => 'Adicione perfis para mesclar usuários gerenciados e identidades locais';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} perfis · ativo: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} perfis';
	@override String get removeConnectionTitle => 'Remover conexão?';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => '${displayName} perderá o acesso a ${connectionLabel}. A conexão em si continua disponível para outros perfis.';
	@override String get deleteProfileTitle => 'Excluir perfil?';
	@override String deleteProfileMessage({required Object displayName}) => 'Isso remove ${displayName} e todas as suas conexões deste dispositivo. Os servidores Plex/Jellyfin subjacentes não são afetados.';
	@override String get profileNameLabel => 'Nome do perfil';
	@override String get pinProtectionLabel => 'Proteção por PIN';
	@override String get pinManagedByPlex => 'PIN gerenciado pelo Plex. Edite em plex.tv.';
	@override String get noPinSetEditOnPlex => 'Nenhum PIN definido. Para exigir um, edite o usuário Home em plex.tv.';
	@override String get setPin => 'Definir PIN';
	@override String get connectionsLabel => 'Conexões';
	@override String get add => 'Adicionar';
	@override String get deleteProfileButton => 'Excluir perfil';
	@override String get noConnectionsHint => 'Sem conexões — adicione uma para usar este perfil.';
	@override String get plexHomeAccount => 'Conta Plex Home';
	@override String get connectionDefault => 'Padrão';
	@override String get makeDefault => 'Definir como padrão';
	@override String get removeConnection => 'Remover';
	@override String borrowAddTo({required Object displayName}) => 'Adicionar a ${displayName}';
	@override String get borrowExplain => 'Tome emprestada uma conexão de outro perfil. Perfis de origem protegidos por PIN pedem o PIN antes de compartilhar.';
	@override String get borrowEmpty => 'Nada para emprestar ainda.';
	@override String get borrowEmptySubtitle => 'Conecte primeiro uma conta Plex ou servidor Jellyfin a outro perfil e volte aqui.';
	@override String get newProfile => 'Novo perfil';
	@override String get profileNameHint => 'ex.: Visitantes, Crianças, Sala de família';
	@override String get pinProtectionOptional => 'Proteção por PIN (opcional)';
	@override String get pinExplain => 'PIN de 4 dígitos necessário para alternar para este perfil. Barreira suave — quem puder limpar os dados do app pode contorná-la.';
	@override String get continueButton => 'Continuar';
	@override String get pinsDontMatch => 'Os PINs não correspondem';
}

// Path: connections
class _TranslationsConnectionsPt extends TranslationsConnectionsEn {
	_TranslationsConnectionsPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Conexões';
	@override String get addConnection => 'Adicionar conexão';
	@override String get addConnectionSubtitleNoProfile => 'Faça login com Plex ou conecte um servidor Jellyfin';
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'Adicionar a ${displayName} — conta Plex, servidor Jellyfin ou emprestar de outro perfil';
	@override String sessionExpiredOne({required Object name}) => 'Sessão expirada para ${name}';
	@override String sessionExpiredMany({required Object count}) => 'Sessão expirada para ${count} servidores';
	@override String get signInAgain => 'Entrar novamente';
}

// Path: discover
class _TranslationsDiscoverPt extends TranslationsDiscoverEn {
	_TranslationsDiscoverPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Descobrir';
	@override String get switchProfile => 'Trocar Perfil';
	@override String get noContentAvailable => 'Nenhum conteúdo disponível';
	@override String get addMediaToLibraries => 'Adicione mídias às suas bibliotecas';
	@override String get continueWatching => 'Continuar Assistindo';
	@override String continueWatchingIn({required Object library}) => 'Continuar assistindo em ${library}';
	@override String get nextUp => 'A seguir';
	@override String nextUpIn({required Object library}) => 'A seguir em ${library}';
	@override String get recentlyAdded => 'Adicionados recentemente';
	@override String recentlyAddedIn({required Object library}) => 'Adicionados recentemente em ${library}';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get overview => 'Sinopse';
	@override String get cast => 'Elenco';
	@override String get extras => 'Trailers e Extras';
	@override String get studio => 'Estúdio';
	@override String get rating => 'Avaliação';
	@override String get movie => 'Filme';
	@override String get tvShow => 'Série de TV';
	@override String minutesLeft({required Object minutes}) => '${minutes} min restantes';
}

// Path: errors
class _TranslationsErrorsPt extends TranslationsErrorsEn {
	_TranslationsErrorsPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Falha na busca: ${error}';
	@override String connectionTimeout({required Object context}) => 'Tempo de conexão esgotado ao carregar ${context}';
	@override String get connectionFailed => 'Não foi possível conectar ao servidor de mídia';
	@override String failedToLoad({required Object context, required Object error}) => 'Falha ao carregar ${context}: ${error}';
	@override String get noClientAvailable => 'Nenhum cliente disponível';
	@override String authenticationFailed({required Object error}) => 'Falha na autenticação: ${error}';
	@override String get couldNotLaunchUrl => 'Não foi possível abrir a URL de autenticação';
	@override String get pleaseEnterToken => 'Insira um token';
	@override String get invalidToken => 'Token inválido';
	@override String failedToVerifyToken({required Object error}) => 'Falha ao verificar token: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Falha ao trocar para ${displayName}';
	@override String failedToDeleteProfile({required Object displayName}) => 'Falha ao excluir ${displayName}';
	@override String get failedToRate => 'Não foi possível atualizar a classificação';
}

// Path: libraries
class _TranslationsLibrariesPt extends TranslationsLibrariesEn {
	_TranslationsLibrariesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bibliotecas';
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
	@override String get all => 'Todos';
	@override String get clearAll => 'Limpar Tudo';
	@override String scanLibraryConfirm({required Object title}) => 'Tem certeza que deseja escanear "${title}"?';
	@override String analyzeLibraryConfirm({required Object title}) => 'Tem certeza que deseja analisar "${title}"?';
	@override String refreshMetadataConfirm({required Object title}) => 'Tem certeza que deseja atualizar os metadados de "${title}"?';
	@override String emptyTrashConfirm({required Object title}) => 'Tem certeza que deseja esvaziar a lixeira de "${title}"?';
	@override String get manageLibraries => 'Gerenciar Bibliotecas';
	@override String get sort => 'Ordenar';
	@override String get sortBy => 'Ordenar Por';
	@override String get filters => 'Filtros';
	@override String get confirmActionMessage => 'Tem certeza que deseja realizar esta ação?';
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
	@override late final _TranslationsLibrariesTabsPt tabs = _TranslationsLibrariesTabsPt._(_root);
	@override late final _TranslationsLibrariesGroupingsPt groupings = _TranslationsLibrariesGroupingsPt._(_root);
	@override late final _TranslationsLibrariesFilterCategoriesPt filterCategories = _TranslationsLibrariesFilterCategoriesPt._(_root);
	@override late final _TranslationsLibrariesSortLabelsPt sortLabels = _TranslationsLibrariesSortLabelsPt._(_root);
}

// Path: about
class _TranslationsAboutPt extends TranslationsAboutEn {
	_TranslationsAboutPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Sobre';
	@override String get openSourceLicenses => 'Licenças Open Source';
	@override String versionLabel({required Object version}) => 'Versão ${version}';
	@override String get appDescription => 'Um belo cliente Plex e Jellyfin para Flutter';
	@override String get viewLicensesDescription => 'Ver licenças de bibliotecas de terceiros';
}

// Path: serverSelection
class _TranslationsServerSelectionPt extends TranslationsServerSelectionEn {
	_TranslationsServerSelectionPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get allServerConnectionsFailed => 'Falha ao conectar a qualquer servidor. Verifique sua rede e tente novamente.';
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Nenhum servidor encontrado para ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Falha ao carregar servidores: ${error}';
}

// Path: hubDetail
class _TranslationsHubDetailPt extends TranslationsHubDetailEn {
	_TranslationsHubDetailPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Título';
	@override String get releaseYear => 'Ano de Lançamento';
	@override String get dateAdded => 'Data de Adição';
	@override String get rating => 'Avaliação';
	@override String get noItemsFound => 'Nenhum item encontrado';
}

// Path: logs
class _TranslationsLogsPt extends TranslationsLogsEn {
	_TranslationsLogsPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Limpar Logs';
	@override String get copyLogs => 'Copiar Logs';
	@override String get uploadLogs => 'Enviar Logs';
}

// Path: licenses
class _TranslationsLicensesPt extends TranslationsLicensesEn {
	_TranslationsLicensesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Pacotes Relacionados';
	@override String get license => 'Licença';
	@override String licenseNumber({required Object number}) => 'Licença ${number}';
	@override String licensesCount({required Object count}) => '${count} licenças';
}

// Path: navigation
class _TranslationsNavigationPt extends TranslationsNavigationEn {
	_TranslationsNavigationPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Bibliotecas';
	@override String get downloads => 'Downloads';
	@override String get liveTv => 'TV ao Vivo';
}

// Path: liveTv
class _TranslationsLiveTvPt extends TranslationsLiveTvEn {
	_TranslationsLiveTvPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'TV ao Vivo';
	@override String get guide => 'Guia';
	@override String get noChannels => 'Nenhum canal disponível';
	@override String get noDvr => 'Nenhum DVR configurado em nenhum servidor';
	@override String get noPrograms => 'Nenhum dado de programação disponível';
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
	@override String get whatsOn => 'O que Está Passando';
	@override String get watchChannel => 'Assistir Canal';
	@override String get favorites => 'Favoritos';
	@override String get reorderFavorites => 'Reordenar favoritos';
	@override String get joinSession => 'Entrar na sessão em andamento';
	@override String watchFromStart({required Object minutes}) => 'Assistir do início (${minutes} min atrás)';
	@override String get watchLive => 'Assistir ao vivo';
	@override String get goToLive => 'Ir para o ao vivo';
	@override String get record => 'Gravar';
	@override String get recordEpisode => 'Gravar episódio';
	@override String get recordSeries => 'Gravar série';
	@override String get recordOptions => 'Opções de gravação';
	@override String get recordings => 'Gravações';
	@override String get scheduledRecordings => 'Agendadas';
	@override String get recordingRules => 'Regras de gravação';
	@override String get noScheduledRecordings => 'Sem gravações agendadas';
	@override String get noRecordingRules => 'Sem regras de gravação';
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
	@override String get loadingRecordings => 'Carregando gravações...';
	@override String get recordingInProgress => 'Gravando agora';
	@override String recordingsCount({required Object count}) => '${count} agendadas';
	@override String get editRule => 'Editar regra';
	@override String get editRuleAction => 'Editar';
	@override String get recordingRuleUpdated => 'Regra de gravação atualizada';
	@override String get guideReloadRequested => 'Atualização da guia solicitada';
	@override String get rulesProcessRequested => 'Reavaliação de regras solicitada';
	@override String get recordShow => 'Gravar programa';
}

// Path: collections
class _TranslationsCollectionsPt extends TranslationsCollectionsEn {
	_TranslationsCollectionsPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Coleções';
	@override String get collection => 'Coleção';
	@override String get empty => 'A coleção está vazia';
	@override String get unknownLibrarySection => 'Não é possível excluir: Seção de biblioteca desconhecida';
	@override String get deleteCollection => 'Excluir Coleção';
	@override String deleteConfirm({required Object title}) => 'Tem certeza que deseja excluir "${title}"? Esta ação não pode ser desfeita.';
	@override String get deleted => 'Coleção excluída';
	@override String get deleteFailed => 'Falha ao excluir coleção';
	@override String deleteFailedWithError({required Object error}) => 'Falha ao excluir coleção: ${error}';
	@override String failedToLoadItems({required Object error}) => 'Falha ao carregar itens da coleção: ${error}';
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
class _TranslationsPlaylistsPt extends TranslationsPlaylistsEn {
	_TranslationsPlaylistsPt._(TranslationsPt root) : this._root = root, super.internal(root);

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
	@override String deleteMessage({required Object name}) => 'Tem certeza que deseja excluir "${name}"?';
	@override String get created => 'Playlist criada';
	@override String get deleted => 'Playlist excluída';
	@override String get itemAdded => 'Adicionado à playlist';
	@override String get itemRemoved => 'Removido da playlist';
	@override String get selectPlaylist => 'Selecionar Playlist';
	@override String get errorCreating => 'Falha ao criar playlist';
	@override String get errorDeleting => 'Falha ao excluir playlist';
	@override String get errorLoading => 'Falha ao carregar playlists';
	@override String get errorAdding => 'Falha ao adicionar à playlist';
	@override String get errorReordering => 'Falha ao reordenar item da playlist';
	@override String get errorRemoving => 'Falha ao remover da playlist';
}

// Path: watchTogether
class _TranslationsWatchTogetherPt extends TranslationsWatchTogetherEn {
	_TranslationsWatchTogetherPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Assistir Juntos';
	@override String get description => 'Assista conteúdo sincronizado com amigos e família';
	@override String get createSession => 'Criar Sessão';
	@override String get creating => 'Criando...';
	@override String get joinSession => 'Entrar na Sessão';
	@override String get joining => 'Entrando...';
	@override String get controlMode => 'Modo de Controle';
	@override String get controlModeQuestion => 'Quem pode controlar a reprodução?';
	@override String get hostOnly => 'Apenas o Anfitrião';
	@override String get anyone => 'Qualquer pessoa';
	@override String get hostingSession => 'Hospedando Sessão';
	@override String get inSession => 'Em Sessão';
	@override String get sessionCode => 'Código da Sessão';
	@override String get hostControlsPlayback => 'Anfitrião controla a reprodução';
	@override String get anyoneCanControl => 'Qualquer pessoa pode controlar a reprodução';
	@override String get hostControls => 'Controle do anfitrião';
	@override String get anyoneControls => 'Controle de todos';
	@override String get participants => 'Participantes';
	@override String get host => 'Anfitrião';
	@override String get hostBadge => 'HOST';
	@override String get youAreHost => 'Você é o anfitrião';
	@override String get watchingWithOthers => 'Assistindo com outros';
	@override String get endSession => 'Encerrar Sessão';
	@override String get leaveSession => 'Sair da Sessão';
	@override String get endSessionQuestion => 'Encerrar Sessão?';
	@override String get leaveSessionQuestion => 'Sair da Sessão?';
	@override String get endSessionConfirm => 'Isso encerrará a sessão para todos os participantes.';
	@override String get leaveSessionConfirm => 'Você será removido da sessão.';
	@override String get endSessionConfirmOverlay => 'Isso encerrará a sessão de visualização para todos os participantes.';
	@override String get leaveSessionConfirmOverlay => 'Você será desconectado da sessão de visualização.';
	@override String get end => 'Encerrar';
	@override String get leave => 'Sair';
	@override String get syncing => 'Sincronizando...';
	@override String get joinWatchSession => 'Entrar na Sessão';
	@override String get enterCodeHint => 'Insira o código de 5 caracteres';
	@override String get pasteFromClipboard => 'Colar da área de transferência';
	@override String get pleaseEnterCode => 'Insira um código de sessão';
	@override String get codeMustBe5Chars => 'O código da sessão deve ter 5 caracteres';
	@override String get joinInstructions => 'Insira o código da sessão compartilhado pelo anfitrião para entrar na sessão.';
	@override String get failedToCreate => 'Falha ao criar sessão';
	@override String get failedToJoin => 'Falha ao entrar na sessão';
	@override String get sessionCodeCopied => 'Código da sessão copiado para a área de transferência';
	@override String get relayUnreachable => 'O servidor de retransmissão está inacessível. Isso pode ser causado pelo seu provedor bloqueando a conexão. Você ainda pode tentar, mas o Assistir Juntos pode não funcionar.';
	@override String get reconnectingToHost => 'Reconectando ao anfitrião...';
	@override String get currentPlayback => 'Reprodução Atual';
	@override String get joinCurrentPlayback => 'Entrar na Reprodução Atual';
	@override String get joinCurrentPlaybackDescription => 'Voltar ao que o anfitrião está assistindo agora';
	@override String get failedToOpenCurrentPlayback => 'Falha ao abrir reprodução atual';
	@override String participantJoined({required Object name}) => '${name} entrou';
	@override String participantLeft({required Object name}) => '${name} saiu';
	@override String participantPaused({required Object name}) => '${name} pausou';
	@override String participantResumed({required Object name}) => '${name} retomou';
	@override String participantSeeked({required Object name}) => '${name} avançou';
	@override String participantBuffering({required Object name}) => '${name} está carregando';
	@override String get waitingForParticipants => 'Aguardando outros carregarem...';
	@override String get recentRooms => 'Salas recentes';
	@override String get renameRoom => 'Renomear sala';
	@override String get removeRoom => 'Remover';
	@override String get guestSwitchUnavailable => 'Não foi possível trocar — servidor indisponível para sincronização';
	@override String get guestSwitchFailed => 'Não foi possível trocar — conteúdo não encontrado neste servidor';
}

// Path: downloads
class _TranslationsDownloadsPt extends TranslationsDownloadsEn {
	_TranslationsDownloadsPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Downloads';
	@override String get manage => 'Gerenciar';
	@override String get tvShows => 'Séries de TV';
	@override String get movies => 'Filmes';
	@override String get noDownloads => 'Nenhum download ainda';
	@override String get noDownloadsDescription => 'Conteúdo baixado aparecerá aqui para visualização offline';
	@override String get downloadNow => 'Baixar';
	@override String get deleteDownload => 'Excluir download';
	@override String get retryDownload => 'Tentar download novamente';
	@override String get downloadQueued => 'Download na fila';
	@override String get serverErrorBitrate => 'Erro do servidor — o arquivo pode exceder o limite de bitrate de streaming remoto';
	@override String episodesQueued({required Object count}) => '${count} episódios na fila de download';
	@override String get downloadDeleted => 'Download excluído';
	@override String deleteConfirm({required Object title}) => 'Tem certeza que deseja excluir "${title}"? Isso removerá o arquivo baixado do seu dispositivo.';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Excluindo ${title}... (${current} de ${total})';
	@override String get deleting => 'Excluindo...';
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
	@override String nextNUnwatched({required Object count}) => 'Próximos ${count} não assistidos';
	@override String get customAmount => 'Quantidade personalizada...';
	@override String get howManyEpisodes => 'Quantos episódios?';
	@override String itemsQueued({required Object count}) => '${count} itens na fila de download';
	@override String get keepSynced => 'Manter sincronizado';
	@override String get downloadOnce => 'Baixar uma vez';
	@override String keepNUnwatched({required Object count}) => 'Manter ${count} não assistidos';
	@override String get editSyncRule => 'Editar regra de sincronização';
	@override String get removeSyncRule => 'Remover regra de sincronização';
	@override String removeSyncRuleConfirm({required Object title}) => 'Parar de sincronizar "${title}"? Os episódios baixados serão mantidos.';
	@override String syncRuleCreated({required Object count}) => 'Regra de sincronização criada — mantendo ${count} episódios não assistidos';
	@override String get syncRuleUpdated => 'Regra de sincronização atualizada';
	@override String get syncRuleRemoved => 'Regra de sincronização removida';
	@override String syncedNewEpisodes({required Object count, required Object title}) => '${count} novos episódios sincronizados para ${title}';
	@override String get activeSyncRules => 'Regras de sincronização';
	@override String get noSyncRules => 'Nenhuma regra de sincronização';
	@override String get manageSyncRule => 'Gerenciar sincronização';
	@override String get editEpisodeCount => 'Número de episódios';
	@override String get editSyncFilter => 'Filtro de sincronização';
	@override String get syncAllItems => 'Sincronizando todos os itens';
	@override String get syncUnwatchedItems => 'Sincronizando itens não vistos';
	@override String syncRuleServerContext({required Object server, required Object status}) => 'Servidor: ${server} • ${status}';
	@override String get syncRuleAvailable => 'Disponível';
	@override String get syncRuleOffline => 'Offline';
	@override String get syncRuleSignInRequired => 'Início de sessão necessário';
	@override String get syncRuleNotAvailableForProfile => 'Indisponível para o perfil atual';
	@override String get syncRuleUnknownServer => 'Servidor desconhecido';
	@override String get syncRuleListCreated => 'Regra de sincronização criada';
}

// Path: shaders
class _TranslationsShadersPt extends TranslationsShadersEn {
	_TranslationsShadersPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Shaders';
	@override String get noShaderDescription => 'Sem aprimoramento de vídeo';
	@override String get nvscalerDescription => 'Escalonamento de imagem NVIDIA para vídeo mais nítido';
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
class _TranslationsCompanionRemotePt extends TranslationsCompanionRemoteEn {
	_TranslationsCompanionRemotePt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Controle Remoto';
	@override String connectedTo({required Object name}) => 'Conectado a ${name}';
	@override late final _TranslationsCompanionRemoteSessionPt session = _TranslationsCompanionRemoteSessionPt._(_root);
	@override late final _TranslationsCompanionRemotePairingPt pairing = _TranslationsCompanionRemotePairingPt._(_root);
	@override late final _TranslationsCompanionRemoteRemotePt remote = _TranslationsCompanionRemoteRemotePt._(_root);
}

// Path: videoSettings
class _TranslationsVideoSettingsPt extends TranslationsVideoSettingsEn {
	_TranslationsVideoSettingsPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get playbackSettings => 'Configurações de Reprodução';
	@override String get playbackSpeed => 'Velocidade de Reprodução';
	@override String get sleepTimer => 'Timer de Sono';
	@override String get audioSync => 'Sincronia de Áudio';
	@override String get subtitleSync => 'Sincronia de Legendas';
	@override String get hdr => 'HDR';
	@override String get audioOutput => 'Saída de Áudio';
	@override String get performanceOverlay => 'Overlay de Desempenho';
	@override String get audioPassthrough => 'Passagem de Áudio';
	@override String get audioNormalization => 'Normalizar Volume';
}

// Path: externalPlayer
class _TranslationsExternalPlayerPt extends TranslationsExternalPlayerEn {
	_TranslationsExternalPlayerPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Player Externo';
	@override String get useExternalPlayer => 'Usar Player Externo';
	@override String get useExternalPlayerDescription => 'Abrir vídeos em um app externo em vez do player integrado';
	@override String get selectPlayer => 'Selecionar Player';
	@override String get customPlayers => 'Players Personalizados';
	@override String get systemDefault => 'Padrão do Sistema';
	@override String get addCustomPlayer => 'Adicionar Player Personalizado';
	@override String get playerName => 'Nome do Player';
	@override String get playerCommand => 'Comando';
	@override String get playerPackage => 'Nome do Pacote';
	@override String get playerUrlScheme => 'Esquema de URL';
	@override String get off => 'Desativado';
	@override String get launchFailed => 'Falha ao abrir player externo';
	@override String appNotInstalled({required Object name}) => '${name} não está instalado';
	@override String get playInExternalPlayer => 'Reproduzir no Player Externo';
}

// Path: metadataEdit
class _TranslationsMetadataEditPt extends TranslationsMetadataEditEn {
	_TranslationsMetadataEditPt._(TranslationsPt root) : this._root = root, super.internal(root);

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
	@override String get tagline => 'Tagline';
	@override String get summary => 'Sinopse';
	@override String get poster => 'Poster';
	@override String get background => 'Plano de Fundo';
	@override String get logo => 'Logo';
	@override String get squareArt => 'Imagem Quadrada';
	@override String get selectPoster => 'Selecionar Poster';
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
	@override String get style => 'Estilo';
	@override String get mood => 'Humor';
}

// Path: matchScreen
class _TranslationsMatchScreenPt extends TranslationsMatchScreenEn {
	_TranslationsMatchScreenPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get match => 'Associar...';
	@override String get fixMatch => 'Corrigir correspondência...';
	@override String get unmatch => 'Desassociar';
	@override String get unmatchConfirm => 'Limpar a correspondência atual deste item? O Plex vai tratá-lo como não correspondido até que o associe novamente.';
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
class _TranslationsServerTasksPt extends TranslationsServerTasksEn {
	_TranslationsServerTasksPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tarefas do servidor';
	@override String get failedToLoad => 'Falha ao carregar tarefas';
	@override String get noTasks => 'Nenhuma tarefa em execução';
}

// Path: trakt
class _TranslationsTraktPt extends TranslationsTraktEn {
	_TranslationsTraktPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'Conectado';
	@override String connectedAs({required Object username}) => 'Conectado como @${username}';
	@override String get disconnectConfirm => 'Desconectar conta do Trakt?';
	@override String get disconnectConfirmBody => 'O Plezy deixará de enviar eventos de reprodução ao Trakt. Você pode reconectar a qualquer momento.';
	@override String get scrobble => 'Scrobbling em tempo real';
	@override String get scrobbleDescription => 'Envia eventos de reprodução, pausa e parada ao Trakt durante a exibição.';
	@override String get watchedSync => 'Sincronizar status de assistido';
	@override String get watchedSyncDescription => 'Ao marcar itens como assistidos no Plezy, eles também serão marcados no Trakt.';
}

// Path: trackers
class _TranslationsTrackersPt extends TranslationsTrackersEn {
	_TranslationsTrackersPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Rastreadores';
	@override String get hubSubtitle => 'Mantenha seu progresso sincronizado com Trakt e outros serviços.';
	@override String get notConnected => 'Não conectado';
	@override String connectedAs({required Object username}) => 'Conectado como @${username}';
	@override String get scrobble => 'Registrar progresso automaticamente';
	@override String get scrobbleDescription => 'Atualiza sua lista quando você termina um episódio ou filme.';
	@override String disconnectConfirm({required Object service}) => 'Desconectar ${service}?';
	@override String disconnectConfirmBody({required Object service}) => 'Plezy deixará de atualizar sua lista do ${service}. Você pode reconectar a qualquer momento.';
	@override String connectFailed({required Object service}) => 'Não foi possível conectar ao ${service}. Tente novamente.';
	@override late final _TranslationsTrackersServicesPt services = _TranslationsTrackersServicesPt._(_root);
	@override late final _TranslationsTrackersDeviceCodePt deviceCode = _TranslationsTrackersDeviceCodePt._(_root);
	@override late final _TranslationsTrackersOauthProxyPt oauthProxy = _TranslationsTrackersOauthProxyPt._(_root);
	@override late final _TranslationsTrackersLibraryFilterPt libraryFilter = _TranslationsTrackersLibraryFilterPt._(_root);
}

// Path: addServer
class _TranslationsAddServerPt extends TranslationsAddServerEn {
	_TranslationsAddServerPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get addJellyfinTitle => 'Adicionar servidor Jellyfin';
	@override String get jellyfinUrlIntro => 'Insira a URL do seu servidor Jellyfin — ex.: `https://jellyfin.example.com`. Você pode entrar em seguida.';
	@override String get serverUrl => 'URL do servidor';
	@override String get findServer => 'Encontrar servidor';
	@override String get username => 'Usuário';
	@override String get password => 'Senha';
	@override String get signIn => 'Entrar';
	@override String get change => 'Alterar';
	@override String get required => 'Obrigatório';
	@override String couldNotReachServer({required Object error}) => 'Não foi possível conectar ao servidor: ${error}';
	@override String signInFailed({required Object error}) => 'Falha ao entrar: ${error}';
	@override String quickConnectFailed({required Object error}) => 'Quick Connect falhou: ${error}';
	@override String get addPlexTitle => 'Entrar com Plex';
	@override String get plexAuthIntro => 'Escolha como entrar no Plex. O fluxo do navegador abre plex.tv onde você confirma a conexão; a opção QR é prática para TV / dispositivos remotos.';
	@override String get plexQRPrompt => 'Escaneie este código QR para entrar.';
	@override String get waitingForPlexConfirmation => 'Aguardando o plex.tv confirmar o login…';
	@override String get pinExpired => 'O PIN expirou antes do login. Tente novamente.';
	@override String get duplicatePlexAccount => 'Este dispositivo já está conectado a uma conta Plex. Saia nas configurações para trocar de conta.';
	@override String failedToRegisterAccount({required Object error}) => 'Falha ao registrar a conta: ${error}';
	@override String get enterJellyfinUrlError => 'Insira a URL do seu servidor Jellyfin';
	@override String get addConnectionTitle => 'Adicionar conexão';
	@override String addConnectionTitleScoped({required Object name}) => 'Adicionar a ${name}';
	@override String get addConnectionIntroGlobal => 'Adicione outro servidor de mídia. Você pode misturar contas Plex e servidores Jellyfin — itens de cada backend conectado aparecem juntos na tela inicial.';
	@override String get addConnectionIntroScoped => 'Adicione um novo servidor ou pegue um emprestado de outro perfil.';
	@override String get signInWithPlexCard => 'Entrar com Plex';
	@override String get signInWithPlexCardSubtitle => 'Autorize este dispositivo na sua conta Plex. Servidores compartilhados com a conta vêm junto automaticamente.';
	@override String get signInWithPlexCardSubtitleScoped => 'Autorize uma nova conta Plex. Seus usuários Home aparecem como perfis.';
	@override String get connectToJellyfinCard => 'Conectar ao Jellyfin';
	@override String get connectToJellyfinCardSubtitle => 'Insira a URL do seu servidor Jellyfin e entre com usuário + senha (Quick Connect em breve).';
	@override String connectToJellyfinCardSubtitleScoped({required Object name}) => 'Entre em um servidor Jellyfin. Vinculado a ${name}.';
	@override String get borrowFromAnotherProfile => 'Pegar emprestado de outro perfil';
	@override String get borrowFromAnotherProfileSubtitle => 'Reutilize uma conexão já associada a outro perfil. Perfis de origem protegidos por PIN solicitarão o PIN.';
}

// Path: hotkeys.actions
class _TranslationsHotkeysActionsPt extends TranslationsHotkeysActionsEn {
	_TranslationsHotkeysActionsPt._(TranslationsPt root) : this._root = root, super.internal(root);

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
	@override String get subSeekNext => 'Ir para Próxima Legenda';
	@override String get subSeekPrev => 'Ir para Legenda Anterior';
	@override String get shaderToggle => 'Alternar Shaders';
	@override String get skipMarker => 'Pular Intro/Créditos';
}

// Path: videoControls.pipErrors
class _TranslationsVideoControlsPipErrorsPt extends TranslationsVideoControlsPipErrorsEn {
	_TranslationsVideoControlsPipErrorsPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Requer Android 8.0 ou superior';
	@override String get iosVersion => 'Requer iOS 15.0 ou superior';
	@override String get permissionDisabled => 'A permissão de picture-in-picture está desativada. Ative em Configurações > Apps > Plezy > Picture-in-picture';
	@override String get notSupported => 'O dispositivo não suporta modo picture-in-picture';
	@override String get voSwitchFailed => 'Falha ao trocar saída de vídeo para picture-in-picture';
	@override String get failed => 'Falha ao iniciar picture-in-picture';
	@override String unknown({required Object error}) => 'Ocorreu um erro: ${error}';
}

// Path: libraries.tabs
class _TranslationsLibrariesTabsPt extends TranslationsLibrariesTabsEn {
	_TranslationsLibrariesTabsPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Recomendados';
	@override String get browse => 'Navegar';
	@override String get collections => 'Coleções';
	@override String get playlists => 'Playlists';
}

// Path: libraries.groupings
class _TranslationsLibrariesGroupingsPt extends TranslationsLibrariesGroupingsEn {
	_TranslationsLibrariesGroupingsPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Agrupamento';
	@override String get all => 'Todos';
	@override String get movies => 'Filmes';
	@override String get shows => 'Séries de TV';
	@override String get seasons => 'Temporadas';
	@override String get episodes => 'Episódios';
	@override String get folders => 'Pastas';
}

// Path: libraries.filterCategories
class _TranslationsLibrariesFilterCategoriesPt extends TranslationsLibrariesFilterCategoriesEn {
	_TranslationsLibrariesFilterCategoriesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get genre => 'Gênero';
	@override String get year => 'Ano';
	@override String get contentRating => 'Classificação';
	@override String get tag => 'Tag';
}

// Path: libraries.sortLabels
class _TranslationsLibrariesSortLabelsPt extends TranslationsLibrariesSortLabelsEn {
	_TranslationsLibrariesSortLabelsPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Título';
	@override String get dateAdded => 'Data de adição';
	@override String get releaseDate => 'Data de lançamento';
	@override String get rating => 'Avaliação';
	@override String get lastPlayed => 'Última reprodução';
	@override String get playCount => 'Reproduções';
	@override String get random => 'Aleatório';
	@override String get dateShared => 'Data de compartilhamento';
	@override String get latestEpisodeAirDate => 'Última data de exibição do episódio';
}

// Path: companionRemote.session
class _TranslationsCompanionRemoteSessionPt extends TranslationsCompanionRemoteSessionEn {
	_TranslationsCompanionRemoteSessionPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'A iniciar servidor remoto...';
	@override String get failedToCreate => 'Falha ao iniciar o servidor remoto:';
	@override String get hostAddress => 'Endereço do host';
	@override String get connected => 'Conectado';
	@override String get serverRunning => 'Servidor remoto ativo';
	@override String get serverStopped => 'Servidor remoto parado';
	@override String get serverRunningDescription => 'Dispositivos móveis na sua rede podem descobrir e conectar-se a esta aplicação';
	@override String get serverStoppedDescription => 'Inicie o servidor para permitir que dispositivos móveis se conectem';
	@override String get usePhoneToControl => 'Use o seu dispositivo móvel para controlar esta aplicação';
	@override String get startServer => 'Iniciar servidor';
	@override String get stopServer => 'Parar servidor';
	@override String get minimize => 'Minimizar';
}

// Path: companionRemote.pairing
class _TranslationsCompanionRemotePairingPt extends TranslationsCompanionRemotePairingEn {
	_TranslationsCompanionRemotePairingPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'Dispositivos na sua rede a executar Plezy com a mesma conta Plex aparecerão automaticamente';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'A conectar...';
	@override String get searchingForDevices => 'A procurar dispositivos...';
	@override String get noDevicesFound => 'Nenhum dispositivo encontrado na sua rede';
	@override String get noDevicesHint => 'Certifique-se de que o Plezy está aberto no seu desktop e que ambos os dispositivos estão na mesma rede WiFi';
	@override String get availableDevices => 'Dispositivos disponíveis';
	@override String get manualConnection => 'Conexão manual';
	@override String get cryptoInitFailed => 'Não foi possível inicializar a conexão segura. Certifique-se de que está conectado a uma conta Plex.';
	@override String get validationHostRequired => 'Introduza o endereço do host';
	@override String get validationHostFormat => 'O formato deve ser IP:porta (ex. 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'Tempo de conexão esgotado. Certifique-se de que ambos os dispositivos estão na mesma rede.';
	@override String get sessionNotFound => 'Dispositivo não encontrado. Certifique-se de que o Plezy está em execução no host.';
	@override String get authFailed => 'Autenticação falhou. Certifique-se de que ambos os dispositivos usam a mesma conta Plex.';
	@override String failedToConnect({required Object error}) => 'Falha ao conectar: ${error}';
}

// Path: companionRemote.remote
class _TranslationsCompanionRemoteRemotePt extends TranslationsCompanionRemoteRemoteEn {
	_TranslationsCompanionRemoteRemotePt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'Deseja desconectar da sessão remota?';
	@override String get reconnecting => 'Reconectando...';
	@override String attemptOf({required Object current}) => 'Tentativa ${current} de 5';
	@override String get retryNow => 'Tentar Agora';
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
	@override String get fullscreen => 'Tela Cheia';
	@override String get subtitles => 'Legendas';
	@override String get audio => 'Áudio';
	@override String get searchHint => 'Buscar no desktop...';
}

// Path: trackers.services
class _TranslationsTrackersServicesPt extends TranslationsTrackersServicesEn {
	_TranslationsTrackersServicesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
}

// Path: trackers.deviceCode
class _TranslationsTrackersDeviceCodePt extends TranslationsTrackersDeviceCodeEn {
	_TranslationsTrackersDeviceCodePt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Ativar Plezy no ${service}';
	@override String body({required Object url}) => 'Acesse ${url} e insira este código:';
	@override String openToActivate({required Object service}) => 'Abrir ${service} para ativar';
	@override String get waitingForAuthorization => 'Aguardando autorização…';
	@override String get codeCopied => 'Código copiado';
}

// Path: trackers.oauthProxy
class _TranslationsTrackersOauthProxyPt extends TranslationsTrackersOauthProxyEn {
	_TranslationsTrackersOauthProxyPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Entrar no ${service}';
	@override String get body => 'Escaneie este código QR com o celular, ou abra o URL abaixo em qualquer dispositivo com navegador.';
	@override String openToSignIn({required Object service}) => 'Abrir ${service} para entrar';
	@override String get urlCopied => 'URL copiado';
}

// Path: trackers.libraryFilter
class _TranslationsTrackersLibraryFilterPt extends TranslationsTrackersLibraryFilterEn {
	_TranslationsTrackersLibraryFilterPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Filtro de bibliotecas';
	@override String get subtitleAllSyncing => 'Sincronizando todas as bibliotecas';
	@override String get subtitleNoneSyncing => 'Nada a sincronizar';
	@override String subtitleBlocked({required Object count}) => '${count} bloqueadas';
	@override String subtitleAllowed({required Object count}) => '${count} permitidas';
	@override String get mode => 'Modo de filtro';
	@override String get modeBlacklist => 'Lista negra';
	@override String get modeWhitelist => 'Lista branca';
	@override String get modeHintBlacklist => 'Sincronizar todas as bibliotecas exceto as marcadas abaixo.';
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
			'auth.signIn' => 'Entrar',
			'auth.signInWithPlex' => 'Entrar com Plex',
			'auth.showQRCode' => 'Mostrar QR Code',
			'auth.authenticate' => 'Autenticar',
			'auth.authenticationTimeout' => 'A autenticação expirou. Tente novamente.',
			'auth.scanQRToSignIn' => 'Escaneie este QR code para entrar',
			'auth.waitingForAuth' => 'Aguardando autenticação...\nConclua o login no seu navegador.',
			'auth.useBrowser' => 'Usar navegador',
			'auth.or' => 'ou',
			'auth.connectToJellyfin' => 'Conectar ao Jellyfin',
			'auth.useQuickConnect' => 'Usar Quick Connect',
			'auth.quickConnectCode' => 'Código do Quick Connect',
			'auth.quickConnectInstructions' => 'Abra o seu servidor Jellyfin num navegador, inicie sessão e escolha Quick Connect no menu do utilizador. Insira este código para aprovar o início de sessão.',
			'auth.quickConnectWaiting' => 'A aguardar aprovação…',
			'auth.quickConnectCancel' => 'Cancelar',
			'auth.quickConnectExpired' => 'O código do Quick Connect expirou antes da aprovação. Tente novamente.',
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
			'common.reconnect' => 'Reconectar',
			'common.exitConfirmTitle' => 'Sair do app?',
			'common.exitConfirmMessage' => 'Tem certeza que deseja sair?',
			'common.dontAskAgain' => 'Não perguntar novamente',
			'common.exit' => 'Sair',
			'common.viewAll' => 'Ver Tudo',
			'common.checkingNetwork' => 'Verificando rede...',
			'common.refreshingServers' => 'Atualizando servidores...',
			'common.loadingServers' => 'Carregando servidores...',
			'common.connectingToServers' => 'Conectando aos servidores...',
			'common.startingOfflineMode' => 'Iniciando modo offline...',
			'common.loading' => 'Carregando...',
			'common.fullscreen' => 'Tela cheia',
			'common.exitFullscreen' => 'Sair da tela cheia',
			'screens.licenses' => 'Licenças',
			'screens.switchProfile' => 'Trocar Perfil',
			'screens.subtitleStyling' => 'Estilo de Legendas',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'Logs',
			'update.available' => 'Atualização Disponível',
			'update.versionAvailable' => ({required Object version}) => 'Versão ${version} está disponível',
			'update.currentVersion' => ({required Object version}) => 'Atual: ${version}',
			'update.skipVersion' => 'Pular Esta Versão',
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
			'settings.episodePosterMode' => 'Estilo do Poster de Episódio',
			'settings.seriesPoster' => 'Poster da Série',
			'settings.seasonPoster' => 'Poster da Temporada',
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
			'settings.compact' => 'Compacto',
			'settings.comfortable' => 'Confortável',
			'settings.viewMode' => 'Modo de Visualização',
			'settings.gridView' => 'Grade',
			'settings.listView' => 'Lista',
			'settings.showHeroSection' => 'Mostrar Seção de Destaque',
			'settings.useGlobalHubs' => 'Usar layout inicial',
			'settings.useGlobalHubsDescription' => 'Mostra hubs da página inicial como o cliente oficial. Quando desligado, mostra recomendações por biblioteca.',
			'settings.showServerNameOnHubs' => 'Mostrar Nome do Servidor nos Hubs',
			'settings.showServerNameOnHubsDescription' => 'Sempre exibir o nome do servidor nos títulos dos hubs. Quando desativado, mostra apenas para nomes duplicados.',
			'settings.groupLibrariesByServer' => 'Agrupar Bibliotecas por Servidor',
			'settings.groupLibrariesByServerDescription' => 'Mostra um cabeçalho para cada servidor de mídia na barra lateral quando conectado a vários servidores.',
			'settings.alwaysKeepSidebarOpen' => 'Manter Barra Lateral Sempre Aberta',
			'settings.alwaysKeepSidebarOpenDescription' => 'A barra lateral fica expandida e a área de conteúdo se ajusta',
			'settings.showUnwatchedCount' => 'Mostrar Contagem de Não Assistidos',
			'settings.showUnwatchedCountDescription' => 'Exibir contagem de episódios não assistidos em séries e temporadas',
			'settings.showEpisodeNumberOnCards' => 'Mostrar Número do Episódio nos Cards',
			'settings.showEpisodeNumberOnCardsDescription' => 'Mostrar o número do episódio ao lado da temporada (ex. S2 E3) nos cards de episódios',
			'settings.showSeasonPostersOnTabs' => 'Mostrar Pôsteres de Temporada nas Abas',
			'settings.showSeasonPostersOnTabsDescription' => 'Exibe o pôster da temporada acima de cada aba de temporada na página de detalhes de uma série',
			'settings.hideSpoilers' => 'Ocultar Spoilers de Episódios Não Assistidos',
			'settings.hideSpoilersDescription' => 'Desfocar miniaturas e ocultar descrições de episódios que você ainda não assistiu',
			'settings.playerBackend' => 'Backend do Player',
			'settings.exoPlayer' => 'ExoPlayer (Recomendado)',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'Decodificação por Hardware',
			'settings.hardwareDecodingDescription' => 'Usar aceleração por hardware quando disponível',
			'settings.bufferSize' => 'Tamanho do Buffer',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}MB',
			'settings.bufferSizeAuto' => 'Automático (Recomendado)',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => 'Seu dispositivo tem ${heap}MB de memória. Um buffer de ${size}MB pode causar problemas de reprodução.',
			'settings.defaultQualityTitle' => 'Qualidade padrão',
			'settings.defaultQualityDescription' => 'Usado ao iniciar a reprodução. Valores menores reduzem a largura de banda.',
			'settings.subtitleStyling' => 'Estilo de Legendas',
			'settings.subtitleStylingDescription' => 'Personalizar aparência das legendas',
			'settings.smallSkipDuration' => 'Duração do Avanço Curto',
			'settings.largeSkipDuration' => 'Duração do Avanço Longo',
			'settings.rewindOnResume' => 'Rebobinar ao retomar',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} segundos',
			'settings.defaultSleepTimer' => 'Timer de Sono Padrão',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} minutos',
			'settings.rememberTrackSelections' => 'Lembrar seleção de faixas por série/filme',
			'settings.rememberTrackSelectionsDescription' => 'Salvar automaticamente preferências de idioma de áudio e legenda ao trocar faixas durante a reprodução',
			'settings.clickVideoTogglesPlayback' => 'Clicar no vídeo para alternar reprodução/pausa',
			'settings.clickVideoTogglesPlaybackDescription' => 'Se ativado, clicar no player reproduz/pausa o vídeo. Caso contrário, clicar mostra/oculta os controles.',
			'settings.videoPlayerControls' => 'Controles do Player de Vídeo',
			'settings.keyboardShortcuts' => 'Atalhos de Teclado',
			'settings.keyboardShortcutsDescription' => 'Personalizar atalhos de teclado',
			'settings.videoPlayerNavigation' => 'Navegação do Player de Vídeo',
			'settings.videoPlayerNavigationDescription' => 'Usar teclas de seta para navegar nos controles do player',
			'settings.watchTogetherRelay' => 'Relay do Assistir Juntos',
			'settings.watchTogetherRelayDescription' => 'Definir um servidor relay personalizado para Assistir Juntos. Todos os participantes devem usar o mesmo servidor.',
			'settings.watchTogetherRelayHint' => 'https://meu-relay.exemplo.com.br',
			'settings.crashReporting' => 'Relatório de Erros',
			'settings.crashReportingDescription' => 'Enviar relatórios de erros para ajudar a melhorar o app',
			'settings.debugLogging' => 'Log de Depuração',
			'settings.debugLoggingDescription' => 'Ativar log detalhado para solução de problemas',
			'settings.viewLogs' => 'Ver Logs',
			'settings.viewLogsDescription' => 'Ver logs do aplicativo',
			'settings.clearCache' => 'Limpar Cache',
			'settings.clearCacheDescription' => 'Isso limpará todas as imagens e dados em cache. O app pode demorar mais para carregar conteúdo após limpar o cache.',
			'settings.clearCacheSuccess' => 'Cache limpo com sucesso',
			'settings.resetSettings' => 'Redefinir Configurações',
			'settings.resetSettingsDescription' => 'Isso redefinirá todas as configurações para os valores padrão. Esta ação não pode ser desfeita.',
			'settings.resetSettingsSuccess' => 'Configurações redefinidas com sucesso',
			'settings.backup' => 'Backup',
			'settings.exportSettings' => 'Exportar Configurações',
			'settings.exportSettingsDescription' => 'Salve suas preferências em um arquivo',
			'settings.exportSettingsSuccess' => 'Configurações exportadas',
			'settings.exportSettingsFailed' => 'Não foi possível exportar as configurações',
			'settings.importSettings' => 'Importar Configurações',
			'settings.importSettingsDescription' => 'Restaurar preferências a partir de um arquivo',
			'settings.importSettingsConfirm' => 'Isso substituirá suas configurações atuais. Continuar?',
			'settings.importSettingsSuccess' => 'Configurações importadas',
			'settings.importSettingsFailed' => 'Não foi possível importar as configurações',
			'settings.importSettingsInvalidFile' => 'Este arquivo não é uma exportação válida do Plezy',
			'settings.importSettingsNoUser' => 'Entre na conta antes de importar as configurações',
			'settings.shortcutsReset' => 'Atalhos redefinidos para o padrão',
			'settings.about' => 'Sobre',
			'settings.aboutDescription' => 'Informações do app e licenças',
			'settings.updates' => 'Atualizações',
			'settings.updateAvailable' => 'Atualização Disponível',
			'settings.checkForUpdates' => 'Verificar Atualizações',
			'settings.autoCheckUpdatesOnStartup' => 'Verificar atualizações automaticamente ao iniciar',
			'settings.autoCheckUpdatesOnStartupDescription' => 'Mostrar uma notificação quando uma nova versão estiver disponível ao iniciar',
			'settings.validationErrorEnterNumber' => 'Insira um número válido',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'A duração deve ser entre ${min} e ${max} ${unit}',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Atalho já atribuído a ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Atalho atualizado para ${action}',
			'settings.autoSkip' => 'Pular Automaticamente',
			'settings.autoSkipIntro' => 'Pular Intro Automaticamente',
			'settings.autoSkipIntroDescription' => 'Pular marcadores de intro automaticamente após alguns segundos',
			'settings.autoSkipCredits' => 'Pular Créditos Automaticamente',
			'settings.autoSkipCreditsDescription' => 'Pular créditos automaticamente e reproduzir próximo episódio',
			'settings.forceSkipMarkerFallback' => 'Forçar marcadores alternativos',
			'settings.forceSkipMarkerFallbackDescription' => 'Usar padrões de títulos de capítulos para marcadores de pulo mesmo quando o Plex fornece marcadores nativos',
			'settings.autoSkipDelay' => 'Atraso do Pulo Automático',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Aguardar ${seconds} segundos antes de pular automaticamente',
			'settings.introPattern' => 'Padrão de marcador de intro',
			'settings.introPatternDescription' => 'Expressão regular para corresponder marcadores de intro nos títulos dos capítulos',
			'settings.creditsPattern' => 'Padrão de marcador de créditos',
			'settings.creditsPatternDescription' => 'Expressão regular para corresponder marcadores de créditos nos títulos dos capítulos',
			'settings.invalidRegex' => 'Expressão regular inválida',
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
			'settings.downloadLocationSelectError' => 'Falha ao selecionar pasta',
			'settings.downloadOnWifiOnly' => 'Baixar apenas no WiFi',
			'settings.downloadOnWifiOnlyDescription' => 'Impedir downloads quando em dados móveis',
			'settings.autoRemoveWatchedDownloads' => 'Remover downloads assistidos automaticamente',
			'settings.autoRemoveWatchedDownloadsDescription' => 'Excluir automaticamente episódios e filmes baixados quando marcados como assistidos',
			'settings.cellularDownloadBlocked' => 'Downloads estão desativados em dados móveis. Conecte ao WiFi ou altere a configuração.',
			'settings.maxVolume' => 'Volume Máximo',
			'settings.maxVolumeDescription' => 'Permitir aumento de volume acima de 100% para mídias silenciosas',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Mostrar o que você está assistindo no Discord',
			'settings.trakt' => 'Trakt',
			'settings.traktDescription' => 'Sincronizar histórico de exibição com Trakt',
			'settings.trackers' => 'Rastreadores',
			'settings.trackersDescription' => 'Sincronizar progresso com Trakt, MyAnimeList, AniList e Simkl',
			'settings.companionRemoteServer' => 'Servidor de controlo remoto',
			'settings.companionRemoteServerDescription' => 'Permitir que dispositivos móveis na sua rede controlem esta aplicação',
			'settings.autoPip' => 'Picture-in-Picture Automático',
			'settings.autoPipDescription' => 'Entrar automaticamente em picture-in-picture ao sair do app durante a reprodução',
			'settings.matchContentFrameRate' => 'Corresponder Taxa de Quadros do Conteúdo',
			'settings.matchContentFrameRateDescription' => 'Ajustar a taxa de atualização da tela para corresponder ao conteúdo de vídeo, reduzindo tremulação e economizando bateria',
			'settings.matchRefreshRate' => 'Corresponder Taxa de Atualização',
			'settings.matchRefreshRateDescription' => 'Alterar a taxa de atualização da tela para corresponder ao conteúdo de vídeo em tela cheia',
			'settings.matchDynamicRange' => 'Corresponder Faixa Dinâmica',
			'settings.matchDynamicRangeDescription' => 'Ativar automaticamente o HDR para conteúdo HDR e voltar ao SDR ao sair do reprodutor',
			'settings.displaySwitchDelay' => 'Atraso na Troca de Tela',
			'settings.tunneledPlayback' => 'Reprodução Tunelizada',
			'settings.tunneledPlaybackDescription' => 'Usar tunelamento de vídeo acelerado por hardware. Desative se você vir uma tela preta com áudio em conteúdo HDR',
			'settings.requireProfileSelectionOnOpen' => 'Pedir perfil ao abrir o app',
			'settings.requireProfileSelectionOnOpenDescription' => 'Mostrar seleção de perfil toda vez que o app for aberto',
			'settings.confirmExitOnBack' => 'Confirmar antes de sair',
			'settings.confirmExitOnBackDescription' => 'Mostrar diálogo de confirmação ao pressionar voltar para sair do app',
			'settings.forceTvMode' => 'Forçar modo TV',
			'settings.forceTvModeDescription' => 'Usar o layout de TV independentemente da detecção automática. Útil em dispositivos Android TV que não reportam o recurso leanback. Reinicia o app ao alterar.',
			'settings.startInFullscreen' => 'Iniciar em tela cheia',
			'settings.startInFullscreenDescription' => 'Abrir o Plezy em modo de tela cheia ao iniciar',
			'settings.autoHidePerformanceOverlay' => 'Ocultar overlay de desempenho automaticamente',
			'settings.autoHidePerformanceOverlayDescription' => 'Desvanecer o overlay de desempenho com os controles de reprodução',
			'settings.showNavBarLabels' => 'Mostrar Rótulos da Barra de Navegação',
			'settings.showNavBarLabelsDescription' => 'Exibir rótulos de texto sob os ícones da barra de navegação',
			'settings.liveTvDefaultFavorites' => 'Canais favoritos por padrão',
			'settings.liveTvDefaultFavoritesDescription' => 'Mostrar apenas canais favoritos ao abrir TV ao vivo',
			'settings.display' => 'Tela',
			'settings.homeScreen' => 'Tela inicial',
			'settings.navigation' => 'Navegação',
			'settings.window' => 'Janela',
			'settings.content' => 'Conteúdo',
			'settings.player' => 'Reprodutor',
			'settings.subtitlesAndConfig' => 'Legendas e configuração',
			'settings.seekAndTiming' => 'Busca e tempo',
			'settings.behavior' => 'Comportamento',
			'search.hint' => 'Buscar filmes, séries, músicas...',
			'search.tryDifferentTerm' => 'Tente um termo de busca diferente',
			'search.searchYourMedia' => 'Buscar suas mídias',
			'search.enterTitleActorOrKeyword' => 'Insira um título, ator ou palavra-chave',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'Definir Atalho para ${actionName}',
			'hotkeys.clearShortcut' => 'Limpar atalho',
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
			'hotkeys.actions.subSeekNext' => 'Ir para Próxima Legenda',
			'hotkeys.actions.subSeekPrev' => 'Ir para Legenda Anterior',
			'hotkeys.actions.shaderToggle' => 'Alternar Shaders',
			'hotkeys.actions.skipMarker' => 'Pular Intro/Créditos',
			'fileInfo.title' => 'Info do Arquivo',
			'fileInfo.video' => 'Vídeo',
			'fileInfo.audio' => 'Áudio',
			'fileInfo.file' => 'Arquivo',
			'fileInfo.advanced' => 'Avançado',
			'fileInfo.codec' => 'Codec',
			'fileInfo.resolution' => 'Resolução',
			'fileInfo.bitrate' => 'Taxa de Bits',
			'fileInfo.frameRate' => 'Taxa de Quadros',
			'fileInfo.aspectRatio' => 'Proporção',
			'fileInfo.profile' => 'Perfil',
			'fileInfo.bitDepth' => 'Profundidade de Bits',
			'fileInfo.colorSpace' => 'Espaço de Cor',
			'fileInfo.colorRange' => 'Faixa de Cor',
			'fileInfo.colorPrimaries' => 'Primárias de Cor',
			'fileInfo.chromaSubsampling' => 'Subamostragem de Croma',
			'fileInfo.channels' => 'Canais',
			'fileInfo.subtitles' => 'Legendas',
			'fileInfo.overallBitrate' => 'Taxa de bits total',
			'fileInfo.path' => 'Caminho',
			'fileInfo.size' => 'Tamanho',
			'fileInfo.container' => 'Container',
			'fileInfo.duration' => 'Duração',
			'fileInfo.optimizedForStreaming' => 'Otimizado para Streaming',
			'fileInfo.has64bitOffsets' => 'Offsets de 64 bits',
			'mediaMenu.markAsWatched' => 'Marcar como Assistido',
			'mediaMenu.markAsUnwatched' => 'Marcar como Não Assistido',
			'mediaMenu.removeFromContinueWatching' => 'Remover de Continuar Assistindo',
			'mediaMenu.goToSeries' => 'Ir para a série',
			'mediaMenu.goToSeason' => 'Ir para a temporada',
			'mediaMenu.shufflePlay' => 'Reprodução Aleatória',
			'mediaMenu.fileInfo' => 'Info do Arquivo',
			'mediaMenu.deleteFromServer' => 'Excluir do servidor',
			'mediaMenu.confirmDelete' => 'Isso excluirá permanentemente esta mídia e seus arquivos do seu servidor. Esta ação não pode ser desfeita.',
			'mediaMenu.deleteMultipleWarning' => 'Isso inclui todos os episódios e seus arquivos.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Item de mídia excluído com sucesso',
			'mediaMenu.mediaFailedToDelete' => 'Falha ao excluir item de mídia',
			'mediaMenu.rate' => 'Avaliar',
			'mediaMenu.playFromBeginning' => 'Reproduzir do início',
			'mediaMenu.playVersion' => 'Reproduzir versão...',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, filme',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, série de TV',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'assistido',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} por cento assistido',
			'accessibility.mediaCardUnwatched' => 'não assistido',
			'accessibility.tapToPlay' => 'Toque para reproduzir',
			'tooltips.shufflePlay' => 'Reprodução aleatória',
			'tooltips.playTrailer' => 'Reproduzir trailer',
			'tooltips.markAsWatched' => 'Marcar como assistido',
			'tooltips.markAsUnwatched' => 'Marcar como não assistido',
			'videoControls.audioLabel' => 'Áudio',
			'videoControls.subtitlesLabel' => 'Legendas',
			'videoControls.resetToZero' => 'Redefinir para 0ms',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.minusTime' => ({required Object amount, required Object unit}) => '-${amount}${unit}',
			'videoControls.playsLater' => ({required Object label}) => '${label} reproduz depois',
			'videoControls.playsEarlier' => ({required Object label}) => '${label} reproduz antes',
			'videoControls.noOffset' => 'Sem deslocamento',
			'videoControls.letterbox' => 'Letterbox',
			'videoControls.fillScreen' => 'Preencher tela',
			'videoControls.stretch' => 'Esticar',
			'videoControls.lockRotation' => 'Travar rotação',
			'videoControls.unlockRotation' => 'Destravar rotação',
			'videoControls.timerActive' => 'Timer Ativo',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'A reprodução pausará em ${duration}',
			'videoControls.stillWatching' => 'Ainda assistindo?',
			'videoControls.pausingIn' => ({required Object seconds}) => 'Pausando em ${seconds}s',
			'videoControls.continueWatching' => 'Continuar',
			'videoControls.autoPlayNext' => 'Reproduzir Próximo Automaticamente',
			'videoControls.playNext' => 'Reproduzir Próximo',
			'videoControls.playButton' => 'Reproduzir',
			'videoControls.pauseButton' => 'Pausar',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'Retroceder ${seconds} segundos',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'Avançar ${seconds} segundos',
			'videoControls.previousButton' => 'Episódio anterior',
			'videoControls.nextButton' => 'Próximo episódio',
			'videoControls.previousChapterButton' => 'Capítulo anterior',
			'videoControls.nextChapterButton' => 'Próximo capítulo',
			'videoControls.muteButton' => 'Silenciar',
			'videoControls.unmuteButton' => 'Ativar som',
			'videoControls.settingsButton' => 'Configurações de vídeo',
			'videoControls.tracksButton' => 'Áudio e Legendas',
			'videoControls.chaptersButton' => 'Capítulos',
			'videoControls.versionsButton' => 'Versões do vídeo',
			'videoControls.versionQualityButton' => 'Versão e qualidade',
			'videoControls.versionColumnHeader' => 'Versão',
			'videoControls.qualityColumnHeader' => 'Qualidade',
			'videoControls.qualityOriginal' => 'Original',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.qualityBandwidthEstimate' => ({required Object bitrate}) => '~${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => 'Transcodificação indisponível — reproduzindo qualidade original',
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
			'videoControls.pipErrors.androidVersion' => 'Requer Android 8.0 ou superior',
			'videoControls.pipErrors.iosVersion' => 'Requer iOS 15.0 ou superior',
			'videoControls.pipErrors.permissionDisabled' => 'A permissão de picture-in-picture está desativada. Ative em Configurações > Apps > Plezy > Picture-in-picture',
			'videoControls.pipErrors.notSupported' => 'O dispositivo não suporta modo picture-in-picture',
			'videoControls.pipErrors.voSwitchFailed' => 'Falha ao trocar saída de vídeo para picture-in-picture',
			'videoControls.pipErrors.failed' => 'Falha ao iniciar picture-in-picture',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Ocorreu um erro: ${error}',
			'videoControls.chapters' => 'Capítulos',
			'videoControls.noChaptersAvailable' => 'Nenhum capítulo disponível',
			'videoControls.queue' => 'Fila',
			'videoControls.noQueueItems' => 'Nenhum item na fila',
			'videoControls.searchSubtitles' => 'Pesquisar legendas',
			'videoControls.language' => 'Idioma',
			'videoControls.noSubtitlesFound' => 'Nenhuma legenda encontrada',
			'videoControls.subtitleDownloaded' => 'Legenda baixada',
			'videoControls.subtitleDownloadFailed' => 'Falha ao baixar legenda',
			'videoControls.searchLanguages' => 'Pesquisar idiomas...',
			'userStatus.admin' => 'Admin',
			'userStatus.restricted' => 'Restrito',
			'userStatus.protected' => 'Protegido',
			'userStatus.current' => 'ATUAL',
			'messages.markedAsWatched' => 'Marcado como assistido',
			'messages.markedAsUnwatched' => 'Marcado como não assistido',
			'messages.markedAsWatchedOffline' => 'Marcado como assistido (será sincronizado quando online)',
			'messages.markedAsUnwatchedOffline' => 'Marcado como não assistido (será sincronizado quando online)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Removido automaticamente: ${title}',
			'messages.removedFromContinueWatching' => 'Removido de Continuar Assistindo',
			'messages.errorLoading' => ({required Object error}) => 'Erro: ${error}',
			'messages.fileInfoNotAvailable' => 'Informações do arquivo não disponíveis',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Erro ao carregar info do arquivo: ${error}',
			'messages.errorLoadingSeries' => 'Erro ao carregar série',
			'messages.errorLoadingSeason' => 'Erro ao carregar temporada',
			'messages.musicNotSupported' => 'Reprodução de música ainda não é suportada',
			'messages.noDescriptionAvailable' => 'Nenhuma descrição disponível',
			'messages.noProfilesAvailable' => 'Nenhum perfil disponível',
			'messages.contactAdminForProfiles' => 'Contate o administrador do servidor para adicionar perfis',
			'messages.unableToDetermineLibrarySection' => 'Não é possível determinar a secção da biblioteca para este item',
			'messages.logsCleared' => 'Logs limpos',
			'messages.logsCopied' => 'Logs copiados para a área de transferência',
			'messages.noLogsAvailable' => 'Nenhum log disponível',
			'messages.libraryScanning' => ({required Object title}) => 'Escaneando "${title}"...',
			'messages.libraryScanStarted' => ({required Object title}) => 'Escaneamento da biblioteca iniciado para "${title}"',
			'messages.libraryScanFailed' => ({required Object error}) => 'Falha ao escanear biblioteca: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => 'Atualizando metadados de "${title}"...',
			'messages.metadataRefreshStarted' => ({required Object title}) => 'Atualização de metadados iniciada para "${title}"',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'Falha ao atualizar metadados: ${error}',
			'messages.logoutConfirm' => 'Tem certeza que deseja sair?',
			'messages.noSeasonsFound' => 'Nenhuma temporada encontrada',
			'messages.noEpisodesFound' => 'Nenhum episódio encontrado na primeira temporada',
			'messages.noEpisodesFoundGeneral' => 'Nenhum episódio encontrado',
			'messages.noResultsFound' => 'Nenhum resultado encontrado',
			'messages.sleepTimerSet' => ({required Object label}) => 'Timer de sono definido para ${label}',
			'messages.noItemsAvailable' => 'Nenhum item disponível',
			'messages.failedToCreatePlayQueueNoItems' => 'Falha ao criar fila de reprodução - sem itens',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Falha ao ${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Alternando para player compatível...',
			'messages.serverLimitTitle' => 'Falha na reprodução',
			'messages.serverLimitBody' => 'O servidor retornou um erro (HTTP 500). Isso geralmente significa que o proprietário do servidor definiu um limite de largura de banda ou transcodificação que está rejeitando sua sessão. Não há nada a ser feito pelo cliente — o proprietário do servidor precisa ajustar as configurações.',
			'messages.logsUploaded' => 'Logs enviados',
			'messages.logsUploadFailed' => 'Falha ao enviar logs',
			'messages.logId' => 'ID do Log',
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
			'subtitlingStyling.bold' => 'Negrito',
			'subtitlingStyling.italic' => 'Itálico',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => 'Configurações avançadas do player de vídeo',
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
			'mpvConfig.confirmDeletePreset' => 'Tem certeza que deseja excluir esta predefinição?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan\nhwdec=auto\n# comment',
			'dialog.confirmAction' => 'Confirmar Ação',
			'profiles.addPlezyProfile' => 'Adicionar perfil Plezy',
			'profiles.switchingProfile' => 'Mudando perfil…',
			'profiles.deleteThisProfileTitle' => 'Excluir este perfil?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => '${displayName} será removido. As conexões não serão afetadas.',
			'profiles.active' => 'Ativo',
			'profiles.manage' => 'Gerenciar',
			'profiles.delete' => 'Excluir',
			'profiles.signOut' => 'Sair',
			'profiles.signOutPlexTitle' => 'Sair do Plex?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => '${displayName} e todos os usuários do Plex Home desta conta serão removidos deste dispositivo. Você pode entrar novamente a qualquer momento.',
			'profiles.signedOutPlex' => 'Saiu do Plex.',
			'profiles.signOutFailed' => 'Falha ao sair.',
			'profiles.sectionTitle' => 'Perfis',
			'profiles.summarySingle' => 'Adicione perfis para mesclar usuários gerenciados e identidades locais',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} perfis · ativo: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} perfis',
			'profiles.removeConnectionTitle' => 'Remover conexão?',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => '${displayName} perderá o acesso a ${connectionLabel}. A conexão em si continua disponível para outros perfis.',
			'profiles.deleteProfileTitle' => 'Excluir perfil?',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => 'Isso remove ${displayName} e todas as suas conexões deste dispositivo. Os servidores Plex/Jellyfin subjacentes não são afetados.',
			'profiles.profileNameLabel' => 'Nome do perfil',
			'profiles.pinProtectionLabel' => 'Proteção por PIN',
			'profiles.pinManagedByPlex' => 'PIN gerenciado pelo Plex. Edite em plex.tv.',
			'profiles.noPinSetEditOnPlex' => 'Nenhum PIN definido. Para exigir um, edite o usuário Home em plex.tv.',
			'profiles.setPin' => 'Definir PIN',
			'profiles.connectionsLabel' => 'Conexões',
			'profiles.add' => 'Adicionar',
			_ => null,
		} ?? switch (path) {
			'profiles.deleteProfileButton' => 'Excluir perfil',
			'profiles.noConnectionsHint' => 'Sem conexões — adicione uma para usar este perfil.',
			'profiles.plexHomeAccount' => 'Conta Plex Home',
			'profiles.connectionDefault' => 'Padrão',
			'profiles.makeDefault' => 'Definir como padrão',
			'profiles.removeConnection' => 'Remover',
			'profiles.borrowAddTo' => ({required Object displayName}) => 'Adicionar a ${displayName}',
			'profiles.borrowExplain' => 'Tome emprestada uma conexão de outro perfil. Perfis de origem protegidos por PIN pedem o PIN antes de compartilhar.',
			'profiles.borrowEmpty' => 'Nada para emprestar ainda.',
			'profiles.borrowEmptySubtitle' => 'Conecte primeiro uma conta Plex ou servidor Jellyfin a outro perfil e volte aqui.',
			'profiles.newProfile' => 'Novo perfil',
			'profiles.profileNameHint' => 'ex.: Visitantes, Crianças, Sala de família',
			'profiles.pinProtectionOptional' => 'Proteção por PIN (opcional)',
			'profiles.pinExplain' => 'PIN de 4 dígitos necessário para alternar para este perfil. Barreira suave — quem puder limpar os dados do app pode contorná-la.',
			'profiles.continueButton' => 'Continuar',
			'profiles.pinsDontMatch' => 'Os PINs não correspondem',
			'connections.sectionTitle' => 'Conexões',
			'connections.addConnection' => 'Adicionar conexão',
			'connections.addConnectionSubtitleNoProfile' => 'Faça login com Plex ou conecte um servidor Jellyfin',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'Adicionar a ${displayName} — conta Plex, servidor Jellyfin ou emprestar de outro perfil',
			'connections.sessionExpiredOne' => ({required Object name}) => 'Sessão expirada para ${name}',
			'connections.sessionExpiredMany' => ({required Object count}) => 'Sessão expirada para ${count} servidores',
			'connections.signInAgain' => 'Entrar novamente',
			'discover.title' => 'Descobrir',
			'discover.switchProfile' => 'Trocar Perfil',
			'discover.noContentAvailable' => 'Nenhum conteúdo disponível',
			'discover.addMediaToLibraries' => 'Adicione mídias às suas bibliotecas',
			'discover.continueWatching' => 'Continuar Assistindo',
			'discover.continueWatchingIn' => ({required Object library}) => 'Continuar assistindo em ${library}',
			'discover.nextUp' => 'A seguir',
			'discover.nextUpIn' => ({required Object library}) => 'A seguir em ${library}',
			'discover.recentlyAdded' => 'Adicionados recentemente',
			'discover.recentlyAddedIn' => ({required Object library}) => 'Adicionados recentemente em ${library}',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.overview' => 'Sinopse',
			'discover.cast' => 'Elenco',
			'discover.extras' => 'Trailers e Extras',
			'discover.studio' => 'Estúdio',
			'discover.rating' => 'Avaliação',
			'discover.movie' => 'Filme',
			'discover.tvShow' => 'Série de TV',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} min restantes',
			'errors.searchFailed' => ({required Object error}) => 'Falha na busca: ${error}',
			'errors.connectionTimeout' => ({required Object context}) => 'Tempo de conexão esgotado ao carregar ${context}',
			'errors.connectionFailed' => 'Não foi possível conectar ao servidor de mídia',
			'errors.failedToLoad' => ({required Object context, required Object error}) => 'Falha ao carregar ${context}: ${error}',
			'errors.noClientAvailable' => 'Nenhum cliente disponível',
			'errors.authenticationFailed' => ({required Object error}) => 'Falha na autenticação: ${error}',
			'errors.couldNotLaunchUrl' => 'Não foi possível abrir a URL de autenticação',
			'errors.pleaseEnterToken' => 'Insira um token',
			'errors.invalidToken' => 'Token inválido',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Falha ao verificar token: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Falha ao trocar para ${displayName}',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => 'Falha ao excluir ${displayName}',
			'errors.failedToRate' => 'Não foi possível atualizar a classificação',
			'libraries.title' => 'Bibliotecas',
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
			'libraries.all' => 'Todos',
			'libraries.clearAll' => 'Limpar Tudo',
			'libraries.scanLibraryConfirm' => ({required Object title}) => 'Tem certeza que deseja escanear "${title}"?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => 'Tem certeza que deseja analisar "${title}"?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => 'Tem certeza que deseja atualizar os metadados de "${title}"?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => 'Tem certeza que deseja esvaziar a lixeira de "${title}"?',
			'libraries.manageLibraries' => 'Gerenciar Bibliotecas',
			'libraries.sort' => 'Ordenar',
			'libraries.sortBy' => 'Ordenar Por',
			'libraries.filters' => 'Filtros',
			'libraries.confirmActionMessage' => 'Tem certeza que deseja realizar esta ação?',
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
			'libraries.groupings.folders' => 'Pastas',
			'libraries.filterCategories.genre' => 'Gênero',
			'libraries.filterCategories.year' => 'Ano',
			'libraries.filterCategories.contentRating' => 'Classificação',
			'libraries.filterCategories.tag' => 'Tag',
			'libraries.sortLabels.title' => 'Título',
			'libraries.sortLabels.dateAdded' => 'Data de adição',
			'libraries.sortLabels.releaseDate' => 'Data de lançamento',
			'libraries.sortLabels.rating' => 'Avaliação',
			'libraries.sortLabels.lastPlayed' => 'Última reprodução',
			'libraries.sortLabels.playCount' => 'Reproduções',
			'libraries.sortLabels.random' => 'Aleatório',
			'libraries.sortLabels.dateShared' => 'Data de compartilhamento',
			'libraries.sortLabels.latestEpisodeAirDate' => 'Última data de exibição do episódio',
			'about.title' => 'Sobre',
			'about.openSourceLicenses' => 'Licenças Open Source',
			'about.versionLabel' => ({required Object version}) => 'Versão ${version}',
			'about.appDescription' => 'Um belo cliente Plex e Jellyfin para Flutter',
			'about.viewLicensesDescription' => 'Ver licenças de bibliotecas de terceiros',
			'serverSelection.allServerConnectionsFailed' => 'Falha ao conectar a qualquer servidor. Verifique sua rede e tente novamente.',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'Nenhum servidor encontrado para ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Falha ao carregar servidores: ${error}',
			'hubDetail.title' => 'Título',
			'hubDetail.releaseYear' => 'Ano de Lançamento',
			'hubDetail.dateAdded' => 'Data de Adição',
			'hubDetail.rating' => 'Avaliação',
			'hubDetail.noItemsFound' => 'Nenhum item encontrado',
			'logs.clearLogs' => 'Limpar Logs',
			'logs.copyLogs' => 'Copiar Logs',
			'logs.uploadLogs' => 'Enviar Logs',
			'licenses.relatedPackages' => 'Pacotes Relacionados',
			'licenses.license' => 'Licença',
			'licenses.licenseNumber' => ({required Object number}) => 'Licença ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} licenças',
			'navigation.libraries' => 'Bibliotecas',
			'navigation.downloads' => 'Downloads',
			'navigation.liveTv' => 'TV ao Vivo',
			'liveTv.title' => 'TV ao Vivo',
			'liveTv.guide' => 'Guia',
			'liveTv.noChannels' => 'Nenhum canal disponível',
			'liveTv.noDvr' => 'Nenhum DVR configurado em nenhum servidor',
			'liveTv.noPrograms' => 'Nenhum dado de programação disponível',
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
			'liveTv.whatsOn' => 'O que Está Passando',
			'liveTv.watchChannel' => 'Assistir Canal',
			'liveTv.favorites' => 'Favoritos',
			'liveTv.reorderFavorites' => 'Reordenar favoritos',
			'liveTv.joinSession' => 'Entrar na sessão em andamento',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'Assistir do início (${minutes} min atrás)',
			'liveTv.watchLive' => 'Assistir ao vivo',
			'liveTv.goToLive' => 'Ir para o ao vivo',
			'liveTv.record' => 'Gravar',
			'liveTv.recordEpisode' => 'Gravar episódio',
			'liveTv.recordSeries' => 'Gravar série',
			'liveTv.recordOptions' => 'Opções de gravação',
			'liveTv.recordings' => 'Gravações',
			'liveTv.scheduledRecordings' => 'Agendadas',
			'liveTv.recordingRules' => 'Regras de gravação',
			'liveTv.noScheduledRecordings' => 'Sem gravações agendadas',
			'liveTv.noRecordingRules' => 'Sem regras de gravação',
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
			'liveTv.loadingRecordings' => 'Carregando gravações...',
			'liveTv.recordingInProgress' => 'Gravando agora',
			'liveTv.recordingsCount' => ({required Object count}) => '${count} agendadas',
			'liveTv.editRule' => 'Editar regra',
			'liveTv.editRuleAction' => 'Editar',
			'liveTv.recordingRuleUpdated' => 'Regra de gravação atualizada',
			'liveTv.guideReloadRequested' => 'Atualização da guia solicitada',
			'liveTv.rulesProcessRequested' => 'Reavaliação de regras solicitada',
			'liveTv.recordShow' => 'Gravar programa',
			'collections.title' => 'Coleções',
			'collections.collection' => 'Coleção',
			'collections.empty' => 'A coleção está vazia',
			'collections.unknownLibrarySection' => 'Não é possível excluir: Seção de biblioteca desconhecida',
			'collections.deleteCollection' => 'Excluir Coleção',
			'collections.deleteConfirm' => ({required Object title}) => 'Tem certeza que deseja excluir "${title}"? Esta ação não pode ser desfeita.',
			'collections.deleted' => 'Coleção excluída',
			'collections.deleteFailed' => 'Falha ao excluir coleção',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Falha ao excluir coleção: ${error}',
			'collections.failedToLoadItems' => ({required Object error}) => 'Falha ao carregar itens da coleção: ${error}',
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
			'playlists.deleteMessage' => ({required Object name}) => 'Tem certeza que deseja excluir "${name}"?',
			'playlists.created' => 'Playlist criada',
			'playlists.deleted' => 'Playlist excluída',
			'playlists.itemAdded' => 'Adicionado à playlist',
			'playlists.itemRemoved' => 'Removido da playlist',
			'playlists.selectPlaylist' => 'Selecionar Playlist',
			'playlists.errorCreating' => 'Falha ao criar playlist',
			'playlists.errorDeleting' => 'Falha ao excluir playlist',
			'playlists.errorLoading' => 'Falha ao carregar playlists',
			'playlists.errorAdding' => 'Falha ao adicionar à playlist',
			'playlists.errorReordering' => 'Falha ao reordenar item da playlist',
			'playlists.errorRemoving' => 'Falha ao remover da playlist',
			'watchTogether.title' => 'Assistir Juntos',
			'watchTogether.description' => 'Assista conteúdo sincronizado com amigos e família',
			'watchTogether.createSession' => 'Criar Sessão',
			'watchTogether.creating' => 'Criando...',
			'watchTogether.joinSession' => 'Entrar na Sessão',
			'watchTogether.joining' => 'Entrando...',
			'watchTogether.controlMode' => 'Modo de Controle',
			'watchTogether.controlModeQuestion' => 'Quem pode controlar a reprodução?',
			'watchTogether.hostOnly' => 'Apenas o Anfitrião',
			'watchTogether.anyone' => 'Qualquer pessoa',
			'watchTogether.hostingSession' => 'Hospedando Sessão',
			'watchTogether.inSession' => 'Em Sessão',
			'watchTogether.sessionCode' => 'Código da Sessão',
			'watchTogether.hostControlsPlayback' => 'Anfitrião controla a reprodução',
			'watchTogether.anyoneCanControl' => 'Qualquer pessoa pode controlar a reprodução',
			'watchTogether.hostControls' => 'Controle do anfitrião',
			'watchTogether.anyoneControls' => 'Controle de todos',
			'watchTogether.participants' => 'Participantes',
			'watchTogether.host' => 'Anfitrião',
			'watchTogether.hostBadge' => 'HOST',
			'watchTogether.youAreHost' => 'Você é o anfitrião',
			'watchTogether.watchingWithOthers' => 'Assistindo com outros',
			'watchTogether.endSession' => 'Encerrar Sessão',
			'watchTogether.leaveSession' => 'Sair da Sessão',
			'watchTogether.endSessionQuestion' => 'Encerrar Sessão?',
			'watchTogether.leaveSessionQuestion' => 'Sair da Sessão?',
			'watchTogether.endSessionConfirm' => 'Isso encerrará a sessão para todos os participantes.',
			'watchTogether.leaveSessionConfirm' => 'Você será removido da sessão.',
			'watchTogether.endSessionConfirmOverlay' => 'Isso encerrará a sessão de visualização para todos os participantes.',
			'watchTogether.leaveSessionConfirmOverlay' => 'Você será desconectado da sessão de visualização.',
			'watchTogether.end' => 'Encerrar',
			'watchTogether.leave' => 'Sair',
			'watchTogether.syncing' => 'Sincronizando...',
			'watchTogether.joinWatchSession' => 'Entrar na Sessão',
			'watchTogether.enterCodeHint' => 'Insira o código de 5 caracteres',
			'watchTogether.pasteFromClipboard' => 'Colar da área de transferência',
			'watchTogether.pleaseEnterCode' => 'Insira um código de sessão',
			'watchTogether.codeMustBe5Chars' => 'O código da sessão deve ter 5 caracteres',
			'watchTogether.joinInstructions' => 'Insira o código da sessão compartilhado pelo anfitrião para entrar na sessão.',
			'watchTogether.failedToCreate' => 'Falha ao criar sessão',
			'watchTogether.failedToJoin' => 'Falha ao entrar na sessão',
			'watchTogether.sessionCodeCopied' => 'Código da sessão copiado para a área de transferência',
			'watchTogether.relayUnreachable' => 'O servidor de retransmissão está inacessível. Isso pode ser causado pelo seu provedor bloqueando a conexão. Você ainda pode tentar, mas o Assistir Juntos pode não funcionar.',
			'watchTogether.reconnectingToHost' => 'Reconectando ao anfitrião...',
			'watchTogether.currentPlayback' => 'Reprodução Atual',
			'watchTogether.joinCurrentPlayback' => 'Entrar na Reprodução Atual',
			'watchTogether.joinCurrentPlaybackDescription' => 'Voltar ao que o anfitrião está assistindo agora',
			'watchTogether.failedToOpenCurrentPlayback' => 'Falha ao abrir reprodução atual',
			'watchTogether.participantJoined' => ({required Object name}) => '${name} entrou',
			'watchTogether.participantLeft' => ({required Object name}) => '${name} saiu',
			'watchTogether.participantPaused' => ({required Object name}) => '${name} pausou',
			'watchTogether.participantResumed' => ({required Object name}) => '${name} retomou',
			'watchTogether.participantSeeked' => ({required Object name}) => '${name} avançou',
			'watchTogether.participantBuffering' => ({required Object name}) => '${name} está carregando',
			'watchTogether.waitingForParticipants' => 'Aguardando outros carregarem...',
			'watchTogether.recentRooms' => 'Salas recentes',
			'watchTogether.renameRoom' => 'Renomear sala',
			'watchTogether.removeRoom' => 'Remover',
			'watchTogether.guestSwitchUnavailable' => 'Não foi possível trocar — servidor indisponível para sincronização',
			'watchTogether.guestSwitchFailed' => 'Não foi possível trocar — conteúdo não encontrado neste servidor',
			'downloads.title' => 'Downloads',
			'downloads.manage' => 'Gerenciar',
			'downloads.tvShows' => 'Séries de TV',
			'downloads.movies' => 'Filmes',
			'downloads.noDownloads' => 'Nenhum download ainda',
			'downloads.noDownloadsDescription' => 'Conteúdo baixado aparecerá aqui para visualização offline',
			'downloads.downloadNow' => 'Baixar',
			'downloads.deleteDownload' => 'Excluir download',
			'downloads.retryDownload' => 'Tentar download novamente',
			'downloads.downloadQueued' => 'Download na fila',
			'downloads.serverErrorBitrate' => 'Erro do servidor — o arquivo pode exceder o limite de bitrate de streaming remoto',
			'downloads.episodesQueued' => ({required Object count}) => '${count} episódios na fila de download',
			'downloads.downloadDeleted' => 'Download excluído',
			'downloads.deleteConfirm' => ({required Object title}) => 'Tem certeza que deseja excluir "${title}"? Isso removerá o arquivo baixado do seu dispositivo.',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Excluindo ${title}... (${current} de ${total})',
			'downloads.deleting' => 'Excluindo...',
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
			'downloads.nextNUnwatched' => ({required Object count}) => 'Próximos ${count} não assistidos',
			'downloads.customAmount' => 'Quantidade personalizada...',
			'downloads.howManyEpisodes' => 'Quantos episódios?',
			'downloads.itemsQueued' => ({required Object count}) => '${count} itens na fila de download',
			'downloads.keepSynced' => 'Manter sincronizado',
			'downloads.downloadOnce' => 'Baixar uma vez',
			'downloads.keepNUnwatched' => ({required Object count}) => 'Manter ${count} não assistidos',
			'downloads.editSyncRule' => 'Editar regra de sincronização',
			'downloads.removeSyncRule' => 'Remover regra de sincronização',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => 'Parar de sincronizar "${title}"? Os episódios baixados serão mantidos.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'Regra de sincronização criada — mantendo ${count} episódios não assistidos',
			'downloads.syncRuleUpdated' => 'Regra de sincronização atualizada',
			'downloads.syncRuleRemoved' => 'Regra de sincronização removida',
			'downloads.syncedNewEpisodes' => ({required Object count, required Object title}) => '${count} novos episódios sincronizados para ${title}',
			'downloads.activeSyncRules' => 'Regras de sincronização',
			'downloads.noSyncRules' => 'Nenhuma regra de sincronização',
			'downloads.manageSyncRule' => 'Gerenciar sincronização',
			'downloads.editEpisodeCount' => 'Número de episódios',
			'downloads.editSyncFilter' => 'Filtro de sincronização',
			'downloads.syncAllItems' => 'Sincronizando todos os itens',
			'downloads.syncUnwatchedItems' => 'Sincronizando itens não vistos',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'Servidor: ${server} • ${status}',
			'downloads.syncRuleAvailable' => 'Disponível',
			'downloads.syncRuleOffline' => 'Offline',
			'downloads.syncRuleSignInRequired' => 'Início de sessão necessário',
			'downloads.syncRuleNotAvailableForProfile' => 'Indisponível para o perfil atual',
			'downloads.syncRuleUnknownServer' => 'Servidor desconhecido',
			'downloads.syncRuleListCreated' => 'Regra de sincronização criada',
			'shaders.title' => 'Shaders',
			'shaders.noShaderDescription' => 'Sem aprimoramento de vídeo',
			'shaders.nvscalerDescription' => 'Escalonamento de imagem NVIDIA para vídeo mais nítido',
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
			'companionRemote.title' => 'Controle Remoto',
			'companionRemote.connectedTo' => ({required Object name}) => 'Conectado a ${name}',
			'companionRemote.session.startingServer' => 'A iniciar servidor remoto...',
			'companionRemote.session.failedToCreate' => 'Falha ao iniciar o servidor remoto:',
			'companionRemote.session.hostAddress' => 'Endereço do host',
			'companionRemote.session.connected' => 'Conectado',
			'companionRemote.session.serverRunning' => 'Servidor remoto ativo',
			'companionRemote.session.serverStopped' => 'Servidor remoto parado',
			'companionRemote.session.serverRunningDescription' => 'Dispositivos móveis na sua rede podem descobrir e conectar-se a esta aplicação',
			'companionRemote.session.serverStoppedDescription' => 'Inicie o servidor para permitir que dispositivos móveis se conectem',
			'companionRemote.session.usePhoneToControl' => 'Use o seu dispositivo móvel para controlar esta aplicação',
			'companionRemote.session.startServer' => 'Iniciar servidor',
			'companionRemote.session.stopServer' => 'Parar servidor',
			'companionRemote.session.minimize' => 'Minimizar',
			'companionRemote.pairing.discoveryDescription' => 'Dispositivos na sua rede a executar Plezy com a mesma conta Plex aparecerão automaticamente',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'A conectar...',
			'companionRemote.pairing.searchingForDevices' => 'A procurar dispositivos...',
			'companionRemote.pairing.noDevicesFound' => 'Nenhum dispositivo encontrado na sua rede',
			'companionRemote.pairing.noDevicesHint' => 'Certifique-se de que o Plezy está aberto no seu desktop e que ambos os dispositivos estão na mesma rede WiFi',
			'companionRemote.pairing.availableDevices' => 'Dispositivos disponíveis',
			'companionRemote.pairing.manualConnection' => 'Conexão manual',
			'companionRemote.pairing.cryptoInitFailed' => 'Não foi possível inicializar a conexão segura. Certifique-se de que está conectado a uma conta Plex.',
			'companionRemote.pairing.validationHostRequired' => 'Introduza o endereço do host',
			'companionRemote.pairing.validationHostFormat' => 'O formato deve ser IP:porta (ex. 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'Tempo de conexão esgotado. Certifique-se de que ambos os dispositivos estão na mesma rede.',
			'companionRemote.pairing.sessionNotFound' => 'Dispositivo não encontrado. Certifique-se de que o Plezy está em execução no host.',
			'companionRemote.pairing.authFailed' => 'Autenticação falhou. Certifique-se de que ambos os dispositivos usam a mesma conta Plex.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Falha ao conectar: ${error}',
			'companionRemote.remote.disconnectConfirm' => 'Deseja desconectar da sessão remota?',
			'companionRemote.remote.reconnecting' => 'Reconectando...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Tentativa ${current} de 5',
			'companionRemote.remote.retryNow' => 'Tentar Agora',
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
			'companionRemote.remote.fullscreen' => 'Tela Cheia',
			'companionRemote.remote.subtitles' => 'Legendas',
			'companionRemote.remote.audio' => 'Áudio',
			'companionRemote.remote.searchHint' => 'Buscar no desktop...',
			'videoSettings.playbackSettings' => 'Configurações de Reprodução',
			'videoSettings.playbackSpeed' => 'Velocidade de Reprodução',
			'videoSettings.sleepTimer' => 'Timer de Sono',
			'videoSettings.audioSync' => 'Sincronia de Áudio',
			'videoSettings.subtitleSync' => 'Sincronia de Legendas',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.audioOutput' => 'Saída de Áudio',
			'videoSettings.performanceOverlay' => 'Overlay de Desempenho',
			'videoSettings.audioPassthrough' => 'Passagem de Áudio',
			'videoSettings.audioNormalization' => 'Normalizar Volume',
			'externalPlayer.title' => 'Player Externo',
			'externalPlayer.useExternalPlayer' => 'Usar Player Externo',
			'externalPlayer.useExternalPlayerDescription' => 'Abrir vídeos em um app externo em vez do player integrado',
			'externalPlayer.selectPlayer' => 'Selecionar Player',
			'externalPlayer.customPlayers' => 'Players Personalizados',
			'externalPlayer.systemDefault' => 'Padrão do Sistema',
			'externalPlayer.addCustomPlayer' => 'Adicionar Player Personalizado',
			'externalPlayer.playerName' => 'Nome do Player',
			'externalPlayer.playerCommand' => 'Comando',
			'externalPlayer.playerPackage' => 'Nome do Pacote',
			'externalPlayer.playerUrlScheme' => 'Esquema de URL',
			'externalPlayer.off' => 'Desativado',
			'externalPlayer.launchFailed' => 'Falha ao abrir player externo',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} não está instalado',
			'externalPlayer.playInExternalPlayer' => 'Reproduzir no Player Externo',
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
			'metadataEdit.tagline' => 'Tagline',
			'metadataEdit.summary' => 'Sinopse',
			'metadataEdit.poster' => 'Poster',
			'metadataEdit.background' => 'Plano de Fundo',
			'metadataEdit.logo' => 'Logo',
			'metadataEdit.squareArt' => 'Imagem Quadrada',
			'metadataEdit.selectPoster' => 'Selecionar Poster',
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
			_ => null,
		} ?? switch (path) {
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
			'metadataEdit.style' => 'Estilo',
			'metadataEdit.mood' => 'Humor',
			'matchScreen.match' => 'Associar...',
			'matchScreen.fixMatch' => 'Corrigir correspondência...',
			'matchScreen.unmatch' => 'Desassociar',
			'matchScreen.unmatchConfirm' => 'Limpar a correspondência atual deste item? O Plex vai tratá-lo como não correspondido até que o associe novamente.',
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
			'trakt.disconnectConfirm' => 'Desconectar conta do Trakt?',
			'trakt.disconnectConfirmBody' => 'O Plezy deixará de enviar eventos de reprodução ao Trakt. Você pode reconectar a qualquer momento.',
			'trakt.scrobble' => 'Scrobbling em tempo real',
			'trakt.scrobbleDescription' => 'Envia eventos de reprodução, pausa e parada ao Trakt durante a exibição.',
			'trakt.watchedSync' => 'Sincronizar status de assistido',
			'trakt.watchedSyncDescription' => 'Ao marcar itens como assistidos no Plezy, eles também serão marcados no Trakt.',
			'trackers.title' => 'Rastreadores',
			'trackers.hubSubtitle' => 'Mantenha seu progresso sincronizado com Trakt e outros serviços.',
			'trackers.notConnected' => 'Não conectado',
			'trackers.connectedAs' => ({required Object username}) => 'Conectado como @${username}',
			'trackers.scrobble' => 'Registrar progresso automaticamente',
			'trackers.scrobbleDescription' => 'Atualiza sua lista quando você termina um episódio ou filme.',
			'trackers.disconnectConfirm' => ({required Object service}) => 'Desconectar ${service}?',
			'trackers.disconnectConfirmBody' => ({required Object service}) => 'Plezy deixará de atualizar sua lista do ${service}. Você pode reconectar a qualquer momento.',
			'trackers.connectFailed' => ({required Object service}) => 'Não foi possível conectar ao ${service}. Tente novamente.',
			'trackers.services.mal' => 'MyAnimeList',
			'trackers.services.anilist' => 'AniList',
			'trackers.services.simkl' => 'Simkl',
			'trackers.deviceCode.title' => ({required Object service}) => 'Ativar Plezy no ${service}',
			'trackers.deviceCode.body' => ({required Object url}) => 'Acesse ${url} e insira este código:',
			'trackers.deviceCode.openToActivate' => ({required Object service}) => 'Abrir ${service} para ativar',
			'trackers.deviceCode.waitingForAuthorization' => 'Aguardando autorização…',
			'trackers.deviceCode.codeCopied' => 'Código copiado',
			'trackers.oauthProxy.title' => ({required Object service}) => 'Entrar no ${service}',
			'trackers.oauthProxy.body' => 'Escaneie este código QR com o celular, ou abra o URL abaixo em qualquer dispositivo com navegador.',
			'trackers.oauthProxy.openToSignIn' => ({required Object service}) => 'Abrir ${service} para entrar',
			'trackers.oauthProxy.urlCopied' => 'URL copiado',
			'trackers.libraryFilter.title' => 'Filtro de bibliotecas',
			'trackers.libraryFilter.subtitleAllSyncing' => 'Sincronizando todas as bibliotecas',
			'trackers.libraryFilter.subtitleNoneSyncing' => 'Nada a sincronizar',
			'trackers.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} bloqueadas',
			'trackers.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} permitidas',
			'trackers.libraryFilter.mode' => 'Modo de filtro',
			'trackers.libraryFilter.modeBlacklist' => 'Lista negra',
			'trackers.libraryFilter.modeWhitelist' => 'Lista branca',
			'trackers.libraryFilter.modeHintBlacklist' => 'Sincronizar todas as bibliotecas exceto as marcadas abaixo.',
			'trackers.libraryFilter.modeHintWhitelist' => 'Sincronizar apenas as bibliotecas marcadas abaixo.',
			'trackers.libraryFilter.libraries' => 'Bibliotecas',
			'trackers.libraryFilter.noLibraries' => 'Nenhuma biblioteca disponível',
			'addServer.addJellyfinTitle' => 'Adicionar servidor Jellyfin',
			'addServer.jellyfinUrlIntro' => 'Insira a URL do seu servidor Jellyfin — ex.: `https://jellyfin.example.com`. Você pode entrar em seguida.',
			'addServer.serverUrl' => 'URL do servidor',
			'addServer.findServer' => 'Encontrar servidor',
			'addServer.username' => 'Usuário',
			'addServer.password' => 'Senha',
			'addServer.signIn' => 'Entrar',
			'addServer.change' => 'Alterar',
			'addServer.required' => 'Obrigatório',
			'addServer.couldNotReachServer' => ({required Object error}) => 'Não foi possível conectar ao servidor: ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'Falha ao entrar: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Quick Connect falhou: ${error}',
			'addServer.addPlexTitle' => 'Entrar com Plex',
			'addServer.plexAuthIntro' => 'Escolha como entrar no Plex. O fluxo do navegador abre plex.tv onde você confirma a conexão; a opção QR é prática para TV / dispositivos remotos.',
			'addServer.plexQRPrompt' => 'Escaneie este código QR para entrar.',
			'addServer.waitingForPlexConfirmation' => 'Aguardando o plex.tv confirmar o login…',
			'addServer.pinExpired' => 'O PIN expirou antes do login. Tente novamente.',
			'addServer.duplicatePlexAccount' => 'Este dispositivo já está conectado a uma conta Plex. Saia nas configurações para trocar de conta.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'Falha ao registrar a conta: ${error}',
			'addServer.enterJellyfinUrlError' => 'Insira a URL do seu servidor Jellyfin',
			'addServer.addConnectionTitle' => 'Adicionar conexão',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => 'Adicionar a ${name}',
			'addServer.addConnectionIntroGlobal' => 'Adicione outro servidor de mídia. Você pode misturar contas Plex e servidores Jellyfin — itens de cada backend conectado aparecem juntos na tela inicial.',
			'addServer.addConnectionIntroScoped' => 'Adicione um novo servidor ou pegue um emprestado de outro perfil.',
			'addServer.signInWithPlexCard' => 'Entrar com Plex',
			'addServer.signInWithPlexCardSubtitle' => 'Autorize este dispositivo na sua conta Plex. Servidores compartilhados com a conta vêm junto automaticamente.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Autorize uma nova conta Plex. Seus usuários Home aparecem como perfis.',
			'addServer.connectToJellyfinCard' => 'Conectar ao Jellyfin',
			'addServer.connectToJellyfinCardSubtitle' => 'Insira a URL do seu servidor Jellyfin e entre com usuário + senha (Quick Connect em breve).',
			'addServer.connectToJellyfinCardSubtitleScoped' => ({required Object name}) => 'Entre em um servidor Jellyfin. Vinculado a ${name}.',
			'addServer.borrowFromAnotherProfile' => 'Pegar emprestado de outro perfil',
			'addServer.borrowFromAnotherProfileSubtitle' => 'Reutilize uma conexão já associada a outro perfil. Perfis de origem protegidos por PIN solicitarão o PIN.',
			_ => null,
		};
	}
}
