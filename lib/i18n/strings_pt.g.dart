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
class TranslationsPt with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsPt({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.pt,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <pt>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

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
	@override late final _TranslationsPinEntryPt pinEntry = _TranslationsPinEntryPt._(_root);
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
}

// Path: app
class _TranslationsAppPt implements TranslationsAppEn {
	_TranslationsAppPt._(this._root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plezy';
}

// Path: auth
class _TranslationsAuthPt implements TranslationsAuthEn {
	_TranslationsAuthPt._(this._root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Entrar com Plex';
	@override String get showQRCode => 'Mostrar QR Code';
	@override String get authenticate => 'Autenticar';
	@override String get authenticationTimeout => 'A autenticação expirou. Tente novamente.';
	@override String get scanQRToSignIn => 'Escaneie este QR code para entrar';
	@override String get waitingForAuth => 'Aguardando autenticação...\nConclua o login no seu navegador.';
	@override String get useBrowser => 'Usar navegador';
}

// Path: common
class _TranslationsCommonPt implements TranslationsCommonEn {
	_TranslationsCommonPt._(this._root);

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
	@override String get remove => 'Remover';
	@override String get paste => 'Colar';
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
	@override String get loading => 'Carregando...';
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
}

// Path: screens
class _TranslationsScreensPt implements TranslationsScreensEn {
	_TranslationsScreensPt._(this._root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Licenças';
	@override String get switchProfile => 'Trocar Perfil';
	@override String get subtitleStyling => 'Estilo de Legendas';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Logs';
}

// Path: update
class _TranslationsUpdatePt implements TranslationsUpdateEn {
	_TranslationsUpdatePt._(this._root);

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
class _TranslationsSettingsPt implements TranslationsSettingsEn {
	_TranslationsSettingsPt._(this._root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Configurações';
	@override String get language => 'Idioma';
	@override String get theme => 'Tema';
	@override String get appearance => 'Aparência';
	@override String get videoPlayback => 'Reprodução de Vídeo';
	@override String get advanced => 'Avançado';
	@override String get episodePosterMode => 'Estilo do Poster de Episódio';
	@override String get seriesPoster => 'Poster da Série';
	@override String get seriesPosterDescription => 'Mostrar o poster da série para todos os episódios';
	@override String get seasonPoster => 'Poster da Temporada';
	@override String get seasonPosterDescription => 'Mostrar o poster específico da temporada para episódios';
	@override String get episodeThumbnail => 'Miniatura do Episódio';
	@override String get episodeThumbnailDescription => 'Mostrar miniaturas 16:9 de captura de tela do episódio';
	@override String get showHeroSectionDescription => 'Exibir carrossel de conteúdo em destaque na tela inicial';
	@override String get secondsLabel => 'Segundos';
	@override String get minutesLabel => 'Minutos';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => 'Insira a duração (${min}-${max})';
	@override String get systemTheme => 'Sistema';
	@override String get systemThemeDescription => 'Seguir configurações do sistema';
	@override String get lightTheme => 'Claro';
	@override String get darkTheme => 'Escuro';
	@override String get oledTheme => 'OLED';
	@override String get oledThemeDescription => 'Preto puro para telas OLED';
	@override String get libraryDensity => 'Densidade da Biblioteca';
	@override String get compact => 'Compacto';
	@override String get compactDescription => 'Cards menores, mais itens visíveis';
	@override String get normal => 'Normal';
	@override String get normalDescription => 'Tamanho padrão';
	@override String get comfortable => 'Confortável';
	@override String get comfortableDescription => 'Cards maiores, menos itens visíveis';
	@override String get viewMode => 'Modo de Visualização';
	@override String get gridView => 'Grade';
	@override String get gridViewDescription => 'Exibir itens em layout de grade';
	@override String get listView => 'Lista';
	@override String get listViewDescription => 'Exibir itens em layout de lista';
	@override String get showHeroSection => 'Mostrar Seção de Destaque';
	@override String get useGlobalHubs => 'Usar Layout Plex Home';
	@override String get useGlobalHubsDescription => 'Mostrar hubs da página inicial como o cliente oficial Plex. Quando desativado, mostra recomendações por biblioteca.';
	@override String get showServerNameOnHubs => 'Mostrar Nome do Servidor nos Hubs';
	@override String get showServerNameOnHubsDescription => 'Sempre exibir o nome do servidor nos títulos dos hubs. Quando desativado, mostra apenas para nomes duplicados.';
	@override String get alwaysKeepSidebarOpen => 'Manter Barra Lateral Sempre Aberta';
	@override String get alwaysKeepSidebarOpenDescription => 'A barra lateral fica expandida e a área de conteúdo se ajusta';
	@override String get showUnwatchedCount => 'Mostrar Contagem de Não Assistidos';
	@override String get showUnwatchedCountDescription => 'Exibir contagem de episódios não assistidos em séries e temporadas';
	@override String get hideSpoilers => 'Ocultar Spoilers de Episódios Não Assistidos';
	@override String get hideSpoilersDescription => 'Desfocar miniaturas e ocultar descrições de episódios que você ainda não assistiu';
	@override String get playerBackend => 'Backend do Player';
	@override String get exoPlayer => 'ExoPlayer (Recomendado)';
	@override String get exoPlayerDescription => 'Player nativo Android com melhor suporte a hardware';
	@override String get mpv => 'mpv';
	@override String get mpvDescription => 'Player avançado com mais recursos e suporte a legendas ASS';
	@override String get hardwareDecoding => 'Decodificação por Hardware';
	@override String get hardwareDecodingDescription => 'Usar aceleração por hardware quando disponível';
	@override String get bufferSize => 'Tamanho do Buffer';
	@override String bufferSizeMB({required Object size}) => '${size}MB';
	@override String get bufferSizeAuto => 'Automático (Recomendado)';
	@override String bufferSizeWarning({required Object heap, required Object size}) => 'Seu dispositivo tem ${heap}MB de memória. Um buffer de ${size}MB pode causar problemas de reprodução.';
	@override String get subtitleStyling => 'Estilo de Legendas';
	@override String get subtitleStylingDescription => 'Personalizar aparência das legendas';
	@override String get smallSkipDuration => 'Duração do Avanço Curto';
	@override String get largeSkipDuration => 'Duração do Avanço Longo';
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
	@override String get shortcutsReset => 'Atalhos redefinidos para o padrão';
	@override String get about => 'Sobre';
	@override String get aboutDescription => 'Informações do app e licenças';
	@override String get updates => 'Atualizações';
	@override String get updateAvailable => 'Atualização Disponível';
	@override String get checkForUpdates => 'Verificar Atualizações';
	@override String get validationErrorEnterNumber => 'Insira um número válido';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'A duração deve ser entre ${min} e ${max} ${unit}';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Atalho já atribuído a ${action}';
	@override String shortcutUpdated({required Object action}) => 'Atalho atualizado para ${action}';
	@override String get autoSkip => 'Pular Automaticamente';
	@override String get autoSkipIntro => 'Pular Intro Automaticamente';
	@override String get autoSkipIntroDescription => 'Pular marcadores de intro automaticamente após alguns segundos';
	@override String get autoSkipCredits => 'Pular Créditos Automaticamente';
	@override String get autoSkipCreditsDescription => 'Pular créditos automaticamente e reproduzir próximo episódio';
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
	@override String get cellularDownloadBlocked => 'Downloads estão desativados em dados móveis. Conecte ao WiFi ou altere a configuração.';
	@override String get maxVolume => 'Volume Máximo';
	@override String get maxVolumeDescription => 'Permitir aumento de volume acima de 100% para mídias silenciosas';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Mostrar o que você está assistindo no Discord';
	@override String get autoPip => 'Picture-in-Picture Automático';
	@override String get autoPipDescription => 'Entrar automaticamente em picture-in-picture ao sair do app durante a reprodução';
	@override String get matchContentFrameRate => 'Corresponder Taxa de Quadros do Conteúdo';
	@override String get matchContentFrameRateDescription => 'Ajustar a taxa de atualização da tela para corresponder ao conteúdo de vídeo, reduzindo tremulação e economizando bateria';
	@override String get tunneledPlayback => 'Reprodução Tunelizada';
	@override String get tunneledPlaybackDescription => 'Usar tunelamento de vídeo acelerado por hardware. Desative se você vir uma tela preta com áudio em conteúdo HDR';
	@override String get requireProfileSelectionOnOpen => 'Pedir perfil ao abrir o app';
	@override String get requireProfileSelectionOnOpenDescription => 'Mostrar seleção de perfil toda vez que o app for aberto';
	@override String get confirmExitOnBack => 'Confirmar antes de sair';
	@override String get confirmExitOnBackDescription => 'Mostrar diálogo de confirmação ao pressionar voltar para sair do app';
	@override String get showNavBarLabels => 'Mostrar Rótulos da Barra de Navegação';
	@override String get showNavBarLabelsDescription => 'Exibir rótulos de texto sob os ícones da barra de navegação';
}

// Path: search
class _TranslationsSearchPt implements TranslationsSearchEn {
	_TranslationsSearchPt._(this._root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Buscar filmes, séries, músicas...';
	@override String get tryDifferentTerm => 'Tente um termo de busca diferente';
	@override String get searchYourMedia => 'Buscar suas mídias';
	@override String get enterTitleActorOrKeyword => 'Insira um título, ator ou palavra-chave';
}

// Path: hotkeys
class _TranslationsHotkeysPt implements TranslationsHotkeysEn {
	_TranslationsHotkeysPt._(this._root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Definir Atalho para ${actionName}';
	@override String get clearShortcut => 'Limpar atalho';
	@override late final _TranslationsHotkeysActionsPt actions = _TranslationsHotkeysActionsPt._(_root);
}

// Path: pinEntry
class _TranslationsPinEntryPt implements TranslationsPinEntryEn {
	_TranslationsPinEntryPt._(this._root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get enterPin => 'Inserir PIN';
	@override String get showPin => 'Mostrar PIN';
	@override String get hidePin => 'Ocultar PIN';
}

// Path: fileInfo
class _TranslationsFileInfoPt implements TranslationsFileInfoEn {
	_TranslationsFileInfoPt._(this._root);

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
	@override String get path => 'Caminho';
	@override String get size => 'Tamanho';
	@override String get container => 'Container';
	@override String get duration => 'Duração';
	@override String get optimizedForStreaming => 'Otimizado para Streaming';
	@override String get has64bitOffsets => 'Offsets de 64 bits';
}

// Path: mediaMenu
class _TranslationsMediaMenuPt implements TranslationsMediaMenuEn {
	_TranslationsMediaMenuPt._(this._root);

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
}

// Path: accessibility
class _TranslationsAccessibilityPt implements TranslationsAccessibilityEn {
	_TranslationsAccessibilityPt._(this._root);

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
class _TranslationsTooltipsPt implements TranslationsTooltipsEn {
	_TranslationsTooltipsPt._(this._root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Reprodução aleatória';
	@override String get playTrailer => 'Reproduzir trailer';
	@override String get markAsWatched => 'Marcar como assistido';
	@override String get markAsUnwatched => 'Marcar como não assistido';
}

// Path: videoControls
class _TranslationsVideoControlsPt implements TranslationsVideoControlsEn {
	_TranslationsVideoControlsPt._(this._root);

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
	@override String get sleepTimerCompleted => 'Timer de sono concluído - reprodução pausada';
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
	@override String get audioTrackButton => 'Faixas de áudio';
	@override String get subtitlesButton => 'Legendas';
	@override String get tracksButton => 'Áudio e Legendas';
	@override String get chaptersButton => 'Capítulos';
	@override String get versionsButton => 'Versões do vídeo';
	@override String get pipButton => 'Modo Picture-in-Picture';
	@override String get aspectRatioButton => 'Proporção';
	@override String get ambientLighting => 'Iluminação ambiente';
	@override String get ambientLightingOn => 'Ativar iluminação ambiente';
	@override String get ambientLightingOff => 'Desativar iluminação ambiente';
	@override String get fullscreenButton => 'Entrar em tela cheia';
	@override String get exitFullscreenButton => 'Sair da tela cheia';
	@override String get alwaysOnTopButton => 'Sempre no topo';
	@override String get rotationLockButton => 'Travar rotação';
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
}

// Path: userStatus
class _TranslationsUserStatusPt implements TranslationsUserStatusEn {
	_TranslationsUserStatusPt._(this._root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get admin => 'Admin';
	@override String get restricted => 'Restrito';
	@override String get protected => 'Protegido';
	@override String get current => 'ATUAL';
}

// Path: messages
class _TranslationsMessagesPt implements TranslationsMessagesEn {
	_TranslationsMessagesPt._(this._root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Marcado como assistido';
	@override String get markedAsUnwatched => 'Marcado como não assistido';
	@override String get markedAsWatchedOffline => 'Marcado como assistido (será sincronizado quando online)';
	@override String get markedAsUnwatchedOffline => 'Marcado como não assistido (será sincronizado quando online)';
	@override String get removedFromContinueWatching => 'Removido de Continuar Assistindo';
	@override String errorLoading({required Object error}) => 'Erro: ${error}';
	@override String get fileInfoNotAvailable => 'Informações do arquivo não disponíveis';
	@override String errorLoadingFileInfo({required Object error}) => 'Erro ao carregar info do arquivo: ${error}';
	@override String get errorLoadingSeries => 'Erro ao carregar série';
	@override String get errorLoadingSeason => 'Erro ao carregar temporada';
	@override String get musicNotSupported => 'Reprodução de música ainda não é suportada';
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
	@override String get logsUploaded => 'Logs enviados';
	@override String get logsUploadFailed => 'Falha ao enviar logs';
	@override String get logId => 'ID do Log';
}

// Path: subtitlingStyling
class _TranslationsSubtitlingStylingPt implements TranslationsSubtitlingStylingEn {
	_TranslationsSubtitlingStylingPt._(this._root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get stylingOptions => 'Opções de Estilo';
	@override String get fontSize => 'Tamanho da Fonte';
	@override String get textColor => 'Cor do Texto';
	@override String get borderSize => 'Tamanho da Borda';
	@override String get borderColor => 'Cor da Borda';
	@override String get backgroundOpacity => 'Opacidade do Fundo';
	@override String get backgroundColor => 'Cor de Fundo';
	@override String get position => 'Posição';
}

// Path: mpvConfig
class _TranslationsMpvConfigPt implements TranslationsMpvConfigEn {
	_TranslationsMpvConfigPt._(this._root);

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
class _TranslationsDialogPt implements TranslationsDialogEn {
	_TranslationsDialogPt._(this._root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Confirmar Ação';
}

// Path: discover
class _TranslationsDiscoverPt implements TranslationsDiscoverEn {
	_TranslationsDiscoverPt._(this._root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Descobrir';
	@override String get switchProfile => 'Trocar Perfil';
	@override String get noContentAvailable => 'Nenhum conteúdo disponível';
	@override String get addMediaToLibraries => 'Adicione mídias às suas bibliotecas';
	@override String get continueWatching => 'Continuar Assistindo';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get overview => 'Sinopse';
	@override String get cast => 'Elenco';
	@override String get extras => 'Trailers e Extras';
	@override String get seasons => 'Temporadas';
	@override String get studio => 'Estúdio';
	@override String get rating => 'Avaliação';
	@override String episodeCount({required Object count}) => '${count} episódios';
	@override String watchedProgress({required Object watched, required Object total}) => '${watched}/${total} assistidos';
	@override String get movie => 'Filme';
	@override String get tvShow => 'Série de TV';
	@override String minutesLeft({required Object minutes}) => '${minutes} min restantes';
}

// Path: errors
class _TranslationsErrorsPt implements TranslationsErrorsEn {
	_TranslationsErrorsPt._(this._root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Falha na busca: ${error}';
	@override String connectionTimeout({required Object context}) => 'Tempo de conexão esgotado ao carregar ${context}';
	@override String get connectionFailed => 'Não foi possível conectar ao servidor Plex';
	@override String failedToLoad({required Object context, required Object error}) => 'Falha ao carregar ${context}: ${error}';
	@override String get noClientAvailable => 'Nenhum cliente disponível';
	@override String authenticationFailed({required Object error}) => 'Falha na autenticação: ${error}';
	@override String get couldNotLaunchUrl => 'Não foi possível abrir a URL de autenticação';
	@override String get pleaseEnterToken => 'Insira um token';
	@override String get invalidToken => 'Token inválido';
	@override String failedToVerifyToken({required Object error}) => 'Falha ao verificar token: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Falha ao trocar para ${displayName}';
}

// Path: libraries
class _TranslationsLibrariesPt implements TranslationsLibrariesEn {
	_TranslationsLibrariesPt._(this._root);

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
}

// Path: about
class _TranslationsAboutPt implements TranslationsAboutEn {
	_TranslationsAboutPt._(this._root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Sobre';
	@override String get openSourceLicenses => 'Licenças Open Source';
	@override String versionLabel({required Object version}) => 'Versão ${version}';
	@override String get appDescription => 'Um belo cliente Plex para Flutter';
	@override String get viewLicensesDescription => 'Ver licenças de bibliotecas de terceiros';
}

// Path: serverSelection
class _TranslationsServerSelectionPt implements TranslationsServerSelectionEn {
	_TranslationsServerSelectionPt._(this._root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get allServerConnectionsFailed => 'Falha ao conectar a qualquer servidor. Verifique sua rede e tente novamente.';
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Nenhum servidor encontrado para ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Falha ao carregar servidores: ${error}';
}

// Path: hubDetail
class _TranslationsHubDetailPt implements TranslationsHubDetailEn {
	_TranslationsHubDetailPt._(this._root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Título';
	@override String get releaseYear => 'Ano de Lançamento';
	@override String get dateAdded => 'Data de Adição';
	@override String get rating => 'Avaliação';
	@override String get noItemsFound => 'Nenhum item encontrado';
}

// Path: logs
class _TranslationsLogsPt implements TranslationsLogsEn {
	_TranslationsLogsPt._(this._root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Limpar Logs';
	@override String get copyLogs => 'Copiar Logs';
	@override String get uploadLogs => 'Enviar Logs';
	@override String get error => 'Erro:';
	@override String get stackTrace => 'Stack Trace:';
}

// Path: licenses
class _TranslationsLicensesPt implements TranslationsLicensesEn {
	_TranslationsLicensesPt._(this._root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Pacotes Relacionados';
	@override String get license => 'Licença';
	@override String licenseNumber({required Object number}) => 'Licença ${number}';
	@override String licensesCount({required Object count}) => '${count} licenças';
}

// Path: navigation
class _TranslationsNavigationPt implements TranslationsNavigationEn {
	_TranslationsNavigationPt._(this._root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Bibliotecas';
	@override String get downloads => 'Downloads';
	@override String get liveTv => 'TV ao Vivo';
}

// Path: liveTv
class _TranslationsLiveTvPt implements TranslationsLiveTvEn {
	_TranslationsLiveTvPt._(this._root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'TV ao Vivo';
	@override String get channels => 'Canais';
	@override String get guide => 'Guia';
	@override String get noChannels => 'Nenhum canal disponível';
	@override String get noDvr => 'Nenhum DVR configurado em nenhum servidor';
	@override String get tuneFailed => 'Falha ao sintonizar canal';
	@override String get loading => 'Carregando canais...';
	@override String get nowPlaying => 'Reproduzindo Agora';
	@override String get noPrograms => 'Nenhum dado de programação disponível';
	@override String channelNumber({required Object number}) => 'Ch. ${number}';
	@override String get live => 'AO VIVO';
	@override String get hd => 'HD';
	@override String get premiere => 'NOVO';
	@override String get reloadGuide => 'Recarregar Guia';
	@override String get allChannels => 'Todos os Canais';
	@override String get now => 'Agora';
	@override String get today => 'Hoje';
	@override String get midnight => 'Meia-noite';
	@override String get overnight => 'Madrugada';
	@override String get morning => 'Manhã';
	@override String get daytime => 'Dia';
	@override String get evening => 'Noite';
	@override String get lateNight => 'Madrugada';
	@override String get whatsOn => 'O que Está Passando';
	@override String get watchChannel => 'Assistir Canal';
}

// Path: collections
class _TranslationsCollectionsPt implements TranslationsCollectionsEn {
	_TranslationsCollectionsPt._(this._root);

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
}

// Path: playlists
class _TranslationsPlaylistsPt implements TranslationsPlaylistsEn {
	_TranslationsPlaylistsPt._(this._root);

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
class _TranslationsWatchTogetherPt implements TranslationsWatchTogetherEn {
	_TranslationsWatchTogetherPt._(this._root);

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
	@override String get enterCodeHint => 'Insira o código de 8 caracteres';
	@override String get pasteFromClipboard => 'Colar da área de transferência';
	@override String get pleaseEnterCode => 'Insira um código de sessão';
	@override String get codeMustBe8Chars => 'O código da sessão deve ter 8 caracteres';
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
}

// Path: downloads
class _TranslationsDownloadsPt implements TranslationsDownloadsEn {
	_TranslationsDownloadsPt._(this._root);

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
	@override String episodesQueued({required Object count}) => '${count} episódios na fila de download';
	@override String get downloadDeleted => 'Download excluído';
	@override String deleteConfirm({required Object title}) => 'Tem certeza que deseja excluir "${title}"? Isso removerá o arquivo baixado do seu dispositivo.';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Excluindo ${title}... (${current} de ${total})';
	@override String get noDownloadsTree => 'Nenhum download';
	@override String get pauseAll => 'Pausar todos';
	@override String get resumeAll => 'Retomar todos';
	@override String get deleteAll => 'Excluir todos';
}

// Path: shaders
class _TranslationsShadersPt implements TranslationsShadersEn {
	_TranslationsShadersPt._(this._root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Shaders';
	@override String get noShaderDescription => 'Sem aprimoramento de vídeo';
	@override String get nvscalerDescription => 'Escalonamento de imagem NVIDIA para vídeo mais nítido';
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
class _TranslationsCompanionRemotePt implements TranslationsCompanionRemoteEn {
	_TranslationsCompanionRemotePt._(this._root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Controle Remoto';
	@override String get connectToDevice => 'Conectar ao Dispositivo';
	@override String get hostRemoteSession => 'Hospedar Sessão Remota';
	@override String get controlThisDevice => 'Controle este dispositivo com seu celular';
	@override String get remoteControl => 'Controle Remoto';
	@override String get controlDesktop => 'Controlar um dispositivo desktop';
	@override String connectedTo({required Object name}) => 'Conectado a ${name}';
	@override late final _TranslationsCompanionRemoteSessionPt session = _TranslationsCompanionRemoteSessionPt._(_root);
	@override late final _TranslationsCompanionRemotePairingPt pairing = _TranslationsCompanionRemotePairingPt._(_root);
	@override late final _TranslationsCompanionRemoteRemotePt remote = _TranslationsCompanionRemoteRemotePt._(_root);
}

// Path: videoSettings
class _TranslationsVideoSettingsPt implements TranslationsVideoSettingsEn {
	_TranslationsVideoSettingsPt._(this._root);

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
	@override String get audioNormalization => 'Normalização de Áudio';
}

// Path: externalPlayer
class _TranslationsExternalPlayerPt implements TranslationsExternalPlayerEn {
	_TranslationsExternalPlayerPt._(this._root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Player Externo';
	@override String get useExternalPlayer => 'Usar Player Externo';
	@override String get useExternalPlayerDescription => 'Abrir vídeos em um app externo em vez do player integrado';
	@override String get selectPlayer => 'Selecionar Player';
	@override String get systemDefault => 'Padrão do Sistema';
	@override String get addCustomPlayer => 'Adicionar Player Personalizado';
	@override String get playerName => 'Nome do Player';
	@override String get playerCommand => 'Comando';
	@override String get playerPackage => 'Nome do Pacote';
	@override String get playerUrlScheme => 'Esquema de URL';
	@override String get customPlayer => 'Player Personalizado';
	@override String get off => 'Desativado';
	@override String get launchFailed => 'Falha ao abrir player externo';
	@override String appNotInstalled({required Object name}) => '${name} não está instalado';
	@override String get playInExternalPlayer => 'Reproduzir no Player Externo';
}

// Path: metadataEdit
class _TranslationsMetadataEditPt implements TranslationsMetadataEditEn {
	_TranslationsMetadataEditPt._(this._root);

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
	@override String get selectPoster => 'Selecionar Poster';
	@override String get selectBackground => 'Selecionar Plano de Fundo';
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
}

// Path: hotkeys.actions
class _TranslationsHotkeysActionsPt implements TranslationsHotkeysActionsEn {
	_TranslationsHotkeysActionsPt._(this._root);

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
	@override String get speedIncrease => 'Aumentar Velocidade';
	@override String get speedDecrease => 'Diminuir Velocidade';
	@override String get speedReset => 'Redefinir Velocidade';
	@override String get subSeekNext => 'Ir para Próxima Legenda';
	@override String get subSeekPrev => 'Ir para Legenda Anterior';
	@override String get shaderToggle => 'Alternar Shaders';
	@override String get skipMarker => 'Pular Intro/Créditos';
}

// Path: videoControls.pipErrors
class _TranslationsVideoControlsPipErrorsPt implements TranslationsVideoControlsPipErrorsEn {
	_TranslationsVideoControlsPipErrorsPt._(this._root);

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
class _TranslationsLibrariesTabsPt implements TranslationsLibrariesTabsEn {
	_TranslationsLibrariesTabsPt._(this._root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Recomendados';
	@override String get browse => 'Navegar';
	@override String get collections => 'Coleções';
	@override String get playlists => 'Playlists';
}

// Path: libraries.groupings
class _TranslationsLibrariesGroupingsPt implements TranslationsLibrariesGroupingsEn {
	_TranslationsLibrariesGroupingsPt._(this._root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get all => 'Todos';
	@override String get movies => 'Filmes';
	@override String get shows => 'Séries de TV';
	@override String get seasons => 'Temporadas';
	@override String get episodes => 'Episódios';
	@override String get folders => 'Pastas';
}

// Path: companionRemote.session
class _TranslationsCompanionRemoteSessionPt implements TranslationsCompanionRemoteSessionEn {
	_TranslationsCompanionRemoteSessionPt._(this._root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get creatingSession => 'Criando sessão remota...';
	@override String get failedToCreate => 'Falha ao criar sessão remota:';
	@override String get noSession => 'Nenhuma sessão disponível';
	@override String get scanQrCode => 'Escanear QR Code';
	@override String get orEnterManually => 'Ou insira manualmente';
	@override String get hostAddress => 'Endereço do Host';
	@override String get sessionId => 'ID da Sessão';
	@override String get pin => 'PIN';
	@override String get connected => 'Conectado';
	@override String get waitingForConnection => 'Aguardando conexão...';
	@override String get usePhoneToControl => 'Use seu dispositivo móvel para controlar este app';
	@override String copiedToClipboard({required Object label}) => '${label} copiado para a área de transferência';
	@override String get copyToClipboard => 'Copiar para área de transferência';
	@override String get newSession => 'Nova Sessão';
	@override String get minimize => 'Minimizar';
}

// Path: companionRemote.pairing
class _TranslationsCompanionRemotePairingPt implements TranslationsCompanionRemotePairingEn {
	_TranslationsCompanionRemotePairingPt._(this._root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get scan => 'Escanear';
	@override String get manual => 'Manual';
	@override String get pairWithDesktop => 'Parear com Desktop';
	@override String get enterSessionDetails => 'Insira os detalhes da sessão exibidos no seu dispositivo desktop';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get sessionIdHint => 'Insira o ID da sessão de 8 caracteres';
	@override String get pinHint => 'Insira o PIN de 6 dígitos';
	@override String get connecting => 'Conectando...';
	@override String get tips => 'Dicas';
	@override String get tipDesktop => 'Abra o Plezy no desktop e ative o Controle Remoto nas configurações ou menu';
	@override String get tipScan => 'Use a aba Escanear para parear rapidamente escaneando o QR code no seu desktop';
	@override String get tipWifi => 'Certifique-se de que ambos os dispositivos estão na mesma rede WiFi';
	@override String get cameraPermissionRequired => 'A permissão da câmera é necessária para escanear QR codes.\nConceda acesso à câmera nas configurações do dispositivo.';
	@override String cameraError({required Object error}) => 'Não foi possível iniciar a câmera: ${error}';
	@override String get scanInstruction => 'Aponte sua câmera para o QR code exibido no seu desktop';
	@override String get invalidQrCode => 'Formato de QR code inválido';
	@override String get validationHostRequired => 'Insira o endereço do host';
	@override String get validationHostFormat => 'O formato deve ser IP:porta (ex: 192.168.1.100:48632)';
	@override String get validationSessionIdRequired => 'Insira um ID de sessão';
	@override String get validationSessionIdLength => 'O ID da sessão deve ter 8 caracteres';
	@override String get validationPinRequired => 'Insira um PIN';
	@override String get validationPinLength => 'O PIN deve ter 6 dígitos';
	@override String get connectionTimedOut => 'Tempo de conexão esgotado. Verifique o ID da sessão e o PIN.';
	@override String get sessionNotFound => 'Sessão não encontrada. Verifique suas credenciais.';
	@override String failedToConnect({required Object error}) => 'Falha ao conectar: ${error}';
}

// Path: companionRemote.remote
class _TranslationsCompanionRemoteRemotePt implements TranslationsCompanionRemoteRemoteEn {
	_TranslationsCompanionRemoteRemotePt._(this._root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'Deseja desconectar da sessão remota?';
	@override String get reconnecting => 'Reconectando...';
	@override String attemptOf({required Object current}) => 'Tentativa ${current} de 5';
	@override String get retryNow => 'Tentar Agora';
	@override String get connectionError => 'Erro de conexão';
	@override String get notConnected => 'Não conectado';
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
			'auth.showQRCode' => 'Mostrar QR Code',
			'auth.authenticate' => 'Autenticar',
			'auth.authenticationTimeout' => 'A autenticação expirou. Tente novamente.',
			'auth.scanQRToSignIn' => 'Escaneie este QR code para entrar',
			'auth.waitingForAuth' => 'Aguardando autenticação...\nConclua o login no seu navegador.',
			'auth.useBrowser' => 'Usar navegador',
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
			'common.remove' => 'Remover',
			'common.paste' => 'Colar',
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
			'common.loading' => 'Carregando...',
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
			'settings.language' => 'Idioma',
			'settings.theme' => 'Tema',
			'settings.appearance' => 'Aparência',
			'settings.videoPlayback' => 'Reprodução de Vídeo',
			'settings.advanced' => 'Avançado',
			'settings.episodePosterMode' => 'Estilo do Poster de Episódio',
			'settings.seriesPoster' => 'Poster da Série',
			'settings.seriesPosterDescription' => 'Mostrar o poster da série para todos os episódios',
			'settings.seasonPoster' => 'Poster da Temporada',
			'settings.seasonPosterDescription' => 'Mostrar o poster específico da temporada para episódios',
			'settings.episodeThumbnail' => 'Miniatura do Episódio',
			'settings.episodeThumbnailDescription' => 'Mostrar miniaturas 16:9 de captura de tela do episódio',
			'settings.showHeroSectionDescription' => 'Exibir carrossel de conteúdo em destaque na tela inicial',
			'settings.secondsLabel' => 'Segundos',
			'settings.minutesLabel' => 'Minutos',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'm',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Insira a duração (${min}-${max})',
			'settings.systemTheme' => 'Sistema',
			'settings.systemThemeDescription' => 'Seguir configurações do sistema',
			'settings.lightTheme' => 'Claro',
			'settings.darkTheme' => 'Escuro',
			'settings.oledTheme' => 'OLED',
			'settings.oledThemeDescription' => 'Preto puro para telas OLED',
			'settings.libraryDensity' => 'Densidade da Biblioteca',
			'settings.compact' => 'Compacto',
			'settings.compactDescription' => 'Cards menores, mais itens visíveis',
			'settings.normal' => 'Normal',
			'settings.normalDescription' => 'Tamanho padrão',
			'settings.comfortable' => 'Confortável',
			'settings.comfortableDescription' => 'Cards maiores, menos itens visíveis',
			'settings.viewMode' => 'Modo de Visualização',
			'settings.gridView' => 'Grade',
			'settings.gridViewDescription' => 'Exibir itens em layout de grade',
			'settings.listView' => 'Lista',
			'settings.listViewDescription' => 'Exibir itens em layout de lista',
			'settings.showHeroSection' => 'Mostrar Seção de Destaque',
			'settings.useGlobalHubs' => 'Usar Layout Plex Home',
			'settings.useGlobalHubsDescription' => 'Mostrar hubs da página inicial como o cliente oficial Plex. Quando desativado, mostra recomendações por biblioteca.',
			'settings.showServerNameOnHubs' => 'Mostrar Nome do Servidor nos Hubs',
			'settings.showServerNameOnHubsDescription' => 'Sempre exibir o nome do servidor nos títulos dos hubs. Quando desativado, mostra apenas para nomes duplicados.',
			'settings.alwaysKeepSidebarOpen' => 'Manter Barra Lateral Sempre Aberta',
			'settings.alwaysKeepSidebarOpenDescription' => 'A barra lateral fica expandida e a área de conteúdo se ajusta',
			'settings.showUnwatchedCount' => 'Mostrar Contagem de Não Assistidos',
			'settings.showUnwatchedCountDescription' => 'Exibir contagem de episódios não assistidos em séries e temporadas',
			'settings.hideSpoilers' => 'Ocultar Spoilers de Episódios Não Assistidos',
			'settings.hideSpoilersDescription' => 'Desfocar miniaturas e ocultar descrições de episódios que você ainda não assistiu',
			'settings.playerBackend' => 'Backend do Player',
			'settings.exoPlayer' => 'ExoPlayer (Recomendado)',
			'settings.exoPlayerDescription' => 'Player nativo Android com melhor suporte a hardware',
			'settings.mpv' => 'mpv',
			'settings.mpvDescription' => 'Player avançado com mais recursos e suporte a legendas ASS',
			'settings.hardwareDecoding' => 'Decodificação por Hardware',
			'settings.hardwareDecodingDescription' => 'Usar aceleração por hardware quando disponível',
			'settings.bufferSize' => 'Tamanho do Buffer',
			'settings.bufferSizeMB' => ({required Object size}) => '${size}MB',
			'settings.bufferSizeAuto' => 'Automático (Recomendado)',
			'settings.bufferSizeWarning' => ({required Object heap, required Object size}) => 'Seu dispositivo tem ${heap}MB de memória. Um buffer de ${size}MB pode causar problemas de reprodução.',
			'settings.subtitleStyling' => 'Estilo de Legendas',
			'settings.subtitleStylingDescription' => 'Personalizar aparência das legendas',
			'settings.smallSkipDuration' => 'Duração do Avanço Curto',
			'settings.largeSkipDuration' => 'Duração do Avanço Longo',
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
			'settings.shortcutsReset' => 'Atalhos redefinidos para o padrão',
			'settings.about' => 'Sobre',
			'settings.aboutDescription' => 'Informações do app e licenças',
			'settings.updates' => 'Atualizações',
			'settings.updateAvailable' => 'Atualização Disponível',
			'settings.checkForUpdates' => 'Verificar Atualizações',
			'settings.validationErrorEnterNumber' => 'Insira um número válido',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'A duração deve ser entre ${min} e ${max} ${unit}',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Atalho já atribuído a ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Atalho atualizado para ${action}',
			'settings.autoSkip' => 'Pular Automaticamente',
			'settings.autoSkipIntro' => 'Pular Intro Automaticamente',
			'settings.autoSkipIntroDescription' => 'Pular marcadores de intro automaticamente após alguns segundos',
			'settings.autoSkipCredits' => 'Pular Créditos Automaticamente',
			'settings.autoSkipCreditsDescription' => 'Pular créditos automaticamente e reproduzir próximo episódio',
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
			'settings.cellularDownloadBlocked' => 'Downloads estão desativados em dados móveis. Conecte ao WiFi ou altere a configuração.',
			'settings.maxVolume' => 'Volume Máximo',
			'settings.maxVolumeDescription' => 'Permitir aumento de volume acima de 100% para mídias silenciosas',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Mostrar o que você está assistindo no Discord',
			'settings.autoPip' => 'Picture-in-Picture Automático',
			'settings.autoPipDescription' => 'Entrar automaticamente em picture-in-picture ao sair do app durante a reprodução',
			'settings.matchContentFrameRate' => 'Corresponder Taxa de Quadros do Conteúdo',
			'settings.matchContentFrameRateDescription' => 'Ajustar a taxa de atualização da tela para corresponder ao conteúdo de vídeo, reduzindo tremulação e economizando bateria',
			'settings.tunneledPlayback' => 'Reprodução Tunelizada',
			'settings.tunneledPlaybackDescription' => 'Usar tunelamento de vídeo acelerado por hardware. Desative se você vir uma tela preta com áudio em conteúdo HDR',
			'settings.requireProfileSelectionOnOpen' => 'Pedir perfil ao abrir o app',
			'settings.requireProfileSelectionOnOpenDescription' => 'Mostrar seleção de perfil toda vez que o app for aberto',
			'settings.confirmExitOnBack' => 'Confirmar antes de sair',
			'settings.confirmExitOnBackDescription' => 'Mostrar diálogo de confirmação ao pressionar voltar para sair do app',
			'settings.showNavBarLabels' => 'Mostrar Rótulos da Barra de Navegação',
			'settings.showNavBarLabelsDescription' => 'Exibir rótulos de texto sob os ícones da barra de navegação',
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
			'hotkeys.actions.speedIncrease' => 'Aumentar Velocidade',
			'hotkeys.actions.speedDecrease' => 'Diminuir Velocidade',
			'hotkeys.actions.speedReset' => 'Redefinir Velocidade',
			'hotkeys.actions.subSeekNext' => 'Ir para Próxima Legenda',
			'hotkeys.actions.subSeekPrev' => 'Ir para Legenda Anterior',
			'hotkeys.actions.shaderToggle' => 'Alternar Shaders',
			'hotkeys.actions.skipMarker' => 'Pular Intro/Créditos',
			'pinEntry.enterPin' => 'Inserir PIN',
			'pinEntry.showPin' => 'Mostrar PIN',
			'pinEntry.hidePin' => 'Ocultar PIN',
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
			'videoControls.sleepTimerCompleted' => 'Timer de sono concluído - reprodução pausada',
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
			'videoControls.audioTrackButton' => 'Faixas de áudio',
			'videoControls.subtitlesButton' => 'Legendas',
			'videoControls.tracksButton' => 'Áudio e Legendas',
			'videoControls.chaptersButton' => 'Capítulos',
			'videoControls.versionsButton' => 'Versões do vídeo',
			'videoControls.pipButton' => 'Modo Picture-in-Picture',
			'videoControls.aspectRatioButton' => 'Proporção',
			'videoControls.ambientLighting' => 'Iluminação ambiente',
			'videoControls.ambientLightingOn' => 'Ativar iluminação ambiente',
			'videoControls.ambientLightingOff' => 'Desativar iluminação ambiente',
			'videoControls.fullscreenButton' => 'Entrar em tela cheia',
			'videoControls.exitFullscreenButton' => 'Sair da tela cheia',
			'videoControls.alwaysOnTopButton' => 'Sempre no topo',
			'videoControls.rotationLockButton' => 'Travar rotação',
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
			'userStatus.admin' => 'Admin',
			'userStatus.restricted' => 'Restrito',
			'userStatus.protected' => 'Protegido',
			'userStatus.current' => 'ATUAL',
			'messages.markedAsWatched' => 'Marcado como assistido',
			'messages.markedAsUnwatched' => 'Marcado como não assistido',
			'messages.markedAsWatchedOffline' => 'Marcado como assistido (será sincronizado quando online)',
			'messages.markedAsUnwatchedOffline' => 'Marcado como não assistido (será sincronizado quando online)',
			'messages.removedFromContinueWatching' => 'Removido de Continuar Assistindo',
			'messages.errorLoading' => ({required Object error}) => 'Erro: ${error}',
			'messages.fileInfoNotAvailable' => 'Informações do arquivo não disponíveis',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Erro ao carregar info do arquivo: ${error}',
			'messages.errorLoadingSeries' => 'Erro ao carregar série',
			'messages.errorLoadingSeason' => 'Erro ao carregar temporada',
			'messages.musicNotSupported' => 'Reprodução de música ainda não é suportada',
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
			'messages.logsUploaded' => 'Logs enviados',
			'messages.logsUploadFailed' => 'Falha ao enviar logs',
			'messages.logId' => 'ID do Log',
			'subtitlingStyling.stylingOptions' => 'Opções de Estilo',
			'subtitlingStyling.fontSize' => 'Tamanho da Fonte',
			'subtitlingStyling.textColor' => 'Cor do Texto',
			'subtitlingStyling.borderSize' => 'Tamanho da Borda',
			'subtitlingStyling.borderColor' => 'Cor da Borda',
			'subtitlingStyling.backgroundOpacity' => 'Opacidade do Fundo',
			'subtitlingStyling.backgroundColor' => 'Cor de Fundo',
			'subtitlingStyling.position' => 'Posição',
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
			'discover.title' => 'Descobrir',
			'discover.switchProfile' => 'Trocar Perfil',
			'discover.noContentAvailable' => 'Nenhum conteúdo disponível',
			'discover.addMediaToLibraries' => 'Adicione mídias às suas bibliotecas',
			'discover.continueWatching' => 'Continuar Assistindo',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.overview' => 'Sinopse',
			'discover.cast' => 'Elenco',
			'discover.extras' => 'Trailers e Extras',
			'discover.seasons' => 'Temporadas',
			'discover.studio' => 'Estúdio',
			'discover.rating' => 'Avaliação',
			'discover.episodeCount' => ({required Object count}) => '${count} episódios',
			'discover.watchedProgress' => ({required Object watched, required Object total}) => '${watched}/${total} assistidos',
			'discover.movie' => 'Filme',
			'discover.tvShow' => 'Série de TV',
			'discover.minutesLeft' => ({required Object minutes}) => '${minutes} min restantes',
			'errors.searchFailed' => ({required Object error}) => 'Falha na busca: ${error}',
			'errors.connectionTimeout' => ({required Object context}) => 'Tempo de conexão esgotado ao carregar ${context}',
			'errors.connectionFailed' => 'Não foi possível conectar ao servidor Plex',
			'errors.failedToLoad' => ({required Object context, required Object error}) => 'Falha ao carregar ${context}: ${error}',
			'errors.noClientAvailable' => 'Nenhum cliente disponível',
			'errors.authenticationFailed' => ({required Object error}) => 'Falha na autenticação: ${error}',
			'errors.couldNotLaunchUrl' => 'Não foi possível abrir a URL de autenticação',
			'errors.pleaseEnterToken' => 'Insira um token',
			'errors.invalidToken' => 'Token inválido',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Falha ao verificar token: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Falha ao trocar para ${displayName}',
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
			'libraries.groupings.all' => 'Todos',
			'libraries.groupings.movies' => 'Filmes',
			'libraries.groupings.shows' => 'Séries de TV',
			'libraries.groupings.seasons' => 'Temporadas',
			'libraries.groupings.episodes' => 'Episódios',
			'libraries.groupings.folders' => 'Pastas',
			'about.title' => 'Sobre',
			'about.openSourceLicenses' => 'Licenças Open Source',
			'about.versionLabel' => ({required Object version}) => 'Versão ${version}',
			'about.appDescription' => 'Um belo cliente Plex para Flutter',
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
			'logs.error' => 'Erro:',
			'logs.stackTrace' => 'Stack Trace:',
			'licenses.relatedPackages' => 'Pacotes Relacionados',
			'licenses.license' => 'Licença',
			'licenses.licenseNumber' => ({required Object number}) => 'Licença ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} licenças',
			'navigation.libraries' => 'Bibliotecas',
			'navigation.downloads' => 'Downloads',
			'navigation.liveTv' => 'TV ao Vivo',
			'liveTv.title' => 'TV ao Vivo',
			'liveTv.channels' => 'Canais',
			'liveTv.guide' => 'Guia',
			'liveTv.noChannels' => 'Nenhum canal disponível',
			'liveTv.noDvr' => 'Nenhum DVR configurado em nenhum servidor',
			'liveTv.tuneFailed' => 'Falha ao sintonizar canal',
			'liveTv.loading' => 'Carregando canais...',
			'liveTv.nowPlaying' => 'Reproduzindo Agora',
			'liveTv.noPrograms' => 'Nenhum dado de programação disponível',
			'liveTv.channelNumber' => ({required Object number}) => 'Ch. ${number}',
			'liveTv.live' => 'AO VIVO',
			_ => null,
		} ?? switch (path) {
			'liveTv.hd' => 'HD',
			'liveTv.premiere' => 'NOVO',
			'liveTv.reloadGuide' => 'Recarregar Guia',
			'liveTv.allChannels' => 'Todos os Canais',
			'liveTv.now' => 'Agora',
			'liveTv.today' => 'Hoje',
			'liveTv.midnight' => 'Meia-noite',
			'liveTv.overnight' => 'Madrugada',
			'liveTv.morning' => 'Manhã',
			'liveTv.daytime' => 'Dia',
			'liveTv.evening' => 'Noite',
			'liveTv.lateNight' => 'Madrugada',
			'liveTv.whatsOn' => 'O que Está Passando',
			'liveTv.watchChannel' => 'Assistir Canal',
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
			'watchTogether.enterCodeHint' => 'Insira o código de 8 caracteres',
			'watchTogether.pasteFromClipboard' => 'Colar da área de transferência',
			'watchTogether.pleaseEnterCode' => 'Insira um código de sessão',
			'watchTogether.codeMustBe8Chars' => 'O código da sessão deve ter 8 caracteres',
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
			'downloads.episodesQueued' => ({required Object count}) => '${count} episódios na fila de download',
			'downloads.downloadDeleted' => 'Download excluído',
			'downloads.deleteConfirm' => ({required Object title}) => 'Tem certeza que deseja excluir "${title}"? Isso removerá o arquivo baixado do seu dispositivo.',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Excluindo ${title}... (${current} de ${total})',
			'downloads.noDownloadsTree' => 'Nenhum download',
			'downloads.pauseAll' => 'Pausar todos',
			'downloads.resumeAll' => 'Retomar todos',
			'downloads.deleteAll' => 'Excluir todos',
			'shaders.title' => 'Shaders',
			'shaders.noShaderDescription' => 'Sem aprimoramento de vídeo',
			'shaders.nvscalerDescription' => 'Escalonamento de imagem NVIDIA para vídeo mais nítido',
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
			'companionRemote.connectToDevice' => 'Conectar ao Dispositivo',
			'companionRemote.hostRemoteSession' => 'Hospedar Sessão Remota',
			'companionRemote.controlThisDevice' => 'Controle este dispositivo com seu celular',
			'companionRemote.remoteControl' => 'Controle Remoto',
			'companionRemote.controlDesktop' => 'Controlar um dispositivo desktop',
			'companionRemote.connectedTo' => ({required Object name}) => 'Conectado a ${name}',
			'companionRemote.session.creatingSession' => 'Criando sessão remota...',
			'companionRemote.session.failedToCreate' => 'Falha ao criar sessão remota:',
			'companionRemote.session.noSession' => 'Nenhuma sessão disponível',
			'companionRemote.session.scanQrCode' => 'Escanear QR Code',
			'companionRemote.session.orEnterManually' => 'Ou insira manualmente',
			'companionRemote.session.hostAddress' => 'Endereço do Host',
			'companionRemote.session.sessionId' => 'ID da Sessão',
			'companionRemote.session.pin' => 'PIN',
			'companionRemote.session.connected' => 'Conectado',
			'companionRemote.session.waitingForConnection' => 'Aguardando conexão...',
			'companionRemote.session.usePhoneToControl' => 'Use seu dispositivo móvel para controlar este app',
			'companionRemote.session.copiedToClipboard' => ({required Object label}) => '${label} copiado para a área de transferência',
			'companionRemote.session.copyToClipboard' => 'Copiar para área de transferência',
			'companionRemote.session.newSession' => 'Nova Sessão',
			'companionRemote.session.minimize' => 'Minimizar',
			'companionRemote.pairing.scan' => 'Escanear',
			'companionRemote.pairing.manual' => 'Manual',
			'companionRemote.pairing.pairWithDesktop' => 'Parear com Desktop',
			'companionRemote.pairing.enterSessionDetails' => 'Insira os detalhes da sessão exibidos no seu dispositivo desktop',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.sessionIdHint' => 'Insira o ID da sessão de 8 caracteres',
			'companionRemote.pairing.pinHint' => 'Insira o PIN de 6 dígitos',
			'companionRemote.pairing.connecting' => 'Conectando...',
			'companionRemote.pairing.tips' => 'Dicas',
			'companionRemote.pairing.tipDesktop' => 'Abra o Plezy no desktop e ative o Controle Remoto nas configurações ou menu',
			'companionRemote.pairing.tipScan' => 'Use a aba Escanear para parear rapidamente escaneando o QR code no seu desktop',
			'companionRemote.pairing.tipWifi' => 'Certifique-se de que ambos os dispositivos estão na mesma rede WiFi',
			'companionRemote.pairing.cameraPermissionRequired' => 'A permissão da câmera é necessária para escanear QR codes.\nConceda acesso à câmera nas configurações do dispositivo.',
			'companionRemote.pairing.cameraError' => ({required Object error}) => 'Não foi possível iniciar a câmera: ${error}',
			'companionRemote.pairing.scanInstruction' => 'Aponte sua câmera para o QR code exibido no seu desktop',
			'companionRemote.pairing.invalidQrCode' => 'Formato de QR code inválido',
			'companionRemote.pairing.validationHostRequired' => 'Insira o endereço do host',
			'companionRemote.pairing.validationHostFormat' => 'O formato deve ser IP:porta (ex: 192.168.1.100:48632)',
			'companionRemote.pairing.validationSessionIdRequired' => 'Insira um ID de sessão',
			'companionRemote.pairing.validationSessionIdLength' => 'O ID da sessão deve ter 8 caracteres',
			'companionRemote.pairing.validationPinRequired' => 'Insira um PIN',
			'companionRemote.pairing.validationPinLength' => 'O PIN deve ter 6 dígitos',
			'companionRemote.pairing.connectionTimedOut' => 'Tempo de conexão esgotado. Verifique o ID da sessão e o PIN.',
			'companionRemote.pairing.sessionNotFound' => 'Sessão não encontrada. Verifique suas credenciais.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Falha ao conectar: ${error}',
			'companionRemote.remote.disconnectConfirm' => 'Deseja desconectar da sessão remota?',
			'companionRemote.remote.reconnecting' => 'Reconectando...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Tentativa ${current} de 5',
			'companionRemote.remote.retryNow' => 'Tentar Agora',
			'companionRemote.remote.connectionError' => 'Erro de conexão',
			'companionRemote.remote.notConnected' => 'Não conectado',
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
			'videoSettings.audioNormalization' => 'Normalização de Áudio',
			'externalPlayer.title' => 'Player Externo',
			'externalPlayer.useExternalPlayer' => 'Usar Player Externo',
			'externalPlayer.useExternalPlayerDescription' => 'Abrir vídeos em um app externo em vez do player integrado',
			'externalPlayer.selectPlayer' => 'Selecionar Player',
			'externalPlayer.systemDefault' => 'Padrão do Sistema',
			'externalPlayer.addCustomPlayer' => 'Adicionar Player Personalizado',
			'externalPlayer.playerName' => 'Nome do Player',
			'externalPlayer.playerCommand' => 'Comando',
			'externalPlayer.playerPackage' => 'Nome do Pacote',
			'externalPlayer.playerUrlScheme' => 'Esquema de URL',
			'externalPlayer.customPlayer' => 'Player Personalizado',
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
			'metadataEdit.selectPoster' => 'Selecionar Poster',
			'metadataEdit.selectBackground' => 'Selecionar Plano de Fundo',
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
			'metadataEdit.useOriginalTitle' => 'Usar Título Original',
			'metadataEdit.preferredAudioLanguage' => 'Idioma de Áudio Preferido',
			'metadataEdit.preferredSubtitleLanguage' => 'Idioma de Legenda Preferido',
			'metadataEdit.subtitleMode' => 'Modo de Seleção Automática de Legendas',
			'metadataEdit.manuallySelected' => 'Seleção manual',
			'metadataEdit.shownWithForeignAudio' => 'Exibir com áudio estrangeiro',
			'metadataEdit.alwaysEnabled' => 'Sempre ativado',
			_ => null,
		};
	}
}
