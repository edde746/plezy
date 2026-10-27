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
class TranslationsEs extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEs({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.es,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <es>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsEs _root = this; // ignore: unused_field

	@override 
	TranslationsEs $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEs(meta: meta ?? this.$meta);

	// Translations
	@override late final Translations$app$es app = Translations$app$es.internal(_root);
	@override late final Translations$appIcon$es appIcon = Translations$appIcon$es.internal(_root);
	@override late final Translations$auth$es auth = Translations$auth$es.internal(_root);
	@override late final Translations$common$es common = Translations$common$es.internal(_root);
	@override late final Translations$screens$es screens = Translations$screens$es.internal(_root);
	@override late final Translations$update$es update = Translations$update$es.internal(_root);
	@override late final Translations$settings$es settings = Translations$settings$es.internal(_root);
	@override late final Translations$themeEditor$es themeEditor = Translations$themeEditor$es.internal(_root);
	@override late final Translations$search$es search = Translations$search$es.internal(_root);
	@override late final Translations$hotkeys$es hotkeys = Translations$hotkeys$es.internal(_root);
	@override late final Translations$fileInfo$es fileInfo = Translations$fileInfo$es.internal(_root);
	@override late final Translations$mediaMenu$es mediaMenu = Translations$mediaMenu$es.internal(_root);
	@override late final Translations$rateSheet$es rateSheet = Translations$rateSheet$es.internal(_root);
	@override late final Translations$accessibility$es accessibility = Translations$accessibility$es.internal(_root);
	@override late final Translations$tooltips$es tooltips = Translations$tooltips$es.internal(_root);
	@override late final Translations$audioTracks$es audioTracks = Translations$audioTracks$es.internal(_root);
	@override late final Translations$videoControls$es videoControls = Translations$videoControls$es.internal(_root);
	@override late final Translations$messages$es messages = Translations$messages$es.internal(_root);
	@override late final Translations$subtitlingStyling$es subtitlingStyling = Translations$subtitlingStyling$es.internal(_root);
	@override late final Translations$mpvConfig$es mpvConfig = Translations$mpvConfig$es.internal(_root);
	@override late final Translations$dialog$es dialog = Translations$dialog$es.internal(_root);
	@override late final Translations$profiles$es profiles = Translations$profiles$es.internal(_root);
	@override late final Translations$connections$es connections = Translations$connections$es.internal(_root);
	@override late final Translations$accountPreferences$es accountPreferences = Translations$accountPreferences$es.internal(_root);
	@override late final Translations$discover$es discover = Translations$discover$es.internal(_root);
	@override late final Translations$errors$es errors = Translations$errors$es.internal(_root);
	@override late final Translations$libraries$es libraries = Translations$libraries$es.internal(_root);
	@override late final Translations$about$es about = Translations$about$es.internal(_root);
	@override late final Translations$serverSelection$es serverSelection = Translations$serverSelection$es.internal(_root);
	@override late final Translations$hubDetail$es hubDetail = Translations$hubDetail$es.internal(_root);
	@override late final Translations$logs$es logs = Translations$logs$es.internal(_root);
	@override late final Translations$startup$es startup = Translations$startup$es.internal(_root);
	@override late final Translations$licenses$es licenses = Translations$licenses$es.internal(_root);
	@override late final Translations$navigation$es navigation = Translations$navigation$es.internal(_root);
	@override late final Translations$explore$es explore = Translations$explore$es.internal(_root);
	@override late final Translations$liveTv$es liveTv = Translations$liveTv$es.internal(_root);
	@override late final Translations$collections$es collections = Translations$collections$es.internal(_root);
	@override late final Translations$playlists$es playlists = Translations$playlists$es.internal(_root);
	@override late final Translations$music$es music = Translations$music$es.internal(_root);
	@override late final Translations$watchTogether$es watchTogether = Translations$watchTogether$es.internal(_root);
	@override late final Translations$downloads$es downloads = Translations$downloads$es.internal(_root);
	@override late final Translations$shaders$es shaders = Translations$shaders$es.internal(_root);
	@override late final Translations$companionRemote$es companionRemote = Translations$companionRemote$es.internal(_root);
	@override late final Translations$videoSettings$es videoSettings = Translations$videoSettings$es.internal(_root);
	@override late final Translations$performanceOverlay$es performanceOverlay = Translations$performanceOverlay$es.internal(_root);
	@override late final Translations$externalPlayer$es externalPlayer = Translations$externalPlayer$es.internal(_root);
	@override late final Translations$metadataEdit$es metadataEdit = Translations$metadataEdit$es.internal(_root);
	@override late final Translations$matchScreen$es matchScreen = Translations$matchScreen$es.internal(_root);
	@override late final Translations$serverTasks$es serverTasks = Translations$serverTasks$es.internal(_root);
	@override late final Translations$trakt$es trakt = Translations$trakt$es.internal(_root);
	@override late final Translations$seerr$es seerr = Translations$seerr$es.internal(_root);
	@override late final Translations$services$es services = Translations$services$es.internal(_root);
	@override late final Translations$addServer$es addServer = Translations$addServer$es.internal(_root);
	@override late final Translations$cast$es cast = Translations$cast$es.internal(_root);
	@override late final Translations$automation$es automation = Translations$automation$es.internal(_root);
	@override late final Translations$notifications$es notifications = Translations$notifications$es.internal(_root);
	@override late final Translations$appAccess$es appAccess = Translations$appAccess$es.internal(_root);
	@override late final Translations$detail$es detail = Translations$detail$es.internal(_root);
	@override late final Translations$watchLink$es watchLink = Translations$watchLink$es.internal(_root);
	@override late final Translations$homeLayout$es homeLayout = Translations$homeLayout$es.internal(_root);
	@override late final Translations$platform$es platform = Translations$platform$es.internal(_root);
	@override late final Translations$universalMedia$es universalMedia = Translations$universalMedia$es.internal(_root);
	@override late final Translations$fileSources$es fileSources = Translations$fileSources$es.internal(_root);
	@override late final Translations$lending$es lending = Translations$lending$es.internal(_root);
	@override late final Translations$audiobook$es audiobook = Translations$audiobook$es.internal(_root);
	@override late final Translations$sourceSetup$es sourceSetup = Translations$sourceSetup$es.internal(_root);
	@override late final Translations$comics$es comics = Translations$comics$es.internal(_root);
	@override late final Translations$games$es games = Translations$games$es.internal(_root);
}

// Path: app
class Translations$app$es extends Translations$app$en {
	Translations$app$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'PlezyNG';
}

// Path: appIcon
class Translations$appIcon$es extends Translations$appIcon$en {
	Translations$appIcon$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Icono de la aplicación';
	@override String get defaultIcon => 'Predeterminado';
	@override String get current => 'Icono actual';
	@override String get locked => 'Acceso a la vida necesaria';
	@override String get lockedHint => 'Comienza su prueba de 7 días o desbloquea PlezyNG para la vida para utilizar iconos alternativos.';
	@override String get changeFailed => 'No se pudo cambiar el icono de la aplicación';
	@override String get launcherHint => 'El nuevo icono aparecerá en tu pantalla de inicio cuando salgas de PlezyNG.';
	@override String get tvLauncherHint => 'El nuevo banner aparecerá cuando salgas de PlezyNG. Android TV puede seguir mostrando el anterior hasta que se reinicie la TV.';
	@override late final Translations$appIcon$names$es names = Translations$appIcon$names$es.internal(_root);
	@override String get description => 'Seleccione la icona que muestra el lanzador del dispositivo. Las previstas muestran cómo se ve cada opción.';
}

// Path: auth
class Translations$auth$es extends Translations$auth$en {
	Translations$auth$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Inicia sesión con Plex';
	@override String get showQRCode => 'Mostrar código QR';
	@override String get authenticate => 'Autenticar';
	@override String get authenticationTimeout => 'Se agotó el tiempo de autenticación. Inténtalo de nuevo.';
	@override String get scanQRToSignIn => 'Escanea este código QR para iniciar sesión';
	@override String get waitingForAuth => 'Esperando autenticación...\nInicia sesión desde tu navegador.';
	@override String get useBrowser => 'Usar navegador';
	@override String get or => 'o';
	@override String connectToMediaBrowser({required Object product}) => 'Conectar a ${product}';
	@override String get quickConnect => 'Quick Connect';
	@override String get useQuickConnect => 'Usar Quick Connect';
	@override String get quickConnectInstructions => 'Abre Quick Connect en Jellyfin e introduce este código.';
	@override String get quickConnectWaiting => 'Esperando aprobación…';
	@override String get quickConnectCancel => 'Cancelar';
	@override String get quickConnectExpired => 'Quick Connect caducó. Inténtalo de nuevo.';
	@override String get localDataRecoveryRequired => 'PlezyNG no pudo recuperar de forma segura los datos locales de inicio de sesión ni la reproducción pendiente. Vuelve a iniciar sesión.';
	@override String get pinCheckRejected => 'La comprobación del PIN de Plex fue rechazada';
	@override String get connectToDirectPlex => 'Conectar con el servidor local Plex';
}

// Path: common
class Translations$common$es extends Translations$common$en {
	Translations$common$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Cancelar';
	@override String get save => 'Guardar';
	@override String get close => 'Cerrar';
	@override String get closeMiniPlayer => 'Jugar en mini jugador';
	@override String get closeWorkspaceWindow => 'Cerca de la ventana';
	@override String get returnToFullView => 'Volver a la vista completa';
	@override String get manageMediaSessions => 'Gestión de sesiones de medios';
	@override String get hideMediaSessions => 'Condenar las sesiones de medios';
	@override String get mediaSessions => 'Sesión de medios';
	@override String get mediaSessionsHint => 'Seleccione para llevar una sesión hacia adelante.Park esconde su ventana pero la mantiene abierta.Return lo abre en vista completa; cerca termina.';
	@override String get sessionInWorkspace => 'En el espacio de trabajo';
	@override String get sessionParked => 'Aparcado';
	@override String get sessionFullscreen => 'pantalla completa';
	@override String get switchToNextWindow => 'Cambiar con la ventana siguiente';
	@override String get moveWindow => 'Move la ventana';
	@override String get finishMovingWindow => 'Finalizar la ventana de movimiento';
	@override String get moveWindowHint => 'Long-press y atraer la ventana para moverla. este control también permite el movimiento de la llave de arco.';
	@override String get movingWindowHelp => 'Descargar para moverse · Ajustar las claves de tiro · Enter saves · Escape canceles';
	@override String get resizeWindow => 'Revisa la ventana';
	@override String get resizeWindowHint => 'Retire esta mano o utilice las chaves de la pistola para reanudar la ventana.';
	@override String get workspaceWindowHint => 'Utilice el control de movimiento o long-press y drag para moverse.';
	@override String get workspacePaneHint => 'Seleccione este panel para enfocarlo. Utilice su control de pantalla completa para expandir.';
	@override String workspaceWindowLabel({required Object title}) => 'Vista de sesión: ${title}';
	@override String get workspaceTitleHint => 'Descarga la barra de título para mover; use el botón de pantalla completa para expandir.';
	@override String get moveToSessionTray => 'Moverse a la sesión Tray';
	@override String get moveToSessionTrayHint => 'Esta sesión está disponible sin mostrar su ventana.';
	@override String get closeSessionHint => 'Cerra esta ventana y termina su sesión.';
	@override String get sideBySideLayout => 'Descargar el layout de lado a lado';
	@override String get floatingWindows => 'Switch para flotar ventanas';
	@override String get clear => 'Borrar';
	@override String get reset => 'Restablecer';
	@override String get later => 'Más tarde';
	@override String get submit => 'Enviar';
	@override String get confirm => 'Confirmar';
	@override String get retry => 'Reintentar';
	@override String get logout => 'Cerrar sesión';
	@override String get unknown => 'Desconocido';
	@override String get refresh => 'Actualizar';
	@override String get yes => 'Sí';
	@override String get no => 'No';
	@override String get delete => 'Eliminar';
	@override String get edit => 'Editar';
	@override String get shuffle => 'Reproducción aleatoria';
	@override String get addTo => 'Añadir a...';
	@override String get createNew => 'Crear nuevo';
	@override String get connect => 'Conectar';
	@override String get disconnect => 'Desconectar';
	@override String get play => 'Reproducir';
	@override String get pause => 'Pausar';
	@override String get resume => 'Reanudar';
	@override String get error => 'Error';
	@override String get search => 'Buscar';
	@override String get home => 'Inicio';
	@override String get back => 'Atrás';
	@override String get settings => 'Ajustes';
	@override String get mute => 'Silenciar';
	@override String get ok => 'OK';
	@override String get off => 'Desactivado';
	@override String get options => 'Opciones';
	@override String seasonNumber({required Object number}) => 'Temporada ${number}';
	@override String episodeNumberTitle({required Object number, required Object title}) => 'Episodio ${number} - ${title}';
	@override String chapterNumber({required Object number}) => 'Capítulo ${number}';
	@override String get reconnect => 'Reconectar';
	@override String get viewAll => 'Ver todo';
	@override String get checkingNetwork => 'Comprobando red...';
	@override String get loadingServers => 'Cargando servidores...';
	@override String get connectingToServers => 'Conectando a servidores...';
	@override String get startingOfflineMode => 'Iniciando modo sin conexión...';
	@override String get loading => 'Cargando...';
	@override String get fullscreen => 'Pantalla completa';
	@override String get exitFullscreen => 'Salir de pantalla completa';
	@override String get pressBackAgainToExit => 'Pulsa Atrás de nuevo para salir';
	@override late final Translations$common$ratingSource$es ratingSource = Translations$common$ratingSource$es.internal(_root);
	@override String get notAvailable => 'N/D';
	@override String get url => 'URL';
	@override String get letterKeys => 'ABC';
	@override late final Translations$common$mediaKind$es mediaKind = Translations$common$mediaKind$es.internal(_root);
}

// Path: screens
class Translations$screens$es extends Translations$screens$en {
	Translations$screens$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Licencias';
	@override String get switchProfile => 'Cambiar perfil';
	@override String get subtitleStyling => 'Estilo de subtítulos';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Registros';
}

// Path: update
class Translations$update$es extends Translations$update$en {
	Translations$update$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get available => 'Actualización disponible';
	@override String versionAvailable({required Object version}) => 'Versión ${version} disponible';
	@override String currentVersion({required Object version}) => 'Actual: ${version}';
	@override String get skipVersion => 'Saltar esta versión';
	@override String get viewRelease => 'Ver versión';
	@override String get latestVersion => 'Ya estás en la última versión';
	@override String get checkFailed => 'Error al buscar actualizaciones';
}

// Path: settings
class Translations$settings$es extends Translations$settings$en {
	Translations$settings$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Configuración';
	@override String get supportDeveloper => 'Apoya PlezyNG';
	@override String get supportDeveloperDescription => 'Dona para apoyar el desarrollo';
	@override String get lifetimeAccess => 'PlezyNG Acceso a la vida';
	@override String get language => 'Idioma';
	@override String get theme => 'Tema';
	@override String get appearance => 'Apariencia';
	@override String get detailPage => 'Página Detalga';
	@override String get themeSongsEnabled => 'Juega canciones temáticas';
	@override String get themeSongsEnabledDescription => 'Juega canciones de temas disponibles mientras ve los detalles de los medios.';
	@override String get themeSongVolume => 'Temas de la canción volumen';
	@override String get videoPlayback => 'Reproducción de video';
	@override String get videoPlaybackDescription => 'Configurar el comportamiento de reproducción';
	@override String get advanced => 'Avanzado';
	@override String get episodePosterMode => 'Estilo del póster de episodio';
	@override String get seriesPoster => 'Póster de la serie';
	@override String get seasonPoster => 'Póster de la temporada';
	@override String get episodeThumbnail => 'Miniatura';
	@override String get showHeroSectionDescription => 'Mostrar carrusel de contenido destacado en la pantalla de inicio';
	@override String get secondsLabel => 'Segundos';
	@override String get minutesLabel => 'Minutos';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'm';
	@override String durationHint({required Object min, required Object max}) => 'Introduce la duración (${min}-${max})';
	@override String get systemTheme => 'Sistema';
	@override String get lightTheme => 'Claro';
	@override String get darkTheme => 'Oscuro';
	@override String get oledTheme => 'OLED';
	@override String get emberTheme => 'Brasa';
	@override String get glacierTheme => 'Glaciar';
	@override String get forestTheme => 'Bosque';
	@override String get plumTheme => 'Ciruela';
	@override String get paperTheme => 'Papel';
	@override String get libraryDensity => 'Densidad de la biblioteca';
	@override String get displayScale => 'Escala de visualización';
	@override String get compact => 'Compacto';
	@override String get comfortable => 'Cómodo';
	@override String get gridSpacing => 'Espaciado de la cuadrícula';
	@override String get gridSpacingTight => 'Ajustado';
	@override String get gridSpacingNormal => 'Normal';
	@override String get gridSpacingSpacious => 'Espacioso';
	@override String get tvCornerSpotlightBackdrop => 'Imagen destacada en la esquina';
	@override String get tvCornerSpotlightBackdropDescription => 'Mostrar la imagen destacada en la esquina superior derecha en lugar de ocupar toda la pantalla';
	@override String get viewMode => 'Modo de vista';
	@override String get gridView => 'Cuadrícula';
	@override String get listView => 'Lista';
	@override String get showHeroSection => 'Mostrar sección destacada';
	@override String get showHomeBackdrop => 'Mostrar arte de la casa Backdrop';
	@override String get showHomeBackdropDescription => 'Mostrar grandes obras de arte detrás de las ramas de la casa';
	@override String get contentScreensaverEnabled => 'Contenido de pantalla';
	@override String get contentScreensaverEnabledDescription => 'Mostrar arte en pantalla completa después de que la aplicación ha sido idle';
	@override String get contentScreensaverDelay => 'Comienza el monitor después de';
	@override String get contentScreensaverLibraries => 'Escreensaver bibliotecas';
	@override String get contentScreensaverLibrariesDescription => 'Elige qué bibliotecas proporcionan imágenes para el salvapantallas. Si no seleccionas ninguna, se usarán imágenes de todas las bibliotecas.';
	@override String get contentScreensaverAllLibraries => 'Todas las bibliotecas';
	@override String contentScreensaverSelectedLibraries({required Object count}) => '${count} bibliotecas seleccionadas';
	@override String get contentScreensaverNoLibraries => 'No hay bibliotecas de medios conectadas.';
	@override String get contentScreensaverDismissHint => 'Presiona cualquier botón o toque para desactivar';
	@override String get newEpisodeNotifications => 'Noticias de nuevo episodio';
	@override String get newEpisodeNotificationsDescription => 'Alerta cuando se añade un nuevo episodio a un espectáculo que está grabado. verifica mientras Plezy está abierto.';
	@override String get continueWatchingRowSize => 'Continuar observando el tamaño de la línea';
	@override String continueWatchingRowSizeValue({required Object label}) => '${label} tarjetas';
	@override String get rowSizeCompact => 'Compacto';
	@override String get rowSizeStandard => 'estándar';
	@override String get rowSizeLarge => 'Grande';
	@override String get continueWatchingAction => 'Acción de «Seguir viendo»';
	@override String get continueWatchingPlay => 'Reproducir';
	@override String get continueWatchingDetails => 'Abrir detalles';
	@override String get episodeAction => 'Acción de episodio';
	@override String get episodePlay => 'Reproducir';
	@override String get episodeDetails => 'Abrir detalles';
	@override String get useGlobalHubs => 'Usar secciones de inicio';
	@override String get useGlobalHubsDescription => 'Mostrar secciones de inicio unificadas. De lo contrario, usar las recomendaciones de cada biblioteca.';
	@override String get showServerNameOnHubs => 'Mostrar el nombre del servidor en las secciones';
	@override String get showServerNameOnHubsDescription => 'Mostrar siempre el nombre del servidor en los títulos de las secciones.';
	@override String get groupLibrariesByServer => 'Agrupar bibliotecas por servidor';
	@override String get groupLibrariesByServerDescription => 'Agrupar bibliotecas de la barra lateral por servidor multimedia.';
	@override String get alwaysKeepSidebarOpen => 'Mantener siempre la barra lateral abierta';
	@override String get alwaysKeepSidebarOpenDescription => 'La barra lateral permanece expandida y el área de contenido se ajusta para adaptarse';
	@override String get showUnwatchedCount => 'Mostrar el número de elementos no vistos';
	@override String get showUnwatchedCountDescription => 'Mostrar el número de episodios no vistos en series y temporadas';
	@override String get showWatchedIndicators => 'Mostrar indicadores de visto';
	@override String get showWatchedIndicatorsDescription => 'Mostrar una marca de verificación en películas, series y episodios vistos';
	@override String get showEpisodeNumberOnCards => 'Mostrar número de episodio en las tarjetas';
	@override String get showEpisodeNumberOnCardsDescription => 'Mostrar temporada y episodio en tarjetas de episodio';
	@override String get showSeasonPostersOnTabs => 'Mostrar pósters de temporada en las pestañas';
	@override String get showSeasonPostersOnTabsDescription => 'Mostrar el póster de cada temporada sobre su pestaña';
	@override String get tvFullCardLayout => 'Tarjetas TV completas';
	@override String get tvFullCardLayoutDescription => 'Usar tarjetas TV solo con imagen y nombres de actores superpuestos';
	@override String get focusGlow => 'Resplandor de selección';
	@override String get focusGlowDescription => 'Mostrar un resplandor suave alrededor de la tarjeta seleccionada';
	@override String get visualEffects => 'Efectos visuales';
	@override String get visualEffectsAuto => 'Automático';
	@override String get visualEffectsAutoDescription => 'Reduce automáticamente los efectos en dispositivos de bajo consumo';
	@override String get visualEffectsFull => 'Completos';
	@override String get visualEffectsReduced => 'Reducidos';
	@override String get visualEffectsReducedDescription => 'Menos animaciones e ilustraciones de menor resolución';
	@override String get hideSpoilers => 'Ocultar spoilers de episodios no vistos';
	@override String get hideSpoilersDescription => 'Desenfocar miniaturas y descripciones de episodios no vistos';
	@override String get playerBackend => 'Motor de reproducción';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'Decodificación por hardware';
	@override String get hardwareDecodingDescription => 'Usar aceleración por hardware cuando esté disponible';
	@override String get playbackBuffer => 'Búfer de reproducción';
	@override String get playbackBufferAuto => 'Automático (recomendado)';
	@override String get playbackBufferLarge => 'Grande';
	@override String get playbackBufferExtraLarge => 'Extra grande';
	@override String get playbackBufferDescription => 'Almacena más en búfer para conexiones inestables. También limitado por el tamaño del búfer.';
	@override String get streamBufferSize => 'El tamaño de buffer';
	@override String streamBufferSizeValue({required Object size}) => '${size} MB';
	@override String get streamBufferSizeDescription => 'Cuánto vídeo se carga antes cuando se juega directamente. transcodes se detiene en el buffer de transcódulos del servidor. 0 = Auto';
	@override String get streamBufferSizeExoNote => 'Replaza el Playback Buffer cuando se establece, captado a la mitad del límite de memoria de la aplicación';
	@override String get streamBufferMegabytes => 'Megabytes';
	@override String get defaultQualityTitle => 'Calidad predeterminada';
	@override String get cellularQualityTitle => 'Calidad predeterminada en datos móviles';
	@override String get remoteQualityTitle => 'La calidad de la transmisión a distancia';
	@override String get remoteQualitySameAsDefault => 'La misma calidad que la de default';
	@override String get cellularQualitySameAsDefault => 'Igual que la calidad predeterminada';
	@override String get directPlayCoveredQuality => 'Reproducir videos más pequeños en calidad original';
	@override String get directPlayCoveredQualityDescription => 'Reproducir directamente los videos que ya están dentro del límite de calidad en lugar de transcodificarlos';
	@override String get videoCodecs => 'Códecs de video';
	@override String get videoCodecsDescription => 'El servidor transcodifica los códecs no marcados';
	@override String get videoCodecsAlwaysAccepted => 'Siempre aceptado';
	@override String get musicQualityTitle => 'Calidad de música';
	@override String get subtitleStyling => 'Estilo de subtítulos';
	@override String get subtitleStylingDescription => 'Personalizar la apariencia de los subtítulos';
	@override String get smallSkipDuration => 'Salto pequeño';
	@override String get largeSkipDuration => 'Salto grande';
	@override String get rewindOnResume => 'Rebobinar al reanudar';
	@override String secondsUnit({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(seconds,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} segundo',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} segundos',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} segundos',
	);
	@override String get defaultSleepTimer => 'Temporizador de apagado';
	@override String minutesUnit({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(minutes,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minuto',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minutos',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minutos',
	);
	@override String get rememberTrackSelections => 'Recordar selección de pistas por serie/película';
	@override String get chooseTracksBeforePlayback => 'Seleccione audio y subtitulos antes de reproducir';
	@override String get chooseTracksBeforePlaybackDescription => 'Seleccione el audio y las pistas de subtitulos de fuente antes de que cada vídeo comience.';
	@override String get alwaysShowSubtitlesOnDevice => 'Siempre mostrar subtítulos en este dispositivo';
	@override String get alwaysShowSubtitlesOnDeviceDescription => 'Cuando el servidor no tiene ningún subtitulo seleccionado, seleccione un track localmente.';
	@override String get autoDownloadPreferredSubtitle => 'Fechos de los subtítulos preferidos';
	@override String get autoDownloadPreferredSubtitleDescription => 'Seleccione un subtitulo disponible en su lenguaje preferido localmente.Si no existe, pida al servidor que se encuentre uno cuando se apoya.';
	@override String get rememberTrackSelectionsDescription => 'Recordar opciones de audio y subtítulos por título';
	@override String get rememberTrackSelectionsBackendRule => 'Plex guarda cada elección en el servidor por archivo; Jellyfin también activa «Recordar selecciones» de la cuenta; Emby no es compatible';
	@override String get followServerTrackSelections => 'Usar la selección de pistas del servidor por episodio';
	@override String get followServerTrackSelectionsDescription => 'Al cambiar de episodio, aplicar el audio y los subtítulos seleccionados en el servidor en lugar de mantener la elección actual';
	@override String get resumeMusicOnLaunch => 'Recordar la sesión de música';
	@override String get resumeMusicOnLaunchDescription => 'Al iniciar la aplicación, reabrir la última canción en pausa donde se quedó';
	@override String get showChapterMarkersOnTimeline => 'Mostrar marcadores de capítulos en la barra de progreso';
	@override String get showChapterMarkersOnTimelineDescription => 'Dividir la barra de progreso en los límites de capítulos';
	@override String get specialsOrdering => 'Especiales en orden de episodios';
	@override String get specialsOrderingDescription => 'Dónde se reproducen los especiales en el orden de visualización de una serie';
	@override String get specialsOrderingServer => 'Seguir orden del servidor';
	@override String get specialsOrderingAirDate => 'Intercalar por fecha de emisión';
	@override String get specialsOrderingLast => 'Después de las temporadas normales';
	@override String get clickVideoTogglesPlayback => 'Clic en el video para reproducir/pausar';
	@override String get clickVideoTogglesPlaybackDescription => 'Haz clic en el video para reproducir/pausar en vez de mostrar controles.';
	@override String get videoPlayerControls => 'Controles del reproductor de video';
	@override String get keyboardShortcuts => 'Atajos de teclado';
	@override String get keyboardShortcutsDescription => 'Personalizar los atajos de teclado';
	@override String get videoPlayerNavigation => 'Navegación del reproductor de video';
	@override String get videoPlayerNavigationDescription => 'Usar las teclas de flecha para navegar por los controles del reproductor';
	@override String get watchTogetherRelay => 'Servidor de retransmisión de Ver juntos';
	@override String get watchTogetherRelayDescription => 'Servidores de retransmisión públicos de Open Watch Party, salvo que configures el tuyo';
	@override String get watchTogetherRelayHint => 'https://mi-relay.ejemplo.com';
	@override String get watchTogetherRelayInvalid => 'Introduce una URL base HTTP o HTTPS válida para el servidor de retransmisión.';
	@override String get crashReporting => 'Informes de errores';
	@override String get crashReportingDescription => 'Enviar informes de errores para mejorar la aplicación';
	@override String get debugLogging => 'Registro de depuración';
	@override String get debugLoggingDescription => 'Habilitar registros detallados para solucionar problemas';
	@override String get viewLogs => 'Ver registros';
	@override String get viewLogsDescription => 'Ver los registros de la aplicación';
	@override String get clearImageCache => 'Vaciar caché de imágenes';
	@override String get clearImageCacheDescription => 'Borra las carátulas y miniaturas guardadas en caché. Las imágenes pueden tardar más en cargar hasta que se descarguen de nuevo.';
	@override String get clearImageCacheSuccess => 'Caché de imágenes vaciada correctamente';
	@override String get resetSettings => 'Restablecer configuración';
	@override String get resetSettingsDescription => 'Restaurar ajustes predeterminados. No se puede deshacer.';
	@override String get resetSettingsSuccess => 'Configuración restablecida con éxito';
	@override String get backup => 'Copia de seguridad';
	@override String get exportSettings => 'Exportar configuración';
	@override String get exportSettingsDescription => 'Guardar tus preferencias en un archivo';
	@override String get exportSettingsSuccess => 'Configuración exportada';
	@override String get importSettings => 'Importar configuración';
	@override String get importSettingsDescription => 'Restaurar preferencias desde un archivo';
	@override String get importSettingsConfirm => 'Esto reemplazará tu configuración actual. ¿Continuar?';
	@override String get importSettingsSuccess => 'Configuración importada';
	@override String get importSettingsInvalidFile => 'Este archivo no es una exportación válida de PlezyNG';
	@override String get importSettingsNoUser => 'Inicia sesión antes de importar la configuración';
	@override String get cloudBackup => 'Nuevos Backup';
	@override String get cloudBackupDescription => 'Guarda una copia de seguridad de los ajustes transferibles en una dirección WebDAV mediante HTTPS. Las conexiones a los servidores y las credenciales permanecen en este dispositivo.';
	@override String get cloudBackupUrl => 'WebDAV URL de archivo JSON';
	@override String get cloudBackupUsername => 'Usuario';
	@override String get cloudBackupPassword => 'Contraseña';
	@override String get cloudBackupSaved => 'Cloud Backup Destino Salvo';
	@override String get cloudBackupNow => 'Volver ahora';
	@override String get cloudBackupComplete => 'Configuraciones de backup uploaded';
	@override String get cloudBackupRestore => 'Restaurar la Backup';
	@override String get cloudBackupRestoreConfirm => 'Esto sustituirá las configuraciones portátiles que se ajustan a este dispositivo.';
	@override String get cloudBackupRestored => 'Configuraciones restauradas de la backup en la nube';
	@override String get shortcutsReset => 'Atajos restablecidos a los valores predeterminados';
	@override String get resetShortcutsConfirm => 'Esto reemplazará tus atajos personalizados por los predeterminados. ¿Continuar?';
	@override String get about => 'Acerca de';
	@override String get aboutDescription => 'Información de la aplicación y licencias';
	@override String get updates => 'Actualizaciones';
	@override String get updateAvailable => 'Actualización disponible';
	@override String get checkForUpdates => 'Buscar actualizaciones';
	@override String get autoCheckUpdatesOnStartup => 'Buscar actualizaciones automáticamente al iniciar';
	@override String get autoCheckUpdatesOnStartupDescription => 'Avisar al iniciar si hay una actualización disponible';
	@override String get validationErrorEnterNumber => 'Introduce un número válido';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'La duración debe estar entre ${min} y ${max} ${unit}';
	@override String shortcutAlreadyAssigned({required Object action}) => 'El atajo ya está asignado a ${action}';
	@override String shortcutUpdated({required Object action}) => 'Atajo actualizado para ${action}';
	@override String get saveFailed => 'No se pudieron guardar los cambios. Inténtalo de nuevo.';
	@override String get autoPlayAndSkip => 'Reproducción automática y saltos';
	@override String get autoPlayNextEpisode => 'Reproducción automática del siguiente episodio';
	@override String get autoPlayNextEpisodeDescription => 'Iniciar automáticamente el siguiente episodio cuando termine el actual';
	@override String get shuffleStartsFromBeginning => 'La reproducción aleatoria empieza desde el principio';
	@override String get shuffleStartsFromBeginningDescription => 'Empezar cada episodio desde el principio en reproducción aleatoria en lugar de reanudarlo';
	@override String get plexCinemaPreRoll => 'El servidor de cine intros';
	@override String get plexCinemaPreRollDescription => 'Juega configurados Plex pre-rolls o Jellyfin y Emby intros antes de que una película empiece.';
	@override String get playNextCountdown => 'Cuenta atrás para el siguiente episodio';
	@override String get playNextCountdownImmediate => 'Reproducir de inmediato';
	@override String get skipIntroMode => 'Saltar intro';
	@override String get skipIntroModeOffDescription => 'Reproducir las intros normalmente sin botón de salto';
	@override String get skipIntroModeButtonDescription => 'Mostrar un botón de salto cuando empiece una intro';
	@override String get skipIntroModeAutoDescription => 'Saltar las intros automáticamente tras el retraso indicado abajo';
	@override String get skipCreditsMode => 'Saltar créditos';
	@override String get skipCreditsModeOffDescription => 'Reproducir los créditos normalmente sin botón de salto';
	@override String get skipCreditsModeButtonDescription => 'Mostrar un botón de salto cuando empiecen los créditos';
	@override String get skipCreditsModeAutoDescription => 'Saltar los créditos automáticamente y reproducir el siguiente episodio';
	@override String get skipAdsMode => 'Descargar Ads';
	@override String get skipAdsModeOffDescription => 'Play detecta anuncios normalmente sin un botón de escape';
	@override String get skipAdsModeButtonDescription => 'Mostrar un botón de escape cuando Plex detecta un anuncio';
	@override String get skipAdsModeAutoDescription => 'Descargar los anuncios detectados automáticamente después del retraso a continuación';
	@override String get musicPlayback => 'Música Playback';
	@override String get musicSweetFades => 'Sujeto Fades';
	@override String get musicSweetFadesDescription => 'La música se desliza en los límites de la pista cuando Plex tiene datos de ruido.';
	@override String get skipMarkerModeOff => 'Desactivado';
	@override String get skipMarkerModeButton => 'Mostrar botón';
	@override String get skipMarkerModeAuto => 'Automático';
	@override String get forceSkipMarkerFallback => 'Forzar marcadores alternativos';
	@override String get forceSkipMarkerFallbackDescription => 'Usar patrones de títulos de capítulos aunque Plex tenga marcadores';
	@override String get theIntroDbFallback => 'Utilice el TheIntroDB como un intro fallback';
	@override String get theIntroDbFallbackDescription => 'Utilice las timing de la comunidad sólo cuando el servidor no tiene marcador de intro.';
	@override String get autoSkipDelay => 'Retraso del salto automático';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Esperar ${seconds} segundos antes de saltar automáticamente';
	@override String get introPattern => 'Patrón de marcador de introducción';
	@override String get introPatternDescription => 'Expresión regular para reconocer marcadores de introducción en los títulos de los capítulos';
	@override String get creditsPattern => 'Patrón de marcador de créditos';
	@override String get creditsPatternDescription => 'Expresión regular para reconocer marcadores de créditos en los títulos de los capítulos';
	@override String get prerolls => 'Prerolles';
	@override String get playPrerollsBeforeMovies => 'Juega los próroles antes de los filmes';
	@override String get playPrerollsBeforeMoviesDescription => 'Play a un clip aleatorio de su selección a continuación antes de cada película.';
	@override String get prerollLibrary => 'Biblioteca Preroll';
	@override String get prerollLibraryNotSet => 'No establecido';
	@override String get prerollLibraryNoneFound => 'No se encuentran bibliotecas en sus servidores.';
	@override String get prerollSelection => 'Los prerólogos seleccionados';
	@override String get prerollSelectionPickLibraryFirst => 'Póngase una biblioteca primero';
	@override String get prerollSelectionNoneSelected => 'No hay prerólogos seleccionados';
	@override String prerollSelectionCount({required Object count}) => '${count} seleccionados';
	@override String get prerollItemPicker => 'Seleccion de prerogados';
	@override String get prerollItemPickerLoadFailed => 'No podían cargar artículos de esta biblioteca.';
	@override String get invalidRegex => 'Expresión regular no válida';
	@override String get regex => 'Expresión regular';
	@override String get downloads => 'Descargas';
	@override String get downloadLocationDescription => 'Elegir dónde almacenar el contenido descargado';
	@override String get downloadLocationDefault => 'Predeterminado (almacenamiento de la aplicación)';
	@override String get downloadLocationCustom => 'Ubicación personalizada';
	@override String get selectFolder => 'Seleccionar carpeta';
	@override String get resetToDefault => 'Restablecer al predeterminado';
	@override String currentPath({required Object path}) => 'Actual: ${path}';
	@override String get downloadLocationChanged => 'Ubicación de descarga cambiada';
	@override String get downloadLocationReset => 'Ubicación de descarga restablecida al predeterminado';
	@override String get downloadLocationInvalid => 'La carpeta seleccionada no tiene permisos de escritura';
	@override String get downloadLocationPickerUnavailable => 'La selección de carpetas no está disponible en este dispositivo';
	@override String get downloadOnWifiOnly => 'Descargar solo con WiFi';
	@override String get downloadOnWifiOnlyDescription => 'Evitar descargas cuando se usan datos móviles';
	@override String get autoRemoveWatchedDownloads => 'Eliminar descargas vistas automáticamente';
	@override String get autoRemoveWatchedDownloadsDescription => 'Eliminar automáticamente descargas vistas';
	@override String get autoDownloadContinueWatching => 'Auto-Download Continúa Visto';
	@override String get autoDownloadContinueWatchingDescription => 'Mantenga los artículos en su esqueleto de seguimiento continuado descargados, y quita los elementos una vez que dejan el esqueleto';
	@override String get downloadQuality => 'Descarga de calidad';
	@override String get downloadQualityDescription => 'Plex prepara una copia convertida en su cueva de descarga. Jellyfin y Emby transcódicos mientras el archivo se descarga; los transferencias interrumpidos pueden necesitar reiniciar.';
	@override String get askDownloadQualityEachTime => 'Elegir la calidad para cada descarga';
	@override String get askDownloadQualityEachTimeDescription => 'Mostrar el picker de calidad antes de quejar cada descarga de vídeo';
	@override String get cellularDownloadBlocked => 'Las descargas están bloqueadas en red móvil. Usa WiFi o cambia el ajuste.';
	@override String get maxVolume => 'Volumen máximo';
	@override String get maxVolumeDescription => 'Permitir aumento de volumen por encima del 100% para medios con sonido bajo';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Presencia de Discord';
	@override String get discordRichPresenceDescription => 'Mostrar lo que estás viendo en Discord';
	@override String get services => 'Servicios';
	@override String get servicesDescription => 'Conecta Trakt, MyAnimeList, Seerr y más';
	@override String get manageLibrariesDescription => 'Reordena y oculta bibliotecas';
	@override String get companionRemoteServer => 'Servidor de control remoto';
	@override String get companionRemoteServerDescription => 'Permitir que dispositivos móviles en tu red controlen esta aplicación';
	@override String get companionRemoteServerStartFailed => 'No se pudo iniciar el servidor de control remoto';
	@override String get companionRemoteServerStopFailed => 'No se pudo detener el servidor de control remoto';
	@override String get autoPip => 'Imagen en imagen automática';
	@override String get autoPipDescription => 'Activar automáticamente el modo de imagen en imagen al salir de la aplicación durante la reproducción';
	@override String get matchContentFrameRate => 'Ajustar frecuencia de actualización';
	@override String get matchContentFrameRateDescription => 'Ajustar la frecuencia de pantalla al contenido de video';
	@override String get matchContentResolution => 'Ajustar a la resolución del contenido';
	@override String get matchContentResolutionDescription => 'Cambia la pantalla a la resolución nativa del vídeo para que tu televisor se encargue del escalado. Los menús y los subtítulos también se escalan durante la reproducción';
	@override String get matchRefreshRate => 'Ajustar frecuencia de refresco';
	@override String get matchRefreshRateDescription => 'Ajustar la frecuencia de pantalla en pantalla completa';
	@override String get matchDynamicRange => 'Ajustar rango dinámico';
	@override String get matchDynamicRangeDescription => 'Activar HDR para contenido HDR y luego volver a SDR';
	@override String get displaySwitchDelay => 'Retraso de cambio de pantalla';
	@override String get tunneledPlayback => 'Reproducción tunelizada';
	@override String get tunneledPlaybackDescription => 'Usar tunelización de video. Desactívala si HDR muestra video negro o el movimiento se entrecorta.';
	@override String get audioPassthrough => 'Transferencia directa de audio';
	@override String get audioPassthroughDescription => 'Envía el audio Dolby/DTS a tu receptor o TV sin recodificar, conservando el sonido envolvente. Desactívala si no tienes sonido.';
	@override String get audioPassthroughDescriptionApple => 'Usa el decodificador Dolby nativo de Apple para Dolby Digital Plus, incluido Atmos. DTS y TrueHD se siguen reproduciendo como PCM multicanal. Desactívalo si no tienes sonido.';
	@override String get audioPassthroughDescriptionAppleSpatial => 'Usa el decodificador Dolby nativo de Apple para Dolby Digital Plus, incluido Atmos. En iOS, iPadOS y tvOS 26 o posterior, TrueHD Atmos y DTS:X se reproducen como audio espacial. El resto de pistas DTS y TrueHD se reproducen como PCM multicanal. Desactívalo si no tienes sonido.';
	@override String get audioPassthroughOverriddenByNormalization => 'Desactivada mientras la normalización de volumen esté activada';
	@override String get audioChannelLimit => 'Canales de audio';
	@override String get audioChannelLimitDescription => 'Mezcla el audio decodificado a menos canales para altavoces, auriculares o equipos HDMI que no pueden reproducir todos los canales';
	@override String get audioChannelLimitOriginal => 'Original';
	@override String get audioChannelLimitOriginalDescription => 'Reproduce todos los canales de la pista';
	@override String get audioChannelLimitSurround51 => 'Hasta 5.1';
	@override String get audioChannelLimitSurround51Description => 'Mezcla 7.1 a 5.1 para televisores y receptores que solo admiten PCM 5.1. No afecta a la transferencia directa.';
	@override String get audioChannelLimitStereo => 'Estéreo';
	@override String get audioChannelLimitStereoDescription => 'Mezcla a dos canales para altavoces estéreo o auriculares. Desactiva la transferencia directa.';
	@override String get downmixCenterBoost => 'Realce del canal central';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'Realce (dB)';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => 'Normalizar volumen al mezclar';
	@override String get audioDownmixNormalizeDescription => 'Reduce la mezcla para evitar saturación. Desactívalo para mantener el volumen original (puede distorsionar escenas fuertes).';
	@override String get dvConversionMode => 'Conversión de Dolby Vision';
	@override String get dvConversionModeDescription => 'Elige cómo se gestionan los archivos Dolby Vision de perfil 7.';
	@override String get dvConversionAuto => 'Automático';
	@override String get dvConversionNative => 'Nativo / desactivado';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Usar la detección de capacidades del dispositivo y el comportamiento alternativo normal';
	@override String get dvConversionNativeDescription => 'Forzar DV7 nativo y suprimir el reintento de conversión DV';
	@override String get dvConversionDv81Description => 'Forzar la conversión de RPU en línea al perfil 8.1 de Dolby Vision';
	@override String get dvConversionHevcStripDescription => 'Eliminar las capas RPU/EL de Dolby Vision y presentar HEVC convencional';
	@override String get experimentalDolbyVision => 'Dolby Vision experimental';
	@override String get experimentalDolbyVisionDescription => 'Usar el renderizador FEL experimental en la próxima reproducción. Requiere una compilación independiente del motor.';
	@override String get dvExperimentUnavailableDescription => 'Este experimento solo está disponible en Linux por ahora.';
	@override String get dvCompatibilityFallback => 'Alternativa de compatibilidad';
	@override String get dvCompatibilityFallbackDescription => 'Usar el renderizador estándar si el experimento no puede iniciarse. Se pueden perder los datos FEL.';
	@override String get dvExperimentDiagnostics => 'Registro del experimento de vídeo';
	@override String get dvExperimentDiagnosticsDescription => 'Activar registros detallados del reproductor en la próxima reproducción.';
	@override String get disableDolbyVision => 'Desactivar Dolby Vision';
	@override String get disableDolbyVisionDescription => 'Reproducir la capa HDR10 o HLG del archivo en lugar de Dolby Vision, si la tiene';
	@override String get hdrSdrConversion => 'Conversión de HDR a SDR';
	@override String get hdrSdrConversionDescription => 'Elige qué convierte el vídeo HDR cuando la pantalla no puede mostrar HDR.';
	@override String get hdrSdrConversionAuto => 'Automático';
	@override String get hdrSdrConversionAutoDescription => 'Dispositivo en Android 9 y posteriores, reproductor en versiones anteriores';
	@override String get hdrSdrConversionDevice => 'Dispositivo';
	@override String get hdrSdrConversionDeviceDescription => 'El hardware de vídeo del dispositivo realiza la conversión. Lo más rápido, pero los colores dependen del dispositivo';
	@override String get hdrSdrConversionPlayer => 'Reproductor';
	@override String get hdrSdrConversionPlayerDescription => 'El reproductor realiza la conversión. Colores uniformes, pero el 4K puede ir a tirones en TV boxes de gama baja';
	@override String get deinterlace => 'Desentrelazado';
	@override String get deinterlaceDescription => 'Elimina los artefactos de peine del video entrelazado (solo reproductor mpv)';
	@override String get deinterlaceOff => 'Desactivado';
	@override String get deinterlaceOffDescription => 'Muestra el video entrelazado tal como se decodifica';
	@override String get deinterlaceVideo => 'Video';
	@override String get deinterlaceVideoDescription => 'Convierte cada campo en un fotograma completo. Para video grabado para TV, como deportes, noticias y conciertos';
	@override String get deinterlaceFilm => 'Cine';
	@override String get deinterlaceFilmDescription => 'Restaura los fotogramas originales de películas y animación convertidas por telecine a 29,97 fps, algo habitual en los DVD NTSC. El video grabado para TV se entrecorta. La TV en vivo usa el modo Video';
	@override String get requireProfileSelectionOnOpen => 'Pedir perfil al abrir la aplicación';
	@override String get requireProfileSelectionOnOpenDescription => 'Mostrar selección de perfil cada vez que se abre la aplicación';
	@override String get forceTvMode => 'Forzar modo TV';
	@override String get forceTvModeDescription => 'Forzar diseño TV. Para dispositivos que no lo detectan. Requiere reinicio.';
	@override String get startInFullscreen => 'Iniciar en pantalla completa';
	@override String get startInFullscreenDescription => 'Abrir PlezyNG en modo pantalla completa al iniciar';
	@override String get exitFullscreenOnPlayerClose => 'Salir de pantalla completa al cerrar el reproductor';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Salir automáticamente del modo de pantalla completa al cerrar el reproductor de video';
	@override String get autoHidePerformanceOverlay => 'Ocultar superposición de rendimiento automáticamente';
	@override String get autoHidePerformanceOverlayDescription => 'Desvanecer la superposición de rendimiento con los controles de reproducción';
	@override String get showNavBarLabels => 'Mostrar etiquetas de la barra de navegación';
	@override String get showNavBarLabelsDescription => 'Mostrar etiquetas de texto bajo los iconos de la barra de navegación';
	@override String get startupSection => 'Sección de inicio';
	@override String get preferredServer => 'Preferido servidor';
	@override String get preferredServerDescription => 'Priorizar los resultados de este servidor mientras que mantener cada servidor conectado disponible.';
	@override String get preferredServerAutomatic => 'Automático';
	@override String get showExploreTab => 'Mostrar pestaña Explorar';
	@override String get showExploreTabDescription => 'Muestra la pestaña Explorar con contenido de Plex Discover y servicios de seguimiento conectados';
	@override String get hideEmptyLibraries => 'Esconde las bibliotecas vacías';
	@override String get hideEmptyLibrariesDescription => 'Removemos bibliotecas con un número de artículos reportados por el servidor de cero de la navegación.';
	@override String get liveTvDefaultFavorites => 'Canales favoritos por defecto';
	@override String get liveTvDefaultFavoritesDescription => 'Mostrar solo canales favoritos al abrir TV en vivo';
	@override String get general => 'General';
	@override String get generalDescription => 'Idioma, inicio y comportamiento de la ventana';
	@override String get languageAndRegion => 'Idioma y región';
	@override String get startup => 'Inicio';
	@override String get display => 'Pantalla';
	@override String get libraryAndCards => 'Biblioteca y tarjetas';
	@override String get homeScreen => 'Pantalla de inicio';
	@override String get navigation => 'Navegación';
	@override String get window => 'Ventana';
	@override String get liveTv => 'TV en vivo';
	@override String get player => 'Reproductor';
	@override String get videoAndDisplay => 'Video y pantalla';
	@override String get audio => 'Audio';
	@override String get quality => 'Calidad';
	@override String get subtitles => 'Subtítulos';
	@override String get seekAndTiming => 'Desplazamiento y tiempos';
	@override String get behavior => 'Comportamiento';
	@override String get gestures => 'Gestos';
	@override String get gestureBrightnessSwipe => 'Gesto de brillo';
	@override String get gestureBrightnessSwipeDescription => 'Desliza hacia arriba o abajo en el borde izquierdo para ajustar el brillo';
	@override String get gestureVolumeSwipe => 'Gesto de volumen';
	@override String get gestureVolumeSwipeDescription => 'Desliza hacia arriba o abajo en el borde derecho para ajustar el volumen';
	@override String get gesturePinchToZoom => 'Pellizcar para hacer zoom';
	@override String get gesturePinchToZoomDescription => 'Pellizca el video para acercar o alejar';
	@override String get gestureSeekSwipe => 'Buscar Swipe';
	@override String get gestureSeekSwipeDescription => 'Descargar la izquierda o la derecha en cualquier lugar en el video para buscar; liberar para saltar';
	@override String get rememberBrightnessLevel => 'Recordar nivel de brillo';
	@override String get rememberBrightnessLevelDescription => 'Iniciar la reproducción con el brillo establecido por el último deslizamiento';
	@override String get controls => 'Controles';
	@override String get rememberPlayerChanges => 'Recordar cambios del reproductor';
	@override String get rememberPlayerChangesDescription => 'Dónde se guarda y se vuelve a aplicar un cambio realizado durante la reproducción';
	@override String get scopePlaybackSpeed => 'Velocidad de reproducción';
	@override String get scopeShaderPreset => 'Preajuste de sombreado';
	@override String get scopeAspectRatio => 'Relación de aspecto';
	@override String get scopeSyncOffsets => 'Sincronización de audio y subtítulos';
	@override String get playerScopeOff => 'No guardar';
	@override String get playerScopeGlobal => 'En todas partes';
	@override String get playerScopeLibrary => 'Por biblioteca';
	@override String get playerScopeTitle => 'Por serie o película';
	@override String get exportDialogTitle => 'Exportar ajustes de PlezyNG';
	@override String get followSystem => 'Seguir el sistema';
	@override String get followAppLanguage => 'Igual que el idioma de la interfaz';
	@override String get regionFormat => 'Formatos regionales';
	@override String get regionFormatDescription => 'Elige cómo se muestran las fechas, los números y las unidades de medida.';
	@override String get metadataLanguage => 'Idioma de los metadatos';
	@override String get metadataLanguageDescription => 'Idioma preferido para títulos y descripciones cuando el servidor lo permita. Las preferencias de audio y subtítulos se configuran por separado.';
	@override String get enterFullscreenOnPlaybackStart => 'Entrar en pantalla completa cuando comienza el playback';
	@override String get enterFullscreenOnPlaybackStartDescription => 'Abre vídeo de escritorio en pantalla completa cuando comienza el playback';
	@override String get extendVideoIntoDisplayCutout => 'Extendir el video a la pantalla Cutout';
	@override String get extendVideoIntoDisplayCutoutDescription => 'Deja que el vídeo de pantalla completa utilice la cámara en los teléfonos Android';
	@override String get languageDescription => 'Seleccione el idioma utilizado para los controles y mensajes de PlezyNG. Seguir sistema rastreará su lenguaje del dispositivo.';
	@override String get themeDescription => 'Seleccione los colores y contraste utilizados en toda la aplicación.';
	@override String get libraryDensityDescription => 'Cambiar cuántas tarjetas de biblioteca se ajustan en cada línea.';
	@override String get displayScaleDescription => 'Recupere la interfaz en esta pantalla de automóvil sin cambiar el tamaño del texto en todo el dispositivo.';
	@override String get themeSongVolumeDescription => 'Define el volumen de las canciones temáticas en relación con otros audio.';
	@override String get viewModeDescription => 'Seleccione si los artículos de la biblioteca aparecen como carteles en una red o como una lista compacta.';
	@override String get gridViewDescription => 'Arreglar los artículos de la biblioteca en líneas y columnas de carteles.';
	@override String get listViewDescription => 'Mostrar artículos de la biblioteca en una lista vertical con más texto por elemento.';
	@override String get gridSpacingDescription => 'Configure la distancia entre los carteles en las redes de bibliotecas.';
	@override String get gridSpacingTightDescription => 'Coloque más carteles a través de la pantalla con pequeñas franjas.';
	@override String get gridSpacingNormalDescription => 'Utilice la franja estándar entre los carteles.';
	@override String get gridSpacingSpaciousDescription => 'Añadir grandes franjas entre los carteles para más separación.';
	@override String get episodePosterModeDescription => 'Seleccione qué arte aparece en las tarjetas de episodios.';
	@override String get seriesPosterDescription => 'Utilice el poster de la serie para cada episodio.';
	@override String get seasonPosterDescription => 'Utilice el poster de temporada para cada episodio cuando esté disponible.';
	@override String get episodeThumbnailDescription => 'Utilice un marco del episodio cuando esté disponible.';
	@override String get continueWatchingActionDescription => 'Seleccione lo que sucede cuando activas una tarjeta de seguimiento continua.';
	@override String get continueWatchingPlayDescription => 'Comienza la película o el episodio de inmediato.';
	@override String get continueWatchingDetailsDescription => 'Abre la página de título primero para que pueda revisar los detalles y elegir una acción.';
	@override String get episodeActionDescription => 'Seleccione lo que sucede cuando activas una tarjeta de episodio.';
	@override String get episodePlayDescription => 'Comienza el episodio de inmediato.';
	@override String get episodeDetailsDescription => 'Abre la página de episodios antes del playback.';
	@override String get contentScreensaverDelayDescription => 'Seleccione cuánto tiempo PlezyNG espera sin entrada antes de mostrar arte.';
	@override String get continueWatchingRowSizeDescription => 'Seleccione cuán grandes son las tarjetas en la línea de seguimiento continuo.';
	@override String get rowSizeCompactDescription => 'Mostrar tarjetas más pequeñas para que más artículos se ajusten a través de la línea.';
	@override String get rowSizeStandardDescription => 'Utilice el tamaño de la tarjeta.';
	@override String get rowSizeLargeDescription => 'Mostrar tarjetas más grandes con más detalles de arte.';
	@override String get visualEffectsDescription => 'Seleccione el presupuesto de los efectos de animación y arte para este dispositivo.';
	@override String get visualEffectsFullDescription => 'Utilice los efectos de animación y arte completo en cada dispositivo.';
	@override String get startupSectionDescription => 'Seleccione la sección que se abre cuando empieza PlezyNG.';
	@override late final Translations$settings$startupSectionOptions$es startupSectionOptions = Translations$settings$startupSectionOptions$es.internal(_root);
	@override String get smallSkipDurationDescription => 'Establece la distancia movida por el corto atrás y hacia adelante busca controles.';
	@override String get largeSkipDurationDescription => 'Establece la distancia movida por el largo atrás y hacia adelante busca controles.';
	@override String get rewindOnResumeDescription => 'Move playback de vuelta por este importe cuando vuelve a reproducir un vídeo.';
	@override String get defaultSleepTimerDescription => 'Establece la duración inicial utilizada cuando empiezas el horario del sueño.';
	@override String get playNextCountdownDescription => 'Espera mucho antes de que comience el siguiente episodio.Set a 0 para comenzar inmediatamente.';
	@override String get autoSkipDelaySettingDescription => 'Se aplica cuando un intro, crédito o anuncio se establece para escapar automáticamente.';
	@override String get downmixCenterBoostDescription => 'Aumentar el diálogo en el canal central cuando el audio circular se mezcla hacia abajo al estereo.';
	@override String get displaySwitchDelayDescription => 'Espera antes de cambiar el modo de pantalla para que la TV o receptor pueda terminar su anterior interrupción.';
	@override String get playerBackendDescription => 'Seleccione qué motor de reproducción decode y retrasa el vídeo en este dispositivo.';
	@override String get exoPlayerDescription => 'Utilice el reproductor nativo de Android Media3 y los caminos de hardware apoyados.';
	@override String get mpvDescription => 'Utilice mpv, que expone controles adicionales de reproducción, subtítulos y procesamiento de vídeo.';
	@override String get scopeOffDescription => 'Sólo mantenga los cambios para la sesión de reproducción actual.';
	@override String get scopeGlobalDescription => 'Reutilizar el mismo valor para cada biblioteca y título.';
	@override String get scopeLibraryDescription => 'Recuerda un valor separado para cada biblioteca.';
	@override String get scopeTitleDescription => 'Recuerda un valor separado para cada espectáculo o película.';
	@override String get specialsOrderingServerDescription => 'Mantenga la orden del episodio suministrada por el servidor de medios.';
	@override String get specialsOrderingAirDateDescription => 'Coloca especialidades entre episodios regulares por su fecha aérea.';
	@override String get specialsOrderingLastDescription => 'Coloca cada especial después de las temporadas regulares.';
	@override String get skipIntroModeDescription => 'Seleccione si los marcadores intro juegan normalmente, muestran un botón de escape o salen automáticamente.';
	@override String get skipCreditsModeDescription => 'Seleccione si los créditos se juegan normalmente, muestran un botón de escape o salen automáticamente.';
	@override String get skipAdsModeDescription => 'Seleccione si los anuncios detectados juegan normalmente, muestran un botón de escape o salen automáticamente.';
	@override String get playbackBufferAutoDescription => 'Deja al jugador activo elegir su tamaño normal del buffer.';
	@override String get playbackBufferLargeDescription => 'Mantenga más medios listos antes de reproducir; esto utiliza más memoria.';
	@override String get playbackBufferExtraLargeDescription => 'Mantenga el buffer de lectura más grande; esto utiliza la memoria más grande.';
	@override String get defaultQualityDescription => 'Configure la resolución de vídeo por defecto y bitrate el techo para los flujos que el servidor transcoda.';
	@override String get cellularQualityDescription => 'Override Default Quality cuando el dispositivo está utilizando una conexión celular-solo.';
	@override String get remoteQualityDescription => 'Override Default Quality cuando se conecta a un servidor a través de una conexión remota.';
	@override String get qualityPresetOriginalDescription => 'Juega la fuente a su calidad disponible sin pedir al servidor que la transcode.';
	@override String get qualityPresetTranscodeOptionDescription => 'Solicite al servidor para un flujo convertido utilizando la resolución y bitrate que se muestra anteriormente.';
	@override String get qualityPresetSameAsDefaultDescription => 'Utilice la calidad seleccionada en Calidad Default.';
	@override String get musicQualityDescription => 'Establece la bitrate máxima de audio solicitada del servidor; Original mantiene el flujo de fuente.';
	@override String get musicQualityOriginalDescription => 'Juega el audio de fuente sin un transcódigo capped por bitrate.';
	@override String get musicQualityTranscodeOptionDescription => 'Solicita un transcódico del servidor capped cerca de la bitrate mostrada anteriormente; el rendimiento real puede variar.';
	@override String get maxVolumeInputLabel => 'El volumen máximo (%)';
	@override String get checkForUpdatesDescription => 'Verifique ahora si está disponible una versión más nueva de PlezyNG.';
	@override String get appearanceDescription => 'Seleccione el tema de la aplicación y ajuste las tarjetas de la biblioteca, las líneas domésticas y la navegación.';
	@override String get prerollLibraryDescription => 'Seleccione la biblioteca que contiene los clips disponibles como pre-rolls de la película.';
	@override String get prerollSelectionDescription => 'Seleccione qué clips de la biblioteca seleccionada puede jugar antes de las películas.';
	@override String get contentScreensaverDelayOptionDescription => 'Esperar estos muchos minutos sin entrada antes de mostrar la pantalla de almacenamiento artwork.';
	@override String get videoCodecOptionDescription => 'Permite reproducción directa para este codec cuando se apoya. los codecs no verificados son transcodados por el servidor de medios.';
}

// Path: themeEditor
class Translations$themeEditor$es extends Translations$themeEditor$en {
	Translations$themeEditor$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get builtIn => 'Integrados';
	@override String get presets => 'Predefinidos';
	@override String get custom => 'Personalizado';
	@override String get customEmpty => 'Aún no creado';
	@override String get editCustom => 'Editar tema personalizado';
	@override String get editCustomDescription => 'Elige cada color tú mismo';
	@override String get locked => 'Acceso a la vida necesaria';
	@override String get savedLocked => 'Salvo - disponible con acceso a la vida';
	@override String get title => 'Tema personalizado';
	@override String get startFrom => 'Partir de';
	@override String get startFromDescription => 'Copia todos los colores de otro tema';
	@override String get colors => 'Colores';
	@override String get preview => 'Vista previa';
	@override late final Translations$themeEditor$slots$es slots = Translations$themeEditor$slots$es.internal(_root);
	@override String get opacity => 'Opacidad';
	@override String get hexHint => '#RRGGBB o #AARRGGBB';
	@override String get fromOtherThemes => 'De otros temas';
	@override String swatchLabel({required Object color, required Object theme}) => '${color} de ${theme}';
	@override late final Translations$themeEditor$contrast$es contrast = Translations$themeEditor$contrast$es.internal(_root);
	@override String lowContrast({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, por debajo del ${minimum}:1 recomendado';
	@override String get discardTitle => '¿Descartar cambios?';
	@override String get discardMessage => 'Se perderán los cambios de color no guardados.';
	@override String get discard => 'Descartar';
	@override String previewCardTitle({required Object number}) => 'Episodio ${number}';
	@override String previewCardSubtitle({required Object minutes}) => 'Quedan ${minutes} min';
	@override String get previewSwitch => 'Reproducción automática';
	@override String get previewMutedText => 'Así se ve el texto secundario';
	@override String get themeSystemDescription => 'Siga la apariencia de tu dispositivo y cambie automáticamente entre luz y oscuridad.';
	@override String get themeLightDescription => 'Utilice un fondo claro con texto oscuro.';
	@override String get themeDarkDescription => 'Utilice un fondo oscuro con texto claro.';
	@override String get themeOledDescription => 'Utilice superficies cercanas a negro que reducen la luz en las pantallas OLED.';
	@override String get themeEmberDescription => 'Utilice colores de acento amarillo y rojo caliente.';
	@override String get themeGlacierDescription => 'Utilice colores de acento azul fresco.';
	@override String get themeForestDescription => 'Utilice los colores de acento verde y natural.';
	@override String get themePlumDescription => 'Utilice colores de acento violeta y plum.';
	@override String get themePaperDescription => 'Utilice superficies cálidas como papel y colores inspirados en tinta.';
	@override String get themeCustomDescription => 'Utilice la paleta de colores que ha creado en el editor de temas personalizados.';
	@override String get editorDescription => 'Seleccione un color de paleta, ajuste su huevo, saturación, brillo o opacidad y vea la actualización previa antes de ahorrar.';
}

// Path: search
class Translations$search$es extends Translations$search$en {
	Translations$search$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Buscar películas, series, música...';
	@override String get tryDifferentTerm => 'Prueba con un término de búsqueda diferente';
	@override String get searchYourMedia => 'Busca en tu contenido';
	@override String get enterTitleActorOrKeyword => 'Introduce un título, actor o palabra clave';
	@override String get people => 'Personas';
}

// Path: hotkeys
class Translations$hotkeys$es extends Translations$hotkeys$en {
	Translations$hotkeys$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Establecer atajo para ${actionName}';
	@override String get clearShortcut => 'Borrar atajo';
	@override String get noShortcutSet => 'Sin atajo asignado';
	@override String get currentShortcut => 'Atajo actual:';
	@override String get pressToRecord => 'Seleccionar para grabar un atajo';
	@override String get recordingShortcut => 'Pulsa el atajo ahora';
	@override late final Translations$hotkeys$actions$es actions = Translations$hotkeys$actions$es.internal(_root);
}

// Path: fileInfo
class Translations$fileInfo$es extends Translations$fileInfo$en {
	Translations$fileInfo$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Información del archivo';
	@override String get overview => 'Resumen';
	@override String get video => 'Video';
	@override String get audio => 'Audio';
	@override String get subtitles => 'Subtítulos';
	@override String get images => 'Imágenes incrustadas';
	@override String get dataStreams => 'Flujos de datos';
	@override String get lyrics => 'Letras';
	@override String get file => 'Archivo';
	@override String get attachments => 'Archivos adjuntos';
	@override String get delivery => 'Entrega';
	@override String versionCounter({required Object index, required Object count}) => 'Versión ${index} de ${count}';
	@override String fileCounter({required Object index, required Object count}) => 'Archivo ${index} de ${count}';
	@override String get noStreams => 'El servidor no informó de ningún flujo para este archivo.';
	@override String get copyPath => 'Copiar ruta';
	@override String get pathCopied => 'Ruta del archivo copiada';
	@override String get codec => 'Códec';
	@override String get codecTag => 'Etiqueta de códec';
	@override String get resolution => 'Resolución';
	@override String get codedResolution => 'Resolución codificada';
	@override String get bitrate => 'Tasa de bits';
	@override String get frameRate => 'Frecuencia de fotogramas';
	@override String get rotation => 'Rotación';
	@override String get comment => 'Comentario';
	@override String get audioDescription => 'Audiodescripción';
	@override String get headerCompression => 'Compresión de cabecera';
	@override String get sidecarFile => 'Archivo auxiliar';
	@override String get transportTimestamp => 'Marca de tiempo de transporte';
	@override String get displayOffset => 'Desplazamiento de visualización';
	@override String get previewFailureCode => 'Código de error de vista previa';
	@override String get previewRetries => 'Reintentos de vista previa';
	@override String get aspectRatio => 'Relación de aspecto';
	@override String get pixelAspectRatio => 'Relación de aspecto de píxel';
	@override String get profile => 'Perfil';
	@override String get level => 'Nivel';
	@override String get bitDepth => 'Profundidad de bits';
	@override String get pixelFormat => 'Formato de píxel';
	@override String get colorSpace => 'Espacio de color';
	@override String get colorRange => 'Rango de color';
	@override String get colorPrimaries => 'Primarias de color';
	@override String get colorTransfer => 'Transferencia de color';
	@override String get chromaSubsampling => 'Submuestreo de croma';
	@override String get chromaLocation => 'Ubicación de crominancia';
	@override String get scanType => 'Tipo de escaneo';
	@override String get interlaced => 'Entrelazado';
	@override String get anamorphic => 'Anamórfico';
	@override String get referenceFrames => 'Fotogramas de referencia';
	@override String get dynamicRange => 'Rango dinámico';
	@override String get dolbyVision => 'Dolby Vision';
	@override String get dolbyVisionLevel => 'Nivel de Dolby Vision';
	@override String get dolbyVisionVersion => 'Versión de Dolby Vision';
	@override String get dolbyVisionLayers => 'Capas de Dolby Vision';
	@override String get baseLayerCompatibility => 'Compatibilidad de capa base';
	@override String get avcBitstream => 'Flujo de bits AVC';
	@override String get nalLengthSize => 'Tamaño de longitud NAL';
	@override String get scalingMatrix => 'Matriz de escalado personalizada';
	@override String get streamIdentifier => 'Identificador de flujo';
	@override String get streamIndex => 'Índice de flujo';
	@override String get streamId => 'ID de flujo';
	@override String get language => 'Idioma';
	@override String get languageCode => 'Código de idioma';
	@override String get streamTitle => 'Título de la pista';
	@override String get channels => 'Canales';
	@override String get sampleRate => 'Frecuencia de muestreo';
	@override String get spatialAudio => 'Audio espacial';
	@override String get textBased => 'Basado en texto';
	@override String get subtitleFormat => 'Formato de archivo auxiliar';
	@override String get provider => 'Proveedor';
	@override String get matchScore => 'Puntuación de coincidencia';
	@override String get externalDelivery => 'Puede servirse por separado';
	@override String get sidecarPath => 'Ruta del archivo auxiliar';
	@override String get sourceStream => 'Copiado de';
	@override String get temporary => 'Temporal';
	@override String get timeBase => 'Base de tiempo';
	@override String get overallBitrate => 'Tasa de bits total';
	@override String get path => 'Ruta';
	@override String get fileName => 'Nombre de archivo';
	@override String get size => 'Tamaño';
	@override String get totalSize => 'Tamaño total';
	@override String get container => 'Contenedor';
	@override String get duration => 'Duración';
	@override String get previewThumbnails => 'Miniaturas de vista previa';
	@override String get previewIndex => 'Índice de vista previa';
	@override String get packetLength => 'Longitud del paquete';
	@override String get filePresent => 'Archivo presente';
	@override String get fileReadable => 'Legible por el servidor';
	@override String get streamPath => 'Ruta del flujo';
	@override String get optimizedForStreaming => 'Optimizado para transmisión';
	@override String get has64bitOffsets => 'Desplazamientos de 64 bits';
	@override String get protocol => 'Protocolo';
	@override String get mediaType => 'Tipo de medio';
	@override String get sourceKind => 'Tipo de origen';
	@override String get optimizedVersion => 'Versión optimizada';
	@override String get optimizationTarget => 'Destino de optimización';
	@override String get deletedAt => 'Eliminado';
	@override String get remoteSource => 'Origen remoto';
	@override String get infiniteStream => 'Flujo infinito';
	@override String get directPlay => 'Reproducción directa';
	@override String get directStream => 'Flujo directo';
	@override String get transcoding => 'Transcodificación';
	@override String get etag => 'ETag';
	@override String get versionId => 'ID de versión';
	@override String get fileId => 'ID de archivo';
	@override String get defaultAudioTrack => 'Pista de audio predeterminada';
	@override String get defaultSubtitleTrack => 'Pista de subtítulos predeterminada';
	@override String get subtitlesOff => 'Desactivados';
	@override String get flagDefault => 'Predeterminada';
	@override String get flagForced => 'Forzada';
	@override String get flagSelected => 'Seleccionada';
	@override String get flagExternal => 'Externa';
	@override String get flagHearingImpaired => 'Para personas con discapacidad auditiva';
	@override String get flagDub => 'Doblaje';
	@override String get flagOriginal => 'Original';
	@override String get channelsMono => 'Mono';
	@override String dolbyVisionProfile({required Object profile}) => 'Perfil ${profile}';
}

// Path: mediaMenu
class Translations$mediaMenu$es extends Translations$mediaMenu$en {
	Translations$mediaMenu$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Marcar como visto';
	@override String get markAsUnwatched => 'Marcar como no visto';
	@override String get removeFromContinueWatching => 'Eliminar de Seguir viendo';
	@override String get viewDetails => 'Ver detalles';
	@override String get goToSeries => 'Ir a la serie';
	@override String get shufflePlay => 'Reproducción aleatoria';
	@override String get shuffleNotAvailableOffline => 'La reproducción aleatoria no está disponible sin conexión';
	@override String get fileInfo => 'Información del archivo';
	@override String get deleteEpisodeFromServer => 'Eliminar el episodio del servidor';
	@override String get deleteSeasonFromServer => 'Eliminar la temporada del servidor';
	@override String get deleteShowFromServer => 'Eliminar la serie del servidor';
	@override String get deleteMovieFromServer => 'Eliminar la película del servidor';
	@override String get deleteEpisodeTitle => '¿Eliminar este episodio?';
	@override String get deleteSeasonTitle => '¿Eliminar esta temporada?';
	@override String get deleteShowTitle => '¿Eliminar esta serie?';
	@override String get deleteMovieTitle => '¿Eliminar esta película?';
	@override String get deleteEpisodeConfirm => 'Eliminar episodio';
	@override String get deleteSeasonConfirm => 'Eliminar temporada';
	@override String get deleteShowConfirm => 'Eliminar serie';
	@override String get deleteMovieConfirm => 'Eliminar película';
	@override String get deleteAnyway => 'Eliminar de todos modos';
	@override String confirmDeleteTarget({required Object title}) => '¿Eliminar definitivamente ${title} de tu servidor?';
	@override String get deleteMultipleWarning => 'Esto incluye todos los episodios y sus archivos.';
	@override String deleteEpisodeCountWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: 'Esto elimina el único episodio que contiene y su archivo.',
		other: 'Esto elimina los ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episodios que contiene y sus archivos.',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: 'Este elemento se almacena en ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} archivo, que se eliminará.',
		other: 'Este elemento se almacena en ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} archivos, y todos se eliminarán.',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episodio más se almacena en el mismo archivo y también se eliminará:',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episodios más se almacenan en el mismo archivo y también se eliminarán:',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'PlezyNG no pudo comprobar qué archivos se eliminarán, por lo que podría borrar más de lo indicado arriba. Cancela y vuelve a intentarlo, o elimina de todos modos.';
	@override String get deleteScopeUnverifiedNoFileInfo => 'Tu servidor no proporcionó los detalles del archivo de este elemento, por lo que PlezyNG no puede comprobar qué archivos se eliminarán. Podría borrar más de lo indicado arriba.';
	@override String get mediaDeletedSuccessfully => 'Elemento multimedia eliminado con éxito';
	@override String get mediaFailedToDelete => 'Error al eliminar el elemento multimedia';
	@override String get rate => 'Calificar';
	@override String get playFromBeginning => 'Reproducir desde el inicio';
	@override String get playVersion => 'Reproducir versión...';
}

// Path: rateSheet
class Translations$rateSheet$es extends Translations$rateSheet$en {
	Translations$rateSheet$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Calificar';
	@override String get server => 'Servidor';
	@override String get favorite => 'Favorito';
	@override String get favorited => 'Marcado como favorito';
	@override String get saved => 'Guardado';
	@override String get notAvailable => 'No se encontró coincidencia';
	@override String get noConnectedServices => 'Conecta un servicio en Configuración para valorar el contenido en él.';
}

// Path: accessibility
class Translations$accessibility$es extends Translations$accessibility$en {
	Translations$accessibility$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, película';
	@override String mediaCardShow({required Object title}) => '${title}, serie de TV';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'visto';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent} por ciento visto';
	@override String get mediaCardUnwatched => 'no visto';
	@override String get tapToPlay => 'Toca para reproducir';
	@override String get decrease => 'Disminuir';
	@override String get increase => 'Aumentar';
	@override String decreaseValue({required Object label}) => 'Disminuir ${label}';
	@override String increaseValue({required Object label}) => 'Aumentar ${label}';
	@override String get hue => 'Tono';
	@override String get saturation => 'Saturación';
	@override String get brightness => 'Brillo';
	@override String get hexColor => 'Color hexadecimal';
	@override String get expandText => 'Expandir texto';
	@override String get collapseText => 'Contraer texto';
	@override String get alphabetNavigation => 'Navegación alfabética';
	@override String get alphabetScrollHint => 'Desliza hacia arriba o abajo para avanzar por letra';
	@override String rowColumnPosition({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Fila ${row} de ${rowCount}, columna ${column} de ${columnCount}';
	@override String rowPosition({required Object row, required Object rowCount}) => 'Fila ${row} de ${rowCount}';
	@override String get autoScrollPlay => 'Iniciar desplazamiento automático';
	@override String get autoScrollPause => 'Pausar desplazamiento automático';
	@override String get hueShort => 'H';
	@override String get saturationShort => 'S';
	@override String get valueShort => 'V';
	@override String get red => 'Red';
	@override String get green => 'Verde';
	@override String get blue => 'azul';
	@override String get redShort => 'R';
	@override String get greenShort => 'G';
	@override String get blueShort => 'B';
	@override String get colorModeHsv => 'HSV';
	@override String get colorModeRgb => 'RGB';
	@override String get title => 'Accesibilidad';
	@override String get summary => 'Texto, contraste, movimiento y controles';
	@override String get systemHint => 'Las configuraciones de accesibilidad de su dispositivo se aplican siempre. Estas opciones añaden ajustes a lo largo de PlezyNG.';
	@override String get readability => 'Leer y visibilidad';
	@override String get textSize => 'Tamaño de texto adicional';
	@override String get preview => 'Encuentra tu siguiente historia. leer, escuchar y ver a tu propio ritmo.';
	@override String get boldText => 'Interface de texto';
	@override String get highContrast => 'El alto contraste';
	@override String get highContrastHint => 'Texto más fuerte, etiquetas y indicadores de foco en superficies de luz o oscuridad.';
	@override String get interaction => 'Movimiento y interacción';
	@override String get reduceMotion => 'Reducir movimiento';
	@override String get reduceMotionHint => 'Detener el movimiento del indicador de foco, las transiciones de página y los efectos decorativos.';
	@override String get largeTargets => 'Objetivos de mayor toque';
	@override String get largeTargetsHint => 'Dale controles compartidos más espacio para el toque y la navegación asistiva.';
	@override String get navigationHint => 'Usa Tab y Shift+Tab para moverte entre los controles, Enter o la barra espaciadora para activarlos y Escape o Atrás para cerrar. El zoom y las preferencias de lectura están disponibles cuando hay un libro abierto.';
	@override String get textSizeDescription => 'Escala el texto de la interfaz en PlezyNG además de la configuración de tamaño del texto del sistema de su dispositivo.';
	@override String get boldTextHint => 'Utilice un peso más pesado para las etiquetas de interfaz y los mensajes para que sean más fáciles de distinguir.';
}

// Path: tooltips
class Translations$tooltips$es extends Translations$tooltips$en {
	Translations$tooltips$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Reproducción aleatoria';
	@override String get playTrailer => 'Reproducir tráiler';
	@override String get markAsWatched => 'Marcar como visto';
	@override String get markAsUnwatched => 'Marcar como no visto';
}

// Path: audioTracks
class Translations$audioTracks$es extends Translations$audioTracks$en {
	Translations$audioTracks$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => 'Pista de audio ${n}';
}

// Path: videoControls
class Translations$videoControls$es extends Translations$videoControls$en {
	Translations$videoControls$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Audio';
	@override String get subtitlesLabel => 'Subtítulos';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String get letterbox => 'Con bandas negras';
	@override String get fillScreen => 'Llenar pantalla';
	@override String get stretch => 'Estirar';
	@override String get lockRotation => 'Bloquear rotación';
	@override String get unlockRotation => 'Desbloquear rotación';
	@override String get timerActive => 'Temporizador activo';
	@override String playbackWillPauseIn({required Object duration}) => 'La reproducción se pausará en ${duration}';
	@override String get sleepTimerEndOfVideo => 'Fin del video actual';
	@override String get sleepTimerStopAtHeader => 'Detener en';
	@override String get sleepTimerDurationHeader => 'Temporizador';
	@override String get playbackWillPauseAtEnd => 'La reproducción se pausará al final de este video';
	@override String get stillWatching => '¿Sigues viendo?';
	@override String pausingIn({required Object seconds}) => 'Se pausará en ${seconds}s';
	@override String get continueWatching => 'Continuar';
	@override String get autoPlayNext => 'Reproducir siguiente automáticamente';
	@override String get playNext => 'Reproducir siguiente';
	@override String get playButton => 'Reproducir';
	@override String get pauseButton => 'Pausar';
	@override String get playbackPaused => 'En pausa';
	@override String get playbackResumed => 'Reproduciendo';
	@override String get loadingVideo => 'Cargando el vídeo';
	@override String get showPlaybackControls => 'Mostrar controles de reproducción';
	@override String get hidePlaybackControls => 'Ocultar controles de reproducción';
	@override String seekBackwardButton({required Object seconds}) => 'Retroceder ${seconds} segundos';
	@override String seekForwardButton({required Object seconds}) => 'Avanzar ${seconds} segundos';
	@override String get previousButton => 'Episodio anterior';
	@override String get nextButton => 'Episodio siguiente';
	@override String get previousChapterButton => 'Capítulo anterior';
	@override String get nextChapterButton => 'Capítulo siguiente';
	@override String get muteButton => 'Silenciar';
	@override String get unmuteButton => 'Activar sonido';
	@override String get settingsButton => 'Ajustes de reproducción';
	@override String get tracksButton => 'Audio y subtítulos';
	@override String get chaptersButton => 'Capítulos';
	@override String get versionQualityButton => 'Versión y calidad';
	@override String get versionColumnHeader => 'Versión';
	@override String get qualityColumnHeader => 'Calidad';
	@override String get qualityOriginal => 'Original';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => 'Transcodificación no disponible — reproduciendo calidad original';
	@override String get subtitleUnavailableFallback => 'No se pudieron cargar los subtítulos seleccionados — continuando sin subtítulos';
	@override String get pipButton => 'Modo de imagen en imagen';
	@override String get aspectRatioButton => 'Relación de aspecto';
	@override String get ambientLighting => 'Iluminación ambiental';
	@override String get fullscreenButton => 'Entrar en pantalla completa';
	@override String get exitFullscreenButton => 'Salir de pantalla completa';
	@override String get alwaysOnTopButton => 'Siempre visible';
	@override String get rotationLockButton => 'Bloqueo de rotación';
	@override String get lockScreen => 'Bloquear pantalla';
	@override String get screenLockButton => 'Bloqueo de pantalla';
	@override String get timelineSlider => 'Línea de tiempo del video';
	@override String get volumeSlider => 'Nivel de volumen';
	@override String endsAt({required Object time}) => 'Termina a las ${time}';
	@override String get pipActive => 'Reproduciendo en modo de imagen en imagen';
	@override String get pipFailed => 'No se pudo iniciar el modo de imagen en imagen';
	@override String get screenshotSaved => 'Captura de pantalla guardada';
	@override String get screenshotFailed => 'No se pudo hacer la captura de pantalla';
	@override String zoomPercent({required Object percent}) => 'Zoom ${percent}%';
	@override String volumePercent({required Object percent}) => 'Volumen ${percent}%';
	@override late final Translations$videoControls$pipErrors$es pipErrors = Translations$videoControls$pipErrors$es.internal(_root);
	@override String get chapters => 'Capítulos';
	@override String get noChaptersAvailable => 'No hay capítulos disponibles';
	@override String get queue => 'Cola';
	@override String get noQueueItems => 'No hay elementos en la cola';
	@override String get noAudioDevicesAvailable => 'No hay dispositivos de audio disponibles';
	@override String get searchSubtitles => 'Buscar subtítulos';
	@override String get language => 'Idioma';
	@override String get noSubtitlesFound => 'No se encontraron subtítulos';
	@override String get subtitleDownloaded => 'Subtítulo descargado';
	@override String get subtitleDownloadedNotApplied => 'El subtítulo se descargó, pero no se pudo seleccionar';
	@override String get subtitleDownloadFailed => 'Error al descargar subtítulo';
	@override String get searchLanguages => 'Buscar idiomas...';
	@override String get skipIntro => 'Saltar intro';
	@override String get skipCredits => 'Saltar créditos';
	@override String get nextEpisode => 'Episodio siguiente';
	@override String subtitleTrack({required Object n}) => 'Pista ${n}';
	@override String subtitleFile({required Object name}) => 'Subtítulo ${name}';
	@override String forcedTrack({required Object label}) => '${label} (Forzada)';
	@override String get osdSubtitlesOff => 'Subtítulos: desactivados';
	@override String osdSubtitles({required Object track}) => 'Subtítulos: ${track}';
	@override String osdAudio({required Object track}) => 'Audio: ${track}';
	@override String frameCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Frame',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} cuadros',
	);
	@override String get trackSelectionTitle => 'Elegir los rasgos antes de Playback';
	@override String get trackSelectionAuto => 'Selección automática';
	@override String get openMiniPlayer => 'Mini jugador abierto';
	@override String get returnToFullPlayer => 'Volver al jugador completo';
	@override String get loadSubtitleFile => 'Cargar el archivo subtitle.';
	@override String get subtitleLoadFailed => 'No se descarga el archivo subtitle';
	@override String get skipAds => 'Descargar Ads';
}

// Path: messages
class Translations$messages$es extends Translations$messages$en {
	Translations$messages$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Marcado como visto';
	@override String get markedAsUnwatched => 'Marcado como no visto';
	@override String get markedAsWatchedOffline => 'Marcado como visto (se sincronizará al estar en línea)';
	@override String get markedAsUnwatchedOffline => 'Marcado como no visto (se sincronizará al estar en línea)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'Eliminado automáticamente: ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: 'Se eliminó automáticamente ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} descarga vista',
		other: 'Se eliminaron automáticamente ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} descargas vistas',
	);
	@override String get removedFromContinueWatching => 'Eliminado de Seguir Viendo';
	@override String errorLoading({required Object error}) => 'Error: ${error}';
	@override String get searchPartialResults => 'Algunos servidores de medios no se pudieron buscar. Se muestran los resultados disponibles.';
	@override String get streamInterrupted => 'La reproducción se interrumpió. Pulsa reproducir o avanza para volver a intentarlo.';
	@override String get liveStreamInterrupted => 'La transmisión en vivo se interrumpió. Pulsa reproducir para volver a intentarlo.';
	@override String get fileInfoNotAvailable => 'Información de archivo no disponible';
	@override String get playbackAuthenticationRequired => 'Vuelve a iniciar sesión en el servidor multimedia para reproducir este elemento.';
	@override String get playbackServerUnavailable => 'El servidor multimedia no está disponible. Inténtalo de nuevo más tarde.';
	@override String get playbackDataInvalid => 'El servidor devolvió información de reproducción no válida.';
	@override String get playbackCancelled => 'Se canceló la reproducción.';
	@override String get playbackFailed => 'No se pudo iniciar la reproducción.';
	@override String playbackFailedDetail({required Object error}) => 'No se pudo iniciar la reproducción: ${error}';
	@override String get audioOutputFailed => 'La salida de audio dejó de responder. Comprueba la conexión de audio del televisor o receptor; si otras aplicaciones tampoco tienen sonido, reinicia el dispositivo.';
	@override String get mediaUnavailable => 'Este contenido ya no está disponible.';
	@override String errorLoadingFileInfo({required Object error}) => 'Error al cargar la información del archivo: ${error}';
	@override String get errorLoadingSeries => 'Error al cargar la serie';
	@override String get musicNotSupported => 'La reproducción de música aún no es compatible';
	@override String get noDescriptionAvailable => 'No hay descripción disponible';
	@override String get noProfilesAvailable => 'No hay perfiles disponibles';
	@override String get contactAdminForProfiles => 'Contacta a tu administrador del servidor para añadir perfiles';
	@override String get unableToDetermineLibrarySection => 'No se puede determinar la sección de biblioteca para este elemento';
	@override String get logsCleared => 'Registros borrados';
	@override String get logsCopied => 'Registros copiados al portapapeles';
	@override String get noLogsAvailable => 'No hay registros disponibles';
	@override String libraryScanning({required Object title}) => 'Escaneando "${title}"...';
	@override String libraryScanStarted({required Object title}) => 'Escaneo de biblioteca iniciado para "${title}"';
	@override String libraryScanFailed({required Object error}) => 'Error al escanear biblioteca: ${error}';
	@override String metadataRefreshing({required Object title}) => 'Actualizando metadatos de "${title}"...';
	@override String metadataRefreshStarted({required Object title}) => 'Actualización de metadatos iniciada para "${title}"';
	@override String metadataRefreshFailed({required Object error}) => 'Error al actualizar metadatos: ${error}';
	@override String get logoutConfirm => '¿Estás seguro de que quieres cerrar sesión?';
	@override String get noSeasonsFound => 'No se encontraron temporadas';
	@override String get seasonsLoadFailed => 'No se pudieron cargar las temporadas';
	@override String get noEpisodesFound => 'No se encontraron episodios en la primera temporada';
	@override String get noEpisodesFoundGeneral => 'No se encontraron episodios';
	@override String get episodesLoadFailed => 'No se pudieron cargar los episodios';
	@override String get noResultsFound => 'No se encontraron resultados';
	@override String sleepTimerSet({required Object label}) => 'Temporizador establecido en ${label}';
	@override String get noItemsAvailable => 'No hay elementos disponibles';
	@override String get failedToCreatePlayQueueNoItems => 'No se pudo crear la cola de reproducción: no hay elementos';
	@override String failedPlayback({required Object action, required Object error}) => 'Error al ${action}: ${error}';
	@override String get switchingToCompatiblePlayer => 'Cambiando a reproductor compatible...';
	@override String get serverLimitTitle => 'Error de reproducción';
	@override String get serverLimitBody => 'Error del servidor (HTTP 500). Un límite de ancho de banda/transcodificación probablemente rechazó esta sesión. Pide al propietario que lo ajuste.';
	@override String get mediaUnreadableTitle => 'Archivo no disponible';
	@override String get mediaUnreadableBody => 'El servidor encontró este elemento pero no pudo leer su archivo (HTTP 404). Es probable que el archivo se haya movido o eliminado, o que su almacenamiento esté sin conexión. Pide al propietario del servidor que revise el archivo y vuelva a escanear la biblioteca.';
	@override String get serverBusyTitle => 'Reproducción no disponible';
	@override String get serverBusyBody => 'El servidor siguió rechazando la reproducción de este archivo (HTTP 503). Puede que se esté reiniciando, esté ocupado o que el almacenamiento del archivo no esté disponible. Inténtalo de nuevo dentro de un momento; si sigue ocurriendo, pide al propietario del servidor que revise el servidor y el almacenamiento del archivo.';
	@override String get playbackNotAllowedTitle => 'Reproducción no permitida';
	@override String get playbackNotAllowedBody => 'El servidor se negó a transmitir este elemento (HTTP 403). Es posible que tu cuenta no tenga permiso para reproducirlo o que el servidor solo permita la reproducción en su red local.';
	@override String get logsUploaded => 'Registros subidos';
	@override String get logsUploadFailed => 'Error al subir registros';
	@override String get logId => 'ID de registro';
	@override String get burnedSubtitlesUseMenu => 'Los subtítulos están incrustados en esta transmisión. Cámbialos desde el menú de subtítulos.';
	@override String get noVideoUrl => 'No hay ninguna URL de vídeo disponible';
	@override String get playbackNoMediaSources => 'El servidor no devolvió ninguna fuente multimedia reproducible';
	@override String get playbackDataNotPrepared => 'La reproducción se inició antes de que sus datos estuvieran listos';
	@override String get streamSelectionUnavailable => 'La selección de flujos no está disponible para esta fuente';
	@override String get streamSelectionFailed => 'No se pudieron aplicar los flujos seleccionados';
	@override String get trackSelectionNotRemembered => 'Esta selección de pista solo se aplica a la reproducción actual.';
	@override String get serverUnavailableForProfile => 'No hay ningún servidor disponible para el perfil activo';
}

// Path: subtitlingStyling
class Translations$subtitlingStyling$es extends Translations$subtitlingStyling$en {
	Translations$subtitlingStyling$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get previewSample => 'El rápido fox marrón salta sobre el perro lazo';
	@override String get text => 'Texto';
	@override String get border => 'Borde';
	@override String get background => 'Fondo';
	@override String get fontSize => 'Tamaño de fuente';
	@override String get textColor => 'Color del texto';
	@override String get borderSize => 'Tamaño del borde';
	@override String get borderColor => 'Color del borde';
	@override String get backgroundOpacity => 'Opacidad del fondo';
	@override String get backgroundColor => 'Color del fondo';
	@override String get position => 'Posición';
	@override String get assOverride => 'Sobreescritura ASS';
	@override String get overrideScale => 'Escala';
	@override String get overrideForce => 'Forzar';
	@override String get overrideStrip => 'Quitar estilos';
	@override String get positionTop => 'Arriba';
	@override String get positionBottom => 'Abajo';
	@override String get useMargins => 'Usar márgenes';
	@override String get useMarginsDescription => 'Permitir subtítulos de texto en el espacio fuera del video. Los subtítulos con estilo pueden mantener su posición original.';
	@override String get anchorToScreen => 'Anclar a la pantalla';
	@override String get anchorToScreenDescription => 'Muestra los subtítulos de texto en las barras negras situadas debajo del vídeo panorámico';
	@override String get bold => 'Negrita';
	@override String get italic => 'Cursiva';
	@override String get renderResolution => 'Resolución de renderizado';
	@override String get renderResolutionScreen => 'Resolución de pantalla';
	@override String get renderResolutionVideo => 'Resolución del video';
	@override String get fontSizeDescription => 'Configure el tamaño de texto del subtitulo en este dispositivo.';
	@override String get textColorDescription => 'Seleccione el color utilizado para el texto subtitulado.';
	@override String get borderSizeDescription => 'Configure el espesor de la salida alrededor del texto subtitulado.';
	@override String get borderColorDescription => 'Seleccione el color utilizado para la subtitulación.';
	@override String get backgroundColorDescription => 'Seleccione el color detrás del texto subtitulado.';
	@override String get backgroundOpacityDescription => 'Configure cuán transparente es el fondo del subtítulo: 0% es claro y 100% sólido.';
	@override String get positionDescription => 'Move los subtítulos verticalmente. 0% es la parte superior del vídeo y 100% es el fondo.';
	@override String get assOverrideDescription => 'Seleccione si el jugador sigue, ajusta, reemplaza o remove el estilo incorporado en los subtítulos de ASS.';
	@override late final Translations$subtitlingStyling$assOverrideOptions$es assOverrideOptions = Translations$subtitlingStyling$assOverrideOptions$es.internal(_root);
	@override String get renderResolutionDescription => 'Seleccione la resolución utilizada para rasterizar la imagen y los subtítulos de ASS. Escalas Android inferiores pueden reducir el trabajo de rendimiento pero se vean más suaves.';
	@override late final Translations$subtitlingStyling$renderResolutionOptions$es renderResolutionOptions = Translations$subtitlingStyling$renderResolutionOptions$es.internal(_root);
	@override String get boldDescription => 'Toma el texto en un peso más pesado.';
	@override String get italicDescription => 'Descargar subtítulos en italiano.';
}

// Path: mpvConfig
class Translations$mpvConfig$es extends Translations$mpvConfig$en {
	Translations$mpvConfig$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => 'Ajustes avanzados del reproductor de video';
	@override String get presets => 'Preajustes';
	@override String get noPresets => 'No hay preajustes guardados';
	@override String get saveAsPreset => 'Guardar como preajuste...';
	@override String get presetName => 'Nombre del preajuste';
	@override String get presetNameHint => 'Introduce un nombre para este preajuste';
	@override String get loadPreset => 'Cargar';
	@override String get deletePreset => 'Eliminar';
	@override String get presetSaved => 'Preajuste guardado';
	@override String get presetLoaded => 'Preajuste cargado';
	@override String get presetDeleted => 'Preajuste eliminado';
	@override String get confirmDeletePreset => '¿Estás seguro de que quieres eliminar este preajuste?';
	@override String get configPlaceholder => 'gpu-api=vulkan\nhwdec=auto\n# comment';
	@override String get lineHint => 'option=value';
	@override String get addLine => 'Añadir línea';
	@override String get removeLine => 'Eliminar línea';
	@override String get embeddedVoHint => 'vo, gpu-context y gpu-api se ignoran en Linux: el vídeo integrado siempre se renderiza mediante vo=libmpv en el plano de vídeo, y gpu-next (que los shaders de cómputo como ArtCNN necesitan) no puede ejecutarse integrado.';
}

// Path: dialog
class Translations$dialog$es extends Translations$dialog$en {
	Translations$dialog$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Confirmar acción';
}

// Path: profiles
class Translations$profiles$es extends Translations$profiles$en {
	Translations$profiles$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'Añadir perfil de PlezyNG';
	@override String get switchingProfile => 'Cambiando de perfil…';
	@override String get deleteThisProfileTitle => '¿Eliminar este perfil?';
	@override String deleteThisProfileMessage({required Object displayName}) => 'Eliminar ${displayName}. Las conexiones no se verán afectadas.';
	@override String get active => 'Activo';
	@override String get manage => 'Administrar';
	@override String get delete => 'Eliminar';
	@override String get signOut => 'Cerrar sesión';
	@override String get signOutPlexTitle => '¿Cerrar sesión de Plex?';
	@override String signOutPlexMessage({required Object displayName}) => '¿Eliminar ${displayName} y todos los usuarios de Plex Home? Puedes iniciar sesión de nuevo cuando quieras.';
	@override String get signOutPlexDeleteDownloads => 'Eliminar también las descargas';
	@override String get signOutPlexDeleteDownloadsDescription => 'De lo contrario, se conservarán en este dispositivo y volverán a estar disponibles cuando inicies sesión de nuevo en esta cuenta.';
	@override String get signedOutPlex => 'Sesión de Plex cerrada.';
	@override String get signOutFailed => 'Error al cerrar sesión.';
	@override String get sectionTitle => 'Perfiles';
	@override String get summarySingle => 'Añade perfiles para mezclar usuarios gestionados e identidades locales';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} perfiles · activo: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} perfiles';
	@override String get removeConnectionTitle => '¿Eliminar conexión?';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => 'Eliminar el acceso de ${displayName} a ${connectionLabel}. Los demás perfiles lo conservan.';
	@override String get deleteProfileTitle => '¿Eliminar perfil?';
	@override String deleteProfileMessage({required Object displayName}) => 'Eliminar ${displayName} y sus conexiones. Los servidores seguirán disponibles.';
	@override String get profileNameLabel => 'Nombre del perfil';
	@override String get pinProtectionLabel => 'Protección con PIN';
	@override String get copyAutomationLink => 'Copia Android enlace de automatización';
	@override String get copyAutomationLinkDescription => 'Seleccione este perfil desde una intención o automatización Android.';
	@override String get automationLinkCopied => 'El perfil de la automatización de enlace se copia.';
	@override String get pinManagedByPlex => 'PIN gestionado por Plex. Edita en plex.tv.';
	@override String get noPinSetEditOnPlex => 'Sin PIN establecido. Para requerir uno, edita el usuario Home en plex.tv.';
	@override String get setPin => 'Establecer PIN';
	@override String get setPinTitle => 'Establecer PIN';
	@override String get confirmPinTitle => 'Confirmar PIN';
	@override String get pinSet => 'PIN establecido';
	@override String get changePin => 'Cambiar';
	@override String get removePin => 'Eliminar';
	@override String get connectionsLabel => 'Conexiones';
	@override String get add => 'Añadir';
	@override String get deleteProfileButton => 'Eliminar perfil';
	@override String get noConnectionsHint => 'Sin conexiones — añade una para usar este perfil.';
	@override String get noConnections => 'Sin conexiones';
	@override String get plexHomeAccount => 'Cuenta Plex Home';
	@override String plexAccountChip({required Object account}) => 'Cuenta Plex: ${account}';
	@override String plexAccountUserChip({required Object user, required Object account}) => '${user} a través de ${account}';
	@override String get connectionDefault => 'Predeterminada';
	@override String connectionAs({required Object displayName}) => 'como ${displayName}';
	@override String get makeDefault => 'Establecer como predeterminada';
	@override String get removeConnection => 'Eliminar';
	@override String get profileRenamed => 'Se cambió el nombre del perfil.';
	@override String borrowAddTo({required Object displayName}) => 'Añadir a ${displayName}';
	@override String get borrowExplain => 'Toma prestada la conexión de otro perfil. Los perfiles protegidos con PIN requieren un PIN.';
	@override String get borrowEmpty => 'Todavía no hay ninguna conexión que tomar prestada.';
	@override String get borrowEmptySubtitle => 'Conecta primero Plex, Jellyfin o Emby a otro perfil.';
	@override String get borrowLoadFailed => 'No se pudieron cargar las conexiones disponibles. Inténtalo de nuevo.';
	@override String borrowFromProfile({required Object displayName}) => 'De ${displayName}';
	@override String get borrowConnectionBorrowed => 'Conexión tomada prestada.';
	@override String get borrowFailed => 'No se pudo tomar prestada la conexión.';
	@override String get incorrectPin => 'PIN incorrecto.';
	@override String get incorrectPinTryAgain => 'PIN incorrecto. Inténtalo de nuevo.';
	@override String get sourceProfileMissingParentAccount => 'Al perfil de origen le falta su cuenta principal.';
	@override String get failedToLoadHomeUsers => 'No se pudieron cargar tus usuarios de Plex Home. Comprueba tu conexión e inténtalo de nuevo.';
	@override String get failedToVerifyPin => 'No se pudo verificar el PIN.';
	@override String get newProfile => 'Nuevo perfil';
	@override String get profileNameHint => 'p. ej., Invitados, Niños, Sala familiar';
	@override String get pinProtectionOptional => 'Protección con PIN (opcional)';
	@override String get pinExplain => 'Se requiere PIN de 4 dígitos para cambiar de perfil.';
	@override String get continueButton => 'Continuar';
	@override String get pinsDontMatch => 'Los PIN no coinciden';
	@override String get tokenIdentityMismatch => 'El token del perfil de Plex correspondía a un servidor inesperado';
	@override String get settingsLocked => 'Las configuraciones están bloqueadas para este perfil.';
	@override String get unlockSettings => 'Desbloquear las configuraciones';
	@override String get showExploreForProfile => 'Mostrar Explora para este perfil';
	@override String get showExploreForProfileDescription => 'Desactivar para eliminar Explore de la navegación de este perfil.';
}

// Path: connections
class Translations$connections$es extends Translations$connections$en {
	Translations$connections$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Conexiones';
	@override String get addConnection => 'Añadir conexión';
	@override String get addConnectionSubtitleNoProfile => 'Inicia sesión con Plex o conecta un servidor de Jellyfin o Emby';
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'Añadir a ${displayName}: Plex, Jellyfin, Emby u otra conexión de perfil';
	@override String sessionExpiredOne({required Object name}) => 'Sesión caducada para ${name}';
	@override String sessionExpiredMany({required Object count}) => 'Sesión caducada para ${count} servidores';
	@override String accessDeniedOne({required Object name}) => '${name} denegó el acceso a esta cuenta';
	@override String accessDeniedMany({required Object count}) => '${count} servidores denegaron el acceso a esta cuenta';
	@override String get signInAgain => 'Iniciar sesión de nuevo';
	@override String editMediaBrowserTitle({required Object product}) => 'Editar conexión de ${product}';
	@override String editMediaBrowserIntro({required Object serverName}) => 'Añade o elimina URL para ${serverName}. PlezyNG usará la URL accesible con menor latencia.';
}

// Path: accountPreferences
class Translations$accountPreferences$es extends Translations$accountPreferences$en {
	Translations$accountPreferences$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Preferencias de cuenta';
	@override String hubSubtitleSingle({required Object account}) => 'Opciones de audio, subtítulos y biblioteca guardadas en ${account}';
	@override String hubSubtitleMultiple({required Object count}) => 'Opciones de audio, subtítulos y biblioteca guardadas en ${count} cuentas';
	@override String get pickAccount => 'Cada cuenta guarda sus propias preferencias. Elige la que quieras editar.';
	@override String get storedOnAccount => 'Estas opciones se guardan en la propia cuenta, así que cualquier aplicación con la sesión iniciada las usa, incluido PlezyNG en tus otros dispositivos.';
	@override String get noAccounts => 'No hay cuentas que configurar';
	@override String get noAccountsHint => 'Inicia sesión con Plex o conecta un servidor de Jellyfin o Emby y las preferencias guardadas en esa cuenta aparecerán aquí.';
	@override String get unavailable => 'No se puede acceder a esta cuenta';
	@override String get loadFailed => 'No se pudieron cargar estas preferencias';
	@override String get noPreference => 'Sin preferencia';
	@override String get notSet => 'No establecido';
	@override late final Translations$accountPreferences$groups$es groups = Translations$accountPreferences$groups$es.internal(_root);
	@override String get preferredAudioLanguage => 'Idioma de audio preferido';
	@override String get autoSelectAudio => 'Elegir audio por idioma';
	@override String get autoSelectAudioDescription => 'Desactivado mantiene la pista de audio que el archivo marca como predeterminada.';
	@override String get preferredSubtitleLanguage => 'Idioma de subtítulos preferido';
	@override String get subtitleMode => 'Activar subtítulos';
	@override late final Translations$accountPreferences$subtitleModes$es subtitleModes = Translations$accountPreferences$subtitleModes$es.internal(_root);
	@override String get subtitleAccessibility => 'Subtítulos SDH';
	@override late final Translations$accountPreferences$subtitleAccessibilityOptions$es subtitleAccessibilityOptions = Translations$accountPreferences$subtitleAccessibilityOptions$es.internal(_root);
	@override String get forcedSubtitles => 'Subtítulos forzados';
	@override late final Translations$accountPreferences$forcedSubtitleOptions$es forcedSubtitleOptions = Translations$accountPreferences$forcedSubtitleOptions$es.internal(_root);
	@override String get displayMissingEpisodes => 'Mostrar episodios faltantes';
	@override String get displayMissingEpisodesDescription => 'Enumera los episodios que el servidor conoce pero para los que no tiene ningún archivo.';
	@override String get hidePlayedInLatest => 'Ocultar elementos vistos en Recientes';
	@override String get hidePlayedInLatestDescription => 'Deja fuera de las filas de Recientes del servidor los elementos que ya has visto.';
	@override String get displayCollectionsView => 'Mostrar la vista de colecciones';
	@override String get displayCollectionsViewDescription => 'Ofrecer la vista de colecciones del servidor junto a tus bibliotecas.';
	@override String get rewatchingInNextUp => 'Mantener las series revistas en A continuación';
	@override String get rewatchingInNextUpDescription => 'Cuando termines una serie y la vuelvas a empezar, A continuación seguirá tu revisión en lugar de descartarla.';
	@override String get watchedIndicator => 'Indicadores de visto';
	@override late final Translations$accountPreferences$watchedIndicatorOptions$es watchedIndicatorOptions = Translations$accountPreferences$watchedIndicatorOptions$es.internal(_root);
	@override String get mediaReviewsVisibility => 'Valoraciones y reseñas';
	@override late final Translations$accountPreferences$mediaReviewsOptions$es mediaReviewsOptions = Translations$accountPreferences$mediaReviewsOptions$es.internal(_root);
	@override String get preferredAudioLanguageDescription => 'Preferir los rasgos de audio en este idioma cuando el servidor o jugador selecciona automáticamente un rasgo.';
	@override String get preferredSubtitleLanguageDescription => 'Preferir los rastreos de subtitulos en este idioma cuando se seleccionan automáticamente.';
	@override String get subtitleAccessibilityDescription => 'Seleccione si las capciones de SDH son preferidas o necesarias durante la selección automática de subtitulos.';
	@override String get forcedSubtitleDescription => 'Seleccione si las pistas de subtitulos forzados son preferidas o necesarias durante la selección automática.';
	@override String get watchedIndicatorDescription => 'Seleccione qué tipos de medios reciben un marcador observado en la interfaz del servidor.';
	@override String get mediaReviewsVisibilityDescription => 'Seleccione qué audiencia y calificaciones críticas el servidor muestra en las páginas de los medios.';
	@override String get subtitleModeDescription => 'Seleccione cuando los subtítulos se activan automáticamente para esta cuenta del servidor.';
	@override String get hubDescription => 'Estas preferencias se almacenan en su cuenta de servidor de medios y pueden aplicarse también a otros clientes.';
}

// Path: discover
class Translations$discover$es extends Translations$discover$en {
	Translations$discover$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Descubrir';
	@override String get noContentAvailable => 'No hay contenido disponible';
	@override String get addMediaToLibraries => 'Añade contenido a tus bibliotecas';
	@override String get continueWatching => 'Seguir viendo';
	@override String continueWatchingIn({required Object library}) => 'Seguir viendo en ${library}';
	@override String get nextUp => 'A continuación';
	@override String nextUpIn({required Object library}) => 'A continuación en ${library}';
	@override String get recentlyAdded => 'Añadido recientemente';
	@override String recentlyAddedIn({required Object library}) => 'Añadido recientemente en ${library}';
	@override String latestAlbumsIn({required Object library}) => 'Últimos álbumes en ${library}';
	@override String recentlyPlayedIn({required Object library}) => 'Reproducido recientemente en ${library}';
	@override String mostPlayedIn({required Object library}) => 'Más reproducido en ${library}';
	@override String playEpisode({required Object season, required Object episode}) => 'T${season}E${episode}';
	@override String get overview => 'Resumen';
	@override String get cast => 'Reparto';
	@override late final Translations$discover$findNext$es findNext = Translations$discover$findNext$es.internal(_root);
	@override String get extras => 'Tráilers y extras';
	@override String get studio => 'Estudio';
	@override String get rating => 'Valoración';
	@override String get director => 'Director';
	@override String get directors => 'Directores';
	@override String get movie => 'Película';
	@override String get tvShow => 'Serie de TV';
	@override String minutesLeft({required Object minutes}) => 'quedan ${minutes} min';
	@override String get moreLikeThis => 'Más contenido similar';
	@override String titleCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} título',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} títulos',
	);
	@override late final Translations$discover$person$es person = Translations$discover$person$es.internal(_root);
}

// Path: errors
class Translations$errors$es extends Translations$errors$en {
	Translations$errors$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Error en la búsqueda: ${error}';
	@override String get searchUnavailable => 'La búsqueda no pudo alcanzar ningún servidor de medios.';
	@override String connectionTimeout({required Object context}) => 'Tiempo de conexión agotado al cargar ${context}';
	@override String get connectionFailed => 'No se puede conectar al servidor multimedia';
	@override String unableToLoad({required Object context}) => 'No se pudo cargar ${context}. Inténtalo de nuevo.';
	@override String get noClientAvailable => 'No hay cliente disponible';
	@override String get pleaseEnterToken => 'Introduce un token';
	@override String get invalidToken => 'Token no válido';
	@override String failedToVerifyToken({required Object error}) => 'Error al verificar el token: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Error al cambiar al perfil ${displayName}';
	@override String failedToDeleteProfile({required Object displayName}) => 'Error al eliminar ${displayName}';
	@override String get failedToRate => 'No se pudo actualizar la valoración';
	@override String get reasonTimedOut => 'se agotó el tiempo de conexión';
	@override String get reasonUnreachable => 'no se pudo contactar con el servidor';
	@override String get reasonRefused => 'el servidor rechazó la solicitud';
	@override String get reasonNotFound => 'el elemento ya no está en el servidor';
	@override String get reasonServerError => 'el servidor informó de un error';
	@override String get reasonCancelled => 'se canceló la solicitud';
	@override String get reasonUnexpected => 'se produjo un error inesperado';
}

// Path: libraries
class Translations$libraries$es extends Translations$libraries$en {
	Translations$libraries$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get playRandomMovie => 'Juega una película aleatoria';
	@override String get randomPickFailed => 'No podía elegir una película aleatoria de esta biblioteca.';
	@override String get title => 'Bibliotecas';
	@override String get fallbackTitle => 'Biblioteca';
	@override String get scanLibraryFiles => 'Escanear archivos de la biblioteca';
	@override String get scanLibrary => 'Escanear biblioteca';
	@override String get analyze => 'Analizar';
	@override String get analyzeLibrary => 'Analizar biblioteca';
	@override String get refreshMetadata => 'Actualizar metadatos';
	@override String get emptyTrash => 'Vaciar papelera';
	@override String emptyingTrash({required Object title}) => 'Vaciando papelera de "${title}"...';
	@override String trashEmptied({required Object title}) => 'Papelera vaciada para "${title}"';
	@override String failedToEmptyTrash({required Object error}) => 'Error al vaciar papelera: ${error}';
	@override String analyzing({required Object title}) => 'Analizando "${title}"...';
	@override String analysisStarted({required Object title}) => 'Análisis iniciado para "${title}"';
	@override String failedToAnalyze({required Object error}) => 'Error al analizar la biblioteca: ${error}';
	@override String get noLibrariesFound => 'No se encontraron bibliotecas';
	@override String get allLibrariesHidden => 'Todas las bibliotecas están ocultas';
	@override String hiddenLibrariesCount({required Object count}) => 'Bibliotecas ocultas (${count})';
	@override String get thisLibraryIsEmpty => 'Esta biblioteca está vacía';
	@override String get noItemsMatchFilters => 'Ningún elemento coincide con los filtros activos';
	@override String get resetFilters => 'Restablecer filtros';
	@override String get all => 'Todos';
	@override String get clearAll => 'Borrar todo';
	@override String scanLibraryConfirm({required Object title}) => '¿Estás seguro de que quieres escanear "${title}"?';
	@override String analyzeLibraryConfirm({required Object title}) => '¿Estás seguro de que quieres analizar "${title}"?';
	@override String refreshMetadataConfirm({required Object title}) => '¿Estás seguro de que quieres actualizar los metadatos de "${title}"?';
	@override String emptyTrashConfirm({required Object title}) => '¿Estás seguro de que quieres vaciar la papelera de "${title}"?';
	@override String get manageLibraries => 'Gestionar bibliotecas';
	@override String get sort => 'Ordenar';
	@override String get sortBy => 'Ordenar por';
	@override String get filters => 'Filtros';
	@override String get confirmActionMessage => '¿Estás seguro de que quieres realizar esta acción?';
	@override String get showLibrary => 'Mostrar biblioteca';
	@override String get hideLibrary => 'Ocultar biblioteca';
	@override String get libraryOptions => 'Opciones de biblioteca';
	@override String get content => 'contenido de la biblioteca';
	@override String get selectLibrary => 'Seleccionar biblioteca';
	@override String filtersWithCount({required Object count}) => 'Filtros (${count})';
	@override String get noRecommendations => 'No hay recomendaciones disponibles';
	@override String get noCollections => 'No hay colecciones en esta biblioteca';
	@override String get noFoldersFound => 'No se encontraron carpetas';
	@override String get folders => 'carpetas';
	@override late final Translations$libraries$tabs$es tabs = Translations$libraries$tabs$es.internal(_root);
	@override late final Translations$libraries$groupings$es groupings = Translations$libraries$groupings$es.internal(_root);
	@override late final Translations$libraries$filterCategories$es filterCategories = Translations$libraries$filterCategories$es.internal(_root);
	@override late final Translations$libraries$sortLabels$es sortLabels = Translations$libraries$sortLabels$es.internal(_root);
	@override late final Translations$libraries$advancedFilters$es advancedFilters = Translations$libraries$advancedFilters$es.internal(_root);
	@override late final Translations$libraries$selection$es selection = Translations$libraries$selection$es.internal(_root);
}

// Path: about
class Translations$about$es extends Translations$about$en {
	Translations$about$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Acerca de';
	@override String get openSourceLicenses => 'Licencias de código abierto';
	@override String versionLabel({required Object version}) => 'Versión ${version}';
	@override String get appDescription => 'Un cliente de Plex, Jellyfin y Emby para Flutter';
	@override String get viewLicensesDescription => 'Ver las licencias de bibliotecas de terceros';
	@override String get privacyPolicy => 'Política de privacidad';
}

// Path: serverSelection
class Translations$serverSelection$es extends Translations$serverSelection$en {
	Translations$serverSelection$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'No se encontraron servidores para ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Error al cargar servidores: ${error}';
	@override String get noValidServers => 'No se encontraron servidores utilizables en esta cuenta';
}

// Path: hubDetail
class Translations$hubDetail$es extends Translations$hubDetail$en {
	Translations$hubDetail$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Título';
	@override String get releaseYear => 'Año de lanzamiento';
	@override String get dateAdded => 'Añadido el';
	@override String get rating => 'Valoración';
	@override String get noItemsFound => 'No se encontraron elementos';
}

// Path: logs
class Translations$logs$es extends Translations$logs$en {
	Translations$logs$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Borrar registros';
	@override String get copyLogs => 'Copiar registros';
	@override String get uploadLogs => 'Subir registros';
	@override String get saveLogs => 'Salva los logs a los archivos';
	@override String logsSaved({required Object path}) => 'Los registros salvos a ${path}';
	@override String get saveLogsFailed => 'No podía salvar el archivo de registro.';
}

// Path: startup
class Translations$startup$es extends Translations$startup$en {
	Translations$startup$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'PlezyNG no pudo iniciarse';
	@override String get failedBody => 'Algo salió mal durante el inicio. Los detalles de abajo indican qué ha fallado.';
	@override String get failedBodyRepairable => 'El archivo de ajustes guardados de PlezyNG está dañado y debe reconstruirse antes de que PlezyNG pueda iniciarse. Reintentar no servirá: elige Reparar almacenamiento.';
	@override String get phaseLabel => 'Paso';
	@override String get showDetails => 'Mostrar detalles';
	@override String get hideDetails => 'Ocultar detalles';
	@override String get copyDetails => 'Copiar detalles';
	@override String get detailsCopied => 'Detalles copiados al portapapeles';
	@override String get uploadDetails => 'Subir detalles';
	@override String get repairStorage => 'Reparar almacenamiento';
	@override String get repairTitle => '¿Reparar los datos guardados?';
	@override String get repairBodyCommon => 'El archivo de ajustes de PlezyNG está dañado y no puede leerse. La reparación restablece todos los ajustes a sus valores predeterminados.';
	@override String get repairBodyOneCredential => 'Un inicio de sesión guardado está dañado y no puede leerse. La reparación elimina solo ese; el resto de tus ajustes se mantienen intactos.';
	@override String get repairBodySignInsKept => 'Tus servidores y perfiles deberían permanecer con la sesión iniciada.';
	@override String get repairBodySignInsLost => 'La clave que protege tus inicios de sesión guardados no se puede recuperar de este archivo, por lo que tendrás que iniciar sesión de nuevo en cada servidor y perfil. Nada en tu servidor de medios se ve afectado.';
	@override String get repairBodySessionsUncertain => 'Los rastreadores (MAL, AniList, Simkl, Trakt) y Seerr se guardan por separado y pueden sobrevivir o no. PlezyNG te dirá exactamente qué ha conservado.';
	@override String get repairConfirm => 'Reparar';
	@override String get repairSucceeded => 'Almacenamiento reparado';
	@override String get repairNeedsRestart => 'Almacenamiento reparado: es necesario reiniciar';
	@override String get restartRequiredBody => 'Tus datos se repararon, pero PlezyNG debe iniciarse de nuevo antes de poder usarlos. Cierra PlezyNG y ábrelo otra vez.';
	@override String get quitPlezy => 'Salir de PlezyNG';
	@override String get repairFailed => 'Error en la reparación';
	@override String get repairKeptSignIns => 'Tus servidores y perfiles siguen con la sesión iniciada.';
	@override String get repairLostSignIns => 'La clave que protege tus inicios de sesión guardados no se pudo recuperar. Tendrás que iniciar sesión de nuevo en cada servidor y perfil.';
	@override String get repairLostSessions => 'Se perdió al menos una conexión de rastreador o de Seerr y hay que volver a conectarla.';
	@override String get backupTitle => 'Se ha guardado una copia del archivo dañado';
	@override String get backupWarning => 'Contiene tus credenciales de inicio de sesión. No la subas ni la compartas.';
	@override String get deleteBackup => 'Eliminar copia';
	@override String get backupDeleted => 'Copia eliminada.';
	@override String get previousFailureTitle => 'PlezyNG no se inició la última vez';
}

// Path: licenses
class Translations$licenses$es extends Translations$licenses$en {
	Translations$licenses$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Paquetes relacionados';
	@override String get license => 'Licencia';
	@override String licenseNumber({required Object number}) => 'Licencia ${number}';
	@override String licensesCount({required Object count}) => '${count} licencias';
}

// Path: navigation
class Translations$navigation$es extends Translations$navigation$en {
	Translations$navigation$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Bibliotecas';
	@override String get downloads => 'Descargas';
	@override String get liveTv => 'TV en vivo';
	@override String get explore => 'Explorar';
}

// Path: explore
class Translations$explore$es extends Translations$explore$en {
	Translations$explore$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final Translations$explore$mdblistShelves$es mdblistShelves = Translations$explore$mdblistShelves$es.internal(_root);
	@override String get title => 'Explorar';
	@override String get selectSource => 'Seleccionar fuente';
	@override late final Translations$explore$rows$es rows = Translations$explore$rows$es.internal(_root);
	@override late final Translations$explore$status$es status = Translations$explore$status$es.internal(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episodio',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episodios',
	);
	@override String get cast => 'Reparto';
	@override String get characters => 'Personajes';
	@override String get addToWatchlist => 'Añadir a la lista de seguimiento';
	@override String get removeFromWatchlist => 'Quitar de la lista de seguimiento';
	@override String get addedToWatchlist => 'Añadido a la lista de seguimiento';
	@override String get removedFromWatchlist => 'Eliminado de la lista de seguimiento';
	@override String get watchlistUpdateFailed => 'No se pudo actualizar la lista de seguimiento';
	@override String get watchlistNoMatch => 'No se pudo asociar este elemento con una lista de seguimiento';
	@override String get notInLibrary => 'No está en tu biblioteca';
	@override String get inTheseLibraries => 'En estas bibliotecas';
	@override String get checkingLibrary => 'Comprobando tu biblioteca...';
	@override String libraryCheckFailed({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: 'No se pudo comprobar ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} servidor',
		other: 'No se pudo comprobar ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} servidores',
	);
	@override String get emptyTitle => 'Aquí no hay nada todavía';
	@override String emptyMessage({required Object source}) => 'Las filas de ${source} aparecerán aquí cuando tengan contenido.';
	@override String searchHint({required Object source}) => 'Buscar en ${source}';
	@override String searchEmpty({required Object query}) => 'Sin resultados para "${query}"';
	@override String searchPrompt({required Object source}) => 'Busca películas y series en ${source}.';
	@override String get searchFailed => 'La búsqueda falló. Comprueba tu conexión e inténtalo de nuevo.';
	@override late final Translations$explore$badge$es badge = Translations$explore$badge$es.internal(_root);
	@override late final Translations$explore$stats$es stats = Translations$explore$stats$es.internal(_root);
	@override late final Translations$explore$season$es season = Translations$explore$season$es.internal(_root);
	@override late final Translations$explore$format$es format = Translations$explore$format$es.internal(_root);
	@override late final Translations$explore$sourceMaterial$es sourceMaterial = Translations$explore$sourceMaterial$es.internal(_root);
	@override late final Translations$explore$creditRole$es creditRole = Translations$explore$creditRole$es.internal(_root);
	@override late final Translations$explore$relation$es relation = Translations$explore$relation$es.internal(_root);
	@override String broadcast({required Object day, required Object time}) => 'Se emite los ${day} a las ${time}';
	@override String broadcastWithZone({required Object day, required Object time, required Object timezone}) => 'Se emite los ${day} a las ${time} ${timezone}';
	@override late final Translations$explore$detail$es detail = Translations$explore$detail$es.internal(_root);
	@override String totalResults({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} resultado',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} resultados',
	);
}

// Path: liveTv
class Translations$liveTv$es extends Translations$liveTv$en {
	Translations$liveTv$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'TV en vivo';
	@override String get guide => 'Guía';
	@override String get noChannels => 'No hay canales disponibles';
	@override String get noDvr => 'No hay DVR configurado en ningún servidor';
	@override String get serverUnavailable => 'El servidor de TV en vivo no está disponible.';
	@override String get serverNotConnected => 'El servidor de TV en vivo no está conectado.';
	@override String get noPrograms => 'No hay datos de programación disponibles';
	@override String get liveStreamFailed => 'Falló la transmisión en vivo';
	@override String get unknownProgram => 'Programa desconocido';
	@override String get timelineLiveProgram => 'Programa en vivo (el reproductor puede estar fuera de este programa)';
	@override String get timelineBuffer => 'Temas de Buffer';
	@override String get timelineUnavailable => 'Tima de tiempo inaccesible';
	@override String get timelineEstimated => 'El Playback estimado';
	@override String get timelinePending => 'En busca';
	@override String get timelineStale => 'El calendario puede estar envejecido';
	@override String get unknownHub => 'Desconocido';
	@override String get unknownError => 'Error desconocido';
	@override String channelNumber({required Object number}) => 'Canal ${number}';
	@override String get unknownChannel => 'Canal desconocido';
	@override String get live => 'EN VIVO';
	@override String get premiereBadge => 'Nuevo';
	@override String get reloadGuide => 'Recargar guía';
	@override String get searchGuide => 'Buscar en la guía';
	@override String get searchHint => 'Buscar canales y programas';
	@override String searchNoResults({required Object query}) => 'Sin coincidencias para "${query}"';
	@override String get channelsSection => 'Canales';
	@override String get programsSection => 'Programas';
	@override String get now => 'Ahora';
	@override String get today => 'Hoy';
	@override String get tomorrow => 'Mañana';
	@override String get midnight => 'Medianoche';
	@override String get overnight => 'Madrugada';
	@override String get morning => 'Mañana';
	@override String get daytime => 'Día';
	@override String get evening => 'Noche';
	@override String get lateNight => 'Trasnoche';
	@override String get whatsOn => 'En emisión';
	@override String get watchChannel => 'Ver canal';
	@override String get favorites => 'Favoritos';
	@override String get reorderFavorites => 'Reordenar favoritos';
	@override String get noFavoriteChannels => 'No hay canales favoritos';
	@override String get noFavoriteChannelsHint => 'Muestra todos los canales y mantén pulsado uno para añadirlo a tus favoritos.';
	@override String get showAllChannels => 'Mostrar todos los canales';
	@override String get favoritesLoadFailed => 'No se pudieron cargar los favoritos. Comprueba tu conexión e inténtalo de nuevo.';
	@override String get favoritesUpdateFailed => 'No se pudieron actualizar los favoritos. Comprueba tu conexión e inténtalo de nuevo.';
	@override String get joinSession => 'Unirse a sesión en curso';
	@override String watchFromStart({required Object minutes}) => 'Ver desde el inicio (hace ${minutes} min)';
	@override String get watchLive => 'Ver en vivo';
	@override String get goToLive => 'Ir a la emisión en vivo';
	@override String get record => 'Grabar';
	@override String get recordEpisode => 'Grabar episodio';
	@override String get recordSeries => 'Grabar serie';
	@override String get recordOptions => 'Opciones de grabación';
	@override String get saveTo => 'Guardar en';
	@override String get recordings => 'Grabaciones';
	@override String get scheduledRecordings => 'Programadas';
	@override String get recordingRules => 'Reglas de grabación';
	@override String get noScheduledRecordings => 'No hay grabaciones programadas';
	@override String get manageRecording => 'Gestionar grabación';
	@override String get cancelRecording => 'Cancelar grabación';
	@override String get cancelRecordingTitle => '¿Cancelar esta grabación?';
	@override String cancelRecordingMessage({required Object title}) => '${title} ya no se grabará.';
	@override String get deleteRule => 'Eliminar regla';
	@override String get deleteRuleTitle => '¿Eliminar regla de grabación?';
	@override String deleteRuleMessage({required Object title}) => 'Los próximos episodios de ${title} no se grabarán.';
	@override String get recordingScheduled => 'Grabación programada';
	@override String get alreadyScheduled => 'Este programa ya está programado';
	@override String get dvrAdminRequired => 'La configuración DVR requiere una cuenta de administrador';
	@override String get recordingFailed => 'No se pudo programar la grabación';
	@override String get recordingTargetMissing => 'No se pudo determinar la biblioteca de grabación';
	@override String get recordNotAvailable => 'Grabación no disponible para este programa';
	@override String get recordingCancelled => 'Grabación cancelada';
	@override String get recordingRuleDeleted => 'Regla de grabación eliminada';
	@override String get processRecordingRules => 'Reevaluar reglas';
	@override String get recordingInProgress => 'Grabando ahora';
	@override String recordingsCount({required Object count}) => '${count} programadas';
	@override String get editRule => 'Editar regla';
	@override String get editRuleAction => 'Editar';
	@override String get recordingRuleUpdated => 'Regla de grabación actualizada';
	@override String get guideReloadRequested => 'Solicitada actualización de la guía';
	@override String get guideReloadFailed => 'No se pudo actualizar la guía';
	@override String get rulesProcessRequested => 'Solicitada reevaluación de reglas';
	@override String get rulesProcessFailed => 'No se pudieron reevaluar las reglas de grabación';
	@override String get recordShow => 'Grabar programa';
	@override late final Translations$liveTv$recordSettings$es recordSettings = Translations$liveTv$recordSettings$es.internal(_root);
	@override String startingInMinutes({required Object minutes}) => 'Empieza en ${minutes} min';
	@override String dayAtTime({required Object day, required Object time}) => '${day} a las ${time}';
	@override String invalidPlaybackData({required Object product}) => '${product} devolvió datos de reproducción de TV en vivo no válidos';
	@override String get failedToStartChannel => 'No se pudo iniciar el canal en vivo';
	@override String get failedToBuildStreamUrl => 'No se pudo generar la URL de transmisión';
	@override String playbackStartFailed({required Object reason}) => 'No se pudo iniciar el canal: ${reason}';
	@override String channelSwitchFailed({required Object reason}) => 'No se pudo cambiar de canal: ${reason}';
}

// Path: collections
class Translations$collections$es extends Translations$collections$en {
	Translations$collections$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Colecciones';
	@override String get collection => 'Colección';
	@override String get empty => 'La colección está vacía';
	@override String get deleteCollection => 'Eliminar colección';
	@override String deleteConfirm({required Object title}) => '¿Eliminar "${title}"? No se puede deshacer.';
	@override String get deleted => 'Colección eliminada';
	@override String get deleteFailed => 'Error al eliminar la colección';
	@override String deleteFailedWithError({required Object error}) => 'Error al eliminar la colección: ${error}';
	@override String get selectCollection => 'Seleccionar colección';
	@override String get collectionName => 'Nombre de la colección';
	@override String get enterCollectionName => 'Introduce el nombre de la colección';
	@override String get addedToCollection => 'Añadido a la colección';
	@override String get errorAddingToCollection => 'Error al añadir a la colección';
	@override String get created => 'Colección creada';
	@override String get removeFromCollection => 'Eliminar de la colección';
	@override String removeFromCollectionConfirm({required Object title}) => '¿Eliminar "${title}" de esta colección?';
	@override String get removedFromCollection => 'Eliminado de la colección';
	@override String get removeFromCollectionFailed => 'Error al eliminar de la colección';
	@override String removeFromCollectionError({required Object error}) => 'Error al eliminar de la colección: ${error}';
	@override String get searchCollections => 'Buscar colecciones...';
}

// Path: playlists
class Translations$playlists$es extends Translations$playlists$en {
	Translations$playlists$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Listas de reproducción';
	@override String get playlist => 'Lista de reproducción';
	@override String get noPlaylists => 'No se encontraron listas de reproducción';
	@override String get create => 'Crear lista de reproducción';
	@override String get playlistName => 'Nombre de la lista de reproducción';
	@override String get enterPlaylistName => 'Introduce el nombre de la lista de reproducción';
	@override String get delete => 'Eliminar lista de reproducción';
	@override String get removeItem => 'Eliminar de la lista de reproducción';
	@override String get smartPlaylist => 'Lista de reproducción inteligente';
	@override String itemCount({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} elemento',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} elementos',
	);
	@override String get emptyPlaylist => 'Esta lista de reproducción está vacía';
	@override String get deleteConfirm => '¿Eliminar lista de reproducción?';
	@override String deleteMessage({required Object name}) => '¿Estás seguro de que quieres eliminar "${name}"?';
	@override String get created => 'Lista de reproducción creada';
	@override String get deleted => 'Lista de reproducción eliminada';
	@override String get itemAdded => 'Añadido a la lista de reproducción';
	@override String get itemRemoved => 'Eliminado de la lista de reproducción';
	@override String get selectPlaylist => 'Seleccionar lista de reproducción';
	@override String get searchPlaylists => 'Buscar listas de reproducción...';
	@override String get errorCreating => 'Error al crear la lista de reproducción';
	@override String get errorDeleting => 'Error al eliminar la lista de reproducción';
	@override String get errorLoading => 'Error al cargar las listas de reproducción';
	@override String get errorAdding => 'Error al añadir a la lista de reproducción';
	@override String get errorReordering => 'Error al reordenar el elemento de la lista de reproducción';
	@override String get errorRemoving => 'Error al eliminar de la lista de reproducción';
}

// Path: music
class Translations$music$es extends Translations$music$en {
	Translations$music$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => 'Ir al álbum';
	@override String get goToArtist => 'Ir al artista';
	@override String get instantMix => 'Mezcla instantánea';
	@override String get playNext => 'Reproducir a continuación';
	@override String get addToQueue => 'Añadir a la cola';
	@override String discNumber({required Object n}) => 'Disco ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} canción',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} canciones',
	);
	@override String get nowPlaying => 'Reproduciendo ahora';
	@override String playingFrom({required Object title}) => 'Reproduciendo desde ${title}';
	@override String get queue => 'Cola';
	@override String get clearQueue => 'Vaciar la cola';
	@override String get lyrics => 'Letra';
	@override String get visualizer => 'Visualizador';
	@override String get visualizerProfileLoading => 'El análisis de la pista...';
	@override String get visualizerAmbientMotion => 'Movimiento Ambiental';
	@override String get visualizerPlexLoudness => 'Plex ruido';
	@override String get visualizerPreviousPreset => 'Artículo anteriorEl estilo visual';
	@override String get visualizerNextPreset => 'Siguiente Estilo visual';
	@override String get visualizerPresetAurora => 'Aurora';
	@override String get visualizerPresetBloom => 'Blojo';
	@override String get visualizerPresetOrbitals => 'Orbitales';
	@override String get visualizerPresetPrism => 'Prism';
	@override String get visualizerPresetTunnel => 'Túnel';
	@override String get visualizerPresetTrackMap => 'Mapa de Track';
	@override String get noLyrics => 'No hay letra disponible';
	@override String get sleepTimer => 'Temporizador de apagado';
	@override String get sleepTimerEndOfTrack => 'Fin de la canción';
	@override String sleepTimerMinutes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minuto',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minutos',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minutos',
	);
	@override String get stopPlayback => 'Detener reproducción';
	@override String get previousTrack => 'Canción anterior';
	@override String get nextTrack => 'Canción siguiente';
	@override String get repeat => 'Repetir';
	@override String get repeatAll => 'Repetir todo';
	@override String get repeatOne => 'Repetir una';
	@override String get instantMixNoServer => 'No hay ningún servidor disponible para una mezcla instantánea';
	@override String get instantMixFailed => 'Error al cargar la mezcla instantánea';
	@override String get instantMixEmpty => 'La mezcla instantánea no devolvió ninguna canción';
	@override String noAudioUrl({required Object track}) => 'No hay ninguna URL de audio disponible para ${track}';
	@override late final Translations$music$discography$es discography = Translations$music$discography$es.internal(_root);
}

// Path: watchTogether
class Translations$watchTogether$es extends Translations$watchTogether$en {
	Translations$watchTogether$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ver juntos';
	@override String get description => 'Mira contenido sincronizado con amigos y familiares';
	@override String get createRoom => 'Crear sala';
	@override String get creatingRoom => 'Creando sala...';
	@override String get joinRoom => 'Unirse a una sala';
	@override String get joiningRoom => 'Uniéndote a la sala...';
	@override String get connecting => 'Conectando...';
	@override String get relayPublic => 'Las salas usan los servidores de retransmisión públicos de Open Watch Party.';
	@override String relayCustom({required Object url}) => 'Las salas usan tu servidor de retransmisión en ${url}.';
	@override String get recentRooms => 'Salas recientes';
	@override String get roomActions => 'Acciones de la sala';
	@override String get renameRoom => 'Renombrar sala';
	@override String get removeRoom => 'Eliminar';
	@override String get enterRoomCode => 'Introduce el código de 6 caracteres del anfitrión.';
	@override String get roomCode => 'Código de sala';
	@override String get paste => 'Pegar';
	@override String get noCodeInClipboard => 'El portapapeles no contiene un código de sala';
	@override String get copyCode => 'Copiar código';
	@override String get codeCopied => 'Código de sala copiado';
	@override String get shareInvite => 'Compartir invitación';
	@override String get inviteCopied => 'Invitación copiada. Pégala en un mensaje.';
	@override String inviteMessage({required Object code}) => 'Únete a mi sala de Ver juntos en PlezyNG: abre «Ver juntos», elige «Unirse a una sala» e introduce ${code}.';
	@override String get openSessionControls => 'Abrir los controles de la sesión de Ver juntos';
	@override String get reconnecting => 'Reconectando...';
	@override String get reconnectingDescription => 'Se perdió la conexión. Volverás a unirte a la sala automáticamente.';
	@override String get connected => 'Conectado';
	@override String get disconnected => 'Desconectado';
	@override String get youAreHost => 'Eres el anfitrión';
	@override String hostedBy({required Object name}) => 'Anfitrión: ${name}';
	@override String get hostControlsPlayback => 'El anfitrión controla la reproducción';
	@override String get anyoneCanControl => 'Cualquiera puede controlar la reproducción';
	@override String get roomLocked => 'Sala bloqueada';
	@override String get nowPlaying => 'Reproduciendo ahora';
	@override String get nothingPlaying => 'No se está reproduciendo nada';
	@override String get nothingPlayingHost => 'Reproduce algo de cualquier biblioteca para compartirlo con la sala.';
	@override String get nothingPlayingGuest => 'Cuando el anfitrión reproduzca algo, se abrirá aquí.';
	@override String get notShareable => 'Este video no coincide con ningún catálogo, así que solo pueden reproducirlo quienes tengan acceso al mismo servidor.';
	@override String get searching => 'Buscando este video en tus bibliotecas...';
	@override String get yourCopy => 'Tu copia';
	@override String get sharingYourCopy => 'Estás compartiendo tu copia';
	@override String playingOtherLength({required Object difference}) => 'Reproduciendo tu copia · ${difference}';
	@override String get mismatchTitle => 'Tu copia tiene otra duración';
	@override String mismatchDescription({required Object difference}) => 'Tu copia más parecida es ${difference} que el video de la sala. Puede ser otro montaje o versión.';
	@override String get playAnyway => 'Reproducir de todos modos';
	@override String get chooseAnotherCopy => 'Elegir otra copia';
	@override String get dontPlay => 'No reproducir';
	@override String get unavailableTitle => 'No tienes este video';
	@override String get unavailableDescription => 'PlezyNG no lo encontró en tus bibliotecas. Elige una copia tú mismo o vuelve a buscar.';
	@override String get chooseCopy => 'Elegir una copia';
	@override String get searchAgain => 'Buscar de nuevo';
	@override String get noCandidates => 'No se encontraron copias en tus bibliotecas.';
	@override String get choiceFailed => 'No se pudo reproducir esta copia para la sala';
	@override String lengthLonger({required Object duration}) => '${duration} más larga';
	@override String lengthShorter({required Object duration}) => '${duration} más corta';
	@override String get lengthSame => 'Misma duración';
	@override String get lengthUnknown => 'Duración desconocida';
	@override String get joinCurrentPlayback => 'Unirse a la reproducción actual';
	@override String get joinCurrentPlaybackDescription => 'Vuelve a lo que el anfitrión está viendo ahora mismo';
	@override String get stopMedia => 'Detener el video para todos';
	@override String get syncOffset => 'Ajuste de sincronización';
	@override String get syncOffsetDescription => 'Desplaza tu video si va por delante o por detrás de la sala.';
	@override String offsetHint({required Object difference}) => 'Tu copia es ${difference} que el video de la sala.';
	@override String applyDifference({required Object offset}) => 'Usar ${offset}';
	@override String get offsetMinusSecond => '-1 s';
	@override String get offsetMinusTenth => '-100 ms';
	@override String get offsetPlusTenth => '+100 ms';
	@override String get offsetPlusSecond => '+1 s';
	@override String get participants => 'Participantes';
	@override String participantCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} participante',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} participantes',
	);
	@override String get hostBadge => 'ANFITRIÓN';
	@override String nameYou({required Object name}) => '${name} (tú)';
	@override String get playerIdle => 'Inactivo';
	@override String get playerLoading => 'Cargando';
	@override String get playerReady => 'Listo';
	@override String get playerBuffering => 'Almacenando en búfer';
	@override String get matchSearching => 'Buscando';
	@override String get matchMatched => 'Tiene el video';
	@override String get matchMismatched => 'Duración distinta';
	@override String get matchUnavailable => 'No tiene el video';
	@override String participantOffset({required Object offset}) => 'Desfase ${offset}';
	@override String get makeHost => 'Hacer anfitrión';
	@override String get makeHostQuestion => '¿Transferir el rol de anfitrión?';
	@override String makeHostConfirm({required Object name}) => '${name} controlará la reproducción y dirigirá la sesión para todos.';
	@override String get transfer => 'Transferir';
	@override String get removeParticipant => 'Expulsar de la sala';
	@override String removeParticipantQuestion({required Object name}) => '¿Expulsar a ${name}?';
	@override String removeParticipantConfirm({required Object name}) => '${name} saldrá de la sala. Podrá volver a unirse con el código, salvo que bloquees la sala.';
	@override String get remove => 'Expulsar';
	@override String get roomSettings => 'Ajustes de la sala';
	@override String get letEveryoneControl => 'Permitir que todos controlen la reproducción';
	@override String get lockRoom => 'Bloquear sala';
	@override String get lockRoomDescription => 'Nadie nuevo puede unirse';
	@override String get leaveRoom => 'Salir de la sala';
	@override String get leaveRoomQuestion => '¿Salir de la sala?';
	@override String get leaveRoomConfirm => 'Puedes volver a unirte con el código de sala.';
	@override String get leave => 'Salir';
	@override String get endRoom => 'Finalizar sala';
	@override String get endRoomQuestion => '¿Finalizar la sala?';
	@override String get endRoomConfirm => 'La sala se cerrará para todos.';
	@override String get end => 'Finalizar';
	@override String get playBlockedTitle => 'La reproducción no se inició';
	@override String get playBlockedDescription => 'Pulsa reproducir para empezar a ver con la sala.';
	@override late final Translations$watchTogether$notices$es notices = Translations$watchTogether$notices$es.internal(_root);
	@override late final Translations$watchTogether$ended$es ended = Translations$watchTogether$ended$es.internal(_root);
	@override late final Translations$watchTogether$errors$es errors = Translations$watchTogether$errors$es.internal(_root);
	@override String untitledEpisode({required Object number}) => 'Episodio ${number}';
}

// Path: downloads
class Translations$downloads$es extends Translations$downloads$en {
	Translations$downloads$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Descargas';
	@override String get manage => 'Gestionar';
	@override String get tvShows => 'Series de TV';
	@override String get movies => 'Películas';
	@override String get music => 'Música';
	@override String tracksQueued({required Object count}) => '${count} canciones en cola para descargar';
	@override String get noDownloads => 'No hay descargas aún';
	@override String get noDownloadsDescription => 'El contenido descargado aparecerá aquí para verlo sin conexión';
	@override String get downloadNow => 'Descargar';
	@override String get deleteDownload => 'Eliminar descarga';
	@override String get retryDownload => 'Reintentar descarga';
	@override String get downloadQueued => 'Descarga en cola';
	@override String get downloadResumed => 'Descarga reanudada';
	@override String get serverErrorBitrate => 'Error del servidor: el archivo puede superar el límite remoto de tasa de bits';
	@override String get storageFull => 'Las descargas se detuvieron para proteger el espacio disponible. Libera espacio o elige otra ubicación de descarga e inténtalo de nuevo.';
	@override String get storageUnavailable => 'Las descargas se detuvieron porque no se pudo comprobar el almacenamiento disponible. Comprueba la ubicación de descarga y vuelve a intentarlo.';
	@override String episodesQueued({required Object count}) => '${count} episodios en cola para descargar';
	@override String get downloadDeleted => 'Descarga eliminada';
	@override String deleteConfirm({required Object title}) => '¿Eliminar "${title}" de este dispositivo?';
	@override String get deleteCollectionDownloads => 'Eliminar descargas';
	@override String deleteCollectionDownloadsConfirm({required Object title}) => '¿Eliminar todas las descargas de "${title}" de este dispositivo?';
	@override String get collectionDownloadsDeleted => 'Descargas eliminadas';
	@override String get cancelledDownloadTitle => 'Descarga cancelada';
	@override String get cancelledDownloadMessage => 'Esta descarga se canceló. ¿Qué quieres hacer?';
	@override String get allEpisodesAlreadyDownloaded => 'Todos los episodios ya están descargados';
	@override String get resumeDownload => 'Reanudar descarga';
	@override String get cancelledDownload => 'Descarga cancelada';
	@override String syncingFile({required Object file, required Object status}) => '${file} (sincronizando ${status})';
	@override String downloadedFileClickToComplete({required Object file}) => '${file} descargado — haz clic para completar';
	@override String get partialDownloadClickToComplete => 'Descarga parcial — haz clic para completar';
	@override String get deleting => 'Eliminando...';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Eliminando ${title}... (${current} de ${total})';
	@override String get queuedTooltip => 'En cola';
	@override String queuedFilesTooltip({required Object files}) => 'En cola: ${files}';
	@override String get downloadingTooltip => 'Descargando...';
	@override String downloadingFilesTooltip({required Object files}) => 'Descargando ${files}';
	@override String get noDownloadsTree => 'Sin descargas';
	@override String get pauseAll => 'Pausar todo';
	@override String get resumeAll => 'Reanudar todo';
	@override String get retryAll => 'Reintentar todo';
	@override String get retryFailed => 'Reintentar descargas fallidas';
	@override String get deleteAll => 'Eliminar todo';
	@override String get selectVersion => 'Seleccionar versión';
	@override String get allEpisodes => 'Todos los episodios';
	@override String get unwatchedOnly => 'Solo no vistos';
	@override String nextNUnwatched({required Object count}) => 'Próximos ${count} no vistos';
	@override String get customAmount => 'Cantidad personalizada...';
	@override String get customAmountAny => 'Cuantía de la persona (todos los ...';
	@override String get randomEpisodes => 'Episodios aleatorios';
	@override String get includeSpecials => 'Incluir especiales';
	@override String get howManyEpisodes => '¿Cuántos episodios?';
	@override String get invalidEpisodeCount => 'Introduce un número de episodios válido.';
	@override String get keepSynced => 'Mantener sincronizado';
	@override String get downloadOnce => 'Descargar una vez';
	@override String keepNUnwatched({required Object count}) => 'Mantener ${count} no vistos';
	@override String get editSyncRule => 'Editar regla de sincronización';
	@override String get removeSyncRule => 'Eliminar regla de sincronización';
	@override String removeSyncRuleConfirm({required Object title}) => '¿Dejar de sincronizar "${title}"? Los episodios descargados se conservarán.';
	@override String removeListSyncRuleConfirm({required Object title}) => '¿Dejar de sincronizar "${title}"?';
	@override String get deleteSyncRuleDownloads => 'Eliminar también las descargas asociadas';
	@override String get deleteSyncRuleDownloadsDescription => 'Se conservarán las descargas usadas por otra regla de sincronización o perfil.';
	@override String syncRuleCreated({required Object count}) => 'Regla de sincronización creada — se conservarán ${count} episodios no vistos';
	@override String get syncRuleUpdated => 'Regla de sincronización actualizada';
	@override String get syncRuleRemoved => 'Regla de sincronización eliminada';
	@override String get syncRuleAndDownloadsRemoved => 'Regla de sincronización y descargas asociadas eliminadas';
	@override String get syncRuleCleanupBusy => 'Las reglas de sincronización se están actualizando. Inténtalo de nuevo en un momento.';
	@override String get syncRuleCleanupUnavailable => 'No se pudieron identificar las descargas asociadas de forma segura. Vuelve a conectar el servidor e inténtalo de nuevo, o elimina la regla sin borrar las descargas.';
	@override String syncedNewEpisodes({required Object count, required Object title}) => '${count} nuevos episodios sincronizados para ${title}';
	@override String get syncNow => 'Síntomas ahora';
	@override String get downloadsUpToDate => 'Los descargos están hasta la fecha';
	@override String syncComplete({required Object queued, required Object removed}) => 'Sync complete · ${queued} queued, ${removed} eliminado';
	@override String get activeSyncRules => 'Reglas de sincronización';
	@override String get reviewOrphanFiles => 'Revisar descargas huérfanas';
	@override String get orphanReviewTitle => 'Revisar descargas huérfanas';
	@override String get orphanReviewDescription => 'Estos archivos etiquetados están en las carpetas de descargas predeterminadas que administra PlezyNG y no tienen un registro de descarga ni una tarea activa asociada. Revisa la lista antes de eliminarlos.';
	@override String orphanReviewCount({required Object count, required Object size}) => '${count} archivos · ${size}';
	@override String orphanDeleteFiles({required Object count}) => 'Eliminar ${count} archivos';
	@override String get orphanCleanupNone => 'No se encontraron archivos de descarga huérfanos';
	@override String get orphanCleanupFailed => 'PlezyNG no pudo analizar de forma segura la carpeta de descargas administrada. No se eliminó ningún archivo.';
	@override String get orphanCleanupChanged => 'La lista de descargas cambió durante la revisión. Revisa los archivos de nuevo antes de limpiar.';
	@override String orphanCleanupComplete({required Object count, required Object size}) => 'Se eliminaron ${count} archivos de descarga huérfanos · ${size} liberados';
	@override String get noSyncRules => 'Sin reglas de sincronización';
	@override String get manageSyncRule => 'Gestionar sincronización';
	@override String get editEpisodeCount => 'Número de episodios';
	@override String get editSyncFilter => 'Filtro de sincronización';
	@override String get syncAllItems => 'Sincronizando todos los elementos';
	@override String get syncUnwatchedItems => 'Sincronizando elementos no vistos';
	@override String syncRuleServerContext({required Object server, required Object status}) => 'Servidor: ${server} • ${status}';
	@override String get syncRuleAvailable => 'Disponible';
	@override String get syncRuleOffline => 'Sin conexión';
	@override String get syncRuleSignInRequired => 'Se requiere iniciar sesión';
	@override String get syncRuleAccessDenied => 'Acceso denegado';
	@override String get syncRuleNotAvailableForProfile => 'No disponible para el perfil actual';
	@override String get syncRuleUnknownServer => 'Servidor desconocido';
	@override String get syncRuleListCreated => 'Regla de sincronización creada';
	@override late final Translations$downloads$backgroundWarning$es backgroundWarning = Translations$downloads$backgroundWarning$es.internal(_root);
	@override String get options => 'Opciones de descargas';
	@override late final Translations$downloads$groupings$es groupings = Translations$downloads$groupings$es.internal(_root);
	@override String get unknownLibrary => 'Biblioteca desconocida';
	@override String get unknownShow => 'Serie desconocida';
	@override String get unknownSeason => 'Temporada desconocida';
	@override String get unknownAlbum => 'Álbum desconocido';
	@override String completedOfTotal({required Object completed, required Object total}) => '${completed}/${total} completadas';
	@override String storageUsed({required Object size}) => 'Almacenamiento utilizado: ${size}';
	@override String downloadCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} descarga',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} descargas',
	);
	@override String showCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} muestra',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} muestra',
	);
	@override String movieCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} películas',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} películas',
	);
	@override String albumCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} álbum',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} álbumes',
	);
	@override String get errorFileNotFound => 'Archivo no encontrado (404)';
	@override String get errorDownloadNotAllowed => 'El servidor no permite la descarga (403)';
	@override String get errorDownloadFailed => 'Error en la descarga';
	@override String errorDownloadFailedWithReason({required Object reason}) => 'Error en la descarga: ${reason}';
	@override String get convertingOnServer => 'Convertir en el servidor...';
	@override String convertingOnServerPercent({required Object percent}) => 'Convertir en servidor · ${percent}%';
	@override String errorHttpStatus({required Object status}) => 'Error en la descarga (HTTP ${status})';
	@override String errorPostProcessing({required Object reason}) => 'Error en el posprocesamiento: ${reason}';
	@override String get reasonFileNotSaved => 'no se pudo guardar el archivo en este dispositivo';
	@override String get reasonCannotResume => 'no se pudo reanudar la descarga parcial';
	@override String get reasonDeviceStorageFull => 'este dispositivo no tiene espacio de almacenamiento';
	@override String get notificationDownloading => 'Descargando...';
	@override String get notificationComplete => 'Descarga completada';
	@override String get notificationPaused => 'Descarga pausada';
}

// Path: shaders
class Translations$shaders$es extends Translations$shaders$en {
	Translations$shaders$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Shaders';
	@override String get noShaderDescription => 'Sin mejora de video';
	@override String get nvscalerDescription => 'Escalado de imagen NVIDIA para un video más nítido';
	@override String get artcnnVariantNeutral => 'Neutral';
	@override String get artcnnVariantDenoise => 'Reducción de ruido';
	@override String get artcnnVariantDenoiseSharpen => 'Reducción de ruido + enfoque';
	@override String get qualityFast => 'Rápido';
	@override String get qualityHQ => 'Alta calidad';
	@override String get mode => 'Modo';
	@override String get importShader => 'Importar shader';
	@override String get customShaderDescription => 'Shader GLSL personalizado';
	@override String get shaderImported => 'Shader importado';
	@override String get shaderImportFailed => 'Error al importar shader';
	@override String get deleteShader => 'Eliminar shader';
	@override String deleteShaderConfirm({required Object name}) => '¿Eliminar "${name}"?';
}

// Path: companionRemote
class Translations$companionRemote$es extends Translations$companionRemote$en {
	Translations$companionRemote$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Control remoto';
	@override String connectedTo({required Object name}) => 'Conectado a ${name}';
	@override String get unknownDevice => 'Dispositivo desconocido';
	@override late final Translations$companionRemote$session$es session = Translations$companionRemote$session$es.internal(_root);
	@override late final Translations$companionRemote$pairing$es pairing = Translations$companionRemote$pairing$es.internal(_root);
	@override late final Translations$companionRemote$remote$es remote = Translations$companionRemote$remote$es.internal(_root);
	@override late final Translations$companionRemote$errors$es errors = Translations$companionRemote$errors$es.internal(_root);
	@override String get closedBeforeAuth => 'La conexión se cerró antes de la autenticación';
}

// Path: videoSettings
class Translations$videoSettings$es extends Translations$videoSettings$en {
	Translations$videoSettings$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'Velocidad de reproducción';
	@override String get normalSpeed => 'Normal';
	@override String sleepTimerActive({required Object duration}) => 'Activo (${duration})';
	@override String get zoom => 'Zoom';
	@override String get sleepTimer => 'Temporizador de apagado';
	@override String get audioSync => 'Sincronización de audio';
	@override String get subtitleSync => 'Sincronización de subtítulos';
	@override String get hdr => 'HDR';
	@override String get hdrUnsupported => 'HDR no está disponible aquí: este compositor de escritorio o esta salida de vídeo no pueden transmitirlo.';
	@override String get hdrToneMapping => 'Mapeo de tonos HDR';
	@override String get hdrToneMappingCompositor => 'Compositor';
	@override String get hdrToneMappingCompositorDescription => 'Transmite los metadatos HDR de la fuente y deja que el compositor de escritorio haga el mapeo.';
	@override String get hdrToneMappingPlayer => 'Reproductor';
	@override String get hdrToneMappingPlayerDescription => 'Realiza en el reproductor el mapeo al brillo máximo de la pantalla y luego comunica el resultado al compositor.';
	@override String get hdrToneMappingFailed => 'No se pudo cambiar el mapeo de tonos HDR; el modo anterior sigue activo.';
	@override String get audioOutput => 'Salida de audio';
	@override String get performanceOverlay => 'Indicador de rendimiento';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'Envolvente';
	@override String get audioOutputSpatial => 'Audio espacial';
	@override String get audioOutputStereo => 'Estéreo';
	@override String get audioEqualizer => 'Ecualizador de audio';
	@override String get audioEqualizerDescription => 'Ajuste cinco bandas de frecuencia para este dispositivo. Disponible en mpv; un EQ activo decoca el audio y desactiva la adaptación.';
	@override String get audioEqualizerFlat => 'Plano';
	@override String get audioEqualizerActive => 'Personalizado';
	@override String get audioEqualizerSaveFailed => 'No podría salvar la configuración de audio equalizer.';
	@override String get backgroundVideoAudio => 'Video Audio de fondo';
	@override String get backgroundVideoAudioDescription => 'Mantenga el audio de video cuando abandona el reproductor; la imagen está oculta hasta que vuelva. Android utiliza una notificación de reproducción de medios.';
	@override String get audioNormalization => 'Normalizar volumen';
	@override String get audioNormalizationDisablesPassthrough => 'Decodifica el audio a PCM; la transferencia directa está desactivada mientras esta opción esté activa';
}

// Path: performanceOverlay
class Translations$performanceOverlay$es extends Translations$performanceOverlay$en {
	Translations$performanceOverlay$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get color => 'Color';
	@override String get performance => 'Rendimiento';
	@override String get buffer => 'Búfer';
	@override String get app => 'App';
	@override String get decoder => 'Decodificador';
	@override String get rawDecoder => 'Decodificador sin procesar';
	@override String get tunneling => 'Túnel';
	@override String get passthrough => 'Transferencia directa';
	@override String get aspect => 'Aspecto';
	@override String get rotation => 'Rotación';
	@override String get dvSource => 'Origen DV';
	@override String get dvPath => 'Ruta DV';
	@override String get dvRouteDecoder => 'Decodificador Dolby Vision';
	@override String get dvRouteDecoderP81 => 'Decodificador Dolby Vision (P7→8.1)';
	@override String get dvRouteBaseLayer => 'Capa base';
	@override String get dvRouteBaseLayerHdr10 => 'Capa base HDR10';
	@override String get dvRouteBaseLayerHlg => 'Capa base HLG';
	@override String get dvRouteBaseLayerSdr => 'Capa base SDR';
	@override String get dvRouteReshaped => 'Remodelado con RPU (gpu-next)';
	@override String get dvRouteFelGraphActive => 'El gráfico experimental P7 FEL (no cualificado)';
	@override String get p7Conversion => 'Conv. P7';
	@override String get sampleRate => 'Frecuencia de muestreo';
	@override String get pixelFormat => 'Formato de píxel';
	@override String get hwFormat => 'Formato HW';
	@override String get matrix => 'Matriz';
	@override String get primaries => 'Primarios';
	@override String get transfer => 'Transferencia';
	@override String get renderFps => 'FPS render';
	@override String get displayFps => 'FPS pantalla';
	@override String get avSync => 'Sincronía A/V';
	@override String get dropped => 'Descartados';
	@override String get dvRpus => 'DV RPUs';
	@override String get dvRpuAverage => 'Prom. DV RPU';
	@override String get dvSampleAverage => 'Prom. muestra DV';
	@override String get maxLuma => 'Luma máx.';
	@override String get minLuma => 'Luma mín.';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => 'Caché usada';
	@override String get cacheLimit => 'Límite de caché';
	@override String get speed => 'Velocidad';
	@override String get player => 'Reproductor';
	@override String get playMethod => 'El método de juego';
	@override String get memory => 'Memoria';
	@override String get uiFps => 'FPS UI';
	@override String get fps => 'FPS';
	@override String get decoderAndroidHw => 'HW de Android';
	@override String get decoderNvidiaHw => 'HW de NVIDIA';
	@override String get decoderQualcommHw => 'HW de Qualcomm';
	@override String get decoderMediatekHw => 'HW de MediaTek';
	@override String get decoderExynosHw => 'HW de Exynos';
	@override String get decoderSoftware => 'Software';
	@override String get decoderHardware => 'Hardware';
	@override String get tunnelingActive => 'Activo';
	@override String dvRpuFailed({required Object converted, required Object failures}) => '${converted} (${failures} con error)';
}

// Path: externalPlayer
class Translations$externalPlayer$es extends Translations$externalPlayer$en {
	Translations$externalPlayer$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Reproductor externo';
	@override String get useExternalPlayer => 'Usar reproductor externo';
	@override String get useExternalPlayerDescription => 'Abrir videos en otra aplicación';
	@override String get selectPlayer => 'Seleccionar reproductor';
	@override String get customPlayers => 'Reproductores personalizados';
	@override String get systemDefault => 'Predeterminado del sistema';
	@override String get addCustomPlayer => 'Añadir reproductor personalizado';
	@override String get playerName => 'Nombre del reproductor';
	@override String get playerNameHint => 'Mi reproductor';
	@override String get playerCommand => 'Comando';
	@override String get playerPackage => 'Nombre del paquete';
	@override String get playerUrlScheme => 'Esquema URL';
	@override String get off => 'Desactivado';
	@override String get launchFailed => 'No se pudo abrir el reproductor externo';
	@override String appNotInstalled({required Object name}) => '${name} no está instalado';
	@override String get playInExternalPlayer => 'Reproducir en reproductor externo';
	@override String get description => 'Seleccione otra aplicación para abrir videos en. Los jugadores disponibles dependen de su dispositivo y las aplicaciones instaladas.';
	@override String get systemDefaultDescription => 'Deja que el sistema operativo abra el vídeo con su aplicación por defecto.';
	@override String playerOptionDescription({required Object player}) => 'Abrir videos con ${player}.';
	@override String get playerNameDescription => 'La etiqueta que se muestra en la lista de jugadores.';
	@override String get playerPackageDescription => 'Introduce el nombre del paquete Android de la aplicación de jugador, como com.example.player.';
	@override String get playerCommandDescription => 'Introduce el comando de jugador instalado o la ruta ejecutable para este dispositivo.';
	@override String get playerUrlSchemeDescription => 'Introduce el esquema de URL y la plantilla de URL opcional utilizada para lanzar al jugador.';
}

// Path: metadataEdit
class Translations$metadataEdit$es extends Translations$metadataEdit$en {
	Translations$metadataEdit$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'Editar...';
	@override String get screenTitle => 'Editar metadatos';
	@override String get basicInfo => 'Información básica';
	@override String get artwork => 'Imágenes';
	@override String get advancedSettings => 'Ajustes avanzados';
	@override String get title => 'Título';
	@override String get sortTitle => 'Título de ordenación';
	@override String get originalTitle => 'Título original';
	@override String get releaseDate => 'Fecha de estreno';
	@override String get contentRating => 'Clasificación de contenido';
	@override String get studio => 'Estudio';
	@override String get tagline => 'Eslogan';
	@override String get summary => 'Resumen';
	@override String get poster => 'Póster';
	@override String get background => 'Fondo';
	@override String get logo => 'Logo';
	@override String get squareArt => 'Imagen cuadrada';
	@override String get selectPoster => 'Seleccionar póster';
	@override String get selectBackground => 'Seleccionar fondo';
	@override String get selectLogo => 'Seleccionar logo';
	@override String get selectSquareArt => 'Seleccionar imagen cuadrada';
	@override String get fromUrl => 'Desde URL';
	@override String get uploadFile => 'Subir archivo';
	@override String get enterImageUrl => 'Introducir URL de imagen';
	@override String get imageUrl => 'URL de imagen';
	@override String get metadataUpdated => 'Metadatos actualizados';
	@override String get metadataUpdateFailed => 'Error al actualizar los metadatos';
	@override String get artworkUpdated => 'Imágenes actualizadas';
	@override String get artworkUpdateFailed => 'Error al actualizar las imágenes';
	@override String get noArtworkAvailable => 'No hay imágenes disponibles';
	@override String artworkOption({required Object index}) => 'Opción de imagen ${index}';
	@override String selectedArtworkOption({required Object index}) => 'Opción de imagen ${index}, seleccionada';
	@override String get notSet => 'No establecido';
	@override String get libraryDefault => 'Predeterminado de biblioteca';
	@override String get accountDefault => 'Predeterminado de cuenta';
	@override String get seriesDefault => 'Predeterminado de serie';
	@override String get episodeSorting => 'Orden de episodios';
	@override String get oldestFirst => 'Más antiguos primero';
	@override String get newestFirst => 'Más recientes primero';
	@override String get keep => 'Conservar';
	@override String get allEpisodes => 'Todos los episodios';
	@override String latestEpisodes({required Object count}) => '${count} episodios más recientes';
	@override String get latestEpisode => 'Episodio más reciente';
	@override String episodesAddedPastDays({required Object count}) => 'Episodios añadidos en los últimos ${count} días';
	@override String get deleteAfterPlaying => 'Eliminar episodios después de reproducir';
	@override String get never => 'Nunca';
	@override String get afterADay => 'Después de un día';
	@override String get afterAWeek => 'Después de una semana';
	@override String get afterAMonth => 'Después de un mes';
	@override String get onNextRefresh => 'En la próxima actualización';
	@override String get seasons => 'Temporadas';
	@override String get show => 'Mostrar';
	@override String get hide => 'Ocultar';
	@override String get episodeOrdering => 'Orden de episodios';
	@override String get tmdbAiring => 'The Movie Database (Emisión)';
	@override String get tvdbAiring => 'TheTVDB (Emisión)';
	@override String get tvdbAbsolute => 'TheTVDB (Absoluto)';
	@override String get metadataLanguage => 'Idioma de metadatos';
	@override String get useOriginalTitle => 'Usar título original';
	@override String get preferredAudioLanguage => 'Idioma de audio preferido';
	@override String get preferredSubtitleLanguage => 'Idioma de subtítulos preferido';
	@override String get subtitleMode => 'Selección automática de subtítulos';
	@override String get manuallySelected => 'Seleccionado manualmente';
	@override String get shownWithForeignAudio => 'Mostrar con audio extranjero';
	@override String get alwaysEnabled => 'Siempre activado';
	@override String get tags => 'Etiquetas';
	@override String get addTag => 'Añadir etiqueta';
	@override String get genre => 'Género';
	@override String get director => 'Director';
	@override String get writer => 'Guionista';
	@override String get producer => 'Productor';
	@override String get country => 'País';
	@override String get collection => 'Colección';
	@override String get label => 'Etiqueta';
	@override String get quickTag => 'Etiqueta rápida...';
}

// Path: matchScreen
class Translations$matchScreen$es extends Translations$matchScreen$en {
	Translations$matchScreen$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get match => 'Asociar...';
	@override String get fixMatch => 'Corregir asociación...';
	@override String get unmatch => 'Desasociar';
	@override String get unmatchConfirm => '¿Borrar esta asociación? Plex tratará el elemento como no asociado hasta que vuelvas a asociarlo.';
	@override String get unmatchSuccess => 'Elemento desasociado';
	@override String get unmatchFailed => 'No se pudo desasociar el elemento';
	@override String get matchApplied => 'Asociación aplicada';
	@override String get matchFailed => 'No se pudo aplicar la asociación';
	@override String get titleHint => 'Título';
	@override String get yearHint => 'Año';
	@override String get search => 'Buscar';
	@override String get noMatchesFound => 'No se encontraron coincidencias';
}

// Path: serverTasks
class Translations$serverTasks$es extends Translations$serverTasks$en {
	Translations$serverTasks$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tareas del servidor';
	@override String get failedToLoad => 'Error al cargar tareas';
	@override String get noTasks => 'No hay tareas en ejecución';
}

// Path: trakt
class Translations$trakt$es extends Translations$trakt$en {
	Translations$trakt$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'Conectado';
	@override String connectedAs({required Object username}) => 'Conectado como @${username}';
	@override String get disconnectConfirm => '¿Desconectar cuenta de Trakt?';
	@override String get disconnectConfirmBody => 'PlezyNG dejará de enviar eventos a Trakt. Puedes reconectar cuando quieras.';
	@override String get scrobble => 'Scrobbling en tiempo real';
	@override String get scrobbleDescription => 'Enviar eventos de reproducción, pausa y parada a Trakt durante la reproducción.';
	@override String get watchedSync => 'Sincronizar el estado de visualización';
	@override String get watchedSyncDescription => 'Cuando marques contenido como visto en PlezyNG, también se marcará como visto en Trakt.';
}

// Path: seerr
class Translations$seerr$es extends Translations$seerr$en {
	Translations$seerr$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => 'Conectar Seerr';
	@override String get serverUrl => 'URL del servidor';
	@override String get serverUrlHelper => 'La dirección de tu instancia de Seerr';
	@override String get checkServer => 'Continuar';
	@override String get signInWithJellyfin => 'Iniciar sesión con Jellyfin';
	@override String get signInWithEmby => 'Iniciar sesión con Emby';
	@override String get signInWithLocal => 'Usar una cuenta local';
	@override String get email => 'Correo electrónico';
	@override String get noSignInMethods => 'Esta instancia de Seerr no ofrece ningún método de inicio de sesión compatible con PlezyNG.';
	@override String get instance => 'Instancia';
	@override String get disconnectConfirm => '¿Desconectar Seerr?';
	@override String get disconnectConfirmBody => 'PlezyNG olvidará esta instancia de Seerr. Reconecta cuando quieras.';
	@override String get request => 'Solicitar';
	@override String get request4k => 'Solicitar en 4K';
	@override String get seasons => 'Temporadas';
	@override String get allSeasons => 'Todas las temporadas';
	@override String get advancedOptions => 'Avanzado';
	@override String get destinationServer => 'Servidor de destino';
	@override String get qualityProfile => 'Perfil de calidad';
	@override String get rootFolder => 'Carpeta raíz';
	@override String get languageProfile => 'Perfil de idioma';
	@override String get tags => 'Etiquetas';
	@override String get noTags => 'Sin etiquetas';
	@override String defaultOption({required Object name}) => '${name} (predeterminado)';
	@override String get animeNote => 'Esta serie es un anime.';
	@override String get requestSubmitted => 'Solicitud enviada';
	@override String requestFailed({required Object error}) => 'La solicitud falló: ${error}';
	@override String get requestsLoadFailed => 'No se pudieron cargar las opciones de solicitud';
	@override String get nothingToRequest => 'Todo ya está disponible o solicitado.';
	@override String get statusAvailable => 'Disponible';
	@override String get statusPartiallyAvailable => 'Parcialmente disponible';
	@override String get statusRequested => 'Solicitado';
	@override String get statusProcessing => 'Procesando';
	@override String get statusBlocklisted => 'En la lista de bloqueo';
	@override String couldNotReach({required Object url, required Object error}) => 'No se pudo conectar con ${url}: ${error}';
	@override String noInstanceAtUrl({required Object url, required Object status}) => 'No hay ninguna instancia de Seerr en ${url} (HTTP ${status})';
	@override String get behindAuthProxy => 'Un proxy inverso con autenticación (SSO o autenticación HTTP) respondió en lugar de Seerr. PlezyNG no puede iniciar sesión a través de él: permite que la ruta /api/v1 de Seerr omita el proxy para esta aplicación, o usa una dirección que llegue a Seerr directamente.';
	@override String get invalidUrl => 'Introduce una dirección de servidor como https://seerr.example.com';
	@override String get quickConnectUnsupported => 'Esta instancia de Seerr no admite Quick Connect. Necesita Seerr 3.4 o más reciente.';
	@override String get notInitialized => 'Esta instancia de Seerr no ha completado la configuración inicial';
	@override String get noPlexTokenForReauth => 'No hay ningún token de Plex disponible para volver a iniciar sesión';
	@override String get noStoredCredentials => 'No hay credenciales guardadas disponibles para volver a iniciar sesión';
	@override String get signInRejected => 'Se rechazó el inicio de sesión';
	@override String get noSessionCookie => 'Seerr no proporcionó una cookie de sesión';
	@override String get freshCookieRejected => 'Seerr rechazó la nueva cookie de sesión';
	@override String get noUserInformation => 'Seerr no devolvió información del usuario';
	@override String get sessionRejectedAfterReauth => 'La sesión fue rechazada después de volver a iniciar sesión';
	@override String get permissionDenied => 'Seerr denegó esta acción: tu cuenta ya no tiene el permiso necesario';
	@override String get permissionRevoked => 'Ya no tienes permiso para solicitar esto';
}

// Path: services
class Translations$services$es extends Translations$services$en {
	Translations$services$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Servicios';
	@override String get hubSubtitle => 'Sincroniza tu progreso de visualización y solicita nuevos títulos.';
	@override String get integrations => 'Integraciones';
	@override String get notConnected => 'No conectado';
	@override String connectedAs({required Object username}) => 'Conectado como @${username}';
	@override String get scrobble => 'Registrar progreso automáticamente';
	@override String get scrobbleDescription => 'Actualiza tu lista cuando termines un episodio o película.';
	@override String disconnectConfirm({required Object service}) => '¿Desconectar ${service}?';
	@override String disconnectConfirmBody({required Object service}) => 'PlezyNG dejará de actualizar ${service}. Reconecta cuando quieras.';
	@override String connectFailed({required Object service}) => 'No se pudo conectar a ${service}. Inténtalo de nuevo.';
	@override late final Translations$services$names$es names = Translations$services$names$es.internal(_root);
	@override late final Translations$services$simklReconnect$es simklReconnect = Translations$services$simklReconnect$es.internal(_root);
	@override late final Translations$services$deviceCode$es deviceCode = Translations$services$deviceCode$es.internal(_root);
	@override late final Translations$services$oauthProxy$es oauthProxy = Translations$services$oauthProxy$es.internal(_root);
	@override late final Translations$services$pendingAuth$es pendingAuth = Translations$services$pendingAuth$es.internal(_root);
	@override late final Translations$services$libraryFilter$es libraryFilter = Translations$services$libraryFilter$es.internal(_root);
	@override String get seerrDescription => 'Conecte a Seerr o Overseerr para buscar títulos y enviar solicitudes de medios.';
	@override late final Translations$services$trackerDescriptions$es trackerDescriptions = Translations$services$trackerDescriptions$es.internal(_root);
}

// Path: addServer
class Translations$addServer$es extends Translations$addServer$en {
	Translations$addServer$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String addMediaBrowserTitle({required Object product}) => 'Añadir servidor ${product}';
	@override String get serverUrls => 'Direcciones URL del servidor';
	@override String get serverUrlsHelper => 'Se permiten varias URL, separadas por comas.';
	@override String get findServer => 'Buscar servidor';
	@override String searchingLocalMediaBrowserServers({required Object product}) => 'Buscando servidores ${product} locales...';
	@override String localMediaBrowserServers({required Object product}) => 'Servidores ${product} locales';
	@override String get username => 'Usuario';
	@override String get password => 'Contraseña';
	@override String get signIn => 'Iniciar sesión';
	@override String get change => 'Cambiar';
	@override String get required => 'Obligatorio';
	@override String couldNotReachServer({required Object error}) => 'No se pudo conectar con el servidor: ${error}';
	@override String signInFailed({required Object error}) => 'Error al iniciar sesión: ${error}';
	@override String quickConnectFailed({required Object error}) => 'Quick Connect ha fallado: ${error}';
	@override String get addPlexTitle => 'Iniciar sesión con Plex';
	@override String get pinExpired => 'El PIN caducó antes de iniciar sesión. Inténtalo de nuevo.';
	@override String failedToRegisterAccount({required Object error}) => 'No se pudo registrar la cuenta: ${error}';
	@override String enterMediaBrowserUrlError({required Object product}) => 'Introduce la URL de tu servidor ${product}';
	@override String get addConnectionTitle => 'Añadir conexión';
	@override String addConnectionTitleScoped({required Object name}) => 'Añadir a ${name}';
	@override String get signInWithPlexCard => 'Iniciar sesión con Plex';
	@override String get signInWithPlexCardSubtitle => 'Autoriza este dispositivo. Se añaden servidores compartidos.';
	@override String get signInWithPlexCardSubtitleScoped => 'Autoriza una cuenta Plex. Los usuarios de Home se convierten en perfiles.';
	@override String connectToMediaBrowserCard({required Object product}) => 'Conectar a ${product}';
	@override String get connectToMediaBrowserCardSubtitle => 'Introduce la URL de tu servidor, el nombre de usuario y la contraseña.';
	@override String connectToMediaBrowserCardSubtitleScoped({required Object product, required Object name}) => 'Inicia sesión en tu servidor ${product}. Se vincula a ${name}.';
	@override String get borrowFromAnotherProfile => 'Tomar prestado de otro perfil';
	@override String get borrowFromAnotherProfileSubtitle => 'Reutiliza la conexión de otro perfil. Los perfiles protegidos con PIN requieren un PIN.';
	@override String get invalidCredentials => 'Usuario o contraseña no válidos';
	@override String get authResponseNotJson => 'La respuesta de autenticación no era un JSON válido';
	@override String get authResponseIncomplete => 'La respuesta de inicio de sesión del servidor estaba incompleta';
	@override String get quickConnectRejected => 'Quick Connect fue rechazado por el servidor';
	@override String get quickConnectNotJson => 'La respuesta de Quick Connect no era un JSON válido';
	@override String get quickConnectMissingFields => 'La respuesta de Quick Connect no incluye el código o el secreto';
	@override String get quickConnectPollRejected => 'El servidor rechazó el sondeo de Quick Connect';
	@override String get serverTimedOut => 'El servidor no respondió a tiempo';
	@override String get responseNotJson => 'La respuesta del servidor no era un JSON válido';
	@override String responseMissingIdentity({required Object product}) => 'A la respuesta le falta un ID o el nombre del servidor. ¿Es este un servidor ${product}?';
	@override String probeFailed({required Object error}) => 'No se pudo conectar con el servidor: ${error}';
	@override String enterAtLeastOneUrl({required Object product}) => 'Introduce al menos una URL de servidor ${product}';
	@override String noReachableServer({required Object product}) => 'No se encontró ningún servidor ${product} accesible';
	@override String urlsPointToDifferentServers({required Object product}) => 'Estas URL apuntan a servidores ${product} distintos';
	@override String urlDoesNotMatchServer({required Object product}) => 'Esta URL no corresponde al servidor ${product}';
	@override String get redirectUnsupported => 'El servidor redirigió a una URL no compatible';
	@override String redirectDifferentHost({required Object product}) => 'El servidor redirigió a un host diferente. Introduce directamente la URL final de ${product}.';
	@override String get redirectInsecure => 'El servidor redirigió de HTTPS a una URL no segura';
	@override String redirectUnsupportedEnterFinal({required Object product}) => 'El servidor redirigió a una URL no compatible. Introduce directamente la URL final de ${product}.';
	@override String get directPlexServerUrl => 'URL del servidor Plex';
	@override String get directPlexServerUrlHelper => 'Introduce la IP y el puerto local de su servidor de medios Plex.';
	@override String get directPlexServerUrlHint => 'http://192.168.1.100:32400';
	@override String get plexToken => 'Plex Token (opcional)';
	@override String get plexTokenHelper => 'Deja blanco si el acceso sin auth está permitido en este servidor.';
	@override String get plexTokenRequired => 'Por favor, introduzca su token Plex (X-Plex-Token).';
	@override String get connectDirectPlexCard => 'Plex Server de medios (Direct / Local)';
	@override String get connectDirectPlexCardSubtitle => 'Conectar directamente con IP o URL local sin cuenta plex.tv.';
	@override String connectDirectPlexCardSubtitleScoped({required Object name}) => 'Conecta directamente con la IP local o URL. Enlaza a ${name}.';
	@override String get insecureTitle => 'conexión sin cifrado';
	@override String insecureDescription({required Object url}) => '${url} usa HTTP. Otras personas de la red pueden leer o modificar tu contraseña, tus tokens y tus archivos multimedia. Usa HTTPS cuando esté disponible. Continúa solo si confías en esta red y aceptas el riesgo.';
	@override String get allowHttp => 'Permitir HTTP';
	@override String get httpsRequired => 'Uso de HTTPS o permita expresamente una conexión no cifrada.';
}

// Path: cast
class Translations$cast$es extends Translations$cast$en {
	Translations$cast$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get chooseDevice => 'Casta a un dispositivo';
	@override String get searching => 'Buscando los dispositivos de casting...';
	@override String connectedTo({required Object device}) => 'Conectado a ${device}';
	@override String get device => 'Dispositivo de Cast';
	@override String get readyToCast => 'Prepara para lanzar';
	@override String get subtitle => 'Subtítulos';
	@override String get serverNotAvailable => 'El servidor de medios no está disponible.';
	@override String get stopCasting => 'Dejar de casting';
	@override String get castToDevice => 'Casta en el dispositivo';
	@override String get noEpisodeAvailable => 'No hay episodio disponible para ser lanzado.';
	@override String get startFailed => 'No puedo empezar a casting. comprobar el servidor y intentarlo de nuevo.';
}

// Path: automation
class Translations$automation$es extends Translations$automation$en {
	Translations$automation$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get noActivePlayback => 'No hay sesión de vídeo activa para controlar.';
	@override String get profileNotFound => 'El perfil de Plezy no se encontró.';
}

// Path: notifications
class Translations$notifications$es extends Translations$notifications$en {
	Translations$notifications$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get newEpisodeTitle => 'Nuevo episodio';
	@override String newEpisodeBody({required Object show, required Object episode}) => '${show} · ${episode}';
}

// Path: appAccess
class Translations$appAccess$es extends Translations$appAccess$en {
	Translations$appAccess$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tenta cada función gratis durante 7 días';
	@override String get description => 'Comienza un ensayo de siete días con acceso completo a cada función PlezyNG. no hay cargas durante el ensayo y no hay suscripción. Después del ensayo, una compra de vida al precio de su tienda desbloqueará PlezyNG por vida.';
	@override String get trialEndedDescription => 'Desbloquear cada función en PlezyNG para la vida con una compra al precio de su tienda.';
	@override String get startTrial => 'Comienza mi prueba gratuita de 7 días';
	@override String get trialActive => 'Su prueba de 7 días de funcionamiento completo está activa.';
	@override String get trialEnded => 'Su juicio de 7 días ha terminado';
	@override String get trialStartFailed => 'No puedo salvar el ensayo en este dispositivo. por favor, intente de nuevo.';
	@override String get lifetimeTitle => 'PlezyNG desbloqueado para la vida';
	@override String get lifetimeBody => '¡Gracias!Tienes acceso a toda la vida a cada función PlezyNG.';
	@override String get manageTitle => 'PlezyNG Acceso a la vida';
	@override String get manageDescription => 'Proba cada función gratis durante 7 días, luego desbloquea todo por la vida con un solo pago al precio de su tienda.';
	@override String buy({required Object price}) => 'Desbloquear todas las características para ${price}';
	@override String get loadingPrice => 'Precio de la tienda de carga...';
	@override String get retryPrice => 'Retiro de precios Lookup';
	@override String get restore => 'Restaurar la compra de vida';
	@override String get pending => 'Su compra está esperando el pago o la aprobación.El acceso a la vida se desbloqueará tan pronto como la tienda lo completa.';
	@override String get storeUnavailable => 'Verifique que está firmado en el tienda y las compras son permitidas en este dispositivo.';
	@override String get productNotFound => 'El desbloqueo de vida PlezyNG aún no está disponible en esta tienda.';
	@override String get productQueryFailed => 'No podría cargar el precio del almacén. comprobar su conexión y intentarlo de nuevo.';
	@override String get purchaseFailed => 'La compra no ha pasado, vuelve a probar.';
	@override String get restoreFailed => 'No podía llegar a la tienda para restaurar su compra.';
	@override String get nothingToRestore => 'No PlezyNG compra de vida se encontró para esta cuenta de la tienda.';
}

// Path: detail
class Translations$detail$es extends Translations$detail$en {
	Translations$detail$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String endsAt({required Object time}) => 'Termina a las ${time}';
}

// Path: watchLink
class Translations$watchLink$es extends Translations$watchLink$en {
	Translations$watchLink$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get serverUnavailable => 'No podía llegar a un servidor Plex para este enlace.';
	@override String get notFound => 'No podría encontrar este espectáculo o película en sus servidores Plex.';
	@override String get ambiguous => 'Este enlace se ajusta a los elementos en más de un servidor.Añadir un servidor al enlace.';
	@override String get plexOnly => 'Los enlaces de seguimiento actualmente solo soportan los servidores Plex.';
	@override String get unsupportedItem => 'Las ligazones de visualización sólo pueden abrir un espectáculo o una película.';
	@override String get menuItem => 'Ver el enlace';
	@override String get dialogTitle => 'Ver el link';
	@override String get dialogShowHint => 'Abriendo este enlace se juega el siguiente episodio.Añadir &mode=shuffle al final para jugar el espectáculo en shuffle.';
	@override String get dialogMovieHint => 'Abriendo este enlace juega la película.';
	@override String get copy => 'Copia';
	@override String get copied => 'Link copiado';
}

// Path: homeLayout
class Translations$homeLayout$es extends Translations$homeLayout$en {
	Translations$homeLayout$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Home Layout';
	@override String get resetToast => 'Home Reset a la versión original de la versión Plezy';
	@override String get resetHeroTitle => '¿Recuperar el layout de héroe a la stock Plezy?';
	@override String get resetHeroBody => 'Desvia el ajuste de la hermana de cada ronda y retorna el único banner de rotación en la parte superior de la casa, como antes de que las líneas de la hermano existieran.';
	@override String get removeRowTitle => '¿Descubrir la línea de casa?';
	@override String removeRowBody({required Object title}) => '${title} se eliminará. no puede ser negado.';
	@override String get sync => 'Síntomas';
	@override String get syncAccountTitle => 'Síntese el diseño con tu cuenta Plex';
	@override String get syncAccountOn => 'En: este dispositivo comparte orden de línea, líneas, Hero y Auto-slide con sus otros dispositivos.';
	@override String get syncAccountOff => 'Desactivado: este dispositivo mantiene su propio layout.';
	@override String get syncNow => 'Síntomas ahora';
	@override String get plexHomeManager => 'Plex Director de la casa';
	@override String get managePlexRows => 'Gestión Plex líneas en Plezy';
	@override String get managePlexRowsDescription => 'Abierto a organizar las líneas seleccionadas por el hogar';
	@override String get organizeHomeRows => 'Organizar las rutas domésticas';
	@override String organizeHomeRowsDescription({required Object n}) => '${n} líneas: movimiento, Hero, Auto-slide, eliminación';
	@override String organizeLibraryRows({required Object library}) => 'Organizar ${library} líneas';
	@override String organizeLibraryRowsDescription({required Object n}) => 'Continuar Vea + ${n} líneas: movimiento, Biblioteca, Casa, Héroe, Auto-slide';
	@override String get renderAsHero => 'Render como una tarjeta de héroe';
	@override String get heroOnlySingleCollection => 'Sólo disponible cuando esta línea se resuelva a los títulos reales de una sola colección';
	@override String get hero => 'Hermano';
	@override String get autoSlide => 'Auto-Slide';
	@override String get autoSlideDescription => 'Las entradas (PC) y d-pad (TV) siempre funcionan y reinicien el timer.';
	@override String get autoSlideEditDescription => 'También se desliza por sí misma cada pocos segundos. desactivado: sólo se mueve cuando usted haga clic en una pistola (PC) o presiona la izquierda/derecha en la remota (TV).';
	@override String get enableHeroFirst => 'En primer lugar, el héroe';
	@override String get showOnHome => 'Mostrando en la pantalla de casa';
	@override String get home => 'Inicio';
	@override String get removeFromHome => 'Removir de casa';
	@override String get selectRowsFirst => 'Seleccione las líneas de inicio debajo primero.';
	@override String plexManagedRows({required Object n}) => '${n} Plex líneas gestionadas';
	@override String get continueWatching => 'Seguir viendo';
	@override String get continueWatchingLibraryDescription => 'La red de resumen de la propia biblioteca';
	@override String get continueWatchingHomeDescription => 'La línea de progreso de resumen mostrada en Home';
	@override String get nextUpHomeDescription => 'La siguiente secuencia de episodios no observados se muestra separadamente en Home';
	@override String get library => 'Biblioteca';
	@override String get showInRecommended => 'Presentación en Biblioteca Recomendada';
	@override String get customPlexRow => 'Conexión Plex';
	@override String get heroNeedsLibrary => 'Véase la biblioteca primero — El héroe necesita algo para mostrar';
	@override String get heroNeedsSurface => 'Véase la Biblioteca o la Casa primero — El héroe necesita algo para mostrar';
	@override String get removeHub => 'Descargar Hub';
	@override String get noPlexRows => 'No Plex líneas gestionadas devueltas para esta biblioteca.';
	@override String get openDetails => 'Detalles abiertos';
	@override String get heroCards => 'Cartas de héroe';
	@override String get tapHeroCard => 'Tapa una tarjeta de héroe';
	@override String get tvPlayFocus => 'TV remota: botón de juego';
	@override String get tvPlayFocusDescription => 'D-pad abajo se detiene en el botón de juego antes de moverse a la siguiente línea.';
	@override String get tvWrap => 'TV remote: tarjetas de héroe de la cinta';
	@override String get tvWrapDescription => 'Justo en la última tarjeta vuelve a la primera.Después se detiene en la última.La izquierda en la primera tarjeta siempre va a la barra lateral.';
	@override String get castOnHero => 'Los héroes de los banners';
	@override String get castOnHeroDescription => 'Mostra el cast a lo largo del fondo de un banner héroe. Después de lo que guarda sólo el título y el resumen.';
	@override String get customRows => 'Rutas personalizadas';
	@override String get loading => 'La casa de la Layout...';
	@override String get noCustomRows => 'No hay rutas de costumbre';
	@override String get addRowHint => 'Utilice la línea de entrada para crear una.';
	@override String get addHomeRow => 'Añadir la ronda de casa';
	@override String get addHomeRowDescription => 'Seleccione una categoría; la nueva línea se añade automáticamente a Organizador';
	@override String get removeRow => 'Remover la línea';
	@override String get recentlyAdded => 'Añadido recientemente';
	@override String get recentlyReleased => 'recientemente liberado';
	@override String get movieCollections => 'Colecciones de películas';
	@override String get showCollections => 'Mostrar colecciones';
	@override String get rowTitle => 'Título Row';
	@override String get content => 'contenidos';
	@override String get showThisRowIn => 'Mostrar esta línea en:';
	@override String get libraryRecommended => 'Biblioteca Recomendada';
	@override String get heroCard => 'Tarjeta de héroe';
	@override String get heroCardDescription => 'Mostra como una tarjeta de rotación de ancho en lugar de una esquina de carteles.';
	@override String get heroUnavailableDescription => 'Sólo está disponible cuando esta línea se resuelva a los títulos reales de una sola colección — con más de una colección seleccionada no hay ningún título para girar.';
	@override String get librariesSelection => 'Librerías (deja todas las bibliotecas sin verificación para incluir todas las biblioteas)';
	@override String get librariesMergedDescription => 'Cada biblioteca que se ve aquí se une a esta una línea.';
	@override String get movieCollectionsSelection => 'Colecciones de películas (deja todas las no verificadas para cada biblioteca seleccionada)';
	@override String get showCollectionsSelection => 'Mostrar colecciones (deja todas las no verificadas para cada biblioteca seleccionada)';
	@override String get collectionRowsDescription => 'Si una colección se juega, sus títulos muestran directamente en la línea.Si más de una juega, cada colección se muestran como un solo poster, haga clic en él para abrir esa colección.';
	@override String get allCollections => 'Todas las colecciones';
	@override String get noRowsHere => 'No hay líneas aquí todavía.';
	@override String get hideWatchedRows => 'Esconde los objetos observados en líneas';
	@override String get hideWatchedRowsDescription => 'Títulos totalmente observados dejan Casa y biblioteca Rías recomendadas.';
	@override String get untitledCollection => 'Colección sin título';
	@override String get moveRowHint => 'Up/Down: moverse la línea · Seleccione: descifrarlo aquí · Volver: cancelar';
	@override String get organizeRowsHint => 'Seleccione en una línea (o mantenerse Seleccione): moverla · Izquierda/derecha: opciones de línea · Volver: hecho';
	@override String get layoutNavDescription => 'Elegir líneas, bibliotecas y categorías de colección';
	@override String get editHomeRow => 'Edit Home Rue';
	@override String get resetHeroButton => 'Reset el layout de héroe a stock Plezy';
	@override String get reorderingUnlocked => 'Reorganización desbloqueada';
	@override String get reorderingLocked => 'Reorganización localizada';
	@override String get rowsCanBeDragged => 'Las rayas pueden ser atraídas — tapar el cierre para evitar que';
	@override String get tapLockToDrag => 'Toma el cierre para sacar líneas';
	@override String customRowLabel({required Object title}) => 'Cálculo: ${title}';
	@override String libraryHubLabel({required Object library, required Object hub}) => '${library}: ${hub}';
	@override String get hide => 'Ocultar';
	@override String get remove => 'Eliminar';
	@override String get libraryResumeRow => 'La red de la biblioteca de esta red';
	@override String get pressAgainToDelete => 'Presiona de nuevo para eliminar';
	@override String actionState({required Object action, required Object state}) => '${action}: ${state}';
	@override String get on => 'En';
	@override String get resetHeroButtonDescription => 'Desvia el ajuste de la hermana de cada ronda y retorna el único banner de rotación en la parte superior, como antes de que las ramas de hermano existieran.';
	@override String get tapHeroCardDescription => 'Seleccione si tapando o seleccionando una tarjeta Hero comienza la reproducción o abre sus detalles.';
	@override String get heroTapPlayDescription => 'Comienza el elemento seleccionado de inmediato.';
	@override String get heroTapDetailsDescription => 'Abre los detalles del elemento seleccionado antes de elegir una acción.';
}

// Path: platform
class Translations$platform$es extends Translations$platform$en {
	Translations$platform$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get localNetworkPermission => 'PlezyNG se conecta a sus servidores de medios y dispositivos de reproducción en su red local.';
	@override String get locationPermission => 'PlezyNG utiliza el acceso a la ubicación cuando iOS lo requiere para detectar tu red local y conectarse a tus servidores multimedia.';
	@override String get photoLibraryPermission => 'Elige imágenes de tu fototeca para usarlas como carátulas y otras ilustraciones de tus archivos multimedia.';
	@override String get cameraPermission => 'Escanear los códigos QR para unir un Companion Remote.';
}

// Path: universalMedia
class Translations$universalMedia$es extends Translations$universalMedia$en {
	Translations$universalMedia$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Medios abiertos';
	@override String get shortcutHelp => 'Juega un enlace, playlist o archivo para esta sesión.';
	@override String get intro => 'Abra un enlace, lista de reproducción o archivo. Playback utiliza el jugador estándar de PlezyNG y no añade historia a su biblioteca.';
	@override String get openWhat => '¿Qué te gustaría abrir?';
	@override String get stream => 'Dirección de flujo';
	@override String get playlist => 'Playlista';
	@override String get files => 'Archivos de dispositivos';
	@override String get favorites => 'Los favoritos de los flujos salvos';
	@override String get address => 'Dirección de los medios';
	@override String get addressHelp => 'URLs con parámetros de credencia o firma reconocidos se utilizan únicamente para esta sesión y no pueden ser guardados como favoritos.';
	@override String get displayName => 'Nombre de pantalla (opcional)';
	@override String get displayNameHelp => 'Seleccione un nombre corto para el jugador y los controles de medios del sistema.';
	@override String get allowHttp => 'Permite una conexión HTTP sin cifrado';
	@override String get allowHttpHelp => 'HTTP no cifra la conexión. permita sólo en una red confiada. Use HTTPS cuando sea posible.';
	@override String get advancedProtocols => 'Solo MPV: introduzca una dirección RTSP, RTMP/RTMPS, UDP o RTP. Estas direcciones no se pueden guardar como favoritos.';
	@override String get liveStream => 'Tratar como vivo';
	@override String get liveStreamHelp => 'Utilice esto para video en vivo o radio.La aplicación esconde la barra de tiempo, botones de escape y la opción go-to-time.';
	@override String get privateSession => 'Solo esta reproducción utiliza la dirección.Save a un flujo elegible favorito para mantenerlo en este perfil.';
	@override String get saveFavorite => 'Salva los favoritos';
	@override String get playNow => 'Juega ahora';
	@override String get favoriteSaved => 'El flujo favorito se salvó a este perfil';
	@override String skippedEntries({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: 'Descargar ${count} entrada de lista de reproducción no soportada o insegura.',
		many: 'Descargar ${count} entradas de lista de reproducción no apoyadas o inseguras.',
		other: 'Descargar ${count} entradas de lista de reproducción no apoyadas o inseguras.',
	);
	@override String get playlistAddress => 'Dirección Playlist';
	@override String get playlistAddressHelp => 'Abre una lista de reproducción M3U, M3u8, o PLS desde un enderezo web. enlaces de flujo directo no salvan la lista de reprodución.';
	@override String get choosePlaylist => 'Elegir el archivo de playlist';
	@override String get openPlaylist => 'Playlist abierto';
	@override String get playlistFormatsHelp => 'Una lista de reproducción puede contener hasta 1.000 artículos y 2 MB. HLS se manifiesta abierto como corrientes para que el jugador pueda elegir una calidad.';
	@override String get noFavorites => 'No se ha salvado el flujo de favoritos aún. los favoritos permanecen en este perfil.';
	@override String get removeFavorite => 'Eliminar el flujo favorito';
	@override String get filesHelp => 'Seleccione los archivos de audio, vídeo o ISO para una cueva temporal.Los archivos y las URL no se añaden a la historia de la biblioteca.';
	@override String get chooseFiles => 'Elegir archivos';
	@override String fileQueue({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '1 Archivo seleccionado',
		many: '${count} archivos seleccionados',
		other: '${count} archivos seleccionados',
	);
	@override String get wifiTransfer => 'Enviar archivos a través de Wi-Fi';
	@override String get wifiTransferHelp => 'Transferir archivos apoyados de un navegador en la misma red confiada.';
	@override String get wifiTransferIntro => 'Abre esta dirección en un navegador en otro dispositivo. Seleccione los archivos para agregarlos a la biblioteca de archivos y libros de este dispositivo.';
	@override String get wifiTransferPrivacy => 'Este dispositivo recibe archivos a través de su red local.Cualquier persona que conoce esta dirección puede enviar archivos hasta que se detenga la transferencia o la dirección expire después de 15 minutos.Másimo: 100 archivos, 4 GiB por archivo, 10 GiB total.';
	@override String get wifiTransferStarting => 'La preparación de una transferencia privada, a tiempo limitado...';
	@override String get wifiTransferUnavailable => 'No puede comenzar la transferencia. comprobar el acceso a la red local y intentarlo de nuevo.';
	@override String get openThisAddress => 'Abre una de estas direcciones en el dispositivo de envío';
	@override String get copyAddress => 'Copia de la dirección de transferencia';
	@override String get addressCopied => 'Dirección de transferencia copiada';
	@override String transferExpires({required Object time}) => 'Esta dirección expira en ${time}.';
	@override String uploadCount({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${count} archivo recibido',
		many: 'Los archivos ${count} recibidos',
		other: 'Los archivos ${count} recibidos',
	);
	@override String uploadedData({required Object size}) => 'Recogido por ${size}';
	@override String get stopTransfer => 'Detener la transferencia y invalidar la dirección';
	@override String get startTransfer => 'Inicio Transferencia';
	@override String get wifiImportedFiles => 'Transferencia Wi-Fi';
	@override String get wifiBrowserTitle => 'Envío de archivos a PlezyNG';
	@override String get wifiBrowserIntro => 'Seleccione archivos de audio, vídeo, ebook o cómics para enviar. Los archivos se almacenan en la biblioteca de archivos y libros de este dispositivo. Máximo: 100 archivos, 4 GiB por archivo, 10 GiB total.';
	@override String get uploadFilesLabel => 'Archivos para enviar';
	@override String get uploadSelected => 'Descargar archivos seleccionados';
	@override String get uploadSelectFirst => 'Seleccione uno o más archivos primero.';
	@override String get uploading => 'Envío';
	@override String get uploadComplete => 'Archivo añadido a PlezyNG.';
	@override String get uploadFailed => 'El archivo no puede ser añadido. mantenga esta página abierta y trate de nuevo.';
	@override String get liveCue => 'en vivo';
	@override String get liveSession => 'Streaming en vivo';
	@override String get liveCueHelp => 'Para el vídeo o la radio en vivo, la aplicación esconde la barra de tiempo y salta los botones. no salva la dirección o ver historia.';
	@override String get sessionOnly => 'Este playback es solo sesión';
	@override String get sessionOnlyHelp => 'Playback nunca salva el progreso o la historia.Save the stream as a favor to keep it in this profile if it is eligible.';
	@override String get pictureAdjustments => 'Adaptación de imágenes';
	@override String get pictureHelp => 'Estos cambios de imagen solo afectan a esta reproducción. se resuelven cuando la reproducción termina.';
	@override String get resetPicture => 'Recuperar la imagen';
	@override String get brightness => 'brillo';
	@override String get contrast => 'Contrast';
	@override String get gamma => 'El Gamma';
	@override String get hue => 'Hue';
	@override String get saturation => 'Saturado';
	@override String get view360 => 'Vista plana para 360° de vídeo';
	@override String get view360Help => 'Utilice esto para un vídeo 360° equirectangular. MPV necesita el filtro v360 de FFmpeg para esta vista.';
	@override String get view360Unavailable => 'Esta configuración de MPV no podría aplicar el filtro 360°.';
	@override String get view360Yaw => 'Vista horizontal';
	@override String get view360Pitch => 'Vista Vertical';
	@override String get view360FieldOfView => 'El campo de visión';
	@override String get recordStream => 'Recuerdo en directo';
	@override String get stopRecording => 'Detener y guardar la grabación';
	@override String get recordingStarted => 'La grabación está activa. dejar la reproducción se detiene y salva la grabación.';
	@override String get recordingSaved => 'La grabación terminada y salvada.';
	@override String get recordingActive => 'Recuerda este dispositivo. dejar el playback se detiene y lo salva.';
	@override String get recordingFormatHelp => 'Para video, seleccione MKV o MPEG-TS. para audio, selecciona MKA o MKV.';
	@override String get replaceRecordingTitle => '¿Substituir esta grabación?';
	@override String get replaceRecordingHelp => 'PlezyNG recupera el archivo existente durante la grabación.Si no puede guardar la nueva grabación, plezyNG restaura la copia de seguridad.';
	@override String get replaceRecording => 'Reemplazo de archivos';
	@override String get discHelp => 'Abrir un disco en el disco óptico de este ordenador.También puede abrir una imagen ISO desde los archivos del dispositivo.';
	@override String get discs => 'Discos ópticos';
	@override String get dvd => 'DVD';
	@override String get bluray => 'El Blu-ray';
	@override String get audioCd => 'CD de audio';
	@override String get discAvailability => 'La reproducción de discos requiere una configuración MPV compatible, un disco soportado y permiso del sistema operativo. no puede superar la protección comercial del disco.';
	@override String get converterTitle => 'Convertir un archivo de medios locales';
	@override String get converterHelp => 'Utilice FFmpeg para hacer una copia de MP4, M4A o MP3.';
	@override String get converterIntro => 'Convertir un archivo de audio o vídeo local en un formato que funciona en más dispositivos.';
	@override String get converterPrivacy => 'FFmpeg debe ser instalado en este ordenador.Conversion lee solo los archivos locales.No descarga flujos ni elimina DRM.';
	@override String get converterChooseInput => 'Seleccione un archivo de medios locales';
	@override String get converterFormat => 'Formato de salida';
	@override String get converterMp4 => 'MP4 · H.264 y AAC';
	@override String get converterM4a => 'M4A · AAC audio';
	@override String get converterMp3 => 'MP3 y audio';
	@override String get converterSaveAs => 'Salva los medios convertidos como';
	@override String get converterExtensionMismatch => 'Seleccione un nombre de fil con la extensión de salida seleccionada.';
	@override String get converterUnsupportedInput => 'Seleccione un archivo de audio o vídeo.';
	@override String get converterLocalOnly => 'El archivo seleccionado no está disponible como vía de dispositivo local.';
	@override String get converterReplaceTitle => '¿Substituir este archivo?';
	@override String get converterReplaceHelp => 'El PCC recoge el archivo existente hasta que se salve la copia convertida.';
	@override String get converterStarting => 'Comenzando con FFmpeg...';
	@override String get converterProgress => 'Convertir en este ordenador...';
	@override String get converterComplete => 'Conversión completa.El nuevo archivo está listo.';
	@override String get converterFfmpegMissing => 'Instalar FFmpeg con soporte H.264, AAC y MP3, luego intente de nuevo.';
	@override String get converterFailed => 'Verifique que el archivo de fuente se puede leer y el destino tiene suficiente espacio libre.';
	@override String get converterCancelled => 'La conversión fue cancelada. la salida incompleta fue eliminada.';
	@override String get converterDesktopOnly => 'La conversión local está disponible en ordenadores de escritorio con FFmpeg instalado.';
	@override String get converterStart => 'Convertir archivos';
	@override String get mediaToolsTitle => 'herramientas de medios';
	@override String get mediaToolsShortcut => 'Capturar o compartir medios, agregar extensiones de búsqueda, o utilizar la línea de comando.';
	@override String get mediaToolsIntro => 'Seleccione una herramienta enfocada. captura y flujo-out utiliza FFmpeg instalado en este escritorio. Extensiones y comandos CLI utiliza solicitudes HTTPS limitadas y el flujo Open media existente.';
	@override String get mediaToolsAccessibility => 'Las opciones de herramientas y los controles funcionan con toque, indicador, teclado y foco D-pad. Se anuncian cambios en el estado de grabación, compartir y buscar.';
	@override String get mediaTool => 'herramientas de medios';
	@override String get captureIntro => 'Recordar su pantalla o una cámara a un archivo MP4 en este ordenador. FFmpeg debe ser instalado y incluir el codificador H.264.';
	@override String get captureNoDevices => 'No se encontró ninguna pantalla o cámara. verifique el soporte de captura de FFmpeg y las autorizaciones de privacidad del sistema operativo.';
	@override String get captureSource => 'pantalla o cámara';
	@override String get captureAudioSource => 'Introducción de audio (opcional)';
	@override String get captureAudioHelp => 'Añadir audio desde un micrófono o entrada disponible. Las opciones de dispositivo dependen de FFmpeg y las permisiones del sistema.';
	@override String get captureAudioNone => 'No hay audio';
	@override String get captureWaylandHelp => 'Wayland limita esta captura XWayland a X display. Windows fuera de XWayland no puede aparecer.';
	@override String get captureFrameRate => 'Rate de grabación';
	@override String get capturePrivacy => 'La grabación se salva únicamente al archivo que usted elige. la captura de micrófonos es opcional. PlezyNG no carga la grabación.';
	@override String get captureSaveAs => 'Salva la grabación de pantalla como';
	@override String get captureExtensionMismatch => 'Seleccione un nombre de archivo que termina en .mp4.';
	@override String get captureFfmpegMissing => 'FFmpeg o el codificador de vídeo de H.264 no está disponible. instalar un edificio de FFmpeg que se apoya, y luego intentarlo de nuevo.';
	@override String get captureFailed => 'Verificar permiso del dispositivo, almacenamiento disponible, y soporte FFmpeg.';
	@override String get captureSaved => 'La grabación de pantalla se salvó.';
	@override String get captureElapsedLabel => 'tiempo de grabación';
	@override String get captureStart => 'Comienza la grabación';
	@override String get captureStop => 'Parar y salvar';
	@override String get captureMode => 'Capturas';
	@override String get shareMode => 'Compartir';
	@override String get shareIntro => 'Envíe un archivo de medios locales a otro dispositivo en su red privada. PlezyNG crea un flujo temporal de HLS.';
	@override String get sharePrivacy => 'Cualquiera en su red local que reciba el enlace privado puede ver mientras está activo.El enlace expire después de 60 minutos.';
	@override String get shareChooseFile => 'Elegir archivos de medios';
	@override String get shareChooseHelp => 'Seleccione un archivo de audio o vídeo local.El archivo permanece en este ordenador.';
	@override String get shareFfmpegMissing => 'FFmpeg o los codificadores H.264/AAC no están disponibles. Instalar FFmpeg con el soporte de codificación H.264 y AAC.';
	@override String get shareFailed => 'El flujo no pudo comenzar o detenerse inesperadamente. ver FFmpeg y el acceso a la red.';
	@override String get shareActive => 'El flujo está listo en su red privada.';
	@override String get shareEnded => 'Los medios han llegado al final y ya no se comparten.';
	@override String get shareStopped => 'El enlace temporal ya no es válido.';
	@override String get shareUrlCopied => 'La dirección de flujo se copia.';
	@override String get shareOpenUrl => 'Abre esta dirección en un jugador en el otro dispositivo';
	@override String get shareCopyUrl => 'Copia de la dirección de flujo';
	@override String get shareExpiresLabel => 'El enlace expira en';
	@override String get shareStarting => 'Preparando el flujo...';
	@override String get shareStart => 'Comenzar a compartir';
	@override String get shareStop => 'Dejar de compartir';
	@override String get extensionsMode => 'Extensiones y CLI';
	@override String get extensionsIntro => 'Añade una extensión de búsqueda de datos para encontrar medios. Seleccione un resultado para cargarlo en el formulario familiar Open media.';
	@override String get extensionsPrivacy => 'Un manifiesto puede definir uno de los campos de respuesta de búsqueda y de mapa de HTTPS. no puede ejecutar código, añadir títulos de solicitud, leer archivos o lanzar comandos de shell.';
	@override String get extensionImport => 'Añadir extension manifesto';
	@override String get extensionEmpty => 'No hay servicios de búsqueda todavía. Seleccione un archivo manifestado JSON confiable para agregar uno.';
	@override String get extensionChoose => 'Servicio de búsqueda';
	@override String get extensionSearchConsent => 'Cada búsqueda envía sus palabras a este servicio de HTTPS. Los resultados se abren sólo después de que seleccione uno.';
	@override String get extensionSearchLabel => 'Buscar medios';
	@override String get extensionSearch => 'búsqueda';
	@override String get extensionSearching => 'Buscando...';
	@override String get extensionNoResults => 'No se han devuelto resultados de los medios seguros. intenta otra búsqueda.';
	@override String get extensionInstallTitle => '¿Añadir este servicio de búsqueda?';
	@override String get extensionReplaceTitle => '¿Actualiza este servicio de búsqueda?';
	@override String get extensionService => 'Servicio';
	@override String get extensionEndpoint => 'HTTPS punto final';
	@override String get extensionConsent => 'Su texto de búsqueda se envía a este servicio.El manifesto no contiene código ejecutable.Sólo continúa si confía en este punto final.';
	@override String get extensionInstall => 'Añadir servicio';
	@override String get extensionReplace => 'Servicio de actualización';
	@override String get extensionRemoveTitle => '¿Elimina este servicio de búsqueda?';
	@override String get extensionRemoveHelp => 'Esto elimina el servicio de este perfil. PlezyNG no contacta con su punto final.';
	@override String get extensionRemove => 'Eliminar el servicio';
	@override String get extensionInvalidManifest => 'Este archivo no es un manifiesto de extensión apoyado. ver la guía de Open media para el formato.';
	@override String get extensionSaveFailed => 'La extensión no pudo ser salvada al perfil activo.';
	@override String get extensionSearchFailed => 'El servicio de búsqueda no devolvió una respuesta válida. ver el punto final y intentarlo de nuevo.';
	@override String get cliTitle => 'línea de mando';
	@override String get cliHelp => 'Utilice la guía de plezyctl para validar un manifiesto o buscar la misma extensión. Revise su servicio de HTTPS antes de cada búsqueda. Resultados se abren en el formulario de medios existente; seleccione el botón de reproducción para comenzar.';
	@override String get cliCopyExample => 'Copia del ejemplo de comando';
	@override String get cliCopied => 'Exemplos de comandos copiados.';
	@override String get captureScreen => 'pantalla';
	@override String get captureDefaultAudio => 'Introducción de audio';
	@override String get shareQrLabel => 'Código QR para la dirección de flujo temporal';
	@override String get shareQrHelp => 'Escanear con un jugador compatible conectado a la misma red privada.';
	@override String get shareHttpHint => 'Esta corriente utiliza HTTP no cifrado. en PlezyNG, permita HTTP antes de abrirlo.';
}

// Path: fileSources
class Translations$fileSources$es extends Translations$fileSources$en {
	Translations$fileSources$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Archivos y libros';
	@override String get subtitle => 'Leer, escuchar y ver de sus propios archivos.';
	@override String get add => 'añadir fuente';
	@override String get importFiles => 'Importación de archivos';
	@override String get localFiles => 'En este dispositivo';
	@override String get source => 'Fuente';
	@override String get name => 'Nombre';
	@override String get endpoint => 'URL del servidor';
	@override String get smbEndpointHint => 'Ejemplo: smb://nas/Movies';
	@override String get smbEndpointInvalid => 'Introduce un servidor SMB y una carpeta compartida.';
	@override String get root => 'Prefixo o prefixo';
	@override String get smbFolderHelp => 'Déjalo en blanco para usar toda la carpeta compartida o introduce una carpeta dentro de ella.';
	@override String get username => 'Usuario';
	@override String get smbDomain => 'Dominio (opcional)';
	@override String get password => 'Contraseña';
	@override String get token => 'API Título';
	@override String get accessKey => 'Acceso clave ID';
	@override String get secretKey => 'La clave de acceso secreto';
	@override String get sessionToken => 'Toca de sesión (opcional)';
	@override String get region => 'Región';
	@override String get clientId => 'ID de cliente de OAuth';
	@override String get clientSecret => 'OAuth client secreto (sólo Google de escritorio)';
	@override String get allowHttp => 'Permitir HTTP sin cifrar en una red de confianza';
	@override String get smbEncryption => 'Cifrar la conexión SMB3';
	@override String get smbEncryptionHint => 'Usar el cifrado SMB3 cuando el NAS lo admita.';
	@override String get connect => 'Conectar';
	@override String get cancel => 'Cancelar';
	@override String get save => 'Guardar';
	@override String get close => 'Cerrar';
	@override String get removeSource => 'Desconectar fuentes';
	@override String get disconnectMessage => 'Desconectar esta fuente? Los archivos descargados y su historia de lectura y escucha permanecerán en este dispositivo.';
	@override String get localFolder => 'Seleccion de Folder';
	@override String get empty => 'Aquí no hay nada todavía';
	@override String get emptyHint => 'Añadir una fuente o importar un libro, audio, música o vídeo.';
	@override String get search => 'Buscar esta cartera';
	@override String get searchCached => 'Buscar librería salvada';
	@override String get refresh => 'Actualizar';
	@override String get loadMore => 'Carga más';
	@override String get offline => 'Disponible offline';
	@override String get download => 'Mantener offline';
	@override String get removeDownload => 'Descargar copias offline';
	@override String get continueReading => 'Continuar leyendo';
	@override String get continueListening => 'Continuar escuchando';
	@override String get continueWatching => 'Continuar observando';
	@override String get read => 'Leer';
	@override String get listen => 'Escuchando';
	@override String get play => 'Reproducir';
	@override String get pause => 'Pausar';
	@override String get stop => 'Detener';
	@override String get startOver => 'Comenzar por';
	@override String get finished => 'Terminado';
	@override String get markFinished => 'Marca terminó';
	@override String get markUnfinished => 'Marca Infinida';
	@override String get editions => 'Ediciones y archivos';
	@override String get chapters => 'Capítulos';
	@override String get bookmarks => 'Bookmarks y notas';
	@override String get bookmark => 'Añadir Bookmark';
	@override String get highlight => 'El destacamiento';
	@override String get note => 'Nota';
	@override String get delete => 'Eliminar';
	@override String get export => 'Notas de exportación';
	@override String get exported => 'Notas exportadas';
	@override String get sync => 'Síntomas Progreso';
	@override String get synced => 'Progreso sintezo';
	@override String get conflict => 'Otro dispositivo tiene una posición diferente. escoge dónde continuar.';
	@override String get useLocal => 'Utilice este dispositivo';
	@override String get useRemote => 'Utilice otro dispositivo';
	@override String get history => 'Historia de la posición';
	@override String get groupAudio => 'Escucha como un audio';
	@override String get groupHint => 'Combina los archivos de audio que actualmente se cargan en esta cartera. cargue todas las páginas primero.';
	@override String get order => 'Archivo Orden';
	@override String get moveUp => 'Moverse arriba';
	@override String get moveDown => 'Moverse hacia abajo';
	@override String get speed => 'Velocidad de Playback';
	@override String get sleep => 'Temporizador de apagado';
	@override String get sleepOff => 'Desactivado';
	@override String get endChapter => 'Fin del capítulo';
	@override String minutes({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(count,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minuto',
		many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minutos',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minutos',
	);
	@override String get skipBack => 'Escape de vuelta';
	@override String get skipForward => 'Escape hacia adelante';
	@override String get smartRewind => 'El intento de volver después de una pausa';
	@override String get playbackOptions => 'Opciones de escucha';
	@override String remaining({required Object time}) => '${time} Restos';
	@override String get contents => 'contenidos';
	@override String get readerSettings => 'Lectura de Settings';
	@override String get fontSize => 'Tamaño de texto';
	@override String get lineHeight => 'Línia de espacio';
	@override String get margin => 'Margen';
	@override String get font => 'Tipo de cara';
	@override String get serif => 'Serio';
	@override String get sans => 'Sin serio';
	@override String get mono => 'Monospacio';
	@override String get columns => 'Columnas';
	@override String get scroll => 'Escrever verticalmente';
	@override String get justify => 'Justificar el texto';
	@override String get readerTheme => 'Aparecimiento de página';
	@override String get appTheme => 'Siguiente Aplicación Tema';
	@override String get paper => 'Papel';
	@override String get sepia => 'Sepia';
	@override String get night => 'Noche';
	@override String get readAloud => 'Leer esta página en voz alta';
	@override String get readAlong => 'Leer en';
	@override String get stopReading => 'Deja la narración';
	@override String get searchBook => 'Buscar en libro';
	@override String get noMatches => 'No juegos';
	@override String get previousPage => 'Página anterior';
	@override String get nextPage => 'Siguiente Página';
	@override String page({required Object number}) => 'Página ${number}';
	@override String get externalBlocked => 'Los enlaces de libro externos están desactivados en el lector.';
	@override String get loading => 'Abriendo...';
	@override String get narrator => 'narración';
	@override String get audio => 'Audio';
	@override String get video => 'Video';
	@override String get ebooks => 'Ebooks';
	@override String get all => 'Todos';
	@override String get downloads => 'Archivos offline';
	@override String get confirmDelete => '¿Eliminar la copia sin conexión seleccionada? Tu posición y tus notas se conservarán.';
	@override String get errorAuthentication => 'Recibe la información para conectar esta fuente.';
	@override String get errorPermission => 'Esta fuente no permitió el acceso al archivo solicitado.';
	@override String get errorUnavailable => 'La fuente no está disponible.Tenta de nuevo, o abre una copia offline.';
	@override String get errorUnsupported => 'Este formato o conexión no está supportado en este dispositivo. ver el guía de configuración de fuente.';
	@override String get errorInvalidData => 'Este archivo o respuesta del servidor no puede ser leído de forma segura.';
	@override String get errorCancelled => 'La operación fue cancelada.';
	@override String get errorConflict => 'La posición cambió en otra sesión. reabre el elemento para elegir una posición.';
	@override String get signIn => 'Iniciar sesión';
	@override String get reconnect => 'Reconectar';
	@override String get folderHelp => 'Deja blanco para comenzar en la raíz de la fuente. las URL de S3 incluyen el bucket.';
	@override String get preferences => 'Preferencias';
	@override String get timePosition => 'Posición';
	@override String get audioTrack => 'Audio Track';
	@override String get subtitleTrack => 'Subtítulo Track';
	@override String get none => 'Ninguno';
	@override String get fullscreen => 'pantalla completa';
	@override String get syncLocation => 'Ficheiro de sincronización de progreso (opcional)';
	@override String get syncLocationHint => 'Una cartera dedicada WebDAV para PlezyNG estado. utiliza escritos condicionales; los medios permanecen inalterados.';
	@override String get audiobooks => 'Audioboques';
	@override String get comics => 'Cómics';
	@override String get scan => 'Escanear libros y medios';
	@override String get browserReader => 'El lector abierto';
	@override String get browserReaderHelp => 'El lector está abierto en su navegador.Mantense abierto PlezyNG para salvar su lugar y notas.';
	@override String get on => 'En';
	@override String get advancedSetup => 'Aplicación de registro';
	@override String get microsoftSignIn => 'Inscribe con Microsoft';
	@override String get zoomIn => 'Zoom en';
	@override String get zoomOut => 'Zoom de salida';
	@override String get fitPage => 'Página de FIT';
	@override String get fitWidth => 'La ampliación';
	@override String get actualSize => 'El tamaño actual';
	@override String get goToPage => 'Ir a la página';
	@override String get goToSection => 'Vuelve al capítulo';
	@override String pageRange({required Object count}) => 'Introduce un número de 1 a ${count}';
	@override String get pageLayout => 'Página de layout';
	@override String get automatic => 'Automático';
	@override String get singlePage => 'Página única';
	@override String get twoPages => 'Dos páginas';
	@override String get readingDirection => 'Lectura dirección';
	@override String get leftToRight => 'A la izquierda a la derecha';
	@override String get rightToLeft => 'De derecha a izquierda';
	@override String get letterSpacing => 'La carta espacial';
	@override String get wordSpacing => 'Palabras espaciales';
	@override String get readerControlsHelp => 'Separa dos dedos o usa los controles de zoom para ampliar las páginas. Arrastra para desplazarte por la página. Ctrl/⌘ con + o − ajusta el zoom; Ctrl/⌘ con 0 lo restablece. Page Up y Page Down cambian de página.';
	@override String get imagePage => 'Página de cómic';
	@override String get resetReader => 'Recuperar las preferencias de lectura';
	@override String get zoom => 'Zoom';
	@override String get useFiles => 'Utilice archivos y libros';
	@override String get cancelScan => 'Cancelar el escáner';
	@override String get googleDrive => 'Google Drive';
	@override String get offlineQuota => 'Límite de descarga Offline';
	@override String get offlineQuotaHelp => 'Establece el espacio máximo utilizado por copias offline, archivos importados y descargas que se quedan. La reducción del límite no remove las copias existentes.';
	@override String get offlineStorageUsage => 'almacenamiento offline';
	@override String get reservedStorage => 'reservado';
	@override String get downloadQueue => 'Descarga de Queue';
	@override String get downloadRunning => 'Descargar';
	@override String get downloadQueued => 'Esperando';
	@override String get downloadPaused => 'pausas';
	@override String get downloadFailed => 'Necesidad de retraso';
	@override String get importing => 'Importación';
	@override String get importInterrupted => 'Importación interrumpida · eliminación para limpiar';
	@override String get errorQuotaExceeded => 'El límite de almacenamiento offline se ha alcanzado. Subir el límite o eliminar una copia descargada.';
	@override String get errorStorageLow => 'No hay suficiente almacenamiento gratuito para mantener la reserva protegida.';
	@override String get errorStorageUnavailable => 'PlezyNG no pudo comprobar el almacenamiento del dispositivo gratuito, por lo que se detuvo la escritura.';
	@override String get removeDownloadJob => 'Descargar Eliminar';
	@override String get downloadAlreadyComplete => 'Esta descarga terminó antes de que pudiera ser eliminado. el artículo ahora está disponible offline.';
	@override String get confirmRemoveDownloadJob => 'Eliminar esta descarga y descifrar todos los datos descargados parcialmente? su posición y las notas permanecerán.';
}

// Path: lending
class Translations$lending$es extends Translations$lending$en {
	Translations$lending$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bibliotecas Públicas';
	@override String get add => 'Añadir una biblioteca';
	@override String get other => 'Otra biblioteca';
	@override String get libraryName => 'Nombre de la Biblioteca';
	@override String get libraryUrl => 'Sitio web de la Biblioteca';
	@override String get libraryUrlHint => 'Utilice el catálogo de su biblioteca o la página de suscripciones.';
	@override String get intro => 'Encuentra tu biblioteca y mantenga sus libros cerrados.';
	@override String get handoff => 'Inscribirse, prestar y leer de forma segura con el servicio de su propia biblioteca.';
	@override String get openService => 'Biblioteca abierta';
	@override String get findLibrary => 'Encuentra una biblioteca';
	@override String get search => 'Buscar libros y autores';
	@override String get catalogue => 'Catálogo';
	@override String get loans => 'préstamos';
	@override String get holds => 'Reservas';
	@override String get signIn => 'Inscribe con tu biblioteca';
	@override String get waiting => 'Terminar la suscripción en su navegador, y luego volver aquí.';
	@override String get cancel => 'Cancelar';
	@override String get disconnect => 'Remover la biblioteca';
	@override String get disconnectMessage => '¿Quitar esta biblioteca de este perfil? Tus préstamos y reservas se conservarán en la biblioteca.';
	@override String get getBook => 'Obtenga libro';
	@override String get checkAvailability => 'Verificar la disponibilidad';
	@override String get available => 'Disponible para prestar';
	@override String get unavailable => 'Actualmente inaccesible';
	@override String get borrow => 'Pedir prestado';
	@override String get placeHold => 'Reservar';
	@override String get returnBook => 'Regreso temprano';
	@override String get cancelHold => 'Cancelar reserva';
	@override String get confirmBorrow => '¿Quieres prestar este título de tu biblioteca?';
	@override String get confirmReturn => '¿Devolver este título ahora? Es posible que tengas que volver a pedirlo prestado para continuar.';
	@override String get confirmCancelHold => '¿Cancelar tu reserva de este título?';
	@override String get email => 'Mantenerse en correo electrónico de notificación';
	@override String due({required Object date}) => 'El número de personas ${date}';
	@override String queue({required Object position}) => 'Posición ${position} en línea';
	@override String get empty => 'No hay títulos aquí.';
	@override String get openLibraryNote => 'Explore el catálogo de la Biblioteca Abierta.Las opciones de lectura y préstamo se muestran en la página de cada título.';
	@override String get more => 'Carga más';
	@override String get gateway => 'Biblioteca en servicio';
	@override String get gatewayHint => 'Proporcionado por su biblioteca o el administrador PlezyNG.';
	@override String get advanced => 'La integración de la biblioteca';
	@override String get loadLibraries => 'Elegir tu biblioteca';
	@override String get expired => 'El préstamo ha expirado.';
	@override String get updated => 'Biblioteca actualizada';
	@override String get continueService => 'Continuar en servicio';
	@override String get comingSoon => 'In-app préstamo · Venga pronto';
	@override String get comingSoonDescription => 'Usted puede usar su biblioteca en Libby mientras terminamos conectándola.';
	@override String get suspendHold => 'Suspensión de mantenimiento';
	@override String get resumeHold => 'Resumen de mantenimiento';
	@override String get suspendMessage => '¿Conservar tu lugar en la cola y permitir que el siguiente lector tome prestado este ejemplar? Puedes reanudar la reserva más adelante.';
	@override String get resumeMessage => '¿Reanudar esta reserva para que la biblioteca pueda ofrecerte el siguiente ejemplar disponible?';
	@override String get editEmail => 'Cambiar la notificación de correo electrónico';
}

// Path: audiobook
class Translations$audiobook$es extends Translations$audiobook$en {
	Translations$audiobook$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get syncTitle => 'Leer y escuchar Sync';
	@override String get syncHelp => 'Mantenga las posiciones de lectura, las posiciones de escucha, el estado de finalización, las notas y las notas a través de sus dispositivos. Seleccione una cuenta de almacenamiento anexada y utilice el mismo código de sincronización en cada dispositivo.';
	@override String get addSyncSource => 'Añadir Google Drive, OneDrive, Dropbox, WebDAV o S3 en los archivos y libros primero.';
	@override String get syncDestination => 'Conta de almacenamiento de sincronización';
	@override String get syncFolder => 'Sincronización de la pasta o prefixo';
	@override String get syncFolderHelp => 'Utilice una pasta existente separada dentro de su fuente WebDAV, o un prefixo dedicado S3.';
	@override String get syncCode => 'Código de sincronización privada';
	@override String get syncCodeHelp => 'Crea un código en tu primer dispositivo, luego introduzca ese código en tus otros dispositivos. Mantiene una copia privada: es la clave para tu estado cifrado. Utilice un código diferente para cada persona.';
	@override String get showCode => 'Mostrar o ocultar el código de sincronización';
	@override String get newSyncCode => 'Crear un nuevo código de sincronización';
	@override String get saveSync => 'Salvando y sincronizando';
	@override String get disableSync => 'Desactivar la sincronización en este dispositivo';
	@override String get syncSourceDisconnect => 'Eliminar esta fuente dejará de leer y escuchar la sincronización aquí. los archivos de sincronización encriptados permanecerán en el proveedor.';
	@override String get syncReconnect => 'Reconectar la cuenta de almacenamiento';
	@override String lastSynced({required Object time}) => 'Última sincronización en ${time}';
	@override String get syncPrivacy => 'Sólo se almacenan los progresos y notas cifrados. Los archivos de audio y ebook, los tokens de cuenta y las contraseñas no se cargan. Google Drive y OneDrive utilizan el almacenamiento de aplicaciones; Dropbox utiliza PlezyNG Sync. Permite la sincronización puede solicitar acceso adicional a la escritura. Mientras está activado, este destino posee la sincronización del progreso; el progreso del servidor permanece separado.';
	@override String get syncConflicts => 'Elegir dónde volver';
	@override String get conflictHelp => 'Estas modificaciones se hicieron de forma independiente. escoge la posición o la versión de la marca para mantener. Un timestamp posterior o un porcentaje superior no gana automáticamente.';
	@override String syncDevice({required Object device}) => 'Dispositivo ${device}';
	@override String get syncUnknownDevice => 'Dispositivo desconocido';
	@override String get deletedBookmark => 'Bookmark eliminado';
	@override String get finished => 'Finalizado';
	@override String readingPosition({required Object percent}) => 'Leer · ${percent}%';
	@override String get chapterTimeline => 'Capítulo Progreso';
	@override String get bookTimeline => 'Todo el libro Progreso';
	@override String bookRemaining({required Object time}) => 'El tiempo que queda en este libro: ${time}';
	@override String chapterRemaining({required Object time}) => 'Tiempo restante en este capítulo: ${time}';
	@override String get unknownRemaining => 'Tiempo completo disponible a medida que se juegan partes';
	@override String get undoSeek => 'La última búsqueda';
	@override String get customSpeed => 'Velocidad de reproducción personalizada';
	@override String get speedHelp => 'Seleccione una velocidad de 0.25× a 4×.';
	@override String get apply => 'Aplique';
	@override String get customSleep => 'Calendario de sueño personalizado';
	@override String get sleepMinutes => 'Minutos (1 a 1440)';
	@override String sleepChapters({required Object count}) => 'Parar después de ${count} capítulos';
	@override String get extendSleep => 'Añadir 5 minutos';
	@override String sleepRemaining({required Object time}) => 'Horario de sueño: ${time}';
	@override String get useDefaults => 'Utilice estos controles de escucha para nuevos libros';
	@override String get librarySort => 'Sorteos de libros';
	@override String get sortTitle => 'Título';
	@override String get sortAuthor => 'Autor';
	@override String get sortNarrator => 'narración';
	@override String get sortSeries => 'Orden de serie';
	@override String get sortRecent => 'recientemente abierto';
	@override String get statusFilter => 'El estado de lectura';
	@override String get statusAll => 'Todos los libros';
	@override String get statusNew => 'No comenzó';
	@override String get statusProgress => 'En el progreso';
	@override String get statusFinished => 'Finalizado';
	@override String get goToTime => 'Vuelve al tiempo';
	@override String get timeHelp => 'Horas: minutos: segundos o minutos: segundos';
	@override String get recoveryHelp => 'Exportar una copia cifrada reciente antes de mover o reparar los datos de sincronización. las importaciones se fusionan con el estado actual; nunca sustituyen la historia de la sincronía local.';
	@override String get recoveryExport => 'Exportación de archivos de recuperación cifrados';
	@override String get recoveryImport => 'Importación de archivos de recuperación cifrados';
	@override String get recoveryImportConfirm => 'Combinar este archivo de recuperación cifrado con las posiciones de lectura y notas actuales? se conservará el historial existente. no se incluyen los IDs de la biblioteca compartida y del elemento; establezca los identificadores correspondientes en cada dispositivo antes de importar.';
	@override String get recoveryExported => 'El archivo de recuperación encriptado se salvó.';
	@override String get recoveryImported => 'Los datos de recuperación se mezclan.';
}

// Path: sourceSetup
class Translations$sourceSetup$es extends Translations$sourceSetup$en {
	Translations$sourceSetup$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get savedCertificate => 'Certificado del servidor guardado';
	@override String get nfsEndpointInvalid => 'Introduce una URL NFS, como nfs://nas:2049/export.';
	@override String get dlnaNone => 'No se encontraron servidores DLNA. Introduce manualmente la URL de descripción del dispositivo.';
	@override String get dlnaServers => 'Servidores multimedia DLNA';
	@override String get dlnaUnavailable => 'La detección DLNA no está disponible en esta red. Introduce manualmente la URL de descripción del dispositivo.';
	@override String get dlnaSearching => 'Buscando servidores DLNA en la red local';
	@override String get networkSearching => 'Buscando en la red local…';
	@override String get dlnaDiscover => 'Detectar servidores DLNA';
	@override String get dlnaHelp => 'La detección depende de la multidifusión de la red local. Si no aparece ningún servidor, introduce arriba su URL de descripción del dispositivo.';
	@override String get dlnaRoot => 'ID de objeto DLNA; déjalo en blanco para usar la raíz del dispositivo.';
	@override String get passwordOrKey => 'Introduce una contraseña o añade una clave privada abajo.';
	@override String get sshFingerprint => 'Huella SHA256 de la clave de host SSH';
	@override String get sshFingerprintHelp => 'Verifícala con el administrador del servidor. En el servidor, ejecuta ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub y usa su valor SHA256.';
	@override String get sshFingerprintKeep => 'Déjalo en blanco para mantener la huella fijada actual o introduce una nueva huella del servidor.';
	@override String get sshAuthentication => 'Autenticación SSH con clave pública';
	@override String get sshAuthenticationHelp => 'Opcional; también se admite la autenticación con contraseña.';
	@override String get privateKey => 'Clave privada (formato PEM u OpenSSH)';
	@override String get privateKeyPassphrase => 'Frase de contraseña de la clave privada';
	@override String get nfsMountPort => 'Puerto TCP del servicio de montaje NFS';
	@override String get nfsMountPortHelp => 'Predeterminado: 20048';
	@override String get nfsUserId => 'ID de usuario NFS (AUTH_SYS)';
	@override String get nfsUserIdHelp => 'Predeterminado: 1000. Usa el ID permitido por el recurso NFS compartido del NAS.';
	@override String get nfsGroupId => 'ID de grupo NFS (AUTH_SYS)';
	@override String get nfsGroupIdHelp => 'Predeterminado: 1000. Usa el ID de grupo permitido por el recurso NFS compartido del NAS.';
	@override String get nfsEncryption => 'Exigir NFS cifrado (RPC-with-TLS)';
	@override String get nfsEncryptionHelp => 'Exigir TLS 1.3 para NFS y el servicio de montaje. Si el NAS no lo admite, se rechaza la conexión.';
	@override String get nfsTrustCertificate => 'CA de NFS personalizada o certificado del servidor (PEM, opcional)';
	@override String get nfsTrustHelp => 'Déjalo en blanco para usar certificados de confianza para este dispositivo. Si hace falta, añade un certificado de una CA privada o un certificado de servidor autofirmado; sus nombres deben coincidir con el host de la URL NFS.';
	@override String get nfsTrustInvalid => 'Usa un certificado de CA o de servidor en formato PEM. No incluyas una clave privada.';
	@override String get addTrustCertificate => 'Añadir certificado de confianza personalizado';
	@override String get replaceTrustCertificate => 'Reemplazar el certificado personalizado guardado';
	@override String get nfsTlsHelp => 'RPC-with-TLS usa los puertos habituales de NFS y del servicio de montaje y requiere que el NAS admita RFC 9289. Se exige TLS 1.3. El nombre de host o la IP debe coincidir con el certificado. Los UID/GID de AUTH_SYS siguen aplicándose dentro del canal cifrado.';
	@override String get clientCertificate => 'Certificado de cliente (opcional)';
	@override String get clientCertificateHelp => 'Permite que el NAS autentique este cliente; los ID de AUTH_SYS siguen sujetos a la política del recurso NFS compartido del NAS.';
	@override String get savedIdentity => 'Se usará una identidad de cliente guardada.';
	@override String get replaceIdentity => 'Reemplazar la identidad de cliente guardada';
	@override String get chooseIdentity => 'Elegir identidad de cliente PKCS#12';
	@override String get identityPassphrase => 'Frase de contraseña de la identidad de cliente';
	@override String get identityPassphraseHelp => 'Déjalo en blanco si el archivo no tiene frase de contraseña.';
	@override String get removeIdentity => 'Eliminar cualquier identidad de cliente guardada';
	@override String get identityStorageHelp => 'Las identidades de cliente se guardan en el almacén cifrado de credenciales de la fuente. No cambies esta sección para conservar la identidad guardada.';
	@override String get nfsLimitations => 'NFSv3 de solo lectura sobre TCP. Sin RPC-with-TLS, el tráfico NFS no está cifrado. El NAS debe permitir los ID de AUTH_SYS seleccionados y los puertos de cliente sin privilegios (a menudo mediante la opción de exportación «insecure»). No se admiten NFSv4 ni UDP.';
	@override String get nfsSetupHelp => 'Ayuda para configurar NFS';
	@override String get nfsSetupHint => 'Revisa estos ajustes si no se establece la conexión.';
	@override String get nfsSetupDetails => 'Usa un recurso compartido NFSv3 sobre TCP. Si se exige cifrado, tanto el servicio NFS como el de montaje deben admitir RPC-with-TLS. Deja el certificado personalizado en blanco para usar un certificado de servidor de confianza para este dispositivo, o añade el certificado de CA o autofirmado del NAS. El nombre del certificado debe coincidir con el host del punto de conexión. Si el NAS exige TLS mutuo, añade su identidad de cliente PKCS#12. Por último, confirma que el recurso compartido permite los UID/GID de AUTH_SYS configurados y la política de puertos del cliente.';
	@override String get ftpHelp => 'FTP usa el modo pasivo. Usa ftp:// para FTP sin cifrar, ftpes:// para TLS explícito o ftps:// para TLS (implícito en el puerto 990; explícito en los demás puertos).';
	@override String get openSubtitles => 'OpenSubtitles';
	@override String get subtitleSetup => 'Búsqueda opcional de subtítulos para vídeos independientes.';
	@override String get apiKey => 'Clave API';
	@override String get optionalUsername => 'Nombre de usuario de la cuenta (opcional)';
	@override String get optionalPassword => 'Contraseña de la cuenta (opcional)';
	@override String get subtitlePrivacy => 'Obtén una clave API en opensubtitles.com. La búsqueda envía el título del vídeo y los ID de IMDb/TMDB disponibles, nunca el archivo de vídeo. La clave y las credenciales opcionales de la cuenta se cifran con esta fuente.';
	@override String get automaticMetadata => 'Metadatos de vídeo automáticos en línea';
	@override String get metadataPrivacy => 'Solo envía el título/año del nombre del archivo y los números de episodio, o un ID NFO; nunca envía contenido multimedia ni credenciales. Los campos NFO conservan la prioridad.';
	@override String get nfsEncryptionFailure => 'Para NFS cifrado, comprueba que ambos servicios del NAS admiten RFC 9289 y TLS 1.3, el nombre del certificado y los UID/GID del recurso compartido. PlezyNG no reintentará esta conexión sin cifrado.';
	@override String get sourceConnecting => 'Conectando con la fuente';
	@override String get metadataSearchPrivacy => 'Esta búsqueda de títulos se envía a Trakt. Se envía el título que introduces, no el vídeo ni las credenciales de la fuente.';
	@override String get chooseMatch => 'Elegir una coincidencia';
	@override String get metadataMatchHelp => 'Revisa el título y el año antes de elegir. Trakt recibe el título buscado; el vídeo permanece en su fuente.';
	@override String get metadataNoMatches => 'No se encontraron títulos coincidentes en línea. Prueba con otro título.';
	@override String get metadataSearch => 'Buscar metadatos en línea';
	@override String get metadataLoading => 'Buscando información de películas y series en línea…';
	@override String get metadataFromTrakt => 'Metadatos en línea de Trakt';
	@override String get metadataNoAutomaticMatch => 'No se encontró una coincidencia automática para el título. Busca el título para elegir una coincidencia.';
	@override String get metadataFailed => 'No se pudieron cargar los metadatos en línea. La reproducción y la información local siguen disponibles.';
	@override String get videoDetailsLoading => 'Cargando información del vídeo';
	@override String get subtitleKeyRequired => 'Se necesita una clave API de OpenSubtitles';
	@override String get subtitleKeyHelp => 'Edita esta fuente de archivos y añade una clave API de OpenSubtitles en los ajustes opcionales de subtítulos.';
	@override String get subtitleSearchFailed => 'La búsqueda de subtítulos falló. Comprueba la clave API, la conexión y el acceso al servicio.';
	@override String get subtitleApplyFailed => 'No se pudieron descargar o aplicar estos subtítulos. Comprueba la conexión y prueba otro resultado.';
	@override String get subtitleSearch => 'Buscar en OpenSubtitles';
	@override String get subtitleSearchPrivacy => 'La búsqueda usa el título y los ID de IMDb/TMDB disponibles. El archivo de vídeo permanece en su fuente. Antes de elegir, revisa el idioma, los indicadores de subtítulos forzados o para personas con discapacidad auditiva y la valoración.';
	@override String get movieOrShow => 'Película o serie';
	@override String get subtitleTitleHint => 'Introduce un título para precisar los resultados';
	@override String get subtitleLanguage => 'Idioma de los subtítulos';
	@override String get subtitleSearching => 'Buscando en OpenSubtitles';
	@override String get subtitleNoMatches => 'No se encontraron subtítulos coincidentes. Prueba con otro título o idioma.';
	@override String get downloadSubtitle => 'Descargar subtítulos';
	@override String get subtitle => 'Subtítulos';
	@override String get nfsTlsRequired => 'Se requiere RPC-with-TLS';
	@override String get nfsUnencrypted => 'NFS sin cifrar';
	@override String get tlsEncrypted => 'Cifrado con TLS';
	@override String get ftpPlain => 'FTP sin cifrar';
	@override String get sshPinned => 'SSH cifrado · clave de host fijada';
	@override String get smbEncrypted => 'Cifrado SMB3 activado';
	@override String get smbUnencrypted => 'Cifrado SMB3 desactivado';
	@override String get httpUnencrypted => 'HTTP sin cifrado de transporte';
	@override String get checkEndpointSecurity => 'Comprobar la seguridad del punto de conexión';
	@override String fieldRequired({required Object label}) => 'Se requiere ${label}.';
	@override String integerRange({required Object label, required Object min, required Object max}) => 'Introduce ${label} entre ${min} y ${max}.';
	@override String replaceFile({required Object name}) => 'Reemplazar ${name}';
	@override String selectedIdentity({required Object name}) => 'Identidad de cliente seleccionada: ${name}';
	@override String subtitleRating({required Object rating}) => 'Valoración ${rating}';
	@override String subtitleDownloading({required Object title}) => 'Descargando subtítulos: ${title}';
	@override String get sharedEntryPair => 'Compartir este artículo';
	@override String get sharedEntryPairHelp => 'Introduce el mismo ID para este elemento en cada dispositivo. Utilice un identificador compartido estable o generar uno y copiarlo al item que se ajusta. Progreso sólo se paran cuando los tipos de archivo de edición, tamaños y órdenes se ajustan. Blank remove este mapa.';
	@override String get sharedEntryId => 'Identificación del elemento compartido';
	@override String get generateSharedEntryId => 'Generar el ID del elemento compartido';
	@override String get sharedLibraryId => 'ID de biblioteca compartida (opcional)';
	@override String get sharedLibraryHelp => 'Utilice el mismo ID en los dispositivos que abren la misma biblioteca.Este ID público ayuda a llevar el progreso de la lectura y las notas a través de diferentes conexiones de fuente; no es una contraseña.Cuando los proveedores usan diferentes identificadores de artículos, se paren esos elementos de sus pantallas detalladas.';
	@override String get sharedLibraryInvalid => 'Utilice 8 a 100 letras, números, puntos, subescores o hyphens.';
	@override String get generateSharedLibraryId => 'Generar un ID de biblioteca compartido';
	@override String get nfsReadAhead => 'Requisitos de read-ahead de NFS';
	@override String get nfsReadAheadHelp => 'Más lecturas paralelas pueden mejorar el rendimiento en un NAS o red rápido. Utilice 1 si el servidor limita las solicitudes concurrentes.';
	@override String get nfsReadTest => 'Medir el rendimiento de la lectura NFS';
	@override String get nfsReadTestHelp => 'Lea hasta 64 MiB desde el archivo más grande para medir esta conexión NAS. Esto utiliza la ancho de banda de red.';
	@override String get nfsQualificationResult => 'NFS lectura de medición';
	@override String get nfsReadBytes => 'Los datos leyen';
	@override String get nfsReadSpeed => 'Velocidad medida';
	@override String get nfsReadRequests => 'Leer solicitudes';
	@override String get sharedEntryConflict => 'Este ID de elemento compartido ya está asociado con otro elemento en esta biblioteca.';
}

// Path: comics
class Translations$comics$es extends Translations$comics$en {
	Translations$comics$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get fitHeight => 'Ajustar a la altura';
	@override String get readingMode => 'Modo de lectura';
	@override String get paged => 'Páginas';
	@override String get webtoon => 'Desplazamiento continuo';
	@override String get coverAlone => 'Mostrar la portada sola';
	@override String get splitWide => 'Dividir páginas anchas';
	@override String get splitWideHelp => 'Muestra cada mitad por separado, en orden de lectura. Mientras esté activado, se pausa la vista de dos páginas juntas.';
	@override String get thumbnails => 'Miniaturas de páginas';
	@override String get controlsHelp => 'Desliza para pasar de página. Toca dos veces para cambiar el ajuste. En desplazamiento continuo, desliza verticalmente o usa Re Pág y Av Pág.';
	@override String get savedForComic => 'Los ajustes de visualización se guardan para este cómic en este perfil.';
	@override String get readLists => 'Listas de lectura';
	@override String get collections => 'Colecciones';
}

// Path: games
class Translations$games$es extends Translations$games$en {
	Translations$games$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

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

// Path: appIcon.names
class Translations$appIcon$names$es extends Translations$appIcon$names$en {
	Translations$appIcon$names$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get midnight => 'Medianoche';
	@override String get ember => 'Brasa';
	@override String get paper => 'Papel';
	@override String get oled => 'OLED';
	@override String get line => 'Línea';
	@override String get ocean => 'Océano';
	@override String get ultraviolet => 'Ultravioleta';
	@override String get matcha => 'Matcha';
	@override String get sunset => 'Atardecer';
	@override String get gold => 'Oro';
	@override String get titanium => 'Titanio';
	@override String get glass => 'Cristal';
	@override String get crt => 'CRT';
	@override String get vhs => 'VHS';
	@override String get synthwave => 'Synthwave';
	@override String get pixel => 'Píxel';
	@override String get neon => 'Neón';
	@override String get sticker => 'Pegatina';
	@override String get ticket => 'Entrada';
	@override String get pop => 'Pop';
	@override String get strata => 'Estratos';
	@override String get facet => 'Faceta';
	@override String get tilde => 'Tilde';
}

// Path: common.ratingSource
class Translations$common$ratingSource$es extends Translations$common$ratingSource$en {
	Translations$common$ratingSource$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

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
class Translations$common$mediaKind$es extends Translations$common$mediaKind$en {
	Translations$common$mediaKind$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get movie => 'Película';
	@override String get show => 'Serie';
	@override String get season => 'Temporada';
	@override String get episode => 'Episodio';
	@override String get artist => 'Artista';
	@override String get album => 'Álbum';
	@override String get track => 'Pista';
	@override String get collection => 'Colección';
	@override String get playlist => 'Lista de reproducción';
	@override String get clip => 'Clip';
	@override String get photo => 'Foto';
	@override String get folder => 'Carpeta';
}

// Path: settings.startupSectionOptions
class Translations$settings$startupSectionOptions$es extends Translations$settings$startupSectionOptions$en {
	Translations$settings$startupSectionOptions$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get discover => 'Abre recomendaciones y artículos de fuentes de descubrimiento conectadas.';
	@override String get libraries => 'Abre tus bibliotecas de medios conectados.';
	@override String get liveTv => 'Open Live TV cuando un servidor lo proporciona; de lo contrario, la startup cae de vuelta a Home.';
	@override String get search => 'búsqueda de medios abiertos.';
}

// Path: themeEditor.slots
class Translations$themeEditor$slots$es extends Translations$themeEditor$slots$en {
	Translations$themeEditor$slots$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get bg => 'Fondo';
	@override String get surface => 'Superficie';
	@override String get outline => 'Contorno';
	@override String get text => 'Texto';
	@override String get textMuted => 'Texto secundario';
	@override String get accent => 'Acento';
}

// Path: themeEditor.contrast
class Translations$themeEditor$contrast$es extends Translations$themeEditor$contrast$en {
	Translations$themeEditor$contrast$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get textOnBg => 'Texto sobre fondo';
	@override String get textOnSurface => 'Texto sobre superficie';
	@override String get textMutedOnBg => 'Texto secundario sobre fondo';
	@override String get textMutedOnSurface => 'Texto secundario sobre superficie';
	@override String get accentOnBg => 'Acento sobre fondo';
	@override String get accentOnSurface => 'Acento sobre superficie';
	@override String get labelOnAccent => 'Texto de botón sobre acento';
}

// Path: hotkeys.actions
class Translations$hotkeys$actions$es extends Translations$hotkeys$actions$en {
	Translations$hotkeys$actions$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'Reproducir/pausar';
	@override String get volumeUp => 'Subir volumen';
	@override String get volumeDown => 'Bajar volumen';
	@override String seekForward({required Object seconds}) => 'Avanzar (${seconds}s)';
	@override String seekBackward({required Object seconds}) => 'Retroceder (${seconds}s)';
	@override String get fullscreenToggle => 'Alternar pantalla completa';
	@override String get muteToggle => 'Activar/desactivar silencio';
	@override String get subtitleToggle => 'Activar/desactivar subtítulos';
	@override String get audioTrackNext => 'Pista de audio siguiente';
	@override String get subtitleTrackNext => 'Pista de subtítulos siguiente';
	@override String get chapterNext => 'Capítulo siguiente';
	@override String get chapterPrevious => 'Capítulo anterior';
	@override String get episodeNext => 'Episodio siguiente';
	@override String get episodePrevious => 'Episodio anterior';
	@override String get speedIncrease => 'Aumentar velocidad';
	@override String get speedDecrease => 'Disminuir velocidad';
	@override String get speedReset => 'Restablecer velocidad';
	@override String get zoomIn => 'Acercar';
	@override String get zoomOut => 'Alejar';
	@override String get zoomReset => 'Restablecer zoom';
	@override String get subSeekNext => 'Ir al subtítulo siguiente';
	@override String get subSeekPrev => 'Ir al subtítulo anterior';
	@override String get subtitleDelayIncrease => 'Retrasar subtítulos';
	@override String get subtitleDelayDecrease => 'Adelantar subtítulos';
	@override String get shaderToggle => 'Activar/desactivar shaders';
	@override String get skipMarker => 'Saltar introducción/créditos';
	@override String get screenshot => 'Tomar captura de pantalla';
	@override String get framePrevious => 'Anterior Frame';
	@override String get frameNext => 'Siguiente Frame';
}

// Path: videoControls.pipErrors
class Translations$videoControls$pipErrors$es extends Translations$videoControls$pipErrors$en {
	Translations$videoControls$pipErrors$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Requiere Android 8.0 o más reciente';
	@override String get iosVersion => 'Requiere iOS 15.0 o más reciente';
	@override String get permissionDisabled => 'El modo de imagen en imagen está desactivado. Actívalo en los ajustes del sistema.';
	@override String get notSupported => 'El dispositivo no admite el modo de imagen en imagen';
	@override String get voSwitchFailed => 'No se pudo cambiar la salida de video para el modo de imagen en imagen';
	@override String get failed => 'No se pudo iniciar el modo de imagen en imagen';
	@override String get prepareFailed => 'No se pudo preparar el modo de imagen en imagen';
	@override String unknown({required Object error}) => 'Ocurrió un error: ${error}';
}

// Path: subtitlingStyling.assOverrideOptions
class Translations$subtitlingStyling$assOverrideOptions$es extends Translations$subtitlingStyling$assOverrideOptions$en {
	Translations$subtitlingStyling$assOverrideOptions$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get no => 'Mantenga las letras, colores, tamaños y ubicaciones escritas en el archivo subtitular.';
	@override String get yes => 'Permite que las configuraciones de estilo del subtitulo del jugador ajusten los subtitulos ASS.';
	@override String get scale => 'Aplicar el estilo del jugador y la escala de los tamaños incorporados para corresponder a las dimensiones de vídeo.';
	@override String get force => 'Reemplaza los estilos de ASS incorporados con el estilo del subtitulo del jugador.';
	@override String get strip => 'Remove el formato de ASS incorporado y haga claramente el texto subtitulario.';
}

// Path: subtitlingStyling.renderResolutionOptions
class Translations$subtitlingStyling$renderResolutionOptions$es extends Translations$subtitlingStyling$renderResolutionOptions$en {
	Translations$subtitlingStyling$renderResolutionOptions$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get screen => 'Render a la resolución de superficie completa para el resultado más agudo.';
	@override String get video => 'Render usando la resolución de vídeo como referencia, lo que puede reducir el trabajo en pantallas de alta resolución.';
	@override String get threeQuarter => 'Render al 75% de la resolución de superficie de la pantalla para una reducción modesta del rendimiento.';
	@override String get half => 'Render al 50% de la resolución de la superficie de la pantalla para reducir el trabajo, con lados más suaves.';
	@override String get third => 'Render a un tercio de la resolución de superficie de la pantalla para reducir el trabajo, con lados más suaves.';
	@override String get quarter => 'Render a un cuarto de la resolución de superficie de la pantalla para reducir el trabajo, con el resultado más suave.';
}

// Path: accountPreferences.groups
class Translations$accountPreferences$groups$es extends Translations$accountPreferences$groups$en {
	Translations$accountPreferences$groups$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get audioAndSubtitles => 'Audio y subtítulos';
	@override String get libraryDisplay => 'Biblioteca';
	@override String get personalMedia => 'Medios personales';
}

// Path: accountPreferences.subtitleModes
class Translations$accountPreferences$subtitleModes$es extends Translations$accountPreferences$subtitleModes$en {
	Translations$accountPreferences$subtitleModes$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get none => 'Seleccionado manualmente';
	@override String get noneDescription => 'No activar los subtítulos por sí solo.';
	@override String get defaultMode => 'Seguir las marcas de la pista';
	@override String get defaultModeDescription => 'Usar las marcas de predeterminada y forzada guardadas en cada pista de subtítulos.';
	@override String get always => 'Siempre activado';
	@override String get alwaysDescription => 'Activar una pista de subtítulos en el idioma preferido siempre que exista.';
	@override String get onlyForced => 'Solo subtítulos forzados';
	@override String get onlyForcedDescription => 'Cargar solo las pistas marcadas como forzadas.';
	@override String get smart => 'Mostrar con audio extranjero';
	@override String get smartDescription => 'Activar los subtítulos solo cuando el audio está en otro idioma.';
}

// Path: accountPreferences.subtitleAccessibilityOptions
class Translations$accountPreferences$subtitleAccessibilityOptions$es extends Translations$accountPreferences$subtitleAccessibilityOptions$en {
	Translations$accountPreferences$subtitleAccessibilityOptions$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get preferNonSdh => 'Preferir subtítulos no SDH';
	@override String get preferSdh => 'Preferir subtítulos SDH';
	@override String get onlySdh => 'Solo subtítulos SDH';
	@override String get onlyNonSdh => 'Solo subtítulos no SDH';
	@override String get preferNonSdhDescription => 'Preferir los subtítulos estándar cuando tanto las versiones estándar como SDH están disponibles.';
	@override String get preferSdhDescription => 'Prefiere los subtítulos SDH cuando están disponibles, pero permite que los subtÍTulos estándar como un fallback.';
	@override String get onlySdhDescription => 'Utilice solo los subtítulos SDH; no caiga de vuelta a los subtítulos estándar.';
	@override String get onlyNonSdhDescription => 'Utilice los subtítulos estándar únicamente; excluye los subtítulos SDH.';
}

// Path: accountPreferences.forcedSubtitleOptions
class Translations$accountPreferences$forcedSubtitleOptions$es extends Translations$accountPreferences$forcedSubtitleOptions$en {
	Translations$accountPreferences$forcedSubtitleOptions$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get preferNonForced => 'Preferir subtítulos no forzados';
	@override String get preferForced => 'Preferir subtítulos forzados';
	@override String get onlyForced => 'Solo subtítulos forzados';
	@override String get onlyNonForced => 'Solo subtítulos no forzados';
	@override String get preferNonForcedDescription => 'Prefiere los subtítulos regulares, pero permite las pistas forzadas como una caída.';
	@override String get preferForcedDescription => 'Preferir las pistas forzadas cuando están disponibles, pero permitir los subtítulos regulares como un fallback.';
	@override String get onlyForcedDescription => 'Utilice sólo las pistas marcadas como forzadas.';
	@override String get onlyNonForcedDescription => 'Exclusión de las pistas marcadas como forzadas.';
}

// Path: accountPreferences.watchedIndicatorOptions
class Translations$accountPreferences$watchedIndicatorOptions$es extends Translations$accountPreferences$watchedIndicatorOptions$en {
	Translations$accountPreferences$watchedIndicatorOptions$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get none => 'Nunca';
	@override String get moviesAndShows => 'Películas y series de TV';
	@override String get movies => 'Solo películas';
	@override String get shows => 'Solo series de TV';
	@override String get noneDescription => 'No muestras los marcadores observados.';
	@override String get moviesAndShowsDescription => 'Mostrar marcadores observados para películas y programas de televisión.';
	@override String get moviesDescription => 'Mostrar marcadores observados sólo para las películas.';
	@override String get showsDescription => 'Mostrar los marcadores observados sólo para programas de televisión.';
}

// Path: accountPreferences.mediaReviewsOptions
class Translations$accountPreferences$mediaReviewsOptions$es extends Translations$accountPreferences$mediaReviewsOptions$en {
	Translations$accountPreferences$mediaReviewsOptions$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get usersAndCritics => 'Usuarios y críticos';
	@override String get usersOnly => 'Solo usuarios';
	@override String get criticsOnly => 'Solo críticos';
	@override String get nobody => 'Ocultos';
	@override String get usersAndCriticsDescription => 'Mostrar tanto las calificaciones de los usuarios como las clasificaciones críticas.';
	@override String get usersOnlyDescription => 'Mostrar calificaciones y reseñas presentadas por los usuarios.';
	@override String get criticsOnlyDescription => 'Mostrar calificaciones críticas y reseñas.';
	@override String get nobodyDescription => 'Esconde las calificaciones y las reseñas.';
}

// Path: discover.findNext
class Translations$discover$findNext$es extends Translations$discover$findNext$en {
	Translations$discover$findNext$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Encuentra tu próximo favorito';
	@override String get open => 'Encuentra tu próximo favorito';
	@override String get anyTime => 'Sin límite de tiempo';
	@override String get timeAvailable => '¿Cuánto tiempo tienes?';
	@override String get filters => 'Elige para este momento';
	@override String get watch => 'Ver';
	@override String get listen => 'Escuchar';
	@override String get read => 'Leer';
	@override String finishable({required Object duration}) => 'Se puede terminar en ${duration}';
	@override String aboutDuration({required Object duration}) => 'Unos ${duration}';
	@override String nextUnit({required Object duration}) => 'Siguiente capítulo · ${duration}';
	@override String totalDuration({required Object duration}) => '${duration} en total';
	@override String get timingVaries => 'La duración puede variar';
	@override String get notNow => 'Ahora no';
	@override String get swipeHint => 'Desliza la portada hacia una flecha o usa los botones de abajo.';
	@override String get saved => 'Sugerencias guardadas';
	@override String savedCount({required Object count}) => 'Sugerencias guardadas · ${count}';
	@override String get undo => 'Deshacer';
	@override String get details => 'Detalles';
	@override String get noPicks => 'Aún no hay nada para elegir';
	@override String get noPicksHint => 'Conecta una biblioteca o añade una fuente multimedia para empezar.';
	@override String get noMatches => 'Nada encaja en este momento';
	@override String get noMatchesHint => 'Prueba otro tipo de contenido o reserva un poco más de tiempo.';
	@override String get allDone => 'Ya has visto todas las sugerencias';
	@override String get allDoneHint => 'Inicia una nueva selección para volver a ver estas opciones.';
	@override String get refresh => 'Buscar otra selección';
	@override String sourceReason({required Object source}) => 'De ${source}';
	@override String libraryReason({required Object library}) => 'De ${library}';
	@override String get ownedReason => 'De tu biblioteca';
	@override String get liveNow => 'En emisión';
	@override String get watchLive => 'Ver en directo';
	@override String get filterAnything => 'Cualquier tipo';
	@override String get filterWatch => 'Ver';
	@override String get filterListen => 'Escuchar';
	@override String get filterRead => 'Leer';
	@override String get twentyMinutes => '20 min';
	@override String get fortyFiveMinutes => '45 min';
	@override String get ninetyMinutes => '90 min';
	@override String get apply => 'Aplicar';
	@override String get openFailed => 'Esta opción ya no está disponible. Actualiza para comprobarlo de nuevo.';
	@override String get changeFailed => 'No se pudo guardar el cambio. Inténtalo de nuevo.';
	@override String get savedLimit => 'La lista de sugerencias guardadas está llena. Quita una para guardar otra.';
	@override String get chooseHint => 'Abre un título, guárdalo para después o pasa al siguiente.';
	@override String get howItWorks => 'Cómo funciona';
	@override String get notNowHelp => 'Omite este título por ahora. Seguirá en tu biblioteca.';
	@override String get saveHelp => 'Guárdalo en las selecciones guardadas de este perfil en este dispositivo. Guardarlo no lo descarga.';
	@override String get openHelp => 'Selecciona la portada para ver los detalles. Usa la acción principal para reproducir, leer o abrir el título.';
	@override String get controlsHelp => 'Teclado o mando: enfoca un botón y pulsa Intro o Seleccionar. Deshacer restaura tu última elección.';
	@override String get artworkLoading => 'Cargando imagen…';
	@override String get artworkUnavailable => 'Imagen no disponible';
	@override String get savedFeedback => 'Añadido a las selecciones guardadas';
	@override String get skippedFeedback => 'Omitido por ahora';
	@override String get releaseToConfirm => 'Suelta para confirmar';
	@override String get remoteHint => 'Portada enfocada: ← / → elegir · Seleccionar: detalles · ↑ / ↓ mover el foco';
}

// Path: discover.person
class Translations$discover$person$es extends Translations$discover$person$en {
	Translations$discover$person$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get born => 'Nacimiento';
	@override String get died => 'Fallecimiento';
	@override String get birthplace => 'Lugar de nacimiento';
	@override String dateWithAge({required Object date, required Object age}) => '${date} (${age} años)';
	@override String dateWithAgeAtDeath({required Object date, required Object age}) => '${date} (a los ${age} años)';
}

// Path: libraries.tabs
class Translations$libraries$tabs$es extends Translations$libraries$tabs$en {
	Translations$libraries$tabs$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Recomendado';
	@override String get browse => 'Explorar';
	@override String get collections => 'Colecciones';
	@override String get playlists => 'Listas de reproducción';
}

// Path: libraries.groupings
class Translations$libraries$groupings$es extends Translations$libraries$groupings$en {
	Translations$libraries$groupings$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Agrupación';
	@override String get all => 'Todo';
	@override String get movies => 'Películas';
	@override String get shows => 'Series';
	@override String get seasons => 'Temporadas';
	@override String get episodes => 'Episodios';
	@override String get artists => 'Artistas';
	@override String get albums => 'Álbumes';
	@override String get tracks => 'Canciones';
	@override String get folders => 'Carpetas';
}

// Path: libraries.filterCategories
class Translations$libraries$filterCategories$es extends Translations$libraries$filterCategories$en {
	Translations$libraries$filterCategories$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get genre => 'Género';
	@override String get year => 'Año';
	@override String get contentRating => 'Clasificación por edad';
	@override String get tag => 'Etiqueta';
	@override String get unwatched => 'No vistos';
	@override String get unplayed => 'No reproducidos';
	@override String get favorites => 'Favoritos';
	@override String get filePath => 'Ruta del archivo';
}

// Path: libraries.sortLabels
class Translations$libraries$sortLabels$es extends Translations$libraries$sortLabels$en {
	Translations$libraries$sortLabels$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Título';
	@override String get dateAdded => 'Fecha de adición';
	@override String get releaseDate => 'Fecha de estreno';
	@override String get rating => 'Valoración';
	@override String get communityRating => 'Valoración de la comunidad';
	@override String get criticRating => 'Valoración de la crítica';
	@override String get userRating => 'Valoración del usuario';
	@override String get datePlayed => 'Fecha de reproducción';
	@override String get playCount => 'Reproducciones';
	@override String get productionYear => 'Año de producción';
	@override String get runtime => 'Duración';
	@override String get officialRating => 'Clasificación oficial';
	@override String get premiereDate => 'Fecha de estreno';
	@override String get startDate => 'Fecha de inicio';
	@override String get airTime => 'Hora de emisión';
	@override String get studio => 'Estudio';
	@override String get random => 'Aleatorio';
	@override String get dateShared => 'Fecha en que se compartió';
	@override String get latestEpisodeAirDate => 'Fecha de emisión del episodio más reciente';
	@override String get lastEpisodeDateAdded => 'Fecha en que se añadió el último episodio';
	@override String get dateDownloaded => 'Fecha de descarga';
	@override String get size => 'Tamaño';
	@override String get library => 'Biblioteca';
}

// Path: libraries.advancedFilters
class Translations$libraries$advancedFilters$es extends Translations$libraries$advancedFilters$en {
	Translations$libraries$advancedFilters$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get include => 'Incluir';
	@override String get exclude => 'Excluir';
	@override String get any => 'Cualquiera';
	@override String get yes => 'Sí';
	@override String get no => 'No';
	@override String not({required Object value}) => 'No ${value}';
	@override String valueCount({required Object count}) => '${count} seleccionados';
	@override String valueCountExcluded({required Object count}) => '${count} excluidos';
	@override String get searchValues => 'Buscar valores';
	@override String get noValues => 'Sin valores';
	@override String get matchContains => 'Contiene';
	@override String get matchNotContains => 'No contiene';
	@override String get matchIs => 'Es';
	@override String get matchIsNot => 'No es';
	@override String get matchBeginsWith => 'Empieza por';
	@override String get matchEndsWith => 'Termina en';
	@override String get textHint => 'Escribe para filtrar';
	@override String get from => 'Desde';
	@override String get to => 'Hasta';
	@override String range({required Object from, required Object to}) => 'De ${from} a ${to}';
	@override String atLeast({required Object value}) => '${value} o más';
	@override String atMost({required Object value}) => 'Hasta ${value}';
	@override String dateLastDays({required Object count}) => 'Últimos ${count} días';
	@override String get dateLastYear => 'Último año';
	@override String dateOlderThanDays({required Object count}) => 'Hace más de ${count} días';
	@override String get dateOlderThanYear => 'Hace más de un año';
}

// Path: libraries.selection
class Translations$libraries$selection$es extends Translations$libraries$selection$en {
	Translations$libraries$selection$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get selectItems => 'Seleccion de artículos';
	@override String selectedCount({required Object count}) => '${count} seleccionados';
	@override String get actions => 'Acciones Seleccion';
	@override String get confirmDescendants => 'Esto cambia todos los episodios en los espectáculos y temporadas seleccionados.';
	@override String get confirmUnwatched => 'Esto también borra el progreso de reproducción de los elementos seleccionados.';
	@override String confirmCount({required Object count}) => 'El número de artículos seleccionados: ${count}.';
	@override String completed({required Object count}) => 'Artículos actualizados: ${count}.';
	@override String partialFailure({required Object succeeded, required Object failed}) => 'Actualizado ${succeeded}; fallecido ${failed}. los artículos fallecidos permanecen seleccionados.';
}

// Path: explore.mdblistShelves
class Translations$explore$mdblistShelves$es extends Translations$explore$mdblistShelves$en {
	Translations$explore$mdblistShelves$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get manage => 'Gestión Explora los barrios';
	@override String get manageDescription => 'Seleccione y arregle listas de su cuenta MDBList';
	@override String get description => 'Seleccione listas de películas y televisión públicas de su cuenta MDBList. Crea o copia listas en MDBList, y luego refresca.';
	@override String get selected => 'Cortes seleccionados';
	@override String get available => 'Lista de cuentas disponibles';
	@override String get noLists => 'No hay listas de películas o televisión públicas devueltas. Crea o copia una lista en MDBList, y luego refresca.';
	@override String get displayName => 'Nombre de la muestra Shelf';
	@override String get nameHint => 'Deja blanco para usar el nombre de la lista de fuentes.';
	@override String get add => 'Añadir Shelf';
	@override String get save => 'Salva los chalecos';
	@override String moveUp({required Object title}) => 'Move ${title} arriba';
	@override String moveDown({required Object title}) => 'Move ${title} hacia abajo';
	@override String get unavailable => 'Esta lista no está disponible. retire o eliminar su arca en las configuraciones.';
	@override String get rateLimited => 'MDBList límite de solicitud alcanzado. por favor retire más tarde.';
	@override String get loadFailed => 'No puede cargar las placas. verifique su conexión y retire.';
	@override String get saveFailed => 'No puedo salvar las placas. por favor retire.';
	@override String get accountChanged => 'El perfil o cuenta cambió. reabre estas configuraciones.';
	@override String get settingsUnreadable => 'Las placas ahorradas no se pueden leer. Seleccione las listas de nuevo para reemplazar estas configuraciones.';
}

// Path: explore.rows
class Translations$explore$rows$es extends Translations$explore$rows$en {
	Translations$explore$rows$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'Lista de seguimiento';
	@override String get recommendedMovies => 'Películas recomendadas';
	@override String get recommendedShows => 'Series recomendadas';
	@override String get trendingMovies => 'Películas en tendencia';
	@override String get trendingShows => 'Series en tendencia';
	@override String get popularMovies => 'Películas populares';
	@override String get popularShows => 'Series populares';
	@override String get trendingAnime => 'Anime en tendencia';
	@override String get suggestedAnime => 'Anime sugerido';
	@override String get airingAnime => 'Mejor anime en emisión';
	@override String get popularAnime => 'Anime más popular';
	@override String get trending => 'Tendencias';
	@override String get upcomingMovies => 'Próximas películas';
	@override String get upcomingShows => 'Próximas series';
}

// Path: explore.status
class Translations$explore$status$es extends Translations$explore$status$en {
	Translations$explore$status$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get airing => 'En emisión';
	@override String get ended => 'Finalizada';
	@override String get canceled => 'Cancelada';
	@override String get upcoming => 'Próximamente';
}

// Path: explore.badge
class Translations$explore$badge$es extends Translations$explore$badge$en {
	Translations$explore$badge$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String rankPopular({required Object n}) => '#${n} más popular';
	@override String rankAiring({required Object n}) => '#${n} en emisión';
	@override String rankRated({required Object n}) => '#${n} puntuado';
	@override String rankTrending({required Object n}) => '#${n} en tendencia';
	@override String rankSeasonal({required Object n, required Object season}) => '#${n} en ${season}';
	@override String watchingNow({required Object n}) => '${n} viendo';
	@override String get available => 'Disponible';
	@override String get partiallyAvailable => 'Parcialmente disponible';
	@override String get availableIn4k => 'Disponible en 4K';
	@override String get requested => 'Solicitado';
	@override String get pendingApproval => 'Pendiente de aprobación';
	@override String get processing => 'Procesando';
	@override String get declined => 'Rechazado';
	@override String get requestFailed => 'La solicitud falló';
	@override String get requested4k => 'Solicitado en 4K';
	@override String seasonsAvailable({required Object available, required Object total}) => '${available}/${total} temporadas';
	@override String nextEpisodeIn({required Object episode, required Object duration}) => 'Ep. ${episode} en ${duration}';
	@override String nextAiringIn({required Object duration}) => 'Siguiente en ${duration}';
	@override String episodesShort({required Object n}) => '${n} eps';
	@override String minutesPerEpisode({required Object n}) => '${n} min/ep';
	@override String get adult => '18+';
}

// Path: explore.stats
class Translations$explore$stats$es extends Translations$explore$stats$en {
	Translations$explore$stats$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String listed({required Object n}) => '${n} registrados';
	@override String viewersDay({required Object n}) => '${n} vistos hoy';
	@override String viewersWeek({required Object n}) => '${n} vistos esta semana';
	@override String viewersMonth({required Object n}) => '${n} vistos este mes';
	@override String viewersYear({required Object n}) => '${n} vistos este año';
	@override String viewersAllTime({required Object n}) => '${n} espectadores';
	@override String planning({required Object n}) => '${n} tienen previsto verlo';
	@override String favorited({required Object n}) => '${n} favoritos';
	@override String dropRate({required Object percent}) => '${percent} lo abandonaron';
	@override String comments({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} comentario',
		other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} comentarios',
	);
	@override String votes({required Object n}) => '${n} votos';
	@override String watching({required Object n}) => '${n} lo están viendo';
	@override String completed({required Object n}) => '${n} lo completaron';
	@override String onHold({required Object n}) => '${n} en pausa';
	@override String dropped({required Object n}) => '${n} lo abandonaron';
}

// Path: explore.season
class Translations$explore$season$es extends Translations$explore$season$en {
	Translations$explore$season$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get winter => 'Invierno';
	@override String get spring => 'Primavera';
	@override String get summer => 'Verano';
	@override String get fall => 'Otoño';
	@override String withYear({required Object season, required Object year}) => '${season} ${year}';
}

// Path: explore.format
class Translations$explore$format$es extends Translations$explore$format$en {
	Translations$explore$format$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get tv => 'TV';
	@override String get tvShort => 'Corto de TV';
	@override String get movie => 'Película';
	@override String get special => 'Especial';
	@override String get ova => 'OVA';
	@override String get ona => 'ONA';
	@override String get music => 'Música';
	@override String get other => 'Otro';
}

// Path: explore.sourceMaterial
class Translations$explore$sourceMaterial$es extends Translations$explore$sourceMaterial$en {
	Translations$explore$sourceMaterial$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get original => 'Original';
	@override String get manga => 'Manga';
	@override String get lightNovel => 'Novela ligera';
	@override String get novel => 'Novela';
	@override String get visualNovel => 'Novela visual';
	@override String get game => 'Juego';
	@override String get webComic => 'Cómic web';
	@override String get musicRelease => 'Música';
	@override String get otherMedia => 'Otro';
}

// Path: explore.creditRole
class Translations$explore$creditRole$es extends Translations$explore$creditRole$en {
	Translations$explore$creditRole$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get actor => 'Actor';
	@override String get director => 'Director';
	@override String get writer => 'Guionista';
	@override String get producer => 'Productor';
	@override String get creator => 'Creador';
	@override String get composer => 'Compositor';
}

// Path: explore.relation
class Translations$explore$relation$es extends Translations$explore$relation$en {
	Translations$explore$relation$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get prequel => 'Precuela';
	@override String get sequel => 'Secuela';
	@override String get sideStory => 'Historia paralela';
	@override String get spinOff => 'Spin-off';
	@override String get alternativeVersion => 'Versión alternativa';
	@override String get summary => 'Resumen';
	@override String get parentStory => 'Historia principal';
	@override String get adaptation => 'Adaptación';
	@override String get other => 'Relacionado';
}

// Path: explore.detail
class Translations$explore$detail$es extends Translations$explore$detail$en {
	Translations$explore$detail$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get originalTitle => 'Título original';
	@override String get alsoKnownAs => 'También conocido como';
	@override String get studios => 'Estudios';
	@override String get country => 'País';
	@override String get language => 'Idioma';
	@override String get released => 'Estrenada';
	@override String get physicalRelease => 'En disco';
	@override String get ended => 'Finalizada';
	@override String addedOn({required Object date}) => 'Añadida el ${date}';
	@override String get yourRating => 'Tu valoración';
	@override String get budget => 'Presupuesto';
	@override String get revenue => 'Taquilla';
	@override String get contentAdvisory => 'Orientación por edades';
	@override String get tags => 'Etiquetas';
	@override String get revealSpoilerTags => 'Mostrar etiquetas de spoilers';
	@override String get links => 'Enlaces';
	@override String get watchOn => 'Ver en';
	@override String get watchTrailer => 'Ver tráiler';
	@override String openOn({required Object site}) => 'Abrir en ${site}';
	@override String get crew => 'Equipo';
	@override String get ratings => 'Valoraciones';
	@override String get schedule => 'Programación';
	@override String recommendedByUsers({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: 'Recomendada por ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} usuario',
		other: 'Recomendada por ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} usuarios',
	);
	@override String recommendedBy({required Object who}) => 'Recomendada por ${who}';
	@override String favoritedBy({required Object who}) => 'Marcada como favorita por ${who}';
	@override String unairedEpisodes({required Object n}) => '${n} sin estrenar';
	@override String recommendedByPercent({required Object percent}) => 'Recomendada por el ${percent} de los espectadores';
	@override String get relatedTitles => 'Títulos relacionados';
	@override String get background => 'Antecedentes';
}

// Path: liveTv.recordSettings
class Translations$liveTv$recordSettings$es extends Translations$liveTv$recordSettings$en {
	Translations$liveTv$recordSettings$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get startEarly => 'Empezar antes (segundos)';
	@override String get endLate => 'Terminar después (segundos)';
	@override String get newOnly => 'Solo episodios nuevos';
	@override String get anyChannel => 'Grabar en cualquier canal';
	@override String get anyTime => 'Grabar a cualquier hora';
	@override String get skipInLibrary => 'Omitir episodios que ya están en la biblioteca';
	@override String get keepUpTo => 'Episodios que conservar';
	@override String get keepUpToHint => '0 conserva todos los episodios';
}

// Path: music.discography
class Translations$music$discography$es extends Translations$music$discography$en {
	Translations$music$discography$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get singlesAndEps => 'Sencillos y EP';
	@override String get live => 'En directo';
	@override String get compilations => 'Recopilaciones';
}

// Path: watchTogether.notices
class Translations$watchTogether$notices$es extends Translations$watchTogether$notices$en {
	Translations$watchTogether$notices$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String pressedPlay({required Object name}) => '${name} pulsó reproducir';
	@override String get playbackStarted => 'Reproducción iniciada';
	@override String paused({required Object name}) => '${name} pausó';
	@override String get playbackPaused => 'Reproducción pausada';
	@override String jumpedTo({required Object name, required Object position}) => '${name} saltó a ${position}';
	@override String roomJumpedTo({required Object position}) => 'Salto a ${position}';
	@override String changedSpeed({required Object name, required Object speed}) => '${name} estableció la velocidad en ${speed}';
	@override String speedChanged({required Object speed}) => 'Velocidad establecida en ${speed}';
	@override String startedMedia({required Object name, required Object title}) => '${name} inició ${title}';
	@override String mediaStarted({required Object title}) => 'Reproduciendo ${title}';
	@override String stoppedMedia({required Object name}) => '${name} detuvo el video';
	@override String get mediaStopped => 'El video se detuvo';
	@override String waitingFor({required Object name}) => 'Esperando a ${name}...';
	@override String get waitingForSomeone => 'Esperando a que alguien se ponga al día...';
	@override String get finished => 'Terminado';
	@override String hostChangedTo({required Object name}) => '${name} ahora es el anfitrión';
	@override String get youAreNowHost => 'Ahora eres el anfitrión';
	@override String joined({required Object name}) => '${name} se unió';
	@override String left({required Object name}) => '${name} se fue';
	@override String get controlRefused => 'Solo el anfitrión puede controlar la reproducción';
	@override String get searchFailed => 'No se pudo buscar el video de la sala en algunos servidores';
	@override String get playBlocked => 'Pulsa reproducir para empezar';
	@override String get shareFailed => 'No se pudo compartir este video con la sala';
	@override String get downloadNotShared => 'Las descargas no se comparten con la sala mientras su servidor esté sin conexión';
	@override String get openFailed => 'No se pudo abrir el video de la sala';
}

// Path: watchTogether.ended
class Translations$watchTogether$ended$es extends Translations$watchTogether$ended$en {
	Translations$watchTogether$ended$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get ended => 'El anfitrión finalizó la sala';
	@override String get kicked => 'Te han expulsado de la sala';
	@override String get expired => 'La sala caducó';
	@override String get replaced => 'Te uniste a esta sala en otro dispositivo';
	@override String get lost => 'Se perdió la conexión con la sala';
}

// Path: watchTogether.errors
class Translations$watchTogether$errors$es extends Translations$watchTogether$errors$en {
	Translations$watchTogether$errors$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get invalidCode => 'Eso no es un código de sala. Los códigos tienen 6 letras y dígitos, sin 0, 1, I, L ni O.';
	@override String get roomNotFound => 'Ninguna sala tiene ese código. Puede que haya finalizado.';
	@override String get roomFull => 'Esa sala está llena.';
	@override String get roomLocked => 'El anfitrión bloqueó esa sala.';
	@override String get relayFull => 'Ver juntos está saturado en este momento. Inténtalo de nuevo más tarde.';
	@override String get unreachable => 'No se pudo conectar con el servidor de retransmisión de Ver juntos. Comprueba tu conexión.';
	@override String get rateLimited => 'Demasiados intentos. Espera un momento e inténtalo de nuevo.';
	@override String get clientBlocked => 'Esta versión de PlezyNG no puede usar el servidor de retransmisión. Actualiza la aplicación.';
	@override String get forbidden => 'Solo el anfitrión puede hacer eso.';
	@override String get notInRoom => 'No estás en ninguna sala.';
	@override String get alreadyInRoom => 'Ya estás en una sala.';
	@override String get resumeFailed => 'No se pudo reconectar a la sala.';
	@override String get unsupported => 'El servidor de retransmisión no admite esta función.';
	@override String get generic => 'Algo salió mal. Inténtalo de nuevo.';
}

// Path: downloads.backgroundWarning
class Translations$downloads$backgroundWarning$es extends Translations$downloads$backgroundWarning$en {
	Translations$downloads$backgroundWarning$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get bannerBlocked => 'Las descargas se detendrán al salir de la app';
	@override String get bannerDegraded => 'Las descargas en segundo plano pueden estar limitadas';
	@override String get bannerAction => 'Detalles';
	@override String get sheetTitle => 'Las descargas en segundo plano están bloqueadas';
	@override String get sheetTitleDegraded => 'Las descargas en segundo plano pueden estar limitadas';
	@override String get sheetIntro => 'Android impide que PlezyNG descargue de forma fiable en segundo plano.';
	@override String get sheetIntroDegraded => 'Tu dispositivo limita cuándo puede descargar PlezyNG en segundo plano.';
	@override String get reasonBackgroundRestricted => 'El uso en segundo plano de PlezyNG está restringido. Configura el uso de batería o en segundo plano como "Sin restricciones".';
	@override String get reasonStandbyRestricted => 'Android ha puesto a PlezyNG en un estado de espera restringido. Configura el uso de batería como "Sin restricciones".';
	@override String get reasonDownloadChannelBlocked => 'Las notificaciones de descargas están desactivadas, por lo que el progreso y los controles podrían no estar disponibles.';
	@override String get reasonNotificationsDisabled => 'Las notificaciones están desactivadas. En Android 13 o versiones posteriores, son necesarias para las descargas largas en segundo plano.';
	@override String get reasonDataSaver => 'El Ahorro de datos está activado y bloquea las descargas en segundo plano con datos móviles. Las descargas deberían seguir funcionando con Wi-Fi.';
	@override String get reasonOemUnknown => 'Las descargas se detuvieron repetidamente mientras PlezyNG estaba en segundo plano. Revisa la configuración de batería o de uso en segundo plano de PlezyNG.';
	@override String get openSettings => 'Abrir configuración';
	@override String get stillNotWorking => 'Ayuda específica para tu dispositivo';
	@override String get stillNotWorkingDescription => 'Consulta los pasos para tu dispositivo o envía un registro desde Configuración › Ver registros si el problema continúa.';
	@override String get dialogTitle => 'Es posible que las descargas no finalicen';
	@override String get dialogDownloadAnyway => 'Descargar de todos modos';
	@override String get dialogFixFirst => 'Solucionarlo primero';
	@override String get statusTile => 'Descargas en segundo plano';
	@override String get statusOk => 'Permitidas en segundo plano';
	@override String get statusBlocked => 'Bloqueadas por la configuración del sistema';
	@override String get statusDegraded => 'Limitadas por la configuración del sistema';
	@override String get statusUnknown => 'Aún no se ha comprobado';
	@override String get settingsUnavailable => 'No se pudo abrir la configuración del sistema en este dispositivo';
	@override String get linkUnavailable => 'No se pudo abrir dontkillmyapp.com en este dispositivo';
}

// Path: downloads.groupings
class Translations$downloads$groupings$es extends Translations$downloads$groupings$en {
	Translations$downloads$groupings$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get library => 'Biblioteca';
	@override String get collections => 'Colecciones';
}

// Path: companionRemote.session
class Translations$companionRemote$session$es extends Translations$companionRemote$session$en {
	Translations$companionRemote$session$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'Iniciando servidor remoto...';
	@override String get hostAddress => 'Dirección del host';
	@override String get connected => 'Conectado';
	@override String get serverRunning => 'Servidor remoto activo';
	@override String get serverStopped => 'Servidor remoto detenido';
	@override String get serverRunningDescription => 'Los dispositivos móviles de tu red pueden conectarse a esta aplicación';
	@override String get serverStoppedDescription => 'Inicia el servidor para permitir que los dispositivos móviles se conecten';
	@override String get usePhoneToControl => 'Usa tu dispositivo móvil para controlar esta aplicación';
	@override String get startServer => 'Iniciar servidor';
	@override String get stopServer => 'Detener servidor';
	@override String get minimize => 'Minimizar';
	@override String get manualAddressHint => 'Dirección de conexión manual:';
}

// Path: companionRemote.pairing
class Translations$companionRemote$pairing$es extends Translations$companionRemote$pairing$en {
	Translations$companionRemote$pairing$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'Los dispositivos PlezyNG con la misma cuenta Plex aparecen aquí';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Conectando...';
	@override String get searchingForDevices => 'Buscando dispositivos...';
	@override String get noDevicesFound => 'No se encontraron dispositivos en tu red';
	@override String get noDevicesHint => 'Abre PlezyNG en tu equipo y usa la misma red WiFi';
	@override String get availableDevices => 'Dispositivos disponibles';
	@override String get manualConnection => 'Conexión manual';
	@override String get cryptoInitFailed => 'No se pudo iniciar la conexión segura. Inicia sesión en Plex primero.';
	@override String get validationHostRequired => 'Introduce la dirección del host';
	@override String get validationHostFormat => 'El formato debe ser IP:puerto (p. ej., 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'Tiempo de conexión agotado. Usa la misma red en ambos dispositivos.';
	@override String get sessionNotFound => 'Dispositivo no encontrado. Asegúrate de que PlezyNG esté en ejecución en el host.';
	@override String get authFailed => 'Autenticación fallida. Ambos dispositivos necesitan la misma cuenta Plex.';
	@override String failedToConnect({required Object error}) => 'Error al conectar: ${error}';
	@override String get codeTitle => 'Código de par';
	@override String get codeDescription => 'Introduce el código mostrado en Companion Remote en el dispositivo host. Ambas unidades deben usar una versión que apoye la paridad segura.';
	@override String get codeInvalid => 'Introduce todas las 32 letras y números del código de host.';
	@override String get updateRequired => 'Actualizar ambos dispositivos a una versión que apoya la pared segura.';
	@override String get hostDescription => 'Introduce este código una vez en cada remote. mantenga privado: permite el control de este perfil.';
	@override String get resetCode => 'Resetar el código de par';
	@override String get resetDescription => 'Desconectar todos los remotes y crear un nuevo código. cada remoto tendrá que pararse de nuevo.';
}

// Path: companionRemote.remote
class Translations$companionRemote$remote$es extends Translations$companionRemote$remote$en {
	Translations$companionRemote$remote$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => '¿Quieres desconectarte de la sesión remota?';
	@override String get reconnecting => 'Reconectando...';
	@override String attemptOf({required Object current}) => 'Intento ${current} de 5';
	@override String get retryNow => 'Reintentar ahora';
	@override String get tabRemote => 'Remoto';
	@override String get tabPlay => 'Reproducir';
	@override String get tabMore => 'Más';
	@override String get menu => 'Menú';
	@override String get tabNavigation => 'Navegación por pestañas';
	@override String get tabDiscover => 'Descubrir';
	@override String get tabLibraries => 'Bibliotecas';
	@override String get tabSearch => 'Buscar';
	@override String get tabDownloads => 'Descargas';
	@override String get tabSettings => 'Configuración';
	@override String get previous => 'Anterior';
	@override String get playPause => 'Reproducir/Pausar';
	@override String get next => 'Siguiente';
	@override String get seekBack => 'Retroceder';
	@override String get stop => 'Detener';
	@override String get seekForward => 'Avanzar';
	@override String get volume => 'Volumen';
	@override String get volumeDown => 'Bajar';
	@override String get volumeUp => 'Subir';
	@override String get fullscreen => 'Pantalla completa';
	@override String get subtitles => 'Subtítulos';
	@override String get audio => 'Audio';
	@override String get searchHint => 'Buscar en escritorio...';
}

// Path: companionRemote.errors
class Translations$companionRemote$errors$es extends Translations$companionRemote$errors$en {
	Translations$companionRemote$errors$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => 'No se encontró ninguna interfaz de red';
	@override String get authenticationFailed => 'Autenticación fallida';
	@override String serverStartFailed({required Object error}) => 'No se pudo iniciar el servidor remoto: ${error}';
	@override String commandFailed({required Object error}) => 'No se pudo enviar el comando remoto: ${error}';
	@override String get joinTimedOut => 'Se agotó el tiempo al unirse a la sesión';
	@override String get failedToConnectAnyAddress => 'No se pudo conectar a ninguna dirección';
	@override String connectionLostAfterAttempts({required Object attempts}) => 'Conexión perdida tras ${attempts} intentos';
	@override String get connectionLost => 'Conexión perdida';
}

// Path: services.names
class Translations$services$names$es extends Translations$services$names$en {
	Translations$services$names$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
	@override String get mdblist => 'MDBList';
}

// Path: services.simklReconnect
class Translations$services$simklReconnect$es extends Translations$services$simklReconnect$en {
	Translations$services$simklReconnect$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Reconectar Simkl';
	@override String get subtitle => 'Simkl va a retirar el método de inicio de sesión que usa esta conexión. Al reconectar se abre simkl.com para autorizar a PlezyNG — PlezyNG nunca ve tu contraseña. Tu historial de visualización se conserva en Simkl.';
}

// Path: services.deviceCode
class Translations$services$deviceCode$es extends Translations$services$deviceCode$en {
	Translations$services$deviceCode$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Activar PlezyNG en ${service}';
	@override String get instructions => 'Escanea el código QR o visita la dirección que aparece a continuación e introduce este código:';
	@override String openToActivate({required Object service}) => 'Abrir ${service} para activar';
	@override String get copyCode => 'Copiar código de activación';
	@override String get waitingForAuthorization => 'Esperando autorización…';
	@override String get codeCopied => 'Código copiado';
}

// Path: services.oauthProxy
class Translations$services$oauthProxy$es extends Translations$services$oauthProxy$en {
	Translations$services$oauthProxy$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Inicia sesión en ${service}';
	@override String get body => 'Escanea este código QR o abre la URL en cualquier dispositivo.';
	@override String openToSignIn({required Object service}) => 'Abrir ${service} para iniciar sesión';
}

// Path: services.pendingAuth
class Translations$services$pendingAuth$es extends Translations$services$pendingAuth$en {
	Translations$services$pendingAuth$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get copyUrl => 'Copiar URL de inicio de sesión';
	@override String get urlCopied => 'URL copiada';
}

// Path: services.libraryFilter
class Translations$services$libraryFilter$es extends Translations$services$libraryFilter$en {
	Translations$services$libraryFilter$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Filtro de bibliotecas';
	@override String get subtitleAllSyncing => 'Sincronizando todas las bibliotecas';
	@override String get subtitleNoneSyncing => 'No se sincroniza ninguna biblioteca';
	@override String subtitleBlocked({required Object count}) => '${count} bloqueadas';
	@override String subtitleAllowed({required Object count}) => '${count} permitidas';
	@override String get mode => 'Modo de filtro';
	@override String get modeBlacklist => 'Lista de exclusión';
	@override String get modeWhitelist => 'Lista de inclusión';
	@override String get modeHintBlacklist => 'Sincronizar todas las bibliotecas excepto las seleccionadas abajo.';
	@override String get modeHintWhitelist => 'Sincronizar solo las bibliotecas seleccionadas abajo.';
	@override String get libraries => 'Bibliotecas';
	@override String get noLibraries => 'No hay bibliotecas disponibles';
	@override String get modeDescription => 'Seleccione si las bibliotecas verificadas están bloqueadas de sincronizar o son las únicas bibliotecas que sincronizan.';
}

// Path: services.trackerDescriptions
class Translations$services$trackerDescriptions$es extends Translations$services$trackerDescriptions$en {
	Translations$services$trackerDescriptions$es.internal(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get trakt => 'Sínculo de episodios y películas vistas con su cuenta Trakt.';
	@override String get mal => 'Sync listas de anime y ver el progreso con MyAnimeList.';
	@override String get anilist => 'Sync listas de anime y ver el progreso con AniList.';
	@override String get simkl => 'Sync ha visto películas, programas de televisión y anime con Simkl.';
	@override String get mdblist => 'Mostrar las calificaciones y listas de MDBList en recomendaciones y Explore.';
}

/// The flat map containing all translations for locale <es>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEs {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'PlezyNG',
			'appIcon.title' => 'Icono de la aplicación',
			'appIcon.defaultIcon' => 'Predeterminado',
			'appIcon.current' => 'Icono actual',
			'appIcon.locked' => 'Acceso a la vida necesaria',
			'appIcon.lockedHint' => 'Comienza su prueba de 7 días o desbloquea PlezyNG para la vida para utilizar iconos alternativos.',
			'appIcon.changeFailed' => 'No se pudo cambiar el icono de la aplicación',
			'appIcon.launcherHint' => 'El nuevo icono aparecerá en tu pantalla de inicio cuando salgas de PlezyNG.',
			'appIcon.tvLauncherHint' => 'El nuevo banner aparecerá cuando salgas de PlezyNG. Android TV puede seguir mostrando el anterior hasta que se reinicie la TV.',
			'appIcon.names.midnight' => 'Medianoche',
			'appIcon.names.ember' => 'Brasa',
			'appIcon.names.paper' => 'Papel',
			'appIcon.names.oled' => 'OLED',
			'appIcon.names.line' => 'Línea',
			'appIcon.names.ocean' => 'Océano',
			'appIcon.names.ultraviolet' => 'Ultravioleta',
			'appIcon.names.matcha' => 'Matcha',
			'appIcon.names.sunset' => 'Atardecer',
			'appIcon.names.gold' => 'Oro',
			'appIcon.names.titanium' => 'Titanio',
			'appIcon.names.glass' => 'Cristal',
			'appIcon.names.crt' => 'CRT',
			'appIcon.names.vhs' => 'VHS',
			'appIcon.names.synthwave' => 'Synthwave',
			'appIcon.names.pixel' => 'Píxel',
			'appIcon.names.neon' => 'Neón',
			'appIcon.names.sticker' => 'Pegatina',
			'appIcon.names.ticket' => 'Entrada',
			'appIcon.names.pop' => 'Pop',
			'appIcon.names.strata' => 'Estratos',
			'appIcon.names.facet' => 'Faceta',
			'appIcon.names.tilde' => 'Tilde',
			'appIcon.description' => 'Seleccione la icona que muestra el lanzador del dispositivo. Las previstas muestran cómo se ve cada opción.',
			'auth.signInWithPlex' => 'Inicia sesión con Plex',
			'auth.showQRCode' => 'Mostrar código QR',
			'auth.authenticate' => 'Autenticar',
			'auth.authenticationTimeout' => 'Se agotó el tiempo de autenticación. Inténtalo de nuevo.',
			'auth.scanQRToSignIn' => 'Escanea este código QR para iniciar sesión',
			'auth.waitingForAuth' => 'Esperando autenticación...\nInicia sesión desde tu navegador.',
			'auth.useBrowser' => 'Usar navegador',
			'auth.or' => 'o',
			'auth.connectToMediaBrowser' => ({required Object product}) => 'Conectar a ${product}',
			'auth.quickConnect' => 'Quick Connect',
			'auth.useQuickConnect' => 'Usar Quick Connect',
			'auth.quickConnectInstructions' => 'Abre Quick Connect en Jellyfin e introduce este código.',
			'auth.quickConnectWaiting' => 'Esperando aprobación…',
			'auth.quickConnectCancel' => 'Cancelar',
			'auth.quickConnectExpired' => 'Quick Connect caducó. Inténtalo de nuevo.',
			'auth.localDataRecoveryRequired' => 'PlezyNG no pudo recuperar de forma segura los datos locales de inicio de sesión ni la reproducción pendiente. Vuelve a iniciar sesión.',
			'auth.pinCheckRejected' => 'La comprobación del PIN de Plex fue rechazada',
			'auth.connectToDirectPlex' => 'Conectar con el servidor local Plex',
			'common.cancel' => 'Cancelar',
			'common.save' => 'Guardar',
			'common.close' => 'Cerrar',
			'common.closeMiniPlayer' => 'Jugar en mini jugador',
			'common.closeWorkspaceWindow' => 'Cerca de la ventana',
			'common.returnToFullView' => 'Volver a la vista completa',
			'common.manageMediaSessions' => 'Gestión de sesiones de medios',
			'common.hideMediaSessions' => 'Condenar las sesiones de medios',
			'common.mediaSessions' => 'Sesión de medios',
			'common.mediaSessionsHint' => 'Seleccione para llevar una sesión hacia adelante.Park esconde su ventana pero la mantiene abierta.Return lo abre en vista completa; cerca termina.',
			'common.sessionInWorkspace' => 'En el espacio de trabajo',
			'common.sessionParked' => 'Aparcado',
			'common.sessionFullscreen' => 'pantalla completa',
			'common.switchToNextWindow' => 'Cambiar con la ventana siguiente',
			'common.moveWindow' => 'Move la ventana',
			'common.finishMovingWindow' => 'Finalizar la ventana de movimiento',
			'common.moveWindowHint' => 'Long-press y atraer la ventana para moverla. este control también permite el movimiento de la llave de arco.',
			'common.movingWindowHelp' => 'Descargar para moverse · Ajustar las claves de tiro · Enter saves · Escape canceles',
			'common.resizeWindow' => 'Revisa la ventana',
			'common.resizeWindowHint' => 'Retire esta mano o utilice las chaves de la pistola para reanudar la ventana.',
			'common.workspaceWindowHint' => 'Utilice el control de movimiento o long-press y drag para moverse.',
			'common.workspacePaneHint' => 'Seleccione este panel para enfocarlo. Utilice su control de pantalla completa para expandir.',
			'common.workspaceWindowLabel' => ({required Object title}) => 'Vista de sesión: ${title}',
			'common.workspaceTitleHint' => 'Descarga la barra de título para mover; use el botón de pantalla completa para expandir.',
			'common.moveToSessionTray' => 'Moverse a la sesión Tray',
			'common.moveToSessionTrayHint' => 'Esta sesión está disponible sin mostrar su ventana.',
			'common.closeSessionHint' => 'Cerra esta ventana y termina su sesión.',
			'common.sideBySideLayout' => 'Descargar el layout de lado a lado',
			'common.floatingWindows' => 'Switch para flotar ventanas',
			'common.clear' => 'Borrar',
			'common.reset' => 'Restablecer',
			'common.later' => 'Más tarde',
			'common.submit' => 'Enviar',
			'common.confirm' => 'Confirmar',
			'common.retry' => 'Reintentar',
			'common.logout' => 'Cerrar sesión',
			'common.unknown' => 'Desconocido',
			'common.refresh' => 'Actualizar',
			'common.yes' => 'Sí',
			'common.no' => 'No',
			'common.delete' => 'Eliminar',
			'common.edit' => 'Editar',
			'common.shuffle' => 'Reproducción aleatoria',
			'common.addTo' => 'Añadir a...',
			'common.createNew' => 'Crear nuevo',
			'common.connect' => 'Conectar',
			'common.disconnect' => 'Desconectar',
			'common.play' => 'Reproducir',
			'common.pause' => 'Pausar',
			'common.resume' => 'Reanudar',
			'common.error' => 'Error',
			'common.search' => 'Buscar',
			'common.home' => 'Inicio',
			'common.back' => 'Atrás',
			'common.settings' => 'Ajustes',
			'common.mute' => 'Silenciar',
			'common.ok' => 'OK',
			'common.off' => 'Desactivado',
			'common.options' => 'Opciones',
			'common.seasonNumber' => ({required Object number}) => 'Temporada ${number}',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => 'Episodio ${number} - ${title}',
			'common.chapterNumber' => ({required Object number}) => 'Capítulo ${number}',
			'common.reconnect' => 'Reconectar',
			'common.viewAll' => 'Ver todo',
			'common.checkingNetwork' => 'Comprobando red...',
			'common.loadingServers' => 'Cargando servidores...',
			'common.connectingToServers' => 'Conectando a servidores...',
			'common.startingOfflineMode' => 'Iniciando modo sin conexión...',
			'common.loading' => 'Cargando...',
			'common.fullscreen' => 'Pantalla completa',
			'common.exitFullscreen' => 'Salir de pantalla completa',
			'common.pressBackAgainToExit' => 'Pulsa Atrás de nuevo para salir',
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
			'common.mediaKind.movie' => 'Película',
			'common.mediaKind.show' => 'Serie',
			'common.mediaKind.season' => 'Temporada',
			'common.mediaKind.episode' => 'Episodio',
			'common.mediaKind.artist' => 'Artista',
			'common.mediaKind.album' => 'Álbum',
			'common.mediaKind.track' => 'Pista',
			'common.mediaKind.collection' => 'Colección',
			'common.mediaKind.playlist' => 'Lista de reproducción',
			'common.mediaKind.clip' => 'Clip',
			'common.mediaKind.photo' => 'Foto',
			'common.mediaKind.folder' => 'Carpeta',
			'screens.licenses' => 'Licencias',
			'screens.switchProfile' => 'Cambiar perfil',
			'screens.subtitleStyling' => 'Estilo de subtítulos',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'Registros',
			'update.available' => 'Actualización disponible',
			'update.versionAvailable' => ({required Object version}) => 'Versión ${version} disponible',
			'update.currentVersion' => ({required Object version}) => 'Actual: ${version}',
			'update.skipVersion' => 'Saltar esta versión',
			'update.viewRelease' => 'Ver versión',
			'update.latestVersion' => 'Ya estás en la última versión',
			'update.checkFailed' => 'Error al buscar actualizaciones',
			'settings.title' => 'Configuración',
			'settings.supportDeveloper' => 'Apoya PlezyNG',
			'settings.supportDeveloperDescription' => 'Dona para apoyar el desarrollo',
			'settings.lifetimeAccess' => 'PlezyNG Acceso a la vida',
			'settings.language' => 'Idioma',
			'settings.theme' => 'Tema',
			'settings.appearance' => 'Apariencia',
			'settings.detailPage' => 'Página Detalga',
			'settings.themeSongsEnabled' => 'Juega canciones temáticas',
			'settings.themeSongsEnabledDescription' => 'Juega canciones de temas disponibles mientras ve los detalles de los medios.',
			'settings.themeSongVolume' => 'Temas de la canción volumen',
			'settings.videoPlayback' => 'Reproducción de video',
			'settings.videoPlaybackDescription' => 'Configurar el comportamiento de reproducción',
			'settings.advanced' => 'Avanzado',
			'settings.episodePosterMode' => 'Estilo del póster de episodio',
			'settings.seriesPoster' => 'Póster de la serie',
			'settings.seasonPoster' => 'Póster de la temporada',
			'settings.episodeThumbnail' => 'Miniatura',
			'settings.showHeroSectionDescription' => 'Mostrar carrusel de contenido destacado en la pantalla de inicio',
			'settings.secondsLabel' => 'Segundos',
			'settings.minutesLabel' => 'Minutos',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'm',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Introduce la duración (${min}-${max})',
			'settings.systemTheme' => 'Sistema',
			'settings.lightTheme' => 'Claro',
			'settings.darkTheme' => 'Oscuro',
			'settings.oledTheme' => 'OLED',
			'settings.emberTheme' => 'Brasa',
			'settings.glacierTheme' => 'Glaciar',
			'settings.forestTheme' => 'Bosque',
			'settings.plumTheme' => 'Ciruela',
			'settings.paperTheme' => 'Papel',
			'settings.libraryDensity' => 'Densidad de la biblioteca',
			'settings.displayScale' => 'Escala de visualización',
			'settings.compact' => 'Compacto',
			'settings.comfortable' => 'Cómodo',
			'settings.gridSpacing' => 'Espaciado de la cuadrícula',
			'settings.gridSpacingTight' => 'Ajustado',
			'settings.gridSpacingNormal' => 'Normal',
			'settings.gridSpacingSpacious' => 'Espacioso',
			'settings.tvCornerSpotlightBackdrop' => 'Imagen destacada en la esquina',
			'settings.tvCornerSpotlightBackdropDescription' => 'Mostrar la imagen destacada en la esquina superior derecha en lugar de ocupar toda la pantalla',
			'settings.viewMode' => 'Modo de vista',
			'settings.gridView' => 'Cuadrícula',
			'settings.listView' => 'Lista',
			'settings.showHeroSection' => 'Mostrar sección destacada',
			'settings.showHomeBackdrop' => 'Mostrar arte de la casa Backdrop',
			'settings.showHomeBackdropDescription' => 'Mostrar grandes obras de arte detrás de las ramas de la casa',
			'settings.contentScreensaverEnabled' => 'Contenido de pantalla',
			'settings.contentScreensaverEnabledDescription' => 'Mostrar arte en pantalla completa después de que la aplicación ha sido idle',
			'settings.contentScreensaverDelay' => 'Comienza el monitor después de',
			'settings.contentScreensaverLibraries' => 'Escreensaver bibliotecas',
			'settings.contentScreensaverLibrariesDescription' => 'Elige qué bibliotecas proporcionan imágenes para el salvapantallas. Si no seleccionas ninguna, se usarán imágenes de todas las bibliotecas.',
			'settings.contentScreensaverAllLibraries' => 'Todas las bibliotecas',
			'settings.contentScreensaverSelectedLibraries' => ({required Object count}) => '${count} bibliotecas seleccionadas',
			'settings.contentScreensaverNoLibraries' => 'No hay bibliotecas de medios conectadas.',
			'settings.contentScreensaverDismissHint' => 'Presiona cualquier botón o toque para desactivar',
			'settings.newEpisodeNotifications' => 'Noticias de nuevo episodio',
			'settings.newEpisodeNotificationsDescription' => 'Alerta cuando se añade un nuevo episodio a un espectáculo que está grabado. verifica mientras Plezy está abierto.',
			'settings.continueWatchingRowSize' => 'Continuar observando el tamaño de la línea',
			'settings.continueWatchingRowSizeValue' => ({required Object label}) => '${label} tarjetas',
			'settings.rowSizeCompact' => 'Compacto',
			'settings.rowSizeStandard' => 'estándar',
			'settings.rowSizeLarge' => 'Grande',
			'settings.continueWatchingAction' => 'Acción de «Seguir viendo»',
			'settings.continueWatchingPlay' => 'Reproducir',
			'settings.continueWatchingDetails' => 'Abrir detalles',
			'settings.episodeAction' => 'Acción de episodio',
			'settings.episodePlay' => 'Reproducir',
			'settings.episodeDetails' => 'Abrir detalles',
			'settings.useGlobalHubs' => 'Usar secciones de inicio',
			'settings.useGlobalHubsDescription' => 'Mostrar secciones de inicio unificadas. De lo contrario, usar las recomendaciones de cada biblioteca.',
			'settings.showServerNameOnHubs' => 'Mostrar el nombre del servidor en las secciones',
			'settings.showServerNameOnHubsDescription' => 'Mostrar siempre el nombre del servidor en los títulos de las secciones.',
			'settings.groupLibrariesByServer' => 'Agrupar bibliotecas por servidor',
			'settings.groupLibrariesByServerDescription' => 'Agrupar bibliotecas de la barra lateral por servidor multimedia.',
			'settings.alwaysKeepSidebarOpen' => 'Mantener siempre la barra lateral abierta',
			'settings.alwaysKeepSidebarOpenDescription' => 'La barra lateral permanece expandida y el área de contenido se ajusta para adaptarse',
			'settings.showUnwatchedCount' => 'Mostrar el número de elementos no vistos',
			'settings.showUnwatchedCountDescription' => 'Mostrar el número de episodios no vistos en series y temporadas',
			'settings.showWatchedIndicators' => 'Mostrar indicadores de visto',
			'settings.showWatchedIndicatorsDescription' => 'Mostrar una marca de verificación en películas, series y episodios vistos',
			'settings.showEpisodeNumberOnCards' => 'Mostrar número de episodio en las tarjetas',
			'settings.showEpisodeNumberOnCardsDescription' => 'Mostrar temporada y episodio en tarjetas de episodio',
			'settings.showSeasonPostersOnTabs' => 'Mostrar pósters de temporada en las pestañas',
			'settings.showSeasonPostersOnTabsDescription' => 'Mostrar el póster de cada temporada sobre su pestaña',
			'settings.tvFullCardLayout' => 'Tarjetas TV completas',
			'settings.tvFullCardLayoutDescription' => 'Usar tarjetas TV solo con imagen y nombres de actores superpuestos',
			'settings.focusGlow' => 'Resplandor de selección',
			'settings.focusGlowDescription' => 'Mostrar un resplandor suave alrededor de la tarjeta seleccionada',
			'settings.visualEffects' => 'Efectos visuales',
			'settings.visualEffectsAuto' => 'Automático',
			'settings.visualEffectsAutoDescription' => 'Reduce automáticamente los efectos en dispositivos de bajo consumo',
			'settings.visualEffectsFull' => 'Completos',
			'settings.visualEffectsReduced' => 'Reducidos',
			'settings.visualEffectsReducedDescription' => 'Menos animaciones e ilustraciones de menor resolución',
			'settings.hideSpoilers' => 'Ocultar spoilers de episodios no vistos',
			'settings.hideSpoilersDescription' => 'Desenfocar miniaturas y descripciones de episodios no vistos',
			'settings.playerBackend' => 'Motor de reproducción',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'Decodificación por hardware',
			'settings.hardwareDecodingDescription' => 'Usar aceleración por hardware cuando esté disponible',
			'settings.playbackBuffer' => 'Búfer de reproducción',
			'settings.playbackBufferAuto' => 'Automático (recomendado)',
			'settings.playbackBufferLarge' => 'Grande',
			'settings.playbackBufferExtraLarge' => 'Extra grande',
			'settings.playbackBufferDescription' => 'Almacena más en búfer para conexiones inestables. También limitado por el tamaño del búfer.',
			'settings.streamBufferSize' => 'El tamaño de buffer',
			'settings.streamBufferSizeValue' => ({required Object size}) => '${size} MB',
			'settings.streamBufferSizeDescription' => 'Cuánto vídeo se carga antes cuando se juega directamente. transcodes se detiene en el buffer de transcódulos del servidor. 0 = Auto',
			'settings.streamBufferSizeExoNote' => 'Replaza el Playback Buffer cuando se establece, captado a la mitad del límite de memoria de la aplicación',
			'settings.streamBufferMegabytes' => 'Megabytes',
			'settings.defaultQualityTitle' => 'Calidad predeterminada',
			'settings.cellularQualityTitle' => 'Calidad predeterminada en datos móviles',
			'settings.remoteQualityTitle' => 'La calidad de la transmisión a distancia',
			'settings.remoteQualitySameAsDefault' => 'La misma calidad que la de default',
			'settings.cellularQualitySameAsDefault' => 'Igual que la calidad predeterminada',
			'settings.directPlayCoveredQuality' => 'Reproducir videos más pequeños en calidad original',
			'settings.directPlayCoveredQualityDescription' => 'Reproducir directamente los videos que ya están dentro del límite de calidad en lugar de transcodificarlos',
			'settings.videoCodecs' => 'Códecs de video',
			'settings.videoCodecsDescription' => 'El servidor transcodifica los códecs no marcados',
			'settings.videoCodecsAlwaysAccepted' => 'Siempre aceptado',
			'settings.musicQualityTitle' => 'Calidad de música',
			'settings.subtitleStyling' => 'Estilo de subtítulos',
			'settings.subtitleStylingDescription' => 'Personalizar la apariencia de los subtítulos',
			'settings.smallSkipDuration' => 'Salto pequeño',
			'settings.largeSkipDuration' => 'Salto grande',
			'settings.rewindOnResume' => 'Rebobinar al reanudar',
			'settings.secondsUnit' => ({required num seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(seconds, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} segundo', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} segundos', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(seconds)} segundos', ), 
			'settings.defaultSleepTimer' => 'Temporizador de apagado',
			'settings.minutesUnit' => ({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(minutes, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minuto', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minutos', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(minutes)} minutos', ), 
			'settings.rememberTrackSelections' => 'Recordar selección de pistas por serie/película',
			'settings.chooseTracksBeforePlayback' => 'Seleccione audio y subtitulos antes de reproducir',
			'settings.chooseTracksBeforePlaybackDescription' => 'Seleccione el audio y las pistas de subtitulos de fuente antes de que cada vídeo comience.',
			'settings.alwaysShowSubtitlesOnDevice' => 'Siempre mostrar subtítulos en este dispositivo',
			'settings.alwaysShowSubtitlesOnDeviceDescription' => 'Cuando el servidor no tiene ningún subtitulo seleccionado, seleccione un track localmente.',
			'settings.autoDownloadPreferredSubtitle' => 'Fechos de los subtítulos preferidos',
			'settings.autoDownloadPreferredSubtitleDescription' => 'Seleccione un subtitulo disponible en su lenguaje preferido localmente.Si no existe, pida al servidor que se encuentre uno cuando se apoya.',
			'settings.rememberTrackSelectionsDescription' => 'Recordar opciones de audio y subtítulos por título',
			'settings.rememberTrackSelectionsBackendRule' => 'Plex guarda cada elección en el servidor por archivo; Jellyfin también activa «Recordar selecciones» de la cuenta; Emby no es compatible',
			'settings.followServerTrackSelections' => 'Usar la selección de pistas del servidor por episodio',
			'settings.followServerTrackSelectionsDescription' => 'Al cambiar de episodio, aplicar el audio y los subtítulos seleccionados en el servidor en lugar de mantener la elección actual',
			'settings.resumeMusicOnLaunch' => 'Recordar la sesión de música',
			'settings.resumeMusicOnLaunchDescription' => 'Al iniciar la aplicación, reabrir la última canción en pausa donde se quedó',
			'settings.showChapterMarkersOnTimeline' => 'Mostrar marcadores de capítulos en la barra de progreso',
			'settings.showChapterMarkersOnTimelineDescription' => 'Dividir la barra de progreso en los límites de capítulos',
			'settings.specialsOrdering' => 'Especiales en orden de episodios',
			'settings.specialsOrderingDescription' => 'Dónde se reproducen los especiales en el orden de visualización de una serie',
			'settings.specialsOrderingServer' => 'Seguir orden del servidor',
			'settings.specialsOrderingAirDate' => 'Intercalar por fecha de emisión',
			'settings.specialsOrderingLast' => 'Después de las temporadas normales',
			'settings.clickVideoTogglesPlayback' => 'Clic en el video para reproducir/pausar',
			'settings.clickVideoTogglesPlaybackDescription' => 'Haz clic en el video para reproducir/pausar en vez de mostrar controles.',
			'settings.videoPlayerControls' => 'Controles del reproductor de video',
			'settings.keyboardShortcuts' => 'Atajos de teclado',
			'settings.keyboardShortcutsDescription' => 'Personalizar los atajos de teclado',
			'settings.videoPlayerNavigation' => 'Navegación del reproductor de video',
			'settings.videoPlayerNavigationDescription' => 'Usar las teclas de flecha para navegar por los controles del reproductor',
			'settings.watchTogetherRelay' => 'Servidor de retransmisión de Ver juntos',
			'settings.watchTogetherRelayDescription' => 'Servidores de retransmisión públicos de Open Watch Party, salvo que configures el tuyo',
			'settings.watchTogetherRelayHint' => 'https://mi-relay.ejemplo.com',
			'settings.watchTogetherRelayInvalid' => 'Introduce una URL base HTTP o HTTPS válida para el servidor de retransmisión.',
			'settings.crashReporting' => 'Informes de errores',
			'settings.crashReportingDescription' => 'Enviar informes de errores para mejorar la aplicación',
			'settings.debugLogging' => 'Registro de depuración',
			'settings.debugLoggingDescription' => 'Habilitar registros detallados para solucionar problemas',
			'settings.viewLogs' => 'Ver registros',
			'settings.viewLogsDescription' => 'Ver los registros de la aplicación',
			'settings.clearImageCache' => 'Vaciar caché de imágenes',
			'settings.clearImageCacheDescription' => 'Borra las carátulas y miniaturas guardadas en caché. Las imágenes pueden tardar más en cargar hasta que se descarguen de nuevo.',
			'settings.clearImageCacheSuccess' => 'Caché de imágenes vaciada correctamente',
			'settings.resetSettings' => 'Restablecer configuración',
			'settings.resetSettingsDescription' => 'Restaurar ajustes predeterminados. No se puede deshacer.',
			'settings.resetSettingsSuccess' => 'Configuración restablecida con éxito',
			'settings.backup' => 'Copia de seguridad',
			'settings.exportSettings' => 'Exportar configuración',
			'settings.exportSettingsDescription' => 'Guardar tus preferencias en un archivo',
			'settings.exportSettingsSuccess' => 'Configuración exportada',
			'settings.importSettings' => 'Importar configuración',
			'settings.importSettingsDescription' => 'Restaurar preferencias desde un archivo',
			'settings.importSettingsConfirm' => 'Esto reemplazará tu configuración actual. ¿Continuar?',
			'settings.importSettingsSuccess' => 'Configuración importada',
			'settings.importSettingsInvalidFile' => 'Este archivo no es una exportación válida de PlezyNG',
			'settings.importSettingsNoUser' => 'Inicia sesión antes de importar la configuración',
			'settings.cloudBackup' => 'Nuevos Backup',
			'settings.cloudBackupDescription' => 'Guarda una copia de seguridad de los ajustes transferibles en una dirección WebDAV mediante HTTPS. Las conexiones a los servidores y las credenciales permanecen en este dispositivo.',
			'settings.cloudBackupUrl' => 'WebDAV URL de archivo JSON',
			'settings.cloudBackupUsername' => 'Usuario',
			'settings.cloudBackupPassword' => 'Contraseña',
			'settings.cloudBackupSaved' => 'Cloud Backup Destino Salvo',
			'settings.cloudBackupNow' => 'Volver ahora',
			'settings.cloudBackupComplete' => 'Configuraciones de backup uploaded',
			'settings.cloudBackupRestore' => 'Restaurar la Backup',
			'settings.cloudBackupRestoreConfirm' => 'Esto sustituirá las configuraciones portátiles que se ajustan a este dispositivo.',
			'settings.cloudBackupRestored' => 'Configuraciones restauradas de la backup en la nube',
			'settings.shortcutsReset' => 'Atajos restablecidos a los valores predeterminados',
			'settings.resetShortcutsConfirm' => 'Esto reemplazará tus atajos personalizados por los predeterminados. ¿Continuar?',
			'settings.about' => 'Acerca de',
			'settings.aboutDescription' => 'Información de la aplicación y licencias',
			'settings.updates' => 'Actualizaciones',
			'settings.updateAvailable' => 'Actualización disponible',
			'settings.checkForUpdates' => 'Buscar actualizaciones',
			'settings.autoCheckUpdatesOnStartup' => 'Buscar actualizaciones automáticamente al iniciar',
			'settings.autoCheckUpdatesOnStartupDescription' => 'Avisar al iniciar si hay una actualización disponible',
			'settings.validationErrorEnterNumber' => 'Introduce un número válido',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'La duración debe estar entre ${min} y ${max} ${unit}',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'El atajo ya está asignado a ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Atajo actualizado para ${action}',
			'settings.saveFailed' => 'No se pudieron guardar los cambios. Inténtalo de nuevo.',
			'settings.autoPlayAndSkip' => 'Reproducción automática y saltos',
			'settings.autoPlayNextEpisode' => 'Reproducción automática del siguiente episodio',
			'settings.autoPlayNextEpisodeDescription' => 'Iniciar automáticamente el siguiente episodio cuando termine el actual',
			'settings.shuffleStartsFromBeginning' => 'La reproducción aleatoria empieza desde el principio',
			'settings.shuffleStartsFromBeginningDescription' => 'Empezar cada episodio desde el principio en reproducción aleatoria en lugar de reanudarlo',
			'settings.plexCinemaPreRoll' => 'El servidor de cine intros',
			'settings.plexCinemaPreRollDescription' => 'Juega configurados Plex pre-rolls o Jellyfin y Emby intros antes de que una película empiece.',
			'settings.playNextCountdown' => 'Cuenta atrás para el siguiente episodio',
			'settings.playNextCountdownImmediate' => 'Reproducir de inmediato',
			'settings.skipIntroMode' => 'Saltar intro',
			'settings.skipIntroModeOffDescription' => 'Reproducir las intros normalmente sin botón de salto',
			'settings.skipIntroModeButtonDescription' => 'Mostrar un botón de salto cuando empiece una intro',
			'settings.skipIntroModeAutoDescription' => 'Saltar las intros automáticamente tras el retraso indicado abajo',
			'settings.skipCreditsMode' => 'Saltar créditos',
			'settings.skipCreditsModeOffDescription' => 'Reproducir los créditos normalmente sin botón de salto',
			'settings.skipCreditsModeButtonDescription' => 'Mostrar un botón de salto cuando empiecen los créditos',
			'settings.skipCreditsModeAutoDescription' => 'Saltar los créditos automáticamente y reproducir el siguiente episodio',
			'settings.skipAdsMode' => 'Descargar Ads',
			'settings.skipAdsModeOffDescription' => 'Play detecta anuncios normalmente sin un botón de escape',
			'settings.skipAdsModeButtonDescription' => 'Mostrar un botón de escape cuando Plex detecta un anuncio',
			'settings.skipAdsModeAutoDescription' => 'Descargar los anuncios detectados automáticamente después del retraso a continuación',
			'settings.musicPlayback' => 'Música Playback',
			'settings.musicSweetFades' => 'Sujeto Fades',
			'settings.musicSweetFadesDescription' => 'La música se desliza en los límites de la pista cuando Plex tiene datos de ruido.',
			'settings.skipMarkerModeOff' => 'Desactivado',
			'settings.skipMarkerModeButton' => 'Mostrar botón',
			'settings.skipMarkerModeAuto' => 'Automático',
			'settings.forceSkipMarkerFallback' => 'Forzar marcadores alternativos',
			'settings.forceSkipMarkerFallbackDescription' => 'Usar patrones de títulos de capítulos aunque Plex tenga marcadores',
			'settings.theIntroDbFallback' => 'Utilice el TheIntroDB como un intro fallback',
			'settings.theIntroDbFallbackDescription' => 'Utilice las timing de la comunidad sólo cuando el servidor no tiene marcador de intro.',
			'settings.autoSkipDelay' => 'Retraso del salto automático',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Esperar ${seconds} segundos antes de saltar automáticamente',
			'settings.introPattern' => 'Patrón de marcador de introducción',
			'settings.introPatternDescription' => 'Expresión regular para reconocer marcadores de introducción en los títulos de los capítulos',
			'settings.creditsPattern' => 'Patrón de marcador de créditos',
			'settings.creditsPatternDescription' => 'Expresión regular para reconocer marcadores de créditos en los títulos de los capítulos',
			'settings.prerolls' => 'Prerolles',
			'settings.playPrerollsBeforeMovies' => 'Juega los próroles antes de los filmes',
			'settings.playPrerollsBeforeMoviesDescription' => 'Play a un clip aleatorio de su selección a continuación antes de cada película.',
			'settings.prerollLibrary' => 'Biblioteca Preroll',
			'settings.prerollLibraryNotSet' => 'No establecido',
			'settings.prerollLibraryNoneFound' => 'No se encuentran bibliotecas en sus servidores.',
			'settings.prerollSelection' => 'Los prerólogos seleccionados',
			'settings.prerollSelectionPickLibraryFirst' => 'Póngase una biblioteca primero',
			'settings.prerollSelectionNoneSelected' => 'No hay prerólogos seleccionados',
			'settings.prerollSelectionCount' => ({required Object count}) => '${count} seleccionados',
			'settings.prerollItemPicker' => 'Seleccion de prerogados',
			'settings.prerollItemPickerLoadFailed' => 'No podían cargar artículos de esta biblioteca.',
			'settings.invalidRegex' => 'Expresión regular no válida',
			'settings.regex' => 'Expresión regular',
			'settings.downloads' => 'Descargas',
			'settings.downloadLocationDescription' => 'Elegir dónde almacenar el contenido descargado',
			'settings.downloadLocationDefault' => 'Predeterminado (almacenamiento de la aplicación)',
			'settings.downloadLocationCustom' => 'Ubicación personalizada',
			'settings.selectFolder' => 'Seleccionar carpeta',
			'settings.resetToDefault' => 'Restablecer al predeterminado',
			'settings.currentPath' => ({required Object path}) => 'Actual: ${path}',
			'settings.downloadLocationChanged' => 'Ubicación de descarga cambiada',
			'settings.downloadLocationReset' => 'Ubicación de descarga restablecida al predeterminado',
			'settings.downloadLocationInvalid' => 'La carpeta seleccionada no tiene permisos de escritura',
			'settings.downloadLocationPickerUnavailable' => 'La selección de carpetas no está disponible en este dispositivo',
			'settings.downloadOnWifiOnly' => 'Descargar solo con WiFi',
			'settings.downloadOnWifiOnlyDescription' => 'Evitar descargas cuando se usan datos móviles',
			'settings.autoRemoveWatchedDownloads' => 'Eliminar descargas vistas automáticamente',
			'settings.autoRemoveWatchedDownloadsDescription' => 'Eliminar automáticamente descargas vistas',
			'settings.autoDownloadContinueWatching' => 'Auto-Download Continúa Visto',
			'settings.autoDownloadContinueWatchingDescription' => 'Mantenga los artículos en su esqueleto de seguimiento continuado descargados, y quita los elementos una vez que dejan el esqueleto',
			'settings.downloadQuality' => 'Descarga de calidad',
			'settings.downloadQualityDescription' => 'Plex prepara una copia convertida en su cueva de descarga. Jellyfin y Emby transcódicos mientras el archivo se descarga; los transferencias interrumpidos pueden necesitar reiniciar.',
			'settings.askDownloadQualityEachTime' => 'Elegir la calidad para cada descarga',
			'settings.askDownloadQualityEachTimeDescription' => 'Mostrar el picker de calidad antes de quejar cada descarga de vídeo',
			'settings.cellularDownloadBlocked' => 'Las descargas están bloqueadas en red móvil. Usa WiFi o cambia el ajuste.',
			'settings.maxVolume' => 'Volumen máximo',
			'settings.maxVolumeDescription' => 'Permitir aumento de volumen por encima del 100% para medios con sonido bajo',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Presencia de Discord',
			'settings.discordRichPresenceDescription' => 'Mostrar lo que estás viendo en Discord',
			'settings.services' => 'Servicios',
			'settings.servicesDescription' => 'Conecta Trakt, MyAnimeList, Seerr y más',
			'settings.manageLibrariesDescription' => 'Reordena y oculta bibliotecas',
			'settings.companionRemoteServer' => 'Servidor de control remoto',
			'settings.companionRemoteServerDescription' => 'Permitir que dispositivos móviles en tu red controlen esta aplicación',
			'settings.companionRemoteServerStartFailed' => 'No se pudo iniciar el servidor de control remoto',
			'settings.companionRemoteServerStopFailed' => 'No se pudo detener el servidor de control remoto',
			'settings.autoPip' => 'Imagen en imagen automática',
			'settings.autoPipDescription' => 'Activar automáticamente el modo de imagen en imagen al salir de la aplicación durante la reproducción',
			'settings.matchContentFrameRate' => 'Ajustar frecuencia de actualización',
			'settings.matchContentFrameRateDescription' => 'Ajustar la frecuencia de pantalla al contenido de video',
			'settings.matchContentResolution' => 'Ajustar a la resolución del contenido',
			'settings.matchContentResolutionDescription' => 'Cambia la pantalla a la resolución nativa del vídeo para que tu televisor se encargue del escalado. Los menús y los subtítulos también se escalan durante la reproducción',
			'settings.matchRefreshRate' => 'Ajustar frecuencia de refresco',
			'settings.matchRefreshRateDescription' => 'Ajustar la frecuencia de pantalla en pantalla completa',
			'settings.matchDynamicRange' => 'Ajustar rango dinámico',
			'settings.matchDynamicRangeDescription' => 'Activar HDR para contenido HDR y luego volver a SDR',
			'settings.displaySwitchDelay' => 'Retraso de cambio de pantalla',
			'settings.tunneledPlayback' => 'Reproducción tunelizada',
			'settings.tunneledPlaybackDescription' => 'Usar tunelización de video. Desactívala si HDR muestra video negro o el movimiento se entrecorta.',
			'settings.audioPassthrough' => 'Transferencia directa de audio',
			'settings.audioPassthroughDescription' => 'Envía el audio Dolby/DTS a tu receptor o TV sin recodificar, conservando el sonido envolvente. Desactívala si no tienes sonido.',
			'settings.audioPassthroughDescriptionApple' => 'Usa el decodificador Dolby nativo de Apple para Dolby Digital Plus, incluido Atmos. DTS y TrueHD se siguen reproduciendo como PCM multicanal. Desactívalo si no tienes sonido.',
			'settings.audioPassthroughDescriptionAppleSpatial' => 'Usa el decodificador Dolby nativo de Apple para Dolby Digital Plus, incluido Atmos. En iOS, iPadOS y tvOS 26 o posterior, TrueHD Atmos y DTS:X se reproducen como audio espacial. El resto de pistas DTS y TrueHD se reproducen como PCM multicanal. Desactívalo si no tienes sonido.',
			'settings.audioPassthroughOverriddenByNormalization' => 'Desactivada mientras la normalización de volumen esté activada',
			'settings.audioChannelLimit' => 'Canales de audio',
			'settings.audioChannelLimitDescription' => 'Mezcla el audio decodificado a menos canales para altavoces, auriculares o equipos HDMI que no pueden reproducir todos los canales',
			'settings.audioChannelLimitOriginal' => 'Original',
			'settings.audioChannelLimitOriginalDescription' => 'Reproduce todos los canales de la pista',
			'settings.audioChannelLimitSurround51' => 'Hasta 5.1',
			'settings.audioChannelLimitSurround51Description' => 'Mezcla 7.1 a 5.1 para televisores y receptores que solo admiten PCM 5.1. No afecta a la transferencia directa.',
			'settings.audioChannelLimitStereo' => 'Estéreo',
			'settings.audioChannelLimitStereoDescription' => 'Mezcla a dos canales para altavoces estéreo o auriculares. Desactiva la transferencia directa.',
			'settings.downmixCenterBoost' => 'Realce del canal central',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'Realce (dB)',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => 'Normalizar volumen al mezclar',
			'settings.audioDownmixNormalizeDescription' => 'Reduce la mezcla para evitar saturación. Desactívalo para mantener el volumen original (puede distorsionar escenas fuertes).',
			'settings.dvConversionMode' => 'Conversión de Dolby Vision',
			'settings.dvConversionModeDescription' => 'Elige cómo se gestionan los archivos Dolby Vision de perfil 7.',
			'settings.dvConversionAuto' => 'Automático',
			'settings.dvConversionNative' => 'Nativo / desactivado',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Usar la detección de capacidades del dispositivo y el comportamiento alternativo normal',
			'settings.dvConversionNativeDescription' => 'Forzar DV7 nativo y suprimir el reintento de conversión DV',
			'settings.dvConversionDv81Description' => 'Forzar la conversión de RPU en línea al perfil 8.1 de Dolby Vision',
			'settings.dvConversionHevcStripDescription' => 'Eliminar las capas RPU/EL de Dolby Vision y presentar HEVC convencional',
			'settings.experimentalDolbyVision' => 'Dolby Vision experimental',
			'settings.experimentalDolbyVisionDescription' => 'Usar el renderizador FEL experimental en la próxima reproducción. Requiere una compilación independiente del motor.',
			'settings.dvExperimentUnavailableDescription' => 'Este experimento solo está disponible en Linux por ahora.',
			'settings.dvCompatibilityFallback' => 'Alternativa de compatibilidad',
			'settings.dvCompatibilityFallbackDescription' => 'Usar el renderizador estándar si el experimento no puede iniciarse. Se pueden perder los datos FEL.',
			'settings.dvExperimentDiagnostics' => 'Registro del experimento de vídeo',
			'settings.dvExperimentDiagnosticsDescription' => 'Activar registros detallados del reproductor en la próxima reproducción.',
			'settings.disableDolbyVision' => 'Desactivar Dolby Vision',
			'settings.disableDolbyVisionDescription' => 'Reproducir la capa HDR10 o HLG del archivo en lugar de Dolby Vision, si la tiene',
			'settings.hdrSdrConversion' => 'Conversión de HDR a SDR',
			'settings.hdrSdrConversionDescription' => 'Elige qué convierte el vídeo HDR cuando la pantalla no puede mostrar HDR.',
			_ => null,
		} ?? switch (path) {
			'settings.hdrSdrConversionAuto' => 'Automático',
			'settings.hdrSdrConversionAutoDescription' => 'Dispositivo en Android 9 y posteriores, reproductor en versiones anteriores',
			'settings.hdrSdrConversionDevice' => 'Dispositivo',
			'settings.hdrSdrConversionDeviceDescription' => 'El hardware de vídeo del dispositivo realiza la conversión. Lo más rápido, pero los colores dependen del dispositivo',
			'settings.hdrSdrConversionPlayer' => 'Reproductor',
			'settings.hdrSdrConversionPlayerDescription' => 'El reproductor realiza la conversión. Colores uniformes, pero el 4K puede ir a tirones en TV boxes de gama baja',
			'settings.deinterlace' => 'Desentrelazado',
			'settings.deinterlaceDescription' => 'Elimina los artefactos de peine del video entrelazado (solo reproductor mpv)',
			'settings.deinterlaceOff' => 'Desactivado',
			'settings.deinterlaceOffDescription' => 'Muestra el video entrelazado tal como se decodifica',
			'settings.deinterlaceVideo' => 'Video',
			'settings.deinterlaceVideoDescription' => 'Convierte cada campo en un fotograma completo. Para video grabado para TV, como deportes, noticias y conciertos',
			'settings.deinterlaceFilm' => 'Cine',
			'settings.deinterlaceFilmDescription' => 'Restaura los fotogramas originales de películas y animación convertidas por telecine a 29,97 fps, algo habitual en los DVD NTSC. El video grabado para TV se entrecorta. La TV en vivo usa el modo Video',
			'settings.requireProfileSelectionOnOpen' => 'Pedir perfil al abrir la aplicación',
			'settings.requireProfileSelectionOnOpenDescription' => 'Mostrar selección de perfil cada vez que se abre la aplicación',
			'settings.forceTvMode' => 'Forzar modo TV',
			'settings.forceTvModeDescription' => 'Forzar diseño TV. Para dispositivos que no lo detectan. Requiere reinicio.',
			'settings.startInFullscreen' => 'Iniciar en pantalla completa',
			'settings.startInFullscreenDescription' => 'Abrir PlezyNG en modo pantalla completa al iniciar',
			'settings.exitFullscreenOnPlayerClose' => 'Salir de pantalla completa al cerrar el reproductor',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Salir automáticamente del modo de pantalla completa al cerrar el reproductor de video',
			'settings.autoHidePerformanceOverlay' => 'Ocultar superposición de rendimiento automáticamente',
			'settings.autoHidePerformanceOverlayDescription' => 'Desvanecer la superposición de rendimiento con los controles de reproducción',
			'settings.showNavBarLabels' => 'Mostrar etiquetas de la barra de navegación',
			'settings.showNavBarLabelsDescription' => 'Mostrar etiquetas de texto bajo los iconos de la barra de navegación',
			'settings.startupSection' => 'Sección de inicio',
			'settings.preferredServer' => 'Preferido servidor',
			'settings.preferredServerDescription' => 'Priorizar los resultados de este servidor mientras que mantener cada servidor conectado disponible.',
			'settings.preferredServerAutomatic' => 'Automático',
			'settings.showExploreTab' => 'Mostrar pestaña Explorar',
			'settings.showExploreTabDescription' => 'Muestra la pestaña Explorar con contenido de Plex Discover y servicios de seguimiento conectados',
			'settings.hideEmptyLibraries' => 'Esconde las bibliotecas vacías',
			'settings.hideEmptyLibrariesDescription' => 'Removemos bibliotecas con un número de artículos reportados por el servidor de cero de la navegación.',
			'settings.liveTvDefaultFavorites' => 'Canales favoritos por defecto',
			'settings.liveTvDefaultFavoritesDescription' => 'Mostrar solo canales favoritos al abrir TV en vivo',
			'settings.general' => 'General',
			'settings.generalDescription' => 'Idioma, inicio y comportamiento de la ventana',
			'settings.languageAndRegion' => 'Idioma y región',
			'settings.startup' => 'Inicio',
			'settings.display' => 'Pantalla',
			'settings.libraryAndCards' => 'Biblioteca y tarjetas',
			'settings.homeScreen' => 'Pantalla de inicio',
			'settings.navigation' => 'Navegación',
			'settings.window' => 'Ventana',
			'settings.liveTv' => 'TV en vivo',
			'settings.player' => 'Reproductor',
			'settings.videoAndDisplay' => 'Video y pantalla',
			'settings.audio' => 'Audio',
			'settings.quality' => 'Calidad',
			'settings.subtitles' => 'Subtítulos',
			'settings.seekAndTiming' => 'Desplazamiento y tiempos',
			'settings.behavior' => 'Comportamiento',
			'settings.gestures' => 'Gestos',
			'settings.gestureBrightnessSwipe' => 'Gesto de brillo',
			'settings.gestureBrightnessSwipeDescription' => 'Desliza hacia arriba o abajo en el borde izquierdo para ajustar el brillo',
			'settings.gestureVolumeSwipe' => 'Gesto de volumen',
			'settings.gestureVolumeSwipeDescription' => 'Desliza hacia arriba o abajo en el borde derecho para ajustar el volumen',
			'settings.gesturePinchToZoom' => 'Pellizcar para hacer zoom',
			'settings.gesturePinchToZoomDescription' => 'Pellizca el video para acercar o alejar',
			'settings.gestureSeekSwipe' => 'Buscar Swipe',
			'settings.gestureSeekSwipeDescription' => 'Descargar la izquierda o la derecha en cualquier lugar en el video para buscar; liberar para saltar',
			'settings.rememberBrightnessLevel' => 'Recordar nivel de brillo',
			'settings.rememberBrightnessLevelDescription' => 'Iniciar la reproducción con el brillo establecido por el último deslizamiento',
			'settings.controls' => 'Controles',
			'settings.rememberPlayerChanges' => 'Recordar cambios del reproductor',
			'settings.rememberPlayerChangesDescription' => 'Dónde se guarda y se vuelve a aplicar un cambio realizado durante la reproducción',
			'settings.scopePlaybackSpeed' => 'Velocidad de reproducción',
			'settings.scopeShaderPreset' => 'Preajuste de sombreado',
			'settings.scopeAspectRatio' => 'Relación de aspecto',
			'settings.scopeSyncOffsets' => 'Sincronización de audio y subtítulos',
			'settings.playerScopeOff' => 'No guardar',
			'settings.playerScopeGlobal' => 'En todas partes',
			'settings.playerScopeLibrary' => 'Por biblioteca',
			'settings.playerScopeTitle' => 'Por serie o película',
			'settings.exportDialogTitle' => 'Exportar ajustes de PlezyNG',
			'settings.followSystem' => 'Seguir el sistema',
			'settings.followAppLanguage' => 'Igual que el idioma de la interfaz',
			'settings.regionFormat' => 'Formatos regionales',
			'settings.regionFormatDescription' => 'Elige cómo se muestran las fechas, los números y las unidades de medida.',
			'settings.metadataLanguage' => 'Idioma de los metadatos',
			'settings.metadataLanguageDescription' => 'Idioma preferido para títulos y descripciones cuando el servidor lo permita. Las preferencias de audio y subtítulos se configuran por separado.',
			'settings.enterFullscreenOnPlaybackStart' => 'Entrar en pantalla completa cuando comienza el playback',
			'settings.enterFullscreenOnPlaybackStartDescription' => 'Abre vídeo de escritorio en pantalla completa cuando comienza el playback',
			'settings.extendVideoIntoDisplayCutout' => 'Extendir el video a la pantalla Cutout',
			'settings.extendVideoIntoDisplayCutoutDescription' => 'Deja que el vídeo de pantalla completa utilice la cámara en los teléfonos Android',
			'settings.languageDescription' => 'Seleccione el idioma utilizado para los controles y mensajes de PlezyNG. Seguir sistema rastreará su lenguaje del dispositivo.',
			'settings.themeDescription' => 'Seleccione los colores y contraste utilizados en toda la aplicación.',
			'settings.libraryDensityDescription' => 'Cambiar cuántas tarjetas de biblioteca se ajustan en cada línea.',
			'settings.displayScaleDescription' => 'Recupere la interfaz en esta pantalla de automóvil sin cambiar el tamaño del texto en todo el dispositivo.',
			'settings.themeSongVolumeDescription' => 'Define el volumen de las canciones temáticas en relación con otros audio.',
			'settings.viewModeDescription' => 'Seleccione si los artículos de la biblioteca aparecen como carteles en una red o como una lista compacta.',
			'settings.gridViewDescription' => 'Arreglar los artículos de la biblioteca en líneas y columnas de carteles.',
			'settings.listViewDescription' => 'Mostrar artículos de la biblioteca en una lista vertical con más texto por elemento.',
			'settings.gridSpacingDescription' => 'Configure la distancia entre los carteles en las redes de bibliotecas.',
			'settings.gridSpacingTightDescription' => 'Coloque más carteles a través de la pantalla con pequeñas franjas.',
			'settings.gridSpacingNormalDescription' => 'Utilice la franja estándar entre los carteles.',
			'settings.gridSpacingSpaciousDescription' => 'Añadir grandes franjas entre los carteles para más separación.',
			'settings.episodePosterModeDescription' => 'Seleccione qué arte aparece en las tarjetas de episodios.',
			'settings.seriesPosterDescription' => 'Utilice el poster de la serie para cada episodio.',
			'settings.seasonPosterDescription' => 'Utilice el poster de temporada para cada episodio cuando esté disponible.',
			'settings.episodeThumbnailDescription' => 'Utilice un marco del episodio cuando esté disponible.',
			'settings.continueWatchingActionDescription' => 'Seleccione lo que sucede cuando activas una tarjeta de seguimiento continua.',
			'settings.continueWatchingPlayDescription' => 'Comienza la película o el episodio de inmediato.',
			'settings.continueWatchingDetailsDescription' => 'Abre la página de título primero para que pueda revisar los detalles y elegir una acción.',
			'settings.episodeActionDescription' => 'Seleccione lo que sucede cuando activas una tarjeta de episodio.',
			'settings.episodePlayDescription' => 'Comienza el episodio de inmediato.',
			'settings.episodeDetailsDescription' => 'Abre la página de episodios antes del playback.',
			'settings.contentScreensaverDelayDescription' => 'Seleccione cuánto tiempo PlezyNG espera sin entrada antes de mostrar arte.',
			'settings.continueWatchingRowSizeDescription' => 'Seleccione cuán grandes son las tarjetas en la línea de seguimiento continuo.',
			'settings.rowSizeCompactDescription' => 'Mostrar tarjetas más pequeñas para que más artículos se ajusten a través de la línea.',
			'settings.rowSizeStandardDescription' => 'Utilice el tamaño de la tarjeta.',
			'settings.rowSizeLargeDescription' => 'Mostrar tarjetas más grandes con más detalles de arte.',
			'settings.visualEffectsDescription' => 'Seleccione el presupuesto de los efectos de animación y arte para este dispositivo.',
			'settings.visualEffectsFullDescription' => 'Utilice los efectos de animación y arte completo en cada dispositivo.',
			'settings.startupSectionDescription' => 'Seleccione la sección que se abre cuando empieza PlezyNG.',
			'settings.startupSectionOptions.discover' => 'Abre recomendaciones y artículos de fuentes de descubrimiento conectadas.',
			'settings.startupSectionOptions.libraries' => 'Abre tus bibliotecas de medios conectados.',
			'settings.startupSectionOptions.liveTv' => 'Open Live TV cuando un servidor lo proporciona; de lo contrario, la startup cae de vuelta a Home.',
			'settings.startupSectionOptions.search' => 'búsqueda de medios abiertos.',
			'settings.smallSkipDurationDescription' => 'Establece la distancia movida por el corto atrás y hacia adelante busca controles.',
			'settings.largeSkipDurationDescription' => 'Establece la distancia movida por el largo atrás y hacia adelante busca controles.',
			'settings.rewindOnResumeDescription' => 'Move playback de vuelta por este importe cuando vuelve a reproducir un vídeo.',
			'settings.defaultSleepTimerDescription' => 'Establece la duración inicial utilizada cuando empiezas el horario del sueño.',
			'settings.playNextCountdownDescription' => 'Espera mucho antes de que comience el siguiente episodio.Set a 0 para comenzar inmediatamente.',
			'settings.autoSkipDelaySettingDescription' => 'Se aplica cuando un intro, crédito o anuncio se establece para escapar automáticamente.',
			'settings.downmixCenterBoostDescription' => 'Aumentar el diálogo en el canal central cuando el audio circular se mezcla hacia abajo al estereo.',
			'settings.displaySwitchDelayDescription' => 'Espera antes de cambiar el modo de pantalla para que la TV o receptor pueda terminar su anterior interrupción.',
			'settings.playerBackendDescription' => 'Seleccione qué motor de reproducción decode y retrasa el vídeo en este dispositivo.',
			'settings.exoPlayerDescription' => 'Utilice el reproductor nativo de Android Media3 y los caminos de hardware apoyados.',
			'settings.mpvDescription' => 'Utilice mpv, que expone controles adicionales de reproducción, subtítulos y procesamiento de vídeo.',
			'settings.scopeOffDescription' => 'Sólo mantenga los cambios para la sesión de reproducción actual.',
			'settings.scopeGlobalDescription' => 'Reutilizar el mismo valor para cada biblioteca y título.',
			'settings.scopeLibraryDescription' => 'Recuerda un valor separado para cada biblioteca.',
			'settings.scopeTitleDescription' => 'Recuerda un valor separado para cada espectáculo o película.',
			'settings.specialsOrderingServerDescription' => 'Mantenga la orden del episodio suministrada por el servidor de medios.',
			'settings.specialsOrderingAirDateDescription' => 'Coloca especialidades entre episodios regulares por su fecha aérea.',
			'settings.specialsOrderingLastDescription' => 'Coloca cada especial después de las temporadas regulares.',
			'settings.skipIntroModeDescription' => 'Seleccione si los marcadores intro juegan normalmente, muestran un botón de escape o salen automáticamente.',
			'settings.skipCreditsModeDescription' => 'Seleccione si los créditos se juegan normalmente, muestran un botón de escape o salen automáticamente.',
			'settings.skipAdsModeDescription' => 'Seleccione si los anuncios detectados juegan normalmente, muestran un botón de escape o salen automáticamente.',
			'settings.playbackBufferAutoDescription' => 'Deja al jugador activo elegir su tamaño normal del buffer.',
			'settings.playbackBufferLargeDescription' => 'Mantenga más medios listos antes de reproducir; esto utiliza más memoria.',
			'settings.playbackBufferExtraLargeDescription' => 'Mantenga el buffer de lectura más grande; esto utiliza la memoria más grande.',
			'settings.defaultQualityDescription' => 'Configure la resolución de vídeo por defecto y bitrate el techo para los flujos que el servidor transcoda.',
			'settings.cellularQualityDescription' => 'Override Default Quality cuando el dispositivo está utilizando una conexión celular-solo.',
			'settings.remoteQualityDescription' => 'Override Default Quality cuando se conecta a un servidor a través de una conexión remota.',
			'settings.qualityPresetOriginalDescription' => 'Juega la fuente a su calidad disponible sin pedir al servidor que la transcode.',
			'settings.qualityPresetTranscodeOptionDescription' => 'Solicite al servidor para un flujo convertido utilizando la resolución y bitrate que se muestra anteriormente.',
			'settings.qualityPresetSameAsDefaultDescription' => 'Utilice la calidad seleccionada en Calidad Default.',
			'settings.musicQualityDescription' => 'Establece la bitrate máxima de audio solicitada del servidor; Original mantiene el flujo de fuente.',
			'settings.musicQualityOriginalDescription' => 'Juega el audio de fuente sin un transcódigo capped por bitrate.',
			'settings.musicQualityTranscodeOptionDescription' => 'Solicita un transcódico del servidor capped cerca de la bitrate mostrada anteriormente; el rendimiento real puede variar.',
			'settings.maxVolumeInputLabel' => 'El volumen máximo (%)',
			'settings.checkForUpdatesDescription' => 'Verifique ahora si está disponible una versión más nueva de PlezyNG.',
			'settings.appearanceDescription' => 'Seleccione el tema de la aplicación y ajuste las tarjetas de la biblioteca, las líneas domésticas y la navegación.',
			'settings.prerollLibraryDescription' => 'Seleccione la biblioteca que contiene los clips disponibles como pre-rolls de la película.',
			'settings.prerollSelectionDescription' => 'Seleccione qué clips de la biblioteca seleccionada puede jugar antes de las películas.',
			'settings.contentScreensaverDelayOptionDescription' => 'Esperar estos muchos minutos sin entrada antes de mostrar la pantalla de almacenamiento artwork.',
			'settings.videoCodecOptionDescription' => 'Permite reproducción directa para este codec cuando se apoya. los codecs no verificados son transcodados por el servidor de medios.',
			'themeEditor.builtIn' => 'Integrados',
			'themeEditor.presets' => 'Predefinidos',
			'themeEditor.custom' => 'Personalizado',
			'themeEditor.customEmpty' => 'Aún no creado',
			'themeEditor.editCustom' => 'Editar tema personalizado',
			'themeEditor.editCustomDescription' => 'Elige cada color tú mismo',
			'themeEditor.locked' => 'Acceso a la vida necesaria',
			'themeEditor.savedLocked' => 'Salvo - disponible con acceso a la vida',
			'themeEditor.title' => 'Tema personalizado',
			'themeEditor.startFrom' => 'Partir de',
			'themeEditor.startFromDescription' => 'Copia todos los colores de otro tema',
			'themeEditor.colors' => 'Colores',
			'themeEditor.preview' => 'Vista previa',
			'themeEditor.slots.bg' => 'Fondo',
			'themeEditor.slots.surface' => 'Superficie',
			'themeEditor.slots.outline' => 'Contorno',
			'themeEditor.slots.text' => 'Texto',
			'themeEditor.slots.textMuted' => 'Texto secundario',
			'themeEditor.slots.accent' => 'Acento',
			'themeEditor.opacity' => 'Opacidad',
			'themeEditor.hexHint' => '#RRGGBB o #AARRGGBB',
			'themeEditor.fromOtherThemes' => 'De otros temas',
			'themeEditor.swatchLabel' => ({required Object color, required Object theme}) => '${color} de ${theme}',
			'themeEditor.contrast.textOnBg' => 'Texto sobre fondo',
			'themeEditor.contrast.textOnSurface' => 'Texto sobre superficie',
			'themeEditor.contrast.textMutedOnBg' => 'Texto secundario sobre fondo',
			'themeEditor.contrast.textMutedOnSurface' => 'Texto secundario sobre superficie',
			'themeEditor.contrast.accentOnBg' => 'Acento sobre fondo',
			'themeEditor.contrast.accentOnSurface' => 'Acento sobre superficie',
			'themeEditor.contrast.labelOnAccent' => 'Texto de botón sobre acento',
			'themeEditor.lowContrast' => ({required Object pair, required Object ratio, required Object minimum}) => '${pair}: ${ratio}:1, por debajo del ${minimum}:1 recomendado',
			'themeEditor.discardTitle' => '¿Descartar cambios?',
			'themeEditor.discardMessage' => 'Se perderán los cambios de color no guardados.',
			'themeEditor.discard' => 'Descartar',
			'themeEditor.previewCardTitle' => ({required Object number}) => 'Episodio ${number}',
			'themeEditor.previewCardSubtitle' => ({required Object minutes}) => 'Quedan ${minutes} min',
			'themeEditor.previewSwitch' => 'Reproducción automática',
			'themeEditor.previewMutedText' => 'Así se ve el texto secundario',
			'themeEditor.themeSystemDescription' => 'Siga la apariencia de tu dispositivo y cambie automáticamente entre luz y oscuridad.',
			'themeEditor.themeLightDescription' => 'Utilice un fondo claro con texto oscuro.',
			'themeEditor.themeDarkDescription' => 'Utilice un fondo oscuro con texto claro.',
			'themeEditor.themeOledDescription' => 'Utilice superficies cercanas a negro que reducen la luz en las pantallas OLED.',
			'themeEditor.themeEmberDescription' => 'Utilice colores de acento amarillo y rojo caliente.',
			'themeEditor.themeGlacierDescription' => 'Utilice colores de acento azul fresco.',
			'themeEditor.themeForestDescription' => 'Utilice los colores de acento verde y natural.',
			'themeEditor.themePlumDescription' => 'Utilice colores de acento violeta y plum.',
			'themeEditor.themePaperDescription' => 'Utilice superficies cálidas como papel y colores inspirados en tinta.',
			'themeEditor.themeCustomDescription' => 'Utilice la paleta de colores que ha creado en el editor de temas personalizados.',
			'themeEditor.editorDescription' => 'Seleccione un color de paleta, ajuste su huevo, saturación, brillo o opacidad y vea la actualización previa antes de ahorrar.',
			'search.hint' => 'Buscar películas, series, música...',
			'search.tryDifferentTerm' => 'Prueba con un término de búsqueda diferente',
			'search.searchYourMedia' => 'Busca en tu contenido',
			'search.enterTitleActorOrKeyword' => 'Introduce un título, actor o palabra clave',
			'search.people' => 'Personas',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'Establecer atajo para ${actionName}',
			'hotkeys.clearShortcut' => 'Borrar atajo',
			'hotkeys.noShortcutSet' => 'Sin atajo asignado',
			'hotkeys.currentShortcut' => 'Atajo actual:',
			'hotkeys.pressToRecord' => 'Seleccionar para grabar un atajo',
			'hotkeys.recordingShortcut' => 'Pulsa el atajo ahora',
			'hotkeys.actions.playPause' => 'Reproducir/pausar',
			'hotkeys.actions.volumeUp' => 'Subir volumen',
			'hotkeys.actions.volumeDown' => 'Bajar volumen',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'Avanzar (${seconds}s)',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'Retroceder (${seconds}s)',
			'hotkeys.actions.fullscreenToggle' => 'Alternar pantalla completa',
			'hotkeys.actions.muteToggle' => 'Activar/desactivar silencio',
			'hotkeys.actions.subtitleToggle' => 'Activar/desactivar subtítulos',
			'hotkeys.actions.audioTrackNext' => 'Pista de audio siguiente',
			'hotkeys.actions.subtitleTrackNext' => 'Pista de subtítulos siguiente',
			'hotkeys.actions.chapterNext' => 'Capítulo siguiente',
			'hotkeys.actions.chapterPrevious' => 'Capítulo anterior',
			'hotkeys.actions.episodeNext' => 'Episodio siguiente',
			'hotkeys.actions.episodePrevious' => 'Episodio anterior',
			'hotkeys.actions.speedIncrease' => 'Aumentar velocidad',
			'hotkeys.actions.speedDecrease' => 'Disminuir velocidad',
			'hotkeys.actions.speedReset' => 'Restablecer velocidad',
			'hotkeys.actions.zoomIn' => 'Acercar',
			'hotkeys.actions.zoomOut' => 'Alejar',
			'hotkeys.actions.zoomReset' => 'Restablecer zoom',
			'hotkeys.actions.subSeekNext' => 'Ir al subtítulo siguiente',
			'hotkeys.actions.subSeekPrev' => 'Ir al subtítulo anterior',
			'hotkeys.actions.subtitleDelayIncrease' => 'Retrasar subtítulos',
			'hotkeys.actions.subtitleDelayDecrease' => 'Adelantar subtítulos',
			'hotkeys.actions.shaderToggle' => 'Activar/desactivar shaders',
			'hotkeys.actions.skipMarker' => 'Saltar introducción/créditos',
			'hotkeys.actions.screenshot' => 'Tomar captura de pantalla',
			'hotkeys.actions.framePrevious' => 'Anterior Frame',
			'hotkeys.actions.frameNext' => 'Siguiente Frame',
			'fileInfo.title' => 'Información del archivo',
			'fileInfo.overview' => 'Resumen',
			'fileInfo.video' => 'Video',
			'fileInfo.audio' => 'Audio',
			'fileInfo.subtitles' => 'Subtítulos',
			'fileInfo.images' => 'Imágenes incrustadas',
			'fileInfo.dataStreams' => 'Flujos de datos',
			'fileInfo.lyrics' => 'Letras',
			'fileInfo.file' => 'Archivo',
			'fileInfo.attachments' => 'Archivos adjuntos',
			'fileInfo.delivery' => 'Entrega',
			'fileInfo.versionCounter' => ({required Object index, required Object count}) => 'Versión ${index} de ${count}',
			'fileInfo.fileCounter' => ({required Object index, required Object count}) => 'Archivo ${index} de ${count}',
			'fileInfo.noStreams' => 'El servidor no informó de ningún flujo para este archivo.',
			'fileInfo.copyPath' => 'Copiar ruta',
			'fileInfo.pathCopied' => 'Ruta del archivo copiada',
			'fileInfo.codec' => 'Códec',
			'fileInfo.codecTag' => 'Etiqueta de códec',
			'fileInfo.resolution' => 'Resolución',
			'fileInfo.codedResolution' => 'Resolución codificada',
			'fileInfo.bitrate' => 'Tasa de bits',
			'fileInfo.frameRate' => 'Frecuencia de fotogramas',
			'fileInfo.rotation' => 'Rotación',
			'fileInfo.comment' => 'Comentario',
			'fileInfo.audioDescription' => 'Audiodescripción',
			'fileInfo.headerCompression' => 'Compresión de cabecera',
			'fileInfo.sidecarFile' => 'Archivo auxiliar',
			'fileInfo.transportTimestamp' => 'Marca de tiempo de transporte',
			'fileInfo.displayOffset' => 'Desplazamiento de visualización',
			'fileInfo.previewFailureCode' => 'Código de error de vista previa',
			'fileInfo.previewRetries' => 'Reintentos de vista previa',
			'fileInfo.aspectRatio' => 'Relación de aspecto',
			'fileInfo.pixelAspectRatio' => 'Relación de aspecto de píxel',
			'fileInfo.profile' => 'Perfil',
			'fileInfo.level' => 'Nivel',
			'fileInfo.bitDepth' => 'Profundidad de bits',
			'fileInfo.pixelFormat' => 'Formato de píxel',
			'fileInfo.colorSpace' => 'Espacio de color',
			'fileInfo.colorRange' => 'Rango de color',
			'fileInfo.colorPrimaries' => 'Primarias de color',
			'fileInfo.colorTransfer' => 'Transferencia de color',
			'fileInfo.chromaSubsampling' => 'Submuestreo de croma',
			'fileInfo.chromaLocation' => 'Ubicación de crominancia',
			'fileInfo.scanType' => 'Tipo de escaneo',
			'fileInfo.interlaced' => 'Entrelazado',
			'fileInfo.anamorphic' => 'Anamórfico',
			'fileInfo.referenceFrames' => 'Fotogramas de referencia',
			'fileInfo.dynamicRange' => 'Rango dinámico',
			'fileInfo.dolbyVision' => 'Dolby Vision',
			'fileInfo.dolbyVisionLevel' => 'Nivel de Dolby Vision',
			'fileInfo.dolbyVisionVersion' => 'Versión de Dolby Vision',
			'fileInfo.dolbyVisionLayers' => 'Capas de Dolby Vision',
			'fileInfo.baseLayerCompatibility' => 'Compatibilidad de capa base',
			'fileInfo.avcBitstream' => 'Flujo de bits AVC',
			'fileInfo.nalLengthSize' => 'Tamaño de longitud NAL',
			'fileInfo.scalingMatrix' => 'Matriz de escalado personalizada',
			'fileInfo.streamIdentifier' => 'Identificador de flujo',
			'fileInfo.streamIndex' => 'Índice de flujo',
			'fileInfo.streamId' => 'ID de flujo',
			'fileInfo.language' => 'Idioma',
			'fileInfo.languageCode' => 'Código de idioma',
			'fileInfo.streamTitle' => 'Título de la pista',
			'fileInfo.channels' => 'Canales',
			'fileInfo.sampleRate' => 'Frecuencia de muestreo',
			'fileInfo.spatialAudio' => 'Audio espacial',
			'fileInfo.textBased' => 'Basado en texto',
			'fileInfo.subtitleFormat' => 'Formato de archivo auxiliar',
			'fileInfo.provider' => 'Proveedor',
			'fileInfo.matchScore' => 'Puntuación de coincidencia',
			'fileInfo.externalDelivery' => 'Puede servirse por separado',
			'fileInfo.sidecarPath' => 'Ruta del archivo auxiliar',
			'fileInfo.sourceStream' => 'Copiado de',
			'fileInfo.temporary' => 'Temporal',
			'fileInfo.timeBase' => 'Base de tiempo',
			'fileInfo.overallBitrate' => 'Tasa de bits total',
			'fileInfo.path' => 'Ruta',
			'fileInfo.fileName' => 'Nombre de archivo',
			'fileInfo.size' => 'Tamaño',
			'fileInfo.totalSize' => 'Tamaño total',
			'fileInfo.container' => 'Contenedor',
			'fileInfo.duration' => 'Duración',
			'fileInfo.previewThumbnails' => 'Miniaturas de vista previa',
			'fileInfo.previewIndex' => 'Índice de vista previa',
			'fileInfo.packetLength' => 'Longitud del paquete',
			'fileInfo.filePresent' => 'Archivo presente',
			'fileInfo.fileReadable' => 'Legible por el servidor',
			'fileInfo.streamPath' => 'Ruta del flujo',
			'fileInfo.optimizedForStreaming' => 'Optimizado para transmisión',
			'fileInfo.has64bitOffsets' => 'Desplazamientos de 64 bits',
			'fileInfo.protocol' => 'Protocolo',
			'fileInfo.mediaType' => 'Tipo de medio',
			'fileInfo.sourceKind' => 'Tipo de origen',
			'fileInfo.optimizedVersion' => 'Versión optimizada',
			'fileInfo.optimizationTarget' => 'Destino de optimización',
			'fileInfo.deletedAt' => 'Eliminado',
			'fileInfo.remoteSource' => 'Origen remoto',
			'fileInfo.infiniteStream' => 'Flujo infinito',
			'fileInfo.directPlay' => 'Reproducción directa',
			'fileInfo.directStream' => 'Flujo directo',
			'fileInfo.transcoding' => 'Transcodificación',
			'fileInfo.etag' => 'ETag',
			'fileInfo.versionId' => 'ID de versión',
			'fileInfo.fileId' => 'ID de archivo',
			'fileInfo.defaultAudioTrack' => 'Pista de audio predeterminada',
			'fileInfo.defaultSubtitleTrack' => 'Pista de subtítulos predeterminada',
			'fileInfo.subtitlesOff' => 'Desactivados',
			'fileInfo.flagDefault' => 'Predeterminada',
			'fileInfo.flagForced' => 'Forzada',
			'fileInfo.flagSelected' => 'Seleccionada',
			'fileInfo.flagExternal' => 'Externa',
			'fileInfo.flagHearingImpaired' => 'Para personas con discapacidad auditiva',
			'fileInfo.flagDub' => 'Doblaje',
			'fileInfo.flagOriginal' => 'Original',
			'fileInfo.channelsMono' => 'Mono',
			'fileInfo.dolbyVisionProfile' => ({required Object profile}) => 'Perfil ${profile}',
			'mediaMenu.markAsWatched' => 'Marcar como visto',
			'mediaMenu.markAsUnwatched' => 'Marcar como no visto',
			'mediaMenu.removeFromContinueWatching' => 'Eliminar de Seguir viendo',
			'mediaMenu.viewDetails' => 'Ver detalles',
			'mediaMenu.goToSeries' => 'Ir a la serie',
			'mediaMenu.shufflePlay' => 'Reproducción aleatoria',
			'mediaMenu.shuffleNotAvailableOffline' => 'La reproducción aleatoria no está disponible sin conexión',
			'mediaMenu.fileInfo' => 'Información del archivo',
			'mediaMenu.deleteEpisodeFromServer' => 'Eliminar el episodio del servidor',
			'mediaMenu.deleteSeasonFromServer' => 'Eliminar la temporada del servidor',
			'mediaMenu.deleteShowFromServer' => 'Eliminar la serie del servidor',
			'mediaMenu.deleteMovieFromServer' => 'Eliminar la película del servidor',
			'mediaMenu.deleteEpisodeTitle' => '¿Eliminar este episodio?',
			'mediaMenu.deleteSeasonTitle' => '¿Eliminar esta temporada?',
			'mediaMenu.deleteShowTitle' => '¿Eliminar esta serie?',
			'mediaMenu.deleteMovieTitle' => '¿Eliminar esta película?',
			'mediaMenu.deleteEpisodeConfirm' => 'Eliminar episodio',
			'mediaMenu.deleteSeasonConfirm' => 'Eliminar temporada',
			'mediaMenu.deleteShowConfirm' => 'Eliminar serie',
			'mediaMenu.deleteMovieConfirm' => 'Eliminar película',
			'mediaMenu.deleteAnyway' => 'Eliminar de todos modos',
			'mediaMenu.confirmDeleteTarget' => ({required Object title}) => '¿Eliminar definitivamente ${title} de tu servidor?',
			'mediaMenu.deleteMultipleWarning' => 'Esto incluye todos los episodios y sus archivos.',
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: 'Esto elimina el único episodio que contiene y su archivo.', other: 'Esto elimina los ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episodios que contiene y sus archivos.', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: 'Este elemento se almacena en ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} archivo, que se eliminará.', other: 'Este elemento se almacena en ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} archivos, y todos se eliminarán.', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episodio más se almacena en el mismo archivo y también se eliminará:', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episodios más se almacenan en el mismo archivo y también se eliminarán:', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'PlezyNG no pudo comprobar qué archivos se eliminarán, por lo que podría borrar más de lo indicado arriba. Cancela y vuelve a intentarlo, o elimina de todos modos.',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'Tu servidor no proporcionó los detalles del archivo de este elemento, por lo que PlezyNG no puede comprobar qué archivos se eliminarán. Podría borrar más de lo indicado arriba.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Elemento multimedia eliminado con éxito',
			'mediaMenu.mediaFailedToDelete' => 'Error al eliminar el elemento multimedia',
			'mediaMenu.rate' => 'Calificar',
			'mediaMenu.playFromBeginning' => 'Reproducir desde el inicio',
			'mediaMenu.playVersion' => 'Reproducir versión...',
			'rateSheet.title' => 'Calificar',
			'rateSheet.server' => 'Servidor',
			'rateSheet.favorite' => 'Favorito',
			'rateSheet.favorited' => 'Marcado como favorito',
			'rateSheet.saved' => 'Guardado',
			'rateSheet.notAvailable' => 'No se encontró coincidencia',
			'rateSheet.noConnectedServices' => 'Conecta un servicio en Configuración para valorar el contenido en él.',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, película',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, serie de TV',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'visto',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} por ciento visto',
			'accessibility.mediaCardUnwatched' => 'no visto',
			'accessibility.tapToPlay' => 'Toca para reproducir',
			'accessibility.decrease' => 'Disminuir',
			'accessibility.increase' => 'Aumentar',
			'accessibility.decreaseValue' => ({required Object label}) => 'Disminuir ${label}',
			'accessibility.increaseValue' => ({required Object label}) => 'Aumentar ${label}',
			'accessibility.hue' => 'Tono',
			'accessibility.saturation' => 'Saturación',
			'accessibility.brightness' => 'Brillo',
			'accessibility.hexColor' => 'Color hexadecimal',
			'accessibility.expandText' => 'Expandir texto',
			'accessibility.collapseText' => 'Contraer texto',
			'accessibility.alphabetNavigation' => 'Navegación alfabética',
			'accessibility.alphabetScrollHint' => 'Desliza hacia arriba o abajo para avanzar por letra',
			'accessibility.rowColumnPosition' => ({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Fila ${row} de ${rowCount}, columna ${column} de ${columnCount}',
			'accessibility.rowPosition' => ({required Object row, required Object rowCount}) => 'Fila ${row} de ${rowCount}',
			'accessibility.autoScrollPlay' => 'Iniciar desplazamiento automático',
			'accessibility.autoScrollPause' => 'Pausar desplazamiento automático',
			'accessibility.hueShort' => 'H',
			'accessibility.saturationShort' => 'S',
			'accessibility.valueShort' => 'V',
			'accessibility.red' => 'Red',
			'accessibility.green' => 'Verde',
			'accessibility.blue' => 'azul',
			'accessibility.redShort' => 'R',
			'accessibility.greenShort' => 'G',
			'accessibility.blueShort' => 'B',
			'accessibility.colorModeHsv' => 'HSV',
			'accessibility.colorModeRgb' => 'RGB',
			'accessibility.title' => 'Accesibilidad',
			'accessibility.summary' => 'Texto, contraste, movimiento y controles',
			'accessibility.systemHint' => 'Las configuraciones de accesibilidad de su dispositivo se aplican siempre. Estas opciones añaden ajustes a lo largo de PlezyNG.',
			'accessibility.readability' => 'Leer y visibilidad',
			'accessibility.textSize' => 'Tamaño de texto adicional',
			'accessibility.preview' => 'Encuentra tu siguiente historia. leer, escuchar y ver a tu propio ritmo.',
			'accessibility.boldText' => 'Interface de texto',
			'accessibility.highContrast' => 'El alto contraste',
			'accessibility.highContrastHint' => 'Texto más fuerte, etiquetas y indicadores de foco en superficies de luz o oscuridad.',
			'accessibility.interaction' => 'Movimiento y interacción',
			'accessibility.reduceMotion' => 'Reducir movimiento',
			'accessibility.reduceMotionHint' => 'Detener el movimiento del indicador de foco, las transiciones de página y los efectos decorativos.',
			'accessibility.largeTargets' => 'Objetivos de mayor toque',
			'accessibility.largeTargetsHint' => 'Dale controles compartidos más espacio para el toque y la navegación asistiva.',
			'accessibility.navigationHint' => 'Usa Tab y Shift+Tab para moverte entre los controles, Enter o la barra espaciadora para activarlos y Escape o Atrás para cerrar. El zoom y las preferencias de lectura están disponibles cuando hay un libro abierto.',
			'accessibility.textSizeDescription' => 'Escala el texto de la interfaz en PlezyNG además de la configuración de tamaño del texto del sistema de su dispositivo.',
			'accessibility.boldTextHint' => 'Utilice un peso más pesado para las etiquetas de interfaz y los mensajes para que sean más fáciles de distinguir.',
			'tooltips.shufflePlay' => 'Reproducción aleatoria',
			'tooltips.playTrailer' => 'Reproducir tráiler',
			'tooltips.markAsWatched' => 'Marcar como visto',
			'tooltips.markAsUnwatched' => 'Marcar como no visto',
			'audioTracks.track' => ({required Object n}) => 'Pista de audio ${n}',
			'videoControls.audioLabel' => 'Audio',
			'videoControls.subtitlesLabel' => 'Subtítulos',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.letterbox' => 'Con bandas negras',
			'videoControls.fillScreen' => 'Llenar pantalla',
			'videoControls.stretch' => 'Estirar',
			'videoControls.lockRotation' => 'Bloquear rotación',
			'videoControls.unlockRotation' => 'Desbloquear rotación',
			'videoControls.timerActive' => 'Temporizador activo',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'La reproducción se pausará en ${duration}',
			'videoControls.sleepTimerEndOfVideo' => 'Fin del video actual',
			'videoControls.sleepTimerStopAtHeader' => 'Detener en',
			'videoControls.sleepTimerDurationHeader' => 'Temporizador',
			'videoControls.playbackWillPauseAtEnd' => 'La reproducción se pausará al final de este video',
			'videoControls.stillWatching' => '¿Sigues viendo?',
			'videoControls.pausingIn' => ({required Object seconds}) => 'Se pausará en ${seconds}s',
			'videoControls.continueWatching' => 'Continuar',
			'videoControls.autoPlayNext' => 'Reproducir siguiente automáticamente',
			'videoControls.playNext' => 'Reproducir siguiente',
			'videoControls.playButton' => 'Reproducir',
			'videoControls.pauseButton' => 'Pausar',
			'videoControls.playbackPaused' => 'En pausa',
			'videoControls.playbackResumed' => 'Reproduciendo',
			'videoControls.loadingVideo' => 'Cargando el vídeo',
			'videoControls.showPlaybackControls' => 'Mostrar controles de reproducción',
			'videoControls.hidePlaybackControls' => 'Ocultar controles de reproducción',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'Retroceder ${seconds} segundos',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'Avanzar ${seconds} segundos',
			'videoControls.previousButton' => 'Episodio anterior',
			'videoControls.nextButton' => 'Episodio siguiente',
			'videoControls.previousChapterButton' => 'Capítulo anterior',
			'videoControls.nextChapterButton' => 'Capítulo siguiente',
			'videoControls.muteButton' => 'Silenciar',
			'videoControls.unmuteButton' => 'Activar sonido',
			'videoControls.settingsButton' => 'Ajustes de reproducción',
			'videoControls.tracksButton' => 'Audio y subtítulos',
			'videoControls.chaptersButton' => 'Capítulos',
			'videoControls.versionQualityButton' => 'Versión y calidad',
			'videoControls.versionColumnHeader' => 'Versión',
			'videoControls.qualityColumnHeader' => 'Calidad',
			'videoControls.qualityOriginal' => 'Original',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => 'Transcodificación no disponible — reproduciendo calidad original',
			'videoControls.subtitleUnavailableFallback' => 'No se pudieron cargar los subtítulos seleccionados — continuando sin subtítulos',
			'videoControls.pipButton' => 'Modo de imagen en imagen',
			'videoControls.aspectRatioButton' => 'Relación de aspecto',
			'videoControls.ambientLighting' => 'Iluminación ambiental',
			'videoControls.fullscreenButton' => 'Entrar en pantalla completa',
			'videoControls.exitFullscreenButton' => 'Salir de pantalla completa',
			'videoControls.alwaysOnTopButton' => 'Siempre visible',
			'videoControls.rotationLockButton' => 'Bloqueo de rotación',
			_ => null,
		} ?? switch (path) {
			'videoControls.lockScreen' => 'Bloquear pantalla',
			'videoControls.screenLockButton' => 'Bloqueo de pantalla',
			'videoControls.timelineSlider' => 'Línea de tiempo del video',
			'videoControls.volumeSlider' => 'Nivel de volumen',
			'videoControls.endsAt' => ({required Object time}) => 'Termina a las ${time}',
			'videoControls.pipActive' => 'Reproduciendo en modo de imagen en imagen',
			'videoControls.pipFailed' => 'No se pudo iniciar el modo de imagen en imagen',
			'videoControls.screenshotSaved' => 'Captura de pantalla guardada',
			'videoControls.screenshotFailed' => 'No se pudo hacer la captura de pantalla',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Zoom ${percent}%',
			'videoControls.volumePercent' => ({required Object percent}) => 'Volumen ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'Requiere Android 8.0 o más reciente',
			'videoControls.pipErrors.iosVersion' => 'Requiere iOS 15.0 o más reciente',
			'videoControls.pipErrors.permissionDisabled' => 'El modo de imagen en imagen está desactivado. Actívalo en los ajustes del sistema.',
			'videoControls.pipErrors.notSupported' => 'El dispositivo no admite el modo de imagen en imagen',
			'videoControls.pipErrors.voSwitchFailed' => 'No se pudo cambiar la salida de video para el modo de imagen en imagen',
			'videoControls.pipErrors.failed' => 'No se pudo iniciar el modo de imagen en imagen',
			'videoControls.pipErrors.prepareFailed' => 'No se pudo preparar el modo de imagen en imagen',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Ocurrió un error: ${error}',
			'videoControls.chapters' => 'Capítulos',
			'videoControls.noChaptersAvailable' => 'No hay capítulos disponibles',
			'videoControls.queue' => 'Cola',
			'videoControls.noQueueItems' => 'No hay elementos en la cola',
			'videoControls.noAudioDevicesAvailable' => 'No hay dispositivos de audio disponibles',
			'videoControls.searchSubtitles' => 'Buscar subtítulos',
			'videoControls.language' => 'Idioma',
			'videoControls.noSubtitlesFound' => 'No se encontraron subtítulos',
			'videoControls.subtitleDownloaded' => 'Subtítulo descargado',
			'videoControls.subtitleDownloadedNotApplied' => 'El subtítulo se descargó, pero no se pudo seleccionar',
			'videoControls.subtitleDownloadFailed' => 'Error al descargar subtítulo',
			'videoControls.searchLanguages' => 'Buscar idiomas...',
			'videoControls.skipIntro' => 'Saltar intro',
			'videoControls.skipCredits' => 'Saltar créditos',
			'videoControls.nextEpisode' => 'Episodio siguiente',
			'videoControls.subtitleTrack' => ({required Object n}) => 'Pista ${n}',
			'videoControls.subtitleFile' => ({required Object name}) => 'Subtítulo ${name}',
			'videoControls.forcedTrack' => ({required Object label}) => '${label} (Forzada)',
			'videoControls.osdSubtitlesOff' => 'Subtítulos: desactivados',
			'videoControls.osdSubtitles' => ({required Object track}) => 'Subtítulos: ${track}',
			'videoControls.osdAudio' => ({required Object track}) => 'Audio: ${track}',
			'videoControls.frameCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} Frame', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} cuadros', ), 
			'videoControls.trackSelectionTitle' => 'Elegir los rasgos antes de Playback',
			'videoControls.trackSelectionAuto' => 'Selección automática',
			'videoControls.openMiniPlayer' => 'Mini jugador abierto',
			'videoControls.returnToFullPlayer' => 'Volver al jugador completo',
			'videoControls.loadSubtitleFile' => 'Cargar el archivo subtitle.',
			'videoControls.subtitleLoadFailed' => 'No se descarga el archivo subtitle',
			'videoControls.skipAds' => 'Descargar Ads',
			'messages.markedAsWatched' => 'Marcado como visto',
			'messages.markedAsUnwatched' => 'Marcado como no visto',
			'messages.markedAsWatchedOffline' => 'Marcado como visto (se sincronizará al estar en línea)',
			'messages.markedAsUnwatchedOffline' => 'Marcado como no visto (se sincronizará al estar en línea)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Eliminado automáticamente: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: 'Se eliminó automáticamente ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} descarga vista', other: 'Se eliminaron automáticamente ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} descargas vistas', ), 
			'messages.removedFromContinueWatching' => 'Eliminado de Seguir Viendo',
			'messages.errorLoading' => ({required Object error}) => 'Error: ${error}',
			'messages.searchPartialResults' => 'Algunos servidores de medios no se pudieron buscar. Se muestran los resultados disponibles.',
			'messages.streamInterrupted' => 'La reproducción se interrumpió. Pulsa reproducir o avanza para volver a intentarlo.',
			'messages.liveStreamInterrupted' => 'La transmisión en vivo se interrumpió. Pulsa reproducir para volver a intentarlo.',
			'messages.fileInfoNotAvailable' => 'Información de archivo no disponible',
			'messages.playbackAuthenticationRequired' => 'Vuelve a iniciar sesión en el servidor multimedia para reproducir este elemento.',
			'messages.playbackServerUnavailable' => 'El servidor multimedia no está disponible. Inténtalo de nuevo más tarde.',
			'messages.playbackDataInvalid' => 'El servidor devolvió información de reproducción no válida.',
			'messages.playbackCancelled' => 'Se canceló la reproducción.',
			'messages.playbackFailed' => 'No se pudo iniciar la reproducción.',
			'messages.playbackFailedDetail' => ({required Object error}) => 'No se pudo iniciar la reproducción: ${error}',
			'messages.audioOutputFailed' => 'La salida de audio dejó de responder. Comprueba la conexión de audio del televisor o receptor; si otras aplicaciones tampoco tienen sonido, reinicia el dispositivo.',
			'messages.mediaUnavailable' => 'Este contenido ya no está disponible.',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Error al cargar la información del archivo: ${error}',
			'messages.errorLoadingSeries' => 'Error al cargar la serie',
			'messages.musicNotSupported' => 'La reproducción de música aún no es compatible',
			'messages.noDescriptionAvailable' => 'No hay descripción disponible',
			'messages.noProfilesAvailable' => 'No hay perfiles disponibles',
			'messages.contactAdminForProfiles' => 'Contacta a tu administrador del servidor para añadir perfiles',
			'messages.unableToDetermineLibrarySection' => 'No se puede determinar la sección de biblioteca para este elemento',
			'messages.logsCleared' => 'Registros borrados',
			'messages.logsCopied' => 'Registros copiados al portapapeles',
			'messages.noLogsAvailable' => 'No hay registros disponibles',
			'messages.libraryScanning' => ({required Object title}) => 'Escaneando "${title}"...',
			'messages.libraryScanStarted' => ({required Object title}) => 'Escaneo de biblioteca iniciado para "${title}"',
			'messages.libraryScanFailed' => ({required Object error}) => 'Error al escanear biblioteca: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => 'Actualizando metadatos de "${title}"...',
			'messages.metadataRefreshStarted' => ({required Object title}) => 'Actualización de metadatos iniciada para "${title}"',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'Error al actualizar metadatos: ${error}',
			'messages.logoutConfirm' => '¿Estás seguro de que quieres cerrar sesión?',
			'messages.noSeasonsFound' => 'No se encontraron temporadas',
			'messages.seasonsLoadFailed' => 'No se pudieron cargar las temporadas',
			'messages.noEpisodesFound' => 'No se encontraron episodios en la primera temporada',
			'messages.noEpisodesFoundGeneral' => 'No se encontraron episodios',
			'messages.episodesLoadFailed' => 'No se pudieron cargar los episodios',
			'messages.noResultsFound' => 'No se encontraron resultados',
			'messages.sleepTimerSet' => ({required Object label}) => 'Temporizador establecido en ${label}',
			'messages.noItemsAvailable' => 'No hay elementos disponibles',
			'messages.failedToCreatePlayQueueNoItems' => 'No se pudo crear la cola de reproducción: no hay elementos',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Error al ${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Cambiando a reproductor compatible...',
			'messages.serverLimitTitle' => 'Error de reproducción',
			'messages.serverLimitBody' => 'Error del servidor (HTTP 500). Un límite de ancho de banda/transcodificación probablemente rechazó esta sesión. Pide al propietario que lo ajuste.',
			'messages.mediaUnreadableTitle' => 'Archivo no disponible',
			'messages.mediaUnreadableBody' => 'El servidor encontró este elemento pero no pudo leer su archivo (HTTP 404). Es probable que el archivo se haya movido o eliminado, o que su almacenamiento esté sin conexión. Pide al propietario del servidor que revise el archivo y vuelva a escanear la biblioteca.',
			'messages.serverBusyTitle' => 'Reproducción no disponible',
			'messages.serverBusyBody' => 'El servidor siguió rechazando la reproducción de este archivo (HTTP 503). Puede que se esté reiniciando, esté ocupado o que el almacenamiento del archivo no esté disponible. Inténtalo de nuevo dentro de un momento; si sigue ocurriendo, pide al propietario del servidor que revise el servidor y el almacenamiento del archivo.',
			'messages.playbackNotAllowedTitle' => 'Reproducción no permitida',
			'messages.playbackNotAllowedBody' => 'El servidor se negó a transmitir este elemento (HTTP 403). Es posible que tu cuenta no tenga permiso para reproducirlo o que el servidor solo permita la reproducción en su red local.',
			'messages.logsUploaded' => 'Registros subidos',
			'messages.logsUploadFailed' => 'Error al subir registros',
			'messages.logId' => 'ID de registro',
			'messages.burnedSubtitlesUseMenu' => 'Los subtítulos están incrustados en esta transmisión. Cámbialos desde el menú de subtítulos.',
			'messages.noVideoUrl' => 'No hay ninguna URL de vídeo disponible',
			'messages.playbackNoMediaSources' => 'El servidor no devolvió ninguna fuente multimedia reproducible',
			'messages.playbackDataNotPrepared' => 'La reproducción se inició antes de que sus datos estuvieran listos',
			'messages.streamSelectionUnavailable' => 'La selección de flujos no está disponible para esta fuente',
			'messages.streamSelectionFailed' => 'No se pudieron aplicar los flujos seleccionados',
			'messages.trackSelectionNotRemembered' => 'Esta selección de pista solo se aplica a la reproducción actual.',
			'messages.serverUnavailableForProfile' => 'No hay ningún servidor disponible para el perfil activo',
			'subtitlingStyling.previewSample' => 'El rápido fox marrón salta sobre el perro lazo',
			'subtitlingStyling.text' => 'Texto',
			'subtitlingStyling.border' => 'Borde',
			'subtitlingStyling.background' => 'Fondo',
			'subtitlingStyling.fontSize' => 'Tamaño de fuente',
			'subtitlingStyling.textColor' => 'Color del texto',
			'subtitlingStyling.borderSize' => 'Tamaño del borde',
			'subtitlingStyling.borderColor' => 'Color del borde',
			'subtitlingStyling.backgroundOpacity' => 'Opacidad del fondo',
			'subtitlingStyling.backgroundColor' => 'Color del fondo',
			'subtitlingStyling.position' => 'Posición',
			'subtitlingStyling.assOverride' => 'Sobreescritura ASS',
			'subtitlingStyling.overrideScale' => 'Escala',
			'subtitlingStyling.overrideForce' => 'Forzar',
			'subtitlingStyling.overrideStrip' => 'Quitar estilos',
			'subtitlingStyling.positionTop' => 'Arriba',
			'subtitlingStyling.positionBottom' => 'Abajo',
			'subtitlingStyling.useMargins' => 'Usar márgenes',
			'subtitlingStyling.useMarginsDescription' => 'Permitir subtítulos de texto en el espacio fuera del video. Los subtítulos con estilo pueden mantener su posición original.',
			'subtitlingStyling.anchorToScreen' => 'Anclar a la pantalla',
			'subtitlingStyling.anchorToScreenDescription' => 'Muestra los subtítulos de texto en las barras negras situadas debajo del vídeo panorámico',
			'subtitlingStyling.bold' => 'Negrita',
			'subtitlingStyling.italic' => 'Cursiva',
			'subtitlingStyling.renderResolution' => 'Resolución de renderizado',
			'subtitlingStyling.renderResolutionScreen' => 'Resolución de pantalla',
			'subtitlingStyling.renderResolutionVideo' => 'Resolución del video',
			'subtitlingStyling.fontSizeDescription' => 'Configure el tamaño de texto del subtitulo en este dispositivo.',
			'subtitlingStyling.textColorDescription' => 'Seleccione el color utilizado para el texto subtitulado.',
			'subtitlingStyling.borderSizeDescription' => 'Configure el espesor de la salida alrededor del texto subtitulado.',
			'subtitlingStyling.borderColorDescription' => 'Seleccione el color utilizado para la subtitulación.',
			'subtitlingStyling.backgroundColorDescription' => 'Seleccione el color detrás del texto subtitulado.',
			'subtitlingStyling.backgroundOpacityDescription' => 'Configure cuán transparente es el fondo del subtítulo: 0% es claro y 100% sólido.',
			'subtitlingStyling.positionDescription' => 'Move los subtítulos verticalmente. 0% es la parte superior del vídeo y 100% es el fondo.',
			'subtitlingStyling.assOverrideDescription' => 'Seleccione si el jugador sigue, ajusta, reemplaza o remove el estilo incorporado en los subtítulos de ASS.',
			'subtitlingStyling.assOverrideOptions.no' => 'Mantenga las letras, colores, tamaños y ubicaciones escritas en el archivo subtitular.',
			'subtitlingStyling.assOverrideOptions.yes' => 'Permite que las configuraciones de estilo del subtitulo del jugador ajusten los subtitulos ASS.',
			'subtitlingStyling.assOverrideOptions.scale' => 'Aplicar el estilo del jugador y la escala de los tamaños incorporados para corresponder a las dimensiones de vídeo.',
			'subtitlingStyling.assOverrideOptions.force' => 'Reemplaza los estilos de ASS incorporados con el estilo del subtitulo del jugador.',
			'subtitlingStyling.assOverrideOptions.strip' => 'Remove el formato de ASS incorporado y haga claramente el texto subtitulario.',
			'subtitlingStyling.renderResolutionDescription' => 'Seleccione la resolución utilizada para rasterizar la imagen y los subtítulos de ASS. Escalas Android inferiores pueden reducir el trabajo de rendimiento pero se vean más suaves.',
			'subtitlingStyling.renderResolutionOptions.screen' => 'Render a la resolución de superficie completa para el resultado más agudo.',
			'subtitlingStyling.renderResolutionOptions.video' => 'Render usando la resolución de vídeo como referencia, lo que puede reducir el trabajo en pantallas de alta resolución.',
			'subtitlingStyling.renderResolutionOptions.threeQuarter' => 'Render al 75% de la resolución de superficie de la pantalla para una reducción modesta del rendimiento.',
			'subtitlingStyling.renderResolutionOptions.half' => 'Render al 50% de la resolución de la superficie de la pantalla para reducir el trabajo, con lados más suaves.',
			'subtitlingStyling.renderResolutionOptions.third' => 'Render a un tercio de la resolución de superficie de la pantalla para reducir el trabajo, con lados más suaves.',
			'subtitlingStyling.renderResolutionOptions.quarter' => 'Render a un cuarto de la resolución de superficie de la pantalla para reducir el trabajo, con el resultado más suave.',
			'subtitlingStyling.boldDescription' => 'Toma el texto en un peso más pesado.',
			'subtitlingStyling.italicDescription' => 'Descargar subtítulos en italiano.',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => 'Ajustes avanzados del reproductor de video',
			'mpvConfig.presets' => 'Preajustes',
			'mpvConfig.noPresets' => 'No hay preajustes guardados',
			'mpvConfig.saveAsPreset' => 'Guardar como preajuste...',
			'mpvConfig.presetName' => 'Nombre del preajuste',
			'mpvConfig.presetNameHint' => 'Introduce un nombre para este preajuste',
			'mpvConfig.loadPreset' => 'Cargar',
			'mpvConfig.deletePreset' => 'Eliminar',
			'mpvConfig.presetSaved' => 'Preajuste guardado',
			'mpvConfig.presetLoaded' => 'Preajuste cargado',
			'mpvConfig.presetDeleted' => 'Preajuste eliminado',
			'mpvConfig.confirmDeletePreset' => '¿Estás seguro de que quieres eliminar este preajuste?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan\nhwdec=auto\n# comment',
			'mpvConfig.lineHint' => 'option=value',
			'mpvConfig.addLine' => 'Añadir línea',
			'mpvConfig.removeLine' => 'Eliminar línea',
			'mpvConfig.embeddedVoHint' => 'vo, gpu-context y gpu-api se ignoran en Linux: el vídeo integrado siempre se renderiza mediante vo=libmpv en el plano de vídeo, y gpu-next (que los shaders de cómputo como ArtCNN necesitan) no puede ejecutarse integrado.',
			'dialog.confirmAction' => 'Confirmar acción',
			'profiles.addPlezyProfile' => 'Añadir perfil de PlezyNG',
			'profiles.switchingProfile' => 'Cambiando de perfil…',
			'profiles.deleteThisProfileTitle' => '¿Eliminar este perfil?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => 'Eliminar ${displayName}. Las conexiones no se verán afectadas.',
			'profiles.active' => 'Activo',
			'profiles.manage' => 'Administrar',
			'profiles.delete' => 'Eliminar',
			'profiles.signOut' => 'Cerrar sesión',
			'profiles.signOutPlexTitle' => '¿Cerrar sesión de Plex?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => '¿Eliminar ${displayName} y todos los usuarios de Plex Home? Puedes iniciar sesión de nuevo cuando quieras.',
			'profiles.signOutPlexDeleteDownloads' => 'Eliminar también las descargas',
			'profiles.signOutPlexDeleteDownloadsDescription' => 'De lo contrario, se conservarán en este dispositivo y volverán a estar disponibles cuando inicies sesión de nuevo en esta cuenta.',
			'profiles.signedOutPlex' => 'Sesión de Plex cerrada.',
			'profiles.signOutFailed' => 'Error al cerrar sesión.',
			'profiles.sectionTitle' => 'Perfiles',
			'profiles.summarySingle' => 'Añade perfiles para mezclar usuarios gestionados e identidades locales',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} perfiles · activo: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} perfiles',
			'profiles.removeConnectionTitle' => '¿Eliminar conexión?',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => 'Eliminar el acceso de ${displayName} a ${connectionLabel}. Los demás perfiles lo conservan.',
			'profiles.deleteProfileTitle' => '¿Eliminar perfil?',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => 'Eliminar ${displayName} y sus conexiones. Los servidores seguirán disponibles.',
			'profiles.profileNameLabel' => 'Nombre del perfil',
			'profiles.pinProtectionLabel' => 'Protección con PIN',
			'profiles.copyAutomationLink' => 'Copia Android enlace de automatización',
			'profiles.copyAutomationLinkDescription' => 'Seleccione este perfil desde una intención o automatización Android.',
			'profiles.automationLinkCopied' => 'El perfil de la automatización de enlace se copia.',
			'profiles.pinManagedByPlex' => 'PIN gestionado por Plex. Edita en plex.tv.',
			'profiles.noPinSetEditOnPlex' => 'Sin PIN establecido. Para requerir uno, edita el usuario Home en plex.tv.',
			'profiles.setPin' => 'Establecer PIN',
			'profiles.setPinTitle' => 'Establecer PIN',
			'profiles.confirmPinTitle' => 'Confirmar PIN',
			'profiles.pinSet' => 'PIN establecido',
			'profiles.changePin' => 'Cambiar',
			'profiles.removePin' => 'Eliminar',
			'profiles.connectionsLabel' => 'Conexiones',
			'profiles.add' => 'Añadir',
			'profiles.deleteProfileButton' => 'Eliminar perfil',
			'profiles.noConnectionsHint' => 'Sin conexiones — añade una para usar este perfil.',
			'profiles.noConnections' => 'Sin conexiones',
			'profiles.plexHomeAccount' => 'Cuenta Plex Home',
			'profiles.plexAccountChip' => ({required Object account}) => 'Cuenta Plex: ${account}',
			'profiles.plexAccountUserChip' => ({required Object user, required Object account}) => '${user} a través de ${account}',
			'profiles.connectionDefault' => 'Predeterminada',
			'profiles.connectionAs' => ({required Object displayName}) => 'como ${displayName}',
			'profiles.makeDefault' => 'Establecer como predeterminada',
			'profiles.removeConnection' => 'Eliminar',
			'profiles.profileRenamed' => 'Se cambió el nombre del perfil.',
			'profiles.borrowAddTo' => ({required Object displayName}) => 'Añadir a ${displayName}',
			'profiles.borrowExplain' => 'Toma prestada la conexión de otro perfil. Los perfiles protegidos con PIN requieren un PIN.',
			'profiles.borrowEmpty' => 'Todavía no hay ninguna conexión que tomar prestada.',
			'profiles.borrowEmptySubtitle' => 'Conecta primero Plex, Jellyfin o Emby a otro perfil.',
			'profiles.borrowLoadFailed' => 'No se pudieron cargar las conexiones disponibles. Inténtalo de nuevo.',
			'profiles.borrowFromProfile' => ({required Object displayName}) => 'De ${displayName}',
			'profiles.borrowConnectionBorrowed' => 'Conexión tomada prestada.',
			'profiles.borrowFailed' => 'No se pudo tomar prestada la conexión.',
			'profiles.incorrectPin' => 'PIN incorrecto.',
			'profiles.incorrectPinTryAgain' => 'PIN incorrecto. Inténtalo de nuevo.',
			'profiles.sourceProfileMissingParentAccount' => 'Al perfil de origen le falta su cuenta principal.',
			'profiles.failedToLoadHomeUsers' => 'No se pudieron cargar tus usuarios de Plex Home. Comprueba tu conexión e inténtalo de nuevo.',
			'profiles.failedToVerifyPin' => 'No se pudo verificar el PIN.',
			'profiles.newProfile' => 'Nuevo perfil',
			'profiles.profileNameHint' => 'p. ej., Invitados, Niños, Sala familiar',
			'profiles.pinProtectionOptional' => 'Protección con PIN (opcional)',
			'profiles.pinExplain' => 'Se requiere PIN de 4 dígitos para cambiar de perfil.',
			'profiles.continueButton' => 'Continuar',
			'profiles.pinsDontMatch' => 'Los PIN no coinciden',
			'profiles.tokenIdentityMismatch' => 'El token del perfil de Plex correspondía a un servidor inesperado',
			'profiles.settingsLocked' => 'Las configuraciones están bloqueadas para este perfil.',
			'profiles.unlockSettings' => 'Desbloquear las configuraciones',
			'profiles.showExploreForProfile' => 'Mostrar Explora para este perfil',
			'profiles.showExploreForProfileDescription' => 'Desactivar para eliminar Explore de la navegación de este perfil.',
			'connections.sectionTitle' => 'Conexiones',
			'connections.addConnection' => 'Añadir conexión',
			'connections.addConnectionSubtitleNoProfile' => 'Inicia sesión con Plex o conecta un servidor de Jellyfin o Emby',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'Añadir a ${displayName}: Plex, Jellyfin, Emby u otra conexión de perfil',
			'connections.sessionExpiredOne' => ({required Object name}) => 'Sesión caducada para ${name}',
			'connections.sessionExpiredMany' => ({required Object count}) => 'Sesión caducada para ${count} servidores',
			'connections.accessDeniedOne' => ({required Object name}) => '${name} denegó el acceso a esta cuenta',
			'connections.accessDeniedMany' => ({required Object count}) => '${count} servidores denegaron el acceso a esta cuenta',
			'connections.signInAgain' => 'Iniciar sesión de nuevo',
			'connections.editMediaBrowserTitle' => ({required Object product}) => 'Editar conexión de ${product}',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => 'Añade o elimina URL para ${serverName}. PlezyNG usará la URL accesible con menor latencia.',
			'accountPreferences.sectionTitle' => 'Preferencias de cuenta',
			'accountPreferences.hubSubtitleSingle' => ({required Object account}) => 'Opciones de audio, subtítulos y biblioteca guardadas en ${account}',
			'accountPreferences.hubSubtitleMultiple' => ({required Object count}) => 'Opciones de audio, subtítulos y biblioteca guardadas en ${count} cuentas',
			'accountPreferences.pickAccount' => 'Cada cuenta guarda sus propias preferencias. Elige la que quieras editar.',
			'accountPreferences.storedOnAccount' => 'Estas opciones se guardan en la propia cuenta, así que cualquier aplicación con la sesión iniciada las usa, incluido PlezyNG en tus otros dispositivos.',
			'accountPreferences.noAccounts' => 'No hay cuentas que configurar',
			'accountPreferences.noAccountsHint' => 'Inicia sesión con Plex o conecta un servidor de Jellyfin o Emby y las preferencias guardadas en esa cuenta aparecerán aquí.',
			'accountPreferences.unavailable' => 'No se puede acceder a esta cuenta',
			'accountPreferences.loadFailed' => 'No se pudieron cargar estas preferencias',
			'accountPreferences.noPreference' => 'Sin preferencia',
			'accountPreferences.notSet' => 'No establecido',
			'accountPreferences.groups.audioAndSubtitles' => 'Audio y subtítulos',
			'accountPreferences.groups.libraryDisplay' => 'Biblioteca',
			'accountPreferences.groups.personalMedia' => 'Medios personales',
			'accountPreferences.preferredAudioLanguage' => 'Idioma de audio preferido',
			'accountPreferences.autoSelectAudio' => 'Elegir audio por idioma',
			'accountPreferences.autoSelectAudioDescription' => 'Desactivado mantiene la pista de audio que el archivo marca como predeterminada.',
			'accountPreferences.preferredSubtitleLanguage' => 'Idioma de subtítulos preferido',
			'accountPreferences.subtitleMode' => 'Activar subtítulos',
			'accountPreferences.subtitleModes.none' => 'Seleccionado manualmente',
			'accountPreferences.subtitleModes.noneDescription' => 'No activar los subtítulos por sí solo.',
			'accountPreferences.subtitleModes.defaultMode' => 'Seguir las marcas de la pista',
			'accountPreferences.subtitleModes.defaultModeDescription' => 'Usar las marcas de predeterminada y forzada guardadas en cada pista de subtítulos.',
			'accountPreferences.subtitleModes.always' => 'Siempre activado',
			'accountPreferences.subtitleModes.alwaysDescription' => 'Activar una pista de subtítulos en el idioma preferido siempre que exista.',
			'accountPreferences.subtitleModes.onlyForced' => 'Solo subtítulos forzados',
			'accountPreferences.subtitleModes.onlyForcedDescription' => 'Cargar solo las pistas marcadas como forzadas.',
			'accountPreferences.subtitleModes.smart' => 'Mostrar con audio extranjero',
			'accountPreferences.subtitleModes.smartDescription' => 'Activar los subtítulos solo cuando el audio está en otro idioma.',
			'accountPreferences.subtitleAccessibility' => 'Subtítulos SDH',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdh' => 'Preferir subtítulos no SDH',
			'accountPreferences.subtitleAccessibilityOptions.preferSdh' => 'Preferir subtítulos SDH',
			'accountPreferences.subtitleAccessibilityOptions.onlySdh' => 'Solo subtítulos SDH',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdh' => 'Solo subtítulos no SDH',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdhDescription' => 'Preferir los subtítulos estándar cuando tanto las versiones estándar como SDH están disponibles.',
			'accountPreferences.subtitleAccessibilityOptions.preferSdhDescription' => 'Prefiere los subtítulos SDH cuando están disponibles, pero permite que los subtÍTulos estándar como un fallback.',
			'accountPreferences.subtitleAccessibilityOptions.onlySdhDescription' => 'Utilice solo los subtítulos SDH; no caiga de vuelta a los subtítulos estándar.',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdhDescription' => 'Utilice los subtítulos estándar únicamente; excluye los subtítulos SDH.',
			'accountPreferences.forcedSubtitles' => 'Subtítulos forzados',
			'accountPreferences.forcedSubtitleOptions.preferNonForced' => 'Preferir subtítulos no forzados',
			'accountPreferences.forcedSubtitleOptions.preferForced' => 'Preferir subtítulos forzados',
			'accountPreferences.forcedSubtitleOptions.onlyForced' => 'Solo subtítulos forzados',
			'accountPreferences.forcedSubtitleOptions.onlyNonForced' => 'Solo subtítulos no forzados',
			'accountPreferences.forcedSubtitleOptions.preferNonForcedDescription' => 'Prefiere los subtítulos regulares, pero permite las pistas forzadas como una caída.',
			'accountPreferences.forcedSubtitleOptions.preferForcedDescription' => 'Preferir las pistas forzadas cuando están disponibles, pero permitir los subtítulos regulares como un fallback.',
			'accountPreferences.forcedSubtitleOptions.onlyForcedDescription' => 'Utilice sólo las pistas marcadas como forzadas.',
			'accountPreferences.forcedSubtitleOptions.onlyNonForcedDescription' => 'Exclusión de las pistas marcadas como forzadas.',
			'accountPreferences.displayMissingEpisodes' => 'Mostrar episodios faltantes',
			'accountPreferences.displayMissingEpisodesDescription' => 'Enumera los episodios que el servidor conoce pero para los que no tiene ningún archivo.',
			'accountPreferences.hidePlayedInLatest' => 'Ocultar elementos vistos en Recientes',
			'accountPreferences.hidePlayedInLatestDescription' => 'Deja fuera de las filas de Recientes del servidor los elementos que ya has visto.',
			'accountPreferences.displayCollectionsView' => 'Mostrar la vista de colecciones',
			'accountPreferences.displayCollectionsViewDescription' => 'Ofrecer la vista de colecciones del servidor junto a tus bibliotecas.',
			'accountPreferences.rewatchingInNextUp' => 'Mantener las series revistas en A continuación',
			'accountPreferences.rewatchingInNextUpDescription' => 'Cuando termines una serie y la vuelvas a empezar, A continuación seguirá tu revisión en lugar de descartarla.',
			'accountPreferences.watchedIndicator' => 'Indicadores de visto',
			'accountPreferences.watchedIndicatorOptions.none' => 'Nunca',
			'accountPreferences.watchedIndicatorOptions.moviesAndShows' => 'Películas y series de TV',
			'accountPreferences.watchedIndicatorOptions.movies' => 'Solo películas',
			'accountPreferences.watchedIndicatorOptions.shows' => 'Solo series de TV',
			'accountPreferences.watchedIndicatorOptions.noneDescription' => 'No muestras los marcadores observados.',
			'accountPreferences.watchedIndicatorOptions.moviesAndShowsDescription' => 'Mostrar marcadores observados para películas y programas de televisión.',
			'accountPreferences.watchedIndicatorOptions.moviesDescription' => 'Mostrar marcadores observados sólo para las películas.',
			'accountPreferences.watchedIndicatorOptions.showsDescription' => 'Mostrar los marcadores observados sólo para programas de televisión.',
			'accountPreferences.mediaReviewsVisibility' => 'Valoraciones y reseñas',
			'accountPreferences.mediaReviewsOptions.usersAndCritics' => 'Usuarios y críticos',
			'accountPreferences.mediaReviewsOptions.usersOnly' => 'Solo usuarios',
			'accountPreferences.mediaReviewsOptions.criticsOnly' => 'Solo críticos',
			'accountPreferences.mediaReviewsOptions.nobody' => 'Ocultos',
			'accountPreferences.mediaReviewsOptions.usersAndCriticsDescription' => 'Mostrar tanto las calificaciones de los usuarios como las clasificaciones críticas.',
			'accountPreferences.mediaReviewsOptions.usersOnlyDescription' => 'Mostrar calificaciones y reseñas presentadas por los usuarios.',
			'accountPreferences.mediaReviewsOptions.criticsOnlyDescription' => 'Mostrar calificaciones críticas y reseñas.',
			'accountPreferences.mediaReviewsOptions.nobodyDescription' => 'Esconde las calificaciones y las reseñas.',
			'accountPreferences.preferredAudioLanguageDescription' => 'Preferir los rasgos de audio en este idioma cuando el servidor o jugador selecciona automáticamente un rasgo.',
			'accountPreferences.preferredSubtitleLanguageDescription' => 'Preferir los rastreos de subtitulos en este idioma cuando se seleccionan automáticamente.',
			'accountPreferences.subtitleAccessibilityDescription' => 'Seleccione si las capciones de SDH son preferidas o necesarias durante la selección automática de subtitulos.',
			'accountPreferences.forcedSubtitleDescription' => 'Seleccione si las pistas de subtitulos forzados son preferidas o necesarias durante la selección automática.',
			'accountPreferences.watchedIndicatorDescription' => 'Seleccione qué tipos de medios reciben un marcador observado en la interfaz del servidor.',
			'accountPreferences.mediaReviewsVisibilityDescription' => 'Seleccione qué audiencia y calificaciones críticas el servidor muestra en las páginas de los medios.',
			'accountPreferences.subtitleModeDescription' => 'Seleccione cuando los subtítulos se activan automáticamente para esta cuenta del servidor.',
			'accountPreferences.hubDescription' => 'Estas preferencias se almacenan en su cuenta de servidor de medios y pueden aplicarse también a otros clientes.',
			'discover.title' => 'Descubrir',
			'discover.noContentAvailable' => 'No hay contenido disponible',
			'discover.addMediaToLibraries' => 'Añade contenido a tus bibliotecas',
			'discover.continueWatching' => 'Seguir viendo',
			'discover.continueWatchingIn' => ({required Object library}) => 'Seguir viendo en ${library}',
			'discover.nextUp' => 'A continuación',
			'discover.nextUpIn' => ({required Object library}) => 'A continuación en ${library}',
			'discover.recentlyAdded' => 'Añadido recientemente',
			'discover.recentlyAddedIn' => ({required Object library}) => 'Añadido recientemente en ${library}',
			'discover.latestAlbumsIn' => ({required Object library}) => 'Últimos álbumes en ${library}',
			'discover.recentlyPlayedIn' => ({required Object library}) => 'Reproducido recientemente en ${library}',
			'discover.mostPlayedIn' => ({required Object library}) => 'Más reproducido en ${library}',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'T${season}E${episode}',
			'discover.overview' => 'Resumen',
			'discover.cast' => 'Reparto',
			'discover.findNext.title' => 'Encuentra tu próximo favorito',
			'discover.findNext.open' => 'Encuentra tu próximo favorito',
			'discover.findNext.anyTime' => 'Sin límite de tiempo',
			'discover.findNext.timeAvailable' => '¿Cuánto tiempo tienes?',
			'discover.findNext.filters' => 'Elige para este momento',
			'discover.findNext.watch' => 'Ver',
			'discover.findNext.listen' => 'Escuchar',
			'discover.findNext.read' => 'Leer',
			'discover.findNext.finishable' => ({required Object duration}) => 'Se puede terminar en ${duration}',
			'discover.findNext.aboutDuration' => ({required Object duration}) => 'Unos ${duration}',
			'discover.findNext.nextUnit' => ({required Object duration}) => 'Siguiente capítulo · ${duration}',
			'discover.findNext.totalDuration' => ({required Object duration}) => '${duration} en total',
			'discover.findNext.timingVaries' => 'La duración puede variar',
			'discover.findNext.notNow' => 'Ahora no',
			'discover.findNext.swipeHint' => 'Desliza la portada hacia una flecha o usa los botones de abajo.',
			'discover.findNext.saved' => 'Sugerencias guardadas',
			'discover.findNext.savedCount' => ({required Object count}) => 'Sugerencias guardadas · ${count}',
			'discover.findNext.undo' => 'Deshacer',
			'discover.findNext.details' => 'Detalles',
			'discover.findNext.noPicks' => 'Aún no hay nada para elegir',
			'discover.findNext.noPicksHint' => 'Conecta una biblioteca o añade una fuente multimedia para empezar.',
			'discover.findNext.noMatches' => 'Nada encaja en este momento',
			'discover.findNext.noMatchesHint' => 'Prueba otro tipo de contenido o reserva un poco más de tiempo.',
			'discover.findNext.allDone' => 'Ya has visto todas las sugerencias',
			'discover.findNext.allDoneHint' => 'Inicia una nueva selección para volver a ver estas opciones.',
			'discover.findNext.refresh' => 'Buscar otra selección',
			'discover.findNext.sourceReason' => ({required Object source}) => 'De ${source}',
			'discover.findNext.libraryReason' => ({required Object library}) => 'De ${library}',
			'discover.findNext.ownedReason' => 'De tu biblioteca',
			'discover.findNext.liveNow' => 'En emisión',
			'discover.findNext.watchLive' => 'Ver en directo',
			'discover.findNext.filterAnything' => 'Cualquier tipo',
			'discover.findNext.filterWatch' => 'Ver',
			'discover.findNext.filterListen' => 'Escuchar',
			'discover.findNext.filterRead' => 'Leer',
			'discover.findNext.twentyMinutes' => '20 min',
			'discover.findNext.fortyFiveMinutes' => '45 min',
			'discover.findNext.ninetyMinutes' => '90 min',
			'discover.findNext.apply' => 'Aplicar',
			'discover.findNext.openFailed' => 'Esta opción ya no está disponible. Actualiza para comprobarlo de nuevo.',
			'discover.findNext.changeFailed' => 'No se pudo guardar el cambio. Inténtalo de nuevo.',
			'discover.findNext.savedLimit' => 'La lista de sugerencias guardadas está llena. Quita una para guardar otra.',
			'discover.findNext.chooseHint' => 'Abre un título, guárdalo para después o pasa al siguiente.',
			'discover.findNext.howItWorks' => 'Cómo funciona',
			'discover.findNext.notNowHelp' => 'Omite este título por ahora. Seguirá en tu biblioteca.',
			'discover.findNext.saveHelp' => 'Guárdalo en las selecciones guardadas de este perfil en este dispositivo. Guardarlo no lo descarga.',
			'discover.findNext.openHelp' => 'Selecciona la portada para ver los detalles. Usa la acción principal para reproducir, leer o abrir el título.',
			'discover.findNext.controlsHelp' => 'Teclado o mando: enfoca un botón y pulsa Intro o Seleccionar. Deshacer restaura tu última elección.',
			'discover.findNext.artworkLoading' => 'Cargando imagen…',
			'discover.findNext.artworkUnavailable' => 'Imagen no disponible',
			'discover.findNext.savedFeedback' => 'Añadido a las selecciones guardadas',
			'discover.findNext.skippedFeedback' => 'Omitido por ahora',
			'discover.findNext.releaseToConfirm' => 'Suelta para confirmar',
			'discover.findNext.remoteHint' => 'Portada enfocada: ← / → elegir · Seleccionar: detalles · ↑ / ↓ mover el foco',
			'discover.extras' => 'Tráilers y extras',
			'discover.studio' => 'Estudio',
			'discover.rating' => 'Valoración',
			'discover.director' => 'Director',
			'discover.directors' => 'Directores',
			'discover.movie' => 'Película',
			'discover.tvShow' => 'Serie de TV',
			'discover.minutesLeft' => ({required Object minutes}) => 'quedan ${minutes} min',
			'discover.moreLikeThis' => 'Más contenido similar',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} título', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} títulos', ), 
			'discover.person.born' => 'Nacimiento',
			'discover.person.died' => 'Fallecimiento',
			'discover.person.birthplace' => 'Lugar de nacimiento',
			'discover.person.dateWithAge' => ({required Object date, required Object age}) => '${date} (${age} años)',
			'discover.person.dateWithAgeAtDeath' => ({required Object date, required Object age}) => '${date} (a los ${age} años)',
			'errors.searchFailed' => ({required Object error}) => 'Error en la búsqueda: ${error}',
			'errors.searchUnavailable' => 'La búsqueda no pudo alcanzar ningún servidor de medios.',
			'errors.connectionTimeout' => ({required Object context}) => 'Tiempo de conexión agotado al cargar ${context}',
			'errors.connectionFailed' => 'No se puede conectar al servidor multimedia',
			'errors.unableToLoad' => ({required Object context}) => 'No se pudo cargar ${context}. Inténtalo de nuevo.',
			'errors.noClientAvailable' => 'No hay cliente disponible',
			'errors.pleaseEnterToken' => 'Introduce un token',
			'errors.invalidToken' => 'Token no válido',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Error al verificar el token: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Error al cambiar al perfil ${displayName}',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => 'Error al eliminar ${displayName}',
			'errors.failedToRate' => 'No se pudo actualizar la valoración',
			'errors.reasonTimedOut' => 'se agotó el tiempo de conexión',
			'errors.reasonUnreachable' => 'no se pudo contactar con el servidor',
			'errors.reasonRefused' => 'el servidor rechazó la solicitud',
			'errors.reasonNotFound' => 'el elemento ya no está en el servidor',
			'errors.reasonServerError' => 'el servidor informó de un error',
			'errors.reasonCancelled' => 'se canceló la solicitud',
			'errors.reasonUnexpected' => 'se produjo un error inesperado',
			'libraries.playRandomMovie' => 'Juega una película aleatoria',
			'libraries.randomPickFailed' => 'No podía elegir una película aleatoria de esta biblioteca.',
			'libraries.title' => 'Bibliotecas',
			'libraries.fallbackTitle' => 'Biblioteca',
			'libraries.scanLibraryFiles' => 'Escanear archivos de la biblioteca',
			'libraries.scanLibrary' => 'Escanear biblioteca',
			'libraries.analyze' => 'Analizar',
			'libraries.analyzeLibrary' => 'Analizar biblioteca',
			'libraries.refreshMetadata' => 'Actualizar metadatos',
			'libraries.emptyTrash' => 'Vaciar papelera',
			'libraries.emptyingTrash' => ({required Object title}) => 'Vaciando papelera de "${title}"...',
			'libraries.trashEmptied' => ({required Object title}) => 'Papelera vaciada para "${title}"',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'Error al vaciar papelera: ${error}',
			'libraries.analyzing' => ({required Object title}) => 'Analizando "${title}"...',
			'libraries.analysisStarted' => ({required Object title}) => 'Análisis iniciado para "${title}"',
			'libraries.failedToAnalyze' => ({required Object error}) => 'Error al analizar la biblioteca: ${error}',
			'libraries.noLibrariesFound' => 'No se encontraron bibliotecas',
			'libraries.allLibrariesHidden' => 'Todas las bibliotecas están ocultas',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'Bibliotecas ocultas (${count})',
			'libraries.thisLibraryIsEmpty' => 'Esta biblioteca está vacía',
			'libraries.noItemsMatchFilters' => 'Ningún elemento coincide con los filtros activos',
			'libraries.resetFilters' => 'Restablecer filtros',
			'libraries.all' => 'Todos',
			'libraries.clearAll' => 'Borrar todo',
			'libraries.scanLibraryConfirm' => ({required Object title}) => '¿Estás seguro de que quieres escanear "${title}"?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => '¿Estás seguro de que quieres analizar "${title}"?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => '¿Estás seguro de que quieres actualizar los metadatos de "${title}"?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => '¿Estás seguro de que quieres vaciar la papelera de "${title}"?',
			'libraries.manageLibraries' => 'Gestionar bibliotecas',
			'libraries.sort' => 'Ordenar',
			'libraries.sortBy' => 'Ordenar por',
			'libraries.filters' => 'Filtros',
			'libraries.confirmActionMessage' => '¿Estás seguro de que quieres realizar esta acción?',
			'libraries.showLibrary' => 'Mostrar biblioteca',
			'libraries.hideLibrary' => 'Ocultar biblioteca',
			'libraries.libraryOptions' => 'Opciones de biblioteca',
			'libraries.content' => 'contenido de la biblioteca',
			'libraries.selectLibrary' => 'Seleccionar biblioteca',
			'libraries.filtersWithCount' => ({required Object count}) => 'Filtros (${count})',
			'libraries.noRecommendations' => 'No hay recomendaciones disponibles',
			'libraries.noCollections' => 'No hay colecciones en esta biblioteca',
			'libraries.noFoldersFound' => 'No se encontraron carpetas',
			'libraries.folders' => 'carpetas',
			'libraries.tabs.recommended' => 'Recomendado',
			'libraries.tabs.browse' => 'Explorar',
			'libraries.tabs.collections' => 'Colecciones',
			'libraries.tabs.playlists' => 'Listas de reproducción',
			'libraries.groupings.title' => 'Agrupación',
			'libraries.groupings.all' => 'Todo',
			'libraries.groupings.movies' => 'Películas',
			'libraries.groupings.shows' => 'Series',
			'libraries.groupings.seasons' => 'Temporadas',
			'libraries.groupings.episodes' => 'Episodios',
			'libraries.groupings.artists' => 'Artistas',
			'libraries.groupings.albums' => 'Álbumes',
			'libraries.groupings.tracks' => 'Canciones',
			'libraries.groupings.folders' => 'Carpetas',
			'libraries.filterCategories.genre' => 'Género',
			'libraries.filterCategories.year' => 'Año',
			'libraries.filterCategories.contentRating' => 'Clasificación por edad',
			'libraries.filterCategories.tag' => 'Etiqueta',
			'libraries.filterCategories.unwatched' => 'No vistos',
			'libraries.filterCategories.unplayed' => 'No reproducidos',
			_ => null,
		} ?? switch (path) {
			'libraries.filterCategories.favorites' => 'Favoritos',
			'libraries.filterCategories.filePath' => 'Ruta del archivo',
			'libraries.sortLabels.title' => 'Título',
			'libraries.sortLabels.dateAdded' => 'Fecha de adición',
			'libraries.sortLabels.releaseDate' => 'Fecha de estreno',
			'libraries.sortLabels.rating' => 'Valoración',
			'libraries.sortLabels.communityRating' => 'Valoración de la comunidad',
			'libraries.sortLabels.criticRating' => 'Valoración de la crítica',
			'libraries.sortLabels.userRating' => 'Valoración del usuario',
			'libraries.sortLabels.datePlayed' => 'Fecha de reproducción',
			'libraries.sortLabels.playCount' => 'Reproducciones',
			'libraries.sortLabels.productionYear' => 'Año de producción',
			'libraries.sortLabels.runtime' => 'Duración',
			'libraries.sortLabels.officialRating' => 'Clasificación oficial',
			'libraries.sortLabels.premiereDate' => 'Fecha de estreno',
			'libraries.sortLabels.startDate' => 'Fecha de inicio',
			'libraries.sortLabels.airTime' => 'Hora de emisión',
			'libraries.sortLabels.studio' => 'Estudio',
			'libraries.sortLabels.random' => 'Aleatorio',
			'libraries.sortLabels.dateShared' => 'Fecha en que se compartió',
			'libraries.sortLabels.latestEpisodeAirDate' => 'Fecha de emisión del episodio más reciente',
			'libraries.sortLabels.lastEpisodeDateAdded' => 'Fecha en que se añadió el último episodio',
			'libraries.sortLabels.dateDownloaded' => 'Fecha de descarga',
			'libraries.sortLabels.size' => 'Tamaño',
			'libraries.sortLabels.library' => 'Biblioteca',
			'libraries.advancedFilters.include' => 'Incluir',
			'libraries.advancedFilters.exclude' => 'Excluir',
			'libraries.advancedFilters.any' => 'Cualquiera',
			'libraries.advancedFilters.yes' => 'Sí',
			'libraries.advancedFilters.no' => 'No',
			'libraries.advancedFilters.not' => ({required Object value}) => 'No ${value}',
			'libraries.advancedFilters.valueCount' => ({required Object count}) => '${count} seleccionados',
			'libraries.advancedFilters.valueCountExcluded' => ({required Object count}) => '${count} excluidos',
			'libraries.advancedFilters.searchValues' => 'Buscar valores',
			'libraries.advancedFilters.noValues' => 'Sin valores',
			'libraries.advancedFilters.matchContains' => 'Contiene',
			'libraries.advancedFilters.matchNotContains' => 'No contiene',
			'libraries.advancedFilters.matchIs' => 'Es',
			'libraries.advancedFilters.matchIsNot' => 'No es',
			'libraries.advancedFilters.matchBeginsWith' => 'Empieza por',
			'libraries.advancedFilters.matchEndsWith' => 'Termina en',
			'libraries.advancedFilters.textHint' => 'Escribe para filtrar',
			'libraries.advancedFilters.from' => 'Desde',
			'libraries.advancedFilters.to' => 'Hasta',
			'libraries.advancedFilters.range' => ({required Object from, required Object to}) => 'De ${from} a ${to}',
			'libraries.advancedFilters.atLeast' => ({required Object value}) => '${value} o más',
			'libraries.advancedFilters.atMost' => ({required Object value}) => 'Hasta ${value}',
			'libraries.advancedFilters.dateLastDays' => ({required Object count}) => 'Últimos ${count} días',
			'libraries.advancedFilters.dateLastYear' => 'Último año',
			'libraries.advancedFilters.dateOlderThanDays' => ({required Object count}) => 'Hace más de ${count} días',
			'libraries.advancedFilters.dateOlderThanYear' => 'Hace más de un año',
			'libraries.selection.selectItems' => 'Seleccion de artículos',
			'libraries.selection.selectedCount' => ({required Object count}) => '${count} seleccionados',
			'libraries.selection.actions' => 'Acciones Seleccion',
			'libraries.selection.confirmDescendants' => 'Esto cambia todos los episodios en los espectáculos y temporadas seleccionados.',
			'libraries.selection.confirmUnwatched' => 'Esto también borra el progreso de reproducción de los elementos seleccionados.',
			'libraries.selection.confirmCount' => ({required Object count}) => 'El número de artículos seleccionados: ${count}.',
			'libraries.selection.completed' => ({required Object count}) => 'Artículos actualizados: ${count}.',
			'libraries.selection.partialFailure' => ({required Object succeeded, required Object failed}) => 'Actualizado ${succeeded}; fallecido ${failed}. los artículos fallecidos permanecen seleccionados.',
			'about.title' => 'Acerca de',
			'about.openSourceLicenses' => 'Licencias de código abierto',
			'about.versionLabel' => ({required Object version}) => 'Versión ${version}',
			'about.appDescription' => 'Un cliente de Plex, Jellyfin y Emby para Flutter',
			'about.viewLicensesDescription' => 'Ver las licencias de bibliotecas de terceros',
			'about.privacyPolicy' => 'Política de privacidad',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'No se encontraron servidores para ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Error al cargar servidores: ${error}',
			'serverSelection.noValidServers' => 'No se encontraron servidores utilizables en esta cuenta',
			'hubDetail.title' => 'Título',
			'hubDetail.releaseYear' => 'Año de lanzamiento',
			'hubDetail.dateAdded' => 'Añadido el',
			'hubDetail.rating' => 'Valoración',
			'hubDetail.noItemsFound' => 'No se encontraron elementos',
			'logs.clearLogs' => 'Borrar registros',
			'logs.copyLogs' => 'Copiar registros',
			'logs.uploadLogs' => 'Subir registros',
			'logs.saveLogs' => 'Salva los logs a los archivos',
			'logs.logsSaved' => ({required Object path}) => 'Los registros salvos a ${path}',
			'logs.saveLogsFailed' => 'No podía salvar el archivo de registro.',
			'startup.failedTitle' => 'PlezyNG no pudo iniciarse',
			'startup.failedBody' => 'Algo salió mal durante el inicio. Los detalles de abajo indican qué ha fallado.',
			'startup.failedBodyRepairable' => 'El archivo de ajustes guardados de PlezyNG está dañado y debe reconstruirse antes de que PlezyNG pueda iniciarse. Reintentar no servirá: elige Reparar almacenamiento.',
			'startup.phaseLabel' => 'Paso',
			'startup.showDetails' => 'Mostrar detalles',
			'startup.hideDetails' => 'Ocultar detalles',
			'startup.copyDetails' => 'Copiar detalles',
			'startup.detailsCopied' => 'Detalles copiados al portapapeles',
			'startup.uploadDetails' => 'Subir detalles',
			'startup.repairStorage' => 'Reparar almacenamiento',
			'startup.repairTitle' => '¿Reparar los datos guardados?',
			'startup.repairBodyCommon' => 'El archivo de ajustes de PlezyNG está dañado y no puede leerse. La reparación restablece todos los ajustes a sus valores predeterminados.',
			'startup.repairBodyOneCredential' => 'Un inicio de sesión guardado está dañado y no puede leerse. La reparación elimina solo ese; el resto de tus ajustes se mantienen intactos.',
			'startup.repairBodySignInsKept' => 'Tus servidores y perfiles deberían permanecer con la sesión iniciada.',
			'startup.repairBodySignInsLost' => 'La clave que protege tus inicios de sesión guardados no se puede recuperar de este archivo, por lo que tendrás que iniciar sesión de nuevo en cada servidor y perfil. Nada en tu servidor de medios se ve afectado.',
			'startup.repairBodySessionsUncertain' => 'Los rastreadores (MAL, AniList, Simkl, Trakt) y Seerr se guardan por separado y pueden sobrevivir o no. PlezyNG te dirá exactamente qué ha conservado.',
			'startup.repairConfirm' => 'Reparar',
			'startup.repairSucceeded' => 'Almacenamiento reparado',
			'startup.repairNeedsRestart' => 'Almacenamiento reparado: es necesario reiniciar',
			'startup.restartRequiredBody' => 'Tus datos se repararon, pero PlezyNG debe iniciarse de nuevo antes de poder usarlos. Cierra PlezyNG y ábrelo otra vez.',
			'startup.quitPlezy' => 'Salir de PlezyNG',
			'startup.repairFailed' => 'Error en la reparación',
			'startup.repairKeptSignIns' => 'Tus servidores y perfiles siguen con la sesión iniciada.',
			'startup.repairLostSignIns' => 'La clave que protege tus inicios de sesión guardados no se pudo recuperar. Tendrás que iniciar sesión de nuevo en cada servidor y perfil.',
			'startup.repairLostSessions' => 'Se perdió al menos una conexión de rastreador o de Seerr y hay que volver a conectarla.',
			'startup.backupTitle' => 'Se ha guardado una copia del archivo dañado',
			'startup.backupWarning' => 'Contiene tus credenciales de inicio de sesión. No la subas ni la compartas.',
			'startup.deleteBackup' => 'Eliminar copia',
			'startup.backupDeleted' => 'Copia eliminada.',
			'startup.previousFailureTitle' => 'PlezyNG no se inició la última vez',
			'licenses.relatedPackages' => 'Paquetes relacionados',
			'licenses.license' => 'Licencia',
			'licenses.licenseNumber' => ({required Object number}) => 'Licencia ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} licencias',
			'navigation.libraries' => 'Bibliotecas',
			'navigation.downloads' => 'Descargas',
			'navigation.liveTv' => 'TV en vivo',
			'navigation.explore' => 'Explorar',
			'explore.mdblistShelves.manage' => 'Gestión Explora los barrios',
			'explore.mdblistShelves.manageDescription' => 'Seleccione y arregle listas de su cuenta MDBList',
			'explore.mdblistShelves.description' => 'Seleccione listas de películas y televisión públicas de su cuenta MDBList. Crea o copia listas en MDBList, y luego refresca.',
			'explore.mdblistShelves.selected' => 'Cortes seleccionados',
			'explore.mdblistShelves.available' => 'Lista de cuentas disponibles',
			'explore.mdblistShelves.noLists' => 'No hay listas de películas o televisión públicas devueltas. Crea o copia una lista en MDBList, y luego refresca.',
			'explore.mdblistShelves.displayName' => 'Nombre de la muestra Shelf',
			'explore.mdblistShelves.nameHint' => 'Deja blanco para usar el nombre de la lista de fuentes.',
			'explore.mdblistShelves.add' => 'Añadir Shelf',
			'explore.mdblistShelves.save' => 'Salva los chalecos',
			'explore.mdblistShelves.moveUp' => ({required Object title}) => 'Move ${title} arriba',
			'explore.mdblistShelves.moveDown' => ({required Object title}) => 'Move ${title} hacia abajo',
			'explore.mdblistShelves.unavailable' => 'Esta lista no está disponible. retire o eliminar su arca en las configuraciones.',
			'explore.mdblistShelves.rateLimited' => 'MDBList límite de solicitud alcanzado. por favor retire más tarde.',
			'explore.mdblistShelves.loadFailed' => 'No puede cargar las placas. verifique su conexión y retire.',
			'explore.mdblistShelves.saveFailed' => 'No puedo salvar las placas. por favor retire.',
			'explore.mdblistShelves.accountChanged' => 'El perfil o cuenta cambió. reabre estas configuraciones.',
			'explore.mdblistShelves.settingsUnreadable' => 'Las placas ahorradas no se pueden leer. Seleccione las listas de nuevo para reemplazar estas configuraciones.',
			'explore.title' => 'Explorar',
			'explore.selectSource' => 'Seleccionar fuente',
			'explore.rows.watchlist' => 'Lista de seguimiento',
			'explore.rows.recommendedMovies' => 'Películas recomendadas',
			'explore.rows.recommendedShows' => 'Series recomendadas',
			'explore.rows.trendingMovies' => 'Películas en tendencia',
			'explore.rows.trendingShows' => 'Series en tendencia',
			'explore.rows.popularMovies' => 'Películas populares',
			'explore.rows.popularShows' => 'Series populares',
			'explore.rows.trendingAnime' => 'Anime en tendencia',
			'explore.rows.suggestedAnime' => 'Anime sugerido',
			'explore.rows.airingAnime' => 'Mejor anime en emisión',
			'explore.rows.popularAnime' => 'Anime más popular',
			'explore.rows.trending' => 'Tendencias',
			'explore.rows.upcomingMovies' => 'Próximas películas',
			'explore.rows.upcomingShows' => 'Próximas series',
			'explore.status.airing' => 'En emisión',
			'explore.status.ended' => 'Finalizada',
			'explore.status.canceled' => 'Cancelada',
			'explore.status.upcoming' => 'Próximamente',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episodio', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} episodios', ), 
			'explore.cast' => 'Reparto',
			'explore.characters' => 'Personajes',
			'explore.addToWatchlist' => 'Añadir a la lista de seguimiento',
			'explore.removeFromWatchlist' => 'Quitar de la lista de seguimiento',
			'explore.addedToWatchlist' => 'Añadido a la lista de seguimiento',
			'explore.removedFromWatchlist' => 'Eliminado de la lista de seguimiento',
			'explore.watchlistUpdateFailed' => 'No se pudo actualizar la lista de seguimiento',
			'explore.watchlistNoMatch' => 'No se pudo asociar este elemento con una lista de seguimiento',
			'explore.notInLibrary' => 'No está en tu biblioteca',
			'explore.inTheseLibraries' => 'En estas bibliotecas',
			'explore.checkingLibrary' => 'Comprobando tu biblioteca...',
			'explore.libraryCheckFailed' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: 'No se pudo comprobar ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} servidor', other: 'No se pudo comprobar ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} servidores', ), 
			'explore.emptyTitle' => 'Aquí no hay nada todavía',
			'explore.emptyMessage' => ({required Object source}) => 'Las filas de ${source} aparecerán aquí cuando tengan contenido.',
			'explore.searchHint' => ({required Object source}) => 'Buscar en ${source}',
			'explore.searchEmpty' => ({required Object query}) => 'Sin resultados para "${query}"',
			'explore.searchPrompt' => ({required Object source}) => 'Busca películas y series en ${source}.',
			'explore.searchFailed' => 'La búsqueda falló. Comprueba tu conexión e inténtalo de nuevo.',
			'explore.badge.rankPopular' => ({required Object n}) => '#${n} más popular',
			'explore.badge.rankAiring' => ({required Object n}) => '#${n} en emisión',
			'explore.badge.rankRated' => ({required Object n}) => '#${n} puntuado',
			'explore.badge.rankTrending' => ({required Object n}) => '#${n} en tendencia',
			'explore.badge.rankSeasonal' => ({required Object n, required Object season}) => '#${n} en ${season}',
			'explore.badge.watchingNow' => ({required Object n}) => '${n} viendo',
			'explore.badge.available' => 'Disponible',
			'explore.badge.partiallyAvailable' => 'Parcialmente disponible',
			'explore.badge.availableIn4k' => 'Disponible en 4K',
			'explore.badge.requested' => 'Solicitado',
			'explore.badge.pendingApproval' => 'Pendiente de aprobación',
			'explore.badge.processing' => 'Procesando',
			'explore.badge.declined' => 'Rechazado',
			'explore.badge.requestFailed' => 'La solicitud falló',
			'explore.badge.requested4k' => 'Solicitado en 4K',
			'explore.badge.seasonsAvailable' => ({required Object available, required Object total}) => '${available}/${total} temporadas',
			'explore.badge.nextEpisodeIn' => ({required Object episode, required Object duration}) => 'Ep. ${episode} en ${duration}',
			'explore.badge.nextAiringIn' => ({required Object duration}) => 'Siguiente en ${duration}',
			'explore.badge.episodesShort' => ({required Object n}) => '${n} eps',
			'explore.badge.minutesPerEpisode' => ({required Object n}) => '${n} min/ep',
			'explore.badge.adult' => '18+',
			'explore.stats.listed' => ({required Object n}) => '${n} registrados',
			'explore.stats.viewersDay' => ({required Object n}) => '${n} vistos hoy',
			'explore.stats.viewersWeek' => ({required Object n}) => '${n} vistos esta semana',
			'explore.stats.viewersMonth' => ({required Object n}) => '${n} vistos este mes',
			'explore.stats.viewersYear' => ({required Object n}) => '${n} vistos este año',
			'explore.stats.viewersAllTime' => ({required Object n}) => '${n} espectadores',
			'explore.stats.planning' => ({required Object n}) => '${n} tienen previsto verlo',
			'explore.stats.favorited' => ({required Object n}) => '${n} favoritos',
			'explore.stats.dropRate' => ({required Object percent}) => '${percent} lo abandonaron',
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} comentario', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} comentarios', ), 
			'explore.stats.votes' => ({required Object n}) => '${n} votos',
			'explore.stats.watching' => ({required Object n}) => '${n} lo están viendo',
			'explore.stats.completed' => ({required Object n}) => '${n} lo completaron',
			'explore.stats.onHold' => ({required Object n}) => '${n} en pausa',
			'explore.stats.dropped' => ({required Object n}) => '${n} lo abandonaron',
			'explore.season.winter' => 'Invierno',
			'explore.season.spring' => 'Primavera',
			'explore.season.summer' => 'Verano',
			'explore.season.fall' => 'Otoño',
			'explore.season.withYear' => ({required Object season, required Object year}) => '${season} ${year}',
			'explore.format.tv' => 'TV',
			'explore.format.tvShort' => 'Corto de TV',
			'explore.format.movie' => 'Película',
			'explore.format.special' => 'Especial',
			'explore.format.ova' => 'OVA',
			'explore.format.ona' => 'ONA',
			'explore.format.music' => 'Música',
			'explore.format.other' => 'Otro',
			'explore.sourceMaterial.original' => 'Original',
			'explore.sourceMaterial.manga' => 'Manga',
			'explore.sourceMaterial.lightNovel' => 'Novela ligera',
			'explore.sourceMaterial.novel' => 'Novela',
			'explore.sourceMaterial.visualNovel' => 'Novela visual',
			'explore.sourceMaterial.game' => 'Juego',
			'explore.sourceMaterial.webComic' => 'Cómic web',
			'explore.sourceMaterial.musicRelease' => 'Música',
			'explore.sourceMaterial.otherMedia' => 'Otro',
			'explore.creditRole.actor' => 'Actor',
			'explore.creditRole.director' => 'Director',
			'explore.creditRole.writer' => 'Guionista',
			'explore.creditRole.producer' => 'Productor',
			'explore.creditRole.creator' => 'Creador',
			'explore.creditRole.composer' => 'Compositor',
			'explore.relation.prequel' => 'Precuela',
			'explore.relation.sequel' => 'Secuela',
			'explore.relation.sideStory' => 'Historia paralela',
			'explore.relation.spinOff' => 'Spin-off',
			'explore.relation.alternativeVersion' => 'Versión alternativa',
			'explore.relation.summary' => 'Resumen',
			'explore.relation.parentStory' => 'Historia principal',
			'explore.relation.adaptation' => 'Adaptación',
			'explore.relation.other' => 'Relacionado',
			'explore.broadcast' => ({required Object day, required Object time}) => 'Se emite los ${day} a las ${time}',
			'explore.broadcastWithZone' => ({required Object day, required Object time, required Object timezone}) => 'Se emite los ${day} a las ${time} ${timezone}',
			'explore.detail.originalTitle' => 'Título original',
			'explore.detail.alsoKnownAs' => 'También conocido como',
			'explore.detail.studios' => 'Estudios',
			'explore.detail.country' => 'País',
			'explore.detail.language' => 'Idioma',
			'explore.detail.released' => 'Estrenada',
			'explore.detail.physicalRelease' => 'En disco',
			'explore.detail.ended' => 'Finalizada',
			'explore.detail.addedOn' => ({required Object date}) => 'Añadida el ${date}',
			'explore.detail.yourRating' => 'Tu valoración',
			'explore.detail.budget' => 'Presupuesto',
			'explore.detail.revenue' => 'Taquilla',
			'explore.detail.contentAdvisory' => 'Orientación por edades',
			'explore.detail.tags' => 'Etiquetas',
			'explore.detail.revealSpoilerTags' => 'Mostrar etiquetas de spoilers',
			'explore.detail.links' => 'Enlaces',
			'explore.detail.watchOn' => 'Ver en',
			'explore.detail.watchTrailer' => 'Ver tráiler',
			'explore.detail.openOn' => ({required Object site}) => 'Abrir en ${site}',
			'explore.detail.crew' => 'Equipo',
			'explore.detail.ratings' => 'Valoraciones',
			'explore.detail.schedule' => 'Programación',
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: 'Recomendada por ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} usuario', other: 'Recomendada por ${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} usuarios', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => 'Recomendada por ${who}',
			'explore.detail.favoritedBy' => ({required Object who}) => 'Marcada como favorita por ${who}',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '${n} sin estrenar',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => 'Recomendada por el ${percent} de los espectadores',
			'explore.detail.relatedTitles' => 'Títulos relacionados',
			'explore.detail.background' => 'Antecedentes',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} resultado', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} resultados', ), 
			'liveTv.title' => 'TV en vivo',
			'liveTv.guide' => 'Guía',
			'liveTv.noChannels' => 'No hay canales disponibles',
			'liveTv.noDvr' => 'No hay DVR configurado en ningún servidor',
			'liveTv.serverUnavailable' => 'El servidor de TV en vivo no está disponible.',
			'liveTv.serverNotConnected' => 'El servidor de TV en vivo no está conectado.',
			'liveTv.noPrograms' => 'No hay datos de programación disponibles',
			'liveTv.liveStreamFailed' => 'Falló la transmisión en vivo',
			'liveTv.unknownProgram' => 'Programa desconocido',
			'liveTv.timelineLiveProgram' => 'Programa en vivo (el reproductor puede estar fuera de este programa)',
			'liveTv.timelineBuffer' => 'Temas de Buffer',
			'liveTv.timelineUnavailable' => 'Tima de tiempo inaccesible',
			'liveTv.timelineEstimated' => 'El Playback estimado',
			'liveTv.timelinePending' => 'En busca',
			'liveTv.timelineStale' => 'El calendario puede estar envejecido',
			'liveTv.unknownHub' => 'Desconocido',
			'liveTv.unknownError' => 'Error desconocido',
			'liveTv.channelNumber' => ({required Object number}) => 'Canal ${number}',
			'liveTv.unknownChannel' => 'Canal desconocido',
			'liveTv.live' => 'EN VIVO',
			'liveTv.premiereBadge' => 'Nuevo',
			'liveTv.reloadGuide' => 'Recargar guía',
			'liveTv.searchGuide' => 'Buscar en la guía',
			'liveTv.searchHint' => 'Buscar canales y programas',
			'liveTv.searchNoResults' => ({required Object query}) => 'Sin coincidencias para "${query}"',
			'liveTv.channelsSection' => 'Canales',
			'liveTv.programsSection' => 'Programas',
			'liveTv.now' => 'Ahora',
			'liveTv.today' => 'Hoy',
			'liveTv.tomorrow' => 'Mañana',
			'liveTv.midnight' => 'Medianoche',
			'liveTv.overnight' => 'Madrugada',
			'liveTv.morning' => 'Mañana',
			'liveTv.daytime' => 'Día',
			'liveTv.evening' => 'Noche',
			'liveTv.lateNight' => 'Trasnoche',
			'liveTv.whatsOn' => 'En emisión',
			'liveTv.watchChannel' => 'Ver canal',
			'liveTv.favorites' => 'Favoritos',
			'liveTv.reorderFavorites' => 'Reordenar favoritos',
			'liveTv.noFavoriteChannels' => 'No hay canales favoritos',
			'liveTv.noFavoriteChannelsHint' => 'Muestra todos los canales y mantén pulsado uno para añadirlo a tus favoritos.',
			'liveTv.showAllChannels' => 'Mostrar todos los canales',
			'liveTv.favoritesLoadFailed' => 'No se pudieron cargar los favoritos. Comprueba tu conexión e inténtalo de nuevo.',
			'liveTv.favoritesUpdateFailed' => 'No se pudieron actualizar los favoritos. Comprueba tu conexión e inténtalo de nuevo.',
			'liveTv.joinSession' => 'Unirse a sesión en curso',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'Ver desde el inicio (hace ${minutes} min)',
			'liveTv.watchLive' => 'Ver en vivo',
			'liveTv.goToLive' => 'Ir a la emisión en vivo',
			'liveTv.record' => 'Grabar',
			'liveTv.recordEpisode' => 'Grabar episodio',
			'liveTv.recordSeries' => 'Grabar serie',
			'liveTv.recordOptions' => 'Opciones de grabación',
			'liveTv.saveTo' => 'Guardar en',
			'liveTv.recordings' => 'Grabaciones',
			'liveTv.scheduledRecordings' => 'Programadas',
			'liveTv.recordingRules' => 'Reglas de grabación',
			'liveTv.noScheduledRecordings' => 'No hay grabaciones programadas',
			'liveTv.manageRecording' => 'Gestionar grabación',
			'liveTv.cancelRecording' => 'Cancelar grabación',
			'liveTv.cancelRecordingTitle' => '¿Cancelar esta grabación?',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '${title} ya no se grabará.',
			'liveTv.deleteRule' => 'Eliminar regla',
			'liveTv.deleteRuleTitle' => '¿Eliminar regla de grabación?',
			'liveTv.deleteRuleMessage' => ({required Object title}) => 'Los próximos episodios de ${title} no se grabarán.',
			'liveTv.recordingScheduled' => 'Grabación programada',
			'liveTv.alreadyScheduled' => 'Este programa ya está programado',
			'liveTv.dvrAdminRequired' => 'La configuración DVR requiere una cuenta de administrador',
			'liveTv.recordingFailed' => 'No se pudo programar la grabación',
			'liveTv.recordingTargetMissing' => 'No se pudo determinar la biblioteca de grabación',
			'liveTv.recordNotAvailable' => 'Grabación no disponible para este programa',
			'liveTv.recordingCancelled' => 'Grabación cancelada',
			'liveTv.recordingRuleDeleted' => 'Regla de grabación eliminada',
			'liveTv.processRecordingRules' => 'Reevaluar reglas',
			'liveTv.recordingInProgress' => 'Grabando ahora',
			'liveTv.recordingsCount' => ({required Object count}) => '${count} programadas',
			'liveTv.editRule' => 'Editar regla',
			'liveTv.editRuleAction' => 'Editar',
			'liveTv.recordingRuleUpdated' => 'Regla de grabación actualizada',
			'liveTv.guideReloadRequested' => 'Solicitada actualización de la guía',
			'liveTv.guideReloadFailed' => 'No se pudo actualizar la guía',
			'liveTv.rulesProcessRequested' => 'Solicitada reevaluación de reglas',
			'liveTv.rulesProcessFailed' => 'No se pudieron reevaluar las reglas de grabación',
			'liveTv.recordShow' => 'Grabar programa',
			'liveTv.recordSettings.startEarly' => 'Empezar antes (segundos)',
			'liveTv.recordSettings.endLate' => 'Terminar después (segundos)',
			'liveTv.recordSettings.newOnly' => 'Solo episodios nuevos',
			'liveTv.recordSettings.anyChannel' => 'Grabar en cualquier canal',
			'liveTv.recordSettings.anyTime' => 'Grabar a cualquier hora',
			'liveTv.recordSettings.skipInLibrary' => 'Omitir episodios que ya están en la biblioteca',
			'liveTv.recordSettings.keepUpTo' => 'Episodios que conservar',
			'liveTv.recordSettings.keepUpToHint' => '0 conserva todos los episodios',
			'liveTv.startingInMinutes' => ({required Object minutes}) => 'Empieza en ${minutes} min',
			'liveTv.dayAtTime' => ({required Object day, required Object time}) => '${day} a las ${time}',
			'liveTv.invalidPlaybackData' => ({required Object product}) => '${product} devolvió datos de reproducción de TV en vivo no válidos',
			'liveTv.failedToStartChannel' => 'No se pudo iniciar el canal en vivo',
			'liveTv.failedToBuildStreamUrl' => 'No se pudo generar la URL de transmisión',
			'liveTv.playbackStartFailed' => ({required Object reason}) => 'No se pudo iniciar el canal: ${reason}',
			'liveTv.channelSwitchFailed' => ({required Object reason}) => 'No se pudo cambiar de canal: ${reason}',
			'collections.title' => 'Colecciones',
			'collections.collection' => 'Colección',
			'collections.empty' => 'La colección está vacía',
			'collections.deleteCollection' => 'Eliminar colección',
			'collections.deleteConfirm' => ({required Object title}) => '¿Eliminar "${title}"? No se puede deshacer.',
			'collections.deleted' => 'Colección eliminada',
			'collections.deleteFailed' => 'Error al eliminar la colección',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Error al eliminar la colección: ${error}',
			'collections.selectCollection' => 'Seleccionar colección',
			'collections.collectionName' => 'Nombre de la colección',
			'collections.enterCollectionName' => 'Introduce el nombre de la colección',
			'collections.addedToCollection' => 'Añadido a la colección',
			'collections.errorAddingToCollection' => 'Error al añadir a la colección',
			'collections.created' => 'Colección creada',
			'collections.removeFromCollection' => 'Eliminar de la colección',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => '¿Eliminar "${title}" de esta colección?',
			'collections.removedFromCollection' => 'Eliminado de la colección',
			'collections.removeFromCollectionFailed' => 'Error al eliminar de la colección',
			'collections.removeFromCollectionError' => ({required Object error}) => 'Error al eliminar de la colección: ${error}',
			'collections.searchCollections' => 'Buscar colecciones...',
			'playlists.title' => 'Listas de reproducción',
			'playlists.playlist' => 'Lista de reproducción',
			'playlists.noPlaylists' => 'No se encontraron listas de reproducción',
			'playlists.create' => 'Crear lista de reproducción',
			'playlists.playlistName' => 'Nombre de la lista de reproducción',
			'playlists.enterPlaylistName' => 'Introduce el nombre de la lista de reproducción',
			'playlists.delete' => 'Eliminar lista de reproducción',
			'playlists.removeItem' => 'Eliminar de la lista de reproducción',
			'playlists.smartPlaylist' => 'Lista de reproducción inteligente',
			'playlists.itemCount' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} elemento', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} elementos', ), 
			'playlists.emptyPlaylist' => 'Esta lista de reproducción está vacía',
			'playlists.deleteConfirm' => '¿Eliminar lista de reproducción?',
			'playlists.deleteMessage' => ({required Object name}) => '¿Estás seguro de que quieres eliminar "${name}"?',
			'playlists.created' => 'Lista de reproducción creada',
			'playlists.deleted' => 'Lista de reproducción eliminada',
			'playlists.itemAdded' => 'Añadido a la lista de reproducción',
			'playlists.itemRemoved' => 'Eliminado de la lista de reproducción',
			'playlists.selectPlaylist' => 'Seleccionar lista de reproducción',
			'playlists.searchPlaylists' => 'Buscar listas de reproducción...',
			'playlists.errorCreating' => 'Error al crear la lista de reproducción',
			'playlists.errorDeleting' => 'Error al eliminar la lista de reproducción',
			'playlists.errorLoading' => 'Error al cargar las listas de reproducción',
			'playlists.errorAdding' => 'Error al añadir a la lista de reproducción',
			'playlists.errorReordering' => 'Error al reordenar el elemento de la lista de reproducción',
			'playlists.errorRemoving' => 'Error al eliminar de la lista de reproducción',
			'music.goToAlbum' => 'Ir al álbum',
			'music.goToArtist' => 'Ir al artista',
			'music.instantMix' => 'Mezcla instantánea',
			'music.playNext' => 'Reproducir a continuación',
			'music.addToQueue' => 'Añadir a la cola',
			'music.discNumber' => ({required Object n}) => 'Disco ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} canción', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} canciones', ), 
			'music.nowPlaying' => 'Reproduciendo ahora',
			'music.playingFrom' => ({required Object title}) => 'Reproduciendo desde ${title}',
			'music.queue' => 'Cola',
			'music.clearQueue' => 'Vaciar la cola',
			'music.lyrics' => 'Letra',
			'music.visualizer' => 'Visualizador',
			'music.visualizerProfileLoading' => 'El análisis de la pista...',
			'music.visualizerAmbientMotion' => 'Movimiento Ambiental',
			'music.visualizerPlexLoudness' => 'Plex ruido',
			'music.visualizerPreviousPreset' => 'Artículo anteriorEl estilo visual',
			'music.visualizerNextPreset' => 'Siguiente Estilo visual',
			'music.visualizerPresetAurora' => 'Aurora',
			'music.visualizerPresetBloom' => 'Blojo',
			'music.visualizerPresetOrbitals' => 'Orbitales',
			'music.visualizerPresetPrism' => 'Prism',
			'music.visualizerPresetTunnel' => 'Túnel',
			'music.visualizerPresetTrackMap' => 'Mapa de Track',
			'music.noLyrics' => 'No hay letra disponible',
			'music.sleepTimer' => 'Temporizador de apagado',
			'music.sleepTimerEndOfTrack' => 'Fin de la canción',
			'music.sleepTimerMinutes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minuto', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minutos', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} minutos', ), 
			'music.stopPlayback' => 'Detener reproducción',
			'music.previousTrack' => 'Canción anterior',
			'music.nextTrack' => 'Canción siguiente',
			'music.repeat' => 'Repetir',
			'music.repeatAll' => 'Repetir todo',
			'music.repeatOne' => 'Repetir una',
			'music.instantMixNoServer' => 'No hay ningún servidor disponible para una mezcla instantánea',
			'music.instantMixFailed' => 'Error al cargar la mezcla instantánea',
			'music.instantMixEmpty' => 'La mezcla instantánea no devolvió ninguna canción',
			'music.noAudioUrl' => ({required Object track}) => 'No hay ninguna URL de audio disponible para ${track}',
			'music.discography.singlesAndEps' => 'Sencillos y EP',
			'music.discography.live' => 'En directo',
			'music.discography.compilations' => 'Recopilaciones',
			'watchTogether.title' => 'Ver juntos',
			'watchTogether.description' => 'Mira contenido sincronizado con amigos y familiares',
			'watchTogether.createRoom' => 'Crear sala',
			'watchTogether.creatingRoom' => 'Creando sala...',
			'watchTogether.joinRoom' => 'Unirse a una sala',
			'watchTogether.joiningRoom' => 'Uniéndote a la sala...',
			'watchTogether.connecting' => 'Conectando...',
			'watchTogether.relayPublic' => 'Las salas usan los servidores de retransmisión públicos de Open Watch Party.',
			'watchTogether.relayCustom' => ({required Object url}) => 'Las salas usan tu servidor de retransmisión en ${url}.',
			'watchTogether.recentRooms' => 'Salas recientes',
			'watchTogether.roomActions' => 'Acciones de la sala',
			'watchTogether.renameRoom' => 'Renombrar sala',
			'watchTogether.removeRoom' => 'Eliminar',
			'watchTogether.enterRoomCode' => 'Introduce el código de 6 caracteres del anfitrión.',
			'watchTogether.roomCode' => 'Código de sala',
			'watchTogether.paste' => 'Pegar',
			'watchTogether.noCodeInClipboard' => 'El portapapeles no contiene un código de sala',
			'watchTogether.copyCode' => 'Copiar código',
			'watchTogether.codeCopied' => 'Código de sala copiado',
			'watchTogether.shareInvite' => 'Compartir invitación',
			'watchTogether.inviteCopied' => 'Invitación copiada. Pégala en un mensaje.',
			'watchTogether.inviteMessage' => ({required Object code}) => 'Únete a mi sala de Ver juntos en PlezyNG: abre «Ver juntos», elige «Unirse a una sala» e introduce ${code}.',
			'watchTogether.openSessionControls' => 'Abrir los controles de la sesión de Ver juntos',
			'watchTogether.reconnecting' => 'Reconectando...',
			'watchTogether.reconnectingDescription' => 'Se perdió la conexión. Volverás a unirte a la sala automáticamente.',
			'watchTogether.connected' => 'Conectado',
			'watchTogether.disconnected' => 'Desconectado',
			'watchTogether.youAreHost' => 'Eres el anfitrión',
			'watchTogether.hostedBy' => ({required Object name}) => 'Anfitrión: ${name}',
			'watchTogether.hostControlsPlayback' => 'El anfitrión controla la reproducción',
			'watchTogether.anyoneCanControl' => 'Cualquiera puede controlar la reproducción',
			'watchTogether.roomLocked' => 'Sala bloqueada',
			'watchTogether.nowPlaying' => 'Reproduciendo ahora',
			'watchTogether.nothingPlaying' => 'No se está reproduciendo nada',
			'watchTogether.nothingPlayingHost' => 'Reproduce algo de cualquier biblioteca para compartirlo con la sala.',
			'watchTogether.nothingPlayingGuest' => 'Cuando el anfitrión reproduzca algo, se abrirá aquí.',
			'watchTogether.notShareable' => 'Este video no coincide con ningún catálogo, así que solo pueden reproducirlo quienes tengan acceso al mismo servidor.',
			'watchTogether.searching' => 'Buscando este video en tus bibliotecas...',
			'watchTogether.yourCopy' => 'Tu copia',
			'watchTogether.sharingYourCopy' => 'Estás compartiendo tu copia',
			'watchTogether.playingOtherLength' => ({required Object difference}) => 'Reproduciendo tu copia · ${difference}',
			'watchTogether.mismatchTitle' => 'Tu copia tiene otra duración',
			'watchTogether.mismatchDescription' => ({required Object difference}) => 'Tu copia más parecida es ${difference} que el video de la sala. Puede ser otro montaje o versión.',
			'watchTogether.playAnyway' => 'Reproducir de todos modos',
			'watchTogether.chooseAnotherCopy' => 'Elegir otra copia',
			'watchTogether.dontPlay' => 'No reproducir',
			'watchTogether.unavailableTitle' => 'No tienes este video',
			'watchTogether.unavailableDescription' => 'PlezyNG no lo encontró en tus bibliotecas. Elige una copia tú mismo o vuelve a buscar.',
			_ => null,
		} ?? switch (path) {
			'watchTogether.chooseCopy' => 'Elegir una copia',
			'watchTogether.searchAgain' => 'Buscar de nuevo',
			'watchTogether.noCandidates' => 'No se encontraron copias en tus bibliotecas.',
			'watchTogether.choiceFailed' => 'No se pudo reproducir esta copia para la sala',
			'watchTogether.lengthLonger' => ({required Object duration}) => '${duration} más larga',
			'watchTogether.lengthShorter' => ({required Object duration}) => '${duration} más corta',
			'watchTogether.lengthSame' => 'Misma duración',
			'watchTogether.lengthUnknown' => 'Duración desconocida',
			'watchTogether.joinCurrentPlayback' => 'Unirse a la reproducción actual',
			'watchTogether.joinCurrentPlaybackDescription' => 'Vuelve a lo que el anfitrión está viendo ahora mismo',
			'watchTogether.stopMedia' => 'Detener el video para todos',
			'watchTogether.syncOffset' => 'Ajuste de sincronización',
			'watchTogether.syncOffsetDescription' => 'Desplaza tu video si va por delante o por detrás de la sala.',
			'watchTogether.offsetHint' => ({required Object difference}) => 'Tu copia es ${difference} que el video de la sala.',
			'watchTogether.applyDifference' => ({required Object offset}) => 'Usar ${offset}',
			'watchTogether.offsetMinusSecond' => '-1 s',
			'watchTogether.offsetMinusTenth' => '-100 ms',
			'watchTogether.offsetPlusTenth' => '+100 ms',
			'watchTogether.offsetPlusSecond' => '+1 s',
			'watchTogether.participants' => 'Participantes',
			'watchTogether.participantCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} participante', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} participantes', ), 
			'watchTogether.hostBadge' => 'ANFITRIÓN',
			'watchTogether.nameYou' => ({required Object name}) => '${name} (tú)',
			'watchTogether.playerIdle' => 'Inactivo',
			'watchTogether.playerLoading' => 'Cargando',
			'watchTogether.playerReady' => 'Listo',
			'watchTogether.playerBuffering' => 'Almacenando en búfer',
			'watchTogether.matchSearching' => 'Buscando',
			'watchTogether.matchMatched' => 'Tiene el video',
			'watchTogether.matchMismatched' => 'Duración distinta',
			'watchTogether.matchUnavailable' => 'No tiene el video',
			'watchTogether.participantOffset' => ({required Object offset}) => 'Desfase ${offset}',
			'watchTogether.makeHost' => 'Hacer anfitrión',
			'watchTogether.makeHostQuestion' => '¿Transferir el rol de anfitrión?',
			'watchTogether.makeHostConfirm' => ({required Object name}) => '${name} controlará la reproducción y dirigirá la sesión para todos.',
			'watchTogether.transfer' => 'Transferir',
			'watchTogether.removeParticipant' => 'Expulsar de la sala',
			'watchTogether.removeParticipantQuestion' => ({required Object name}) => '¿Expulsar a ${name}?',
			'watchTogether.removeParticipantConfirm' => ({required Object name}) => '${name} saldrá de la sala. Podrá volver a unirse con el código, salvo que bloquees la sala.',
			'watchTogether.remove' => 'Expulsar',
			'watchTogether.roomSettings' => 'Ajustes de la sala',
			'watchTogether.letEveryoneControl' => 'Permitir que todos controlen la reproducción',
			'watchTogether.lockRoom' => 'Bloquear sala',
			'watchTogether.lockRoomDescription' => 'Nadie nuevo puede unirse',
			'watchTogether.leaveRoom' => 'Salir de la sala',
			'watchTogether.leaveRoomQuestion' => '¿Salir de la sala?',
			'watchTogether.leaveRoomConfirm' => 'Puedes volver a unirte con el código de sala.',
			'watchTogether.leave' => 'Salir',
			'watchTogether.endRoom' => 'Finalizar sala',
			'watchTogether.endRoomQuestion' => '¿Finalizar la sala?',
			'watchTogether.endRoomConfirm' => 'La sala se cerrará para todos.',
			'watchTogether.end' => 'Finalizar',
			'watchTogether.playBlockedTitle' => 'La reproducción no se inició',
			'watchTogether.playBlockedDescription' => 'Pulsa reproducir para empezar a ver con la sala.',
			'watchTogether.notices.pressedPlay' => ({required Object name}) => '${name} pulsó reproducir',
			'watchTogether.notices.playbackStarted' => 'Reproducción iniciada',
			'watchTogether.notices.paused' => ({required Object name}) => '${name} pausó',
			'watchTogether.notices.playbackPaused' => 'Reproducción pausada',
			'watchTogether.notices.jumpedTo' => ({required Object name, required Object position}) => '${name} saltó a ${position}',
			'watchTogether.notices.roomJumpedTo' => ({required Object position}) => 'Salto a ${position}',
			'watchTogether.notices.changedSpeed' => ({required Object name, required Object speed}) => '${name} estableció la velocidad en ${speed}',
			'watchTogether.notices.speedChanged' => ({required Object speed}) => 'Velocidad establecida en ${speed}',
			'watchTogether.notices.startedMedia' => ({required Object name, required Object title}) => '${name} inició ${title}',
			'watchTogether.notices.mediaStarted' => ({required Object title}) => 'Reproduciendo ${title}',
			'watchTogether.notices.stoppedMedia' => ({required Object name}) => '${name} detuvo el video',
			'watchTogether.notices.mediaStopped' => 'El video se detuvo',
			'watchTogether.notices.waitingFor' => ({required Object name}) => 'Esperando a ${name}...',
			'watchTogether.notices.waitingForSomeone' => 'Esperando a que alguien se ponga al día...',
			'watchTogether.notices.finished' => 'Terminado',
			'watchTogether.notices.hostChangedTo' => ({required Object name}) => '${name} ahora es el anfitrión',
			'watchTogether.notices.youAreNowHost' => 'Ahora eres el anfitrión',
			'watchTogether.notices.joined' => ({required Object name}) => '${name} se unió',
			'watchTogether.notices.left' => ({required Object name}) => '${name} se fue',
			'watchTogether.notices.controlRefused' => 'Solo el anfitrión puede controlar la reproducción',
			'watchTogether.notices.searchFailed' => 'No se pudo buscar el video de la sala en algunos servidores',
			'watchTogether.notices.playBlocked' => 'Pulsa reproducir para empezar',
			'watchTogether.notices.shareFailed' => 'No se pudo compartir este video con la sala',
			'watchTogether.notices.downloadNotShared' => 'Las descargas no se comparten con la sala mientras su servidor esté sin conexión',
			'watchTogether.notices.openFailed' => 'No se pudo abrir el video de la sala',
			'watchTogether.ended.ended' => 'El anfitrión finalizó la sala',
			'watchTogether.ended.kicked' => 'Te han expulsado de la sala',
			'watchTogether.ended.expired' => 'La sala caducó',
			'watchTogether.ended.replaced' => 'Te uniste a esta sala en otro dispositivo',
			'watchTogether.ended.lost' => 'Se perdió la conexión con la sala',
			'watchTogether.errors.invalidCode' => 'Eso no es un código de sala. Los códigos tienen 6 letras y dígitos, sin 0, 1, I, L ni O.',
			'watchTogether.errors.roomNotFound' => 'Ninguna sala tiene ese código. Puede que haya finalizado.',
			'watchTogether.errors.roomFull' => 'Esa sala está llena.',
			'watchTogether.errors.roomLocked' => 'El anfitrión bloqueó esa sala.',
			'watchTogether.errors.relayFull' => 'Ver juntos está saturado en este momento. Inténtalo de nuevo más tarde.',
			'watchTogether.errors.unreachable' => 'No se pudo conectar con el servidor de retransmisión de Ver juntos. Comprueba tu conexión.',
			'watchTogether.errors.rateLimited' => 'Demasiados intentos. Espera un momento e inténtalo de nuevo.',
			'watchTogether.errors.clientBlocked' => 'Esta versión de PlezyNG no puede usar el servidor de retransmisión. Actualiza la aplicación.',
			'watchTogether.errors.forbidden' => 'Solo el anfitrión puede hacer eso.',
			'watchTogether.errors.notInRoom' => 'No estás en ninguna sala.',
			'watchTogether.errors.alreadyInRoom' => 'Ya estás en una sala.',
			'watchTogether.errors.resumeFailed' => 'No se pudo reconectar a la sala.',
			'watchTogether.errors.unsupported' => 'El servidor de retransmisión no admite esta función.',
			'watchTogether.errors.generic' => 'Algo salió mal. Inténtalo de nuevo.',
			'watchTogether.untitledEpisode' => ({required Object number}) => 'Episodio ${number}',
			'downloads.title' => 'Descargas',
			'downloads.manage' => 'Gestionar',
			'downloads.tvShows' => 'Series de TV',
			'downloads.movies' => 'Películas',
			'downloads.music' => 'Música',
			'downloads.tracksQueued' => ({required Object count}) => '${count} canciones en cola para descargar',
			'downloads.noDownloads' => 'No hay descargas aún',
			'downloads.noDownloadsDescription' => 'El contenido descargado aparecerá aquí para verlo sin conexión',
			'downloads.downloadNow' => 'Descargar',
			'downloads.deleteDownload' => 'Eliminar descarga',
			'downloads.retryDownload' => 'Reintentar descarga',
			'downloads.downloadQueued' => 'Descarga en cola',
			'downloads.downloadResumed' => 'Descarga reanudada',
			'downloads.serverErrorBitrate' => 'Error del servidor: el archivo puede superar el límite remoto de tasa de bits',
			'downloads.storageFull' => 'Las descargas se detuvieron para proteger el espacio disponible. Libera espacio o elige otra ubicación de descarga e inténtalo de nuevo.',
			'downloads.storageUnavailable' => 'Las descargas se detuvieron porque no se pudo comprobar el almacenamiento disponible. Comprueba la ubicación de descarga y vuelve a intentarlo.',
			'downloads.episodesQueued' => ({required Object count}) => '${count} episodios en cola para descargar',
			'downloads.downloadDeleted' => 'Descarga eliminada',
			'downloads.deleteConfirm' => ({required Object title}) => '¿Eliminar "${title}" de este dispositivo?',
			'downloads.deleteCollectionDownloads' => 'Eliminar descargas',
			'downloads.deleteCollectionDownloadsConfirm' => ({required Object title}) => '¿Eliminar todas las descargas de "${title}" de este dispositivo?',
			'downloads.collectionDownloadsDeleted' => 'Descargas eliminadas',
			'downloads.cancelledDownloadTitle' => 'Descarga cancelada',
			'downloads.cancelledDownloadMessage' => 'Esta descarga se canceló. ¿Qué quieres hacer?',
			'downloads.allEpisodesAlreadyDownloaded' => 'Todos los episodios ya están descargados',
			'downloads.resumeDownload' => 'Reanudar descarga',
			'downloads.cancelledDownload' => 'Descarga cancelada',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file} (sincronizando ${status})',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => '${file} descargado — haz clic para completar',
			'downloads.partialDownloadClickToComplete' => 'Descarga parcial — haz clic para completar',
			'downloads.deleting' => 'Eliminando...',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Eliminando ${title}... (${current} de ${total})',
			'downloads.queuedTooltip' => 'En cola',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'En cola: ${files}',
			'downloads.downloadingTooltip' => 'Descargando...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => 'Descargando ${files}',
			'downloads.noDownloadsTree' => 'Sin descargas',
			'downloads.pauseAll' => 'Pausar todo',
			'downloads.resumeAll' => 'Reanudar todo',
			'downloads.retryAll' => 'Reintentar todo',
			'downloads.retryFailed' => 'Reintentar descargas fallidas',
			'downloads.deleteAll' => 'Eliminar todo',
			'downloads.selectVersion' => 'Seleccionar versión',
			'downloads.allEpisodes' => 'Todos los episodios',
			'downloads.unwatchedOnly' => 'Solo no vistos',
			'downloads.nextNUnwatched' => ({required Object count}) => 'Próximos ${count} no vistos',
			'downloads.customAmount' => 'Cantidad personalizada...',
			'downloads.customAmountAny' => 'Cuantía de la persona (todos los ...',
			'downloads.randomEpisodes' => 'Episodios aleatorios',
			'downloads.includeSpecials' => 'Incluir especiales',
			'downloads.howManyEpisodes' => '¿Cuántos episodios?',
			'downloads.invalidEpisodeCount' => 'Introduce un número de episodios válido.',
			'downloads.keepSynced' => 'Mantener sincronizado',
			'downloads.downloadOnce' => 'Descargar una vez',
			'downloads.keepNUnwatched' => ({required Object count}) => 'Mantener ${count} no vistos',
			'downloads.editSyncRule' => 'Editar regla de sincronización',
			'downloads.removeSyncRule' => 'Eliminar regla de sincronización',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => '¿Dejar de sincronizar "${title}"? Los episodios descargados se conservarán.',
			'downloads.removeListSyncRuleConfirm' => ({required Object title}) => '¿Dejar de sincronizar "${title}"?',
			'downloads.deleteSyncRuleDownloads' => 'Eliminar también las descargas asociadas',
			'downloads.deleteSyncRuleDownloadsDescription' => 'Se conservarán las descargas usadas por otra regla de sincronización o perfil.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'Regla de sincronización creada — se conservarán ${count} episodios no vistos',
			'downloads.syncRuleUpdated' => 'Regla de sincronización actualizada',
			'downloads.syncRuleRemoved' => 'Regla de sincronización eliminada',
			'downloads.syncRuleAndDownloadsRemoved' => 'Regla de sincronización y descargas asociadas eliminadas',
			'downloads.syncRuleCleanupBusy' => 'Las reglas de sincronización se están actualizando. Inténtalo de nuevo en un momento.',
			'downloads.syncRuleCleanupUnavailable' => 'No se pudieron identificar las descargas asociadas de forma segura. Vuelve a conectar el servidor e inténtalo de nuevo, o elimina la regla sin borrar las descargas.',
			'downloads.syncedNewEpisodes' => ({required Object count, required Object title}) => '${count} nuevos episodios sincronizados para ${title}',
			'downloads.syncNow' => 'Síntomas ahora',
			'downloads.downloadsUpToDate' => 'Los descargos están hasta la fecha',
			'downloads.syncComplete' => ({required Object queued, required Object removed}) => 'Sync complete · ${queued} queued, ${removed} eliminado',
			'downloads.activeSyncRules' => 'Reglas de sincronización',
			'downloads.reviewOrphanFiles' => 'Revisar descargas huérfanas',
			'downloads.orphanReviewTitle' => 'Revisar descargas huérfanas',
			'downloads.orphanReviewDescription' => 'Estos archivos etiquetados están en las carpetas de descargas predeterminadas que administra PlezyNG y no tienen un registro de descarga ni una tarea activa asociada. Revisa la lista antes de eliminarlos.',
			'downloads.orphanReviewCount' => ({required Object count, required Object size}) => '${count} archivos · ${size}',
			'downloads.orphanDeleteFiles' => ({required Object count}) => 'Eliminar ${count} archivos',
			'downloads.orphanCleanupNone' => 'No se encontraron archivos de descarga huérfanos',
			'downloads.orphanCleanupFailed' => 'PlezyNG no pudo analizar de forma segura la carpeta de descargas administrada. No se eliminó ningún archivo.',
			'downloads.orphanCleanupChanged' => 'La lista de descargas cambió durante la revisión. Revisa los archivos de nuevo antes de limpiar.',
			'downloads.orphanCleanupComplete' => ({required Object count, required Object size}) => 'Se eliminaron ${count} archivos de descarga huérfanos · ${size} liberados',
			'downloads.noSyncRules' => 'Sin reglas de sincronización',
			'downloads.manageSyncRule' => 'Gestionar sincronización',
			'downloads.editEpisodeCount' => 'Número de episodios',
			'downloads.editSyncFilter' => 'Filtro de sincronización',
			'downloads.syncAllItems' => 'Sincronizando todos los elementos',
			'downloads.syncUnwatchedItems' => 'Sincronizando elementos no vistos',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'Servidor: ${server} • ${status}',
			'downloads.syncRuleAvailable' => 'Disponible',
			'downloads.syncRuleOffline' => 'Sin conexión',
			'downloads.syncRuleSignInRequired' => 'Se requiere iniciar sesión',
			'downloads.syncRuleAccessDenied' => 'Acceso denegado',
			'downloads.syncRuleNotAvailableForProfile' => 'No disponible para el perfil actual',
			'downloads.syncRuleUnknownServer' => 'Servidor desconocido',
			'downloads.syncRuleListCreated' => 'Regla de sincronización creada',
			'downloads.backgroundWarning.bannerBlocked' => 'Las descargas se detendrán al salir de la app',
			'downloads.backgroundWarning.bannerDegraded' => 'Las descargas en segundo plano pueden estar limitadas',
			'downloads.backgroundWarning.bannerAction' => 'Detalles',
			'downloads.backgroundWarning.sheetTitle' => 'Las descargas en segundo plano están bloqueadas',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'Las descargas en segundo plano pueden estar limitadas',
			'downloads.backgroundWarning.sheetIntro' => 'Android impide que PlezyNG descargue de forma fiable en segundo plano.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'Tu dispositivo limita cuándo puede descargar PlezyNG en segundo plano.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'El uso en segundo plano de PlezyNG está restringido. Configura el uso de batería o en segundo plano como "Sin restricciones".',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'Android ha puesto a PlezyNG en un estado de espera restringido. Configura el uso de batería como "Sin restricciones".',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'Las notificaciones de descargas están desactivadas, por lo que el progreso y los controles podrían no estar disponibles.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'Las notificaciones están desactivadas. En Android 13 o versiones posteriores, son necesarias para las descargas largas en segundo plano.',
			'downloads.backgroundWarning.reasonDataSaver' => 'El Ahorro de datos está activado y bloquea las descargas en segundo plano con datos móviles. Las descargas deberían seguir funcionando con Wi-Fi.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'Las descargas se detuvieron repetidamente mientras PlezyNG estaba en segundo plano. Revisa la configuración de batería o de uso en segundo plano de PlezyNG.',
			'downloads.backgroundWarning.openSettings' => 'Abrir configuración',
			'downloads.backgroundWarning.stillNotWorking' => 'Ayuda específica para tu dispositivo',
			'downloads.backgroundWarning.stillNotWorkingDescription' => 'Consulta los pasos para tu dispositivo o envía un registro desde Configuración › Ver registros si el problema continúa.',
			'downloads.backgroundWarning.dialogTitle' => 'Es posible que las descargas no finalicen',
			'downloads.backgroundWarning.dialogDownloadAnyway' => 'Descargar de todos modos',
			'downloads.backgroundWarning.dialogFixFirst' => 'Solucionarlo primero',
			'downloads.backgroundWarning.statusTile' => 'Descargas en segundo plano',
			'downloads.backgroundWarning.statusOk' => 'Permitidas en segundo plano',
			'downloads.backgroundWarning.statusBlocked' => 'Bloqueadas por la configuración del sistema',
			'downloads.backgroundWarning.statusDegraded' => 'Limitadas por la configuración del sistema',
			'downloads.backgroundWarning.statusUnknown' => 'Aún no se ha comprobado',
			'downloads.backgroundWarning.settingsUnavailable' => 'No se pudo abrir la configuración del sistema en este dispositivo',
			'downloads.backgroundWarning.linkUnavailable' => 'No se pudo abrir dontkillmyapp.com en este dispositivo',
			'downloads.options' => 'Opciones de descargas',
			'downloads.groupings.library' => 'Biblioteca',
			'downloads.groupings.collections' => 'Colecciones',
			'downloads.unknownLibrary' => 'Biblioteca desconocida',
			'downloads.unknownShow' => 'Serie desconocida',
			'downloads.unknownSeason' => 'Temporada desconocida',
			'downloads.unknownAlbum' => 'Álbum desconocido',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '${completed}/${total} completadas',
			'downloads.storageUsed' => ({required Object size}) => 'Almacenamiento utilizado: ${size}',
			'downloads.downloadCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} descarga', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} descargas', ), 
			'downloads.showCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} muestra', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} muestra', ), 
			'downloads.movieCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} películas', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} películas', ), 
			'downloads.albumCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} álbum', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(n)} álbumes', ), 
			'downloads.errorFileNotFound' => 'Archivo no encontrado (404)',
			'downloads.errorDownloadNotAllowed' => 'El servidor no permite la descarga (403)',
			'downloads.errorDownloadFailed' => 'Error en la descarga',
			'downloads.errorDownloadFailedWithReason' => ({required Object reason}) => 'Error en la descarga: ${reason}',
			'downloads.convertingOnServer' => 'Convertir en el servidor...',
			'downloads.convertingOnServerPercent' => ({required Object percent}) => 'Convertir en servidor · ${percent}%',
			'downloads.errorHttpStatus' => ({required Object status}) => 'Error en la descarga (HTTP ${status})',
			'downloads.errorPostProcessing' => ({required Object reason}) => 'Error en el posprocesamiento: ${reason}',
			'downloads.reasonFileNotSaved' => 'no se pudo guardar el archivo en este dispositivo',
			'downloads.reasonCannotResume' => 'no se pudo reanudar la descarga parcial',
			'downloads.reasonDeviceStorageFull' => 'este dispositivo no tiene espacio de almacenamiento',
			'downloads.notificationDownloading' => 'Descargando...',
			'downloads.notificationComplete' => 'Descarga completada',
			'downloads.notificationPaused' => 'Descarga pausada',
			'shaders.title' => 'Shaders',
			'shaders.noShaderDescription' => 'Sin mejora de video',
			'shaders.nvscalerDescription' => 'Escalado de imagen NVIDIA para un video más nítido',
			'shaders.artcnnVariantNeutral' => 'Neutral',
			'shaders.artcnnVariantDenoise' => 'Reducción de ruido',
			'shaders.artcnnVariantDenoiseSharpen' => 'Reducción de ruido + enfoque',
			'shaders.qualityFast' => 'Rápido',
			'shaders.qualityHQ' => 'Alta calidad',
			'shaders.mode' => 'Modo',
			'shaders.importShader' => 'Importar shader',
			'shaders.customShaderDescription' => 'Shader GLSL personalizado',
			'shaders.shaderImported' => 'Shader importado',
			'shaders.shaderImportFailed' => 'Error al importar shader',
			'shaders.deleteShader' => 'Eliminar shader',
			'shaders.deleteShaderConfirm' => ({required Object name}) => '¿Eliminar "${name}"?',
			'companionRemote.title' => 'Control remoto',
			'companionRemote.connectedTo' => ({required Object name}) => 'Conectado a ${name}',
			'companionRemote.unknownDevice' => 'Dispositivo desconocido',
			'companionRemote.session.startingServer' => 'Iniciando servidor remoto...',
			'companionRemote.session.hostAddress' => 'Dirección del host',
			'companionRemote.session.connected' => 'Conectado',
			'companionRemote.session.serverRunning' => 'Servidor remoto activo',
			'companionRemote.session.serverStopped' => 'Servidor remoto detenido',
			'companionRemote.session.serverRunningDescription' => 'Los dispositivos móviles de tu red pueden conectarse a esta aplicación',
			'companionRemote.session.serverStoppedDescription' => 'Inicia el servidor para permitir que los dispositivos móviles se conecten',
			'companionRemote.session.usePhoneToControl' => 'Usa tu dispositivo móvil para controlar esta aplicación',
			'companionRemote.session.startServer' => 'Iniciar servidor',
			'companionRemote.session.stopServer' => 'Detener servidor',
			'companionRemote.session.minimize' => 'Minimizar',
			'companionRemote.session.manualAddressHint' => 'Dirección de conexión manual:',
			'companionRemote.pairing.discoveryDescription' => 'Los dispositivos PlezyNG con la misma cuenta Plex aparecen aquí',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Conectando...',
			'companionRemote.pairing.searchingForDevices' => 'Buscando dispositivos...',
			'companionRemote.pairing.noDevicesFound' => 'No se encontraron dispositivos en tu red',
			'companionRemote.pairing.noDevicesHint' => 'Abre PlezyNG en tu equipo y usa la misma red WiFi',
			'companionRemote.pairing.availableDevices' => 'Dispositivos disponibles',
			'companionRemote.pairing.manualConnection' => 'Conexión manual',
			'companionRemote.pairing.cryptoInitFailed' => 'No se pudo iniciar la conexión segura. Inicia sesión en Plex primero.',
			'companionRemote.pairing.validationHostRequired' => 'Introduce la dirección del host',
			'companionRemote.pairing.validationHostFormat' => 'El formato debe ser IP:puerto (p. ej., 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'Tiempo de conexión agotado. Usa la misma red en ambos dispositivos.',
			'companionRemote.pairing.sessionNotFound' => 'Dispositivo no encontrado. Asegúrate de que PlezyNG esté en ejecución en el host.',
			'companionRemote.pairing.authFailed' => 'Autenticación fallida. Ambos dispositivos necesitan la misma cuenta Plex.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Error al conectar: ${error}',
			'companionRemote.pairing.codeTitle' => 'Código de par',
			'companionRemote.pairing.codeDescription' => 'Introduce el código mostrado en Companion Remote en el dispositivo host. Ambas unidades deben usar una versión que apoye la paridad segura.',
			'companionRemote.pairing.codeInvalid' => 'Introduce todas las 32 letras y números del código de host.',
			'companionRemote.pairing.updateRequired' => 'Actualizar ambos dispositivos a una versión que apoya la pared segura.',
			'companionRemote.pairing.hostDescription' => 'Introduce este código una vez en cada remote. mantenga privado: permite el control de este perfil.',
			'companionRemote.pairing.resetCode' => 'Resetar el código de par',
			'companionRemote.pairing.resetDescription' => 'Desconectar todos los remotes y crear un nuevo código. cada remoto tendrá que pararse de nuevo.',
			'companionRemote.remote.disconnectConfirm' => '¿Quieres desconectarte de la sesión remota?',
			'companionRemote.remote.reconnecting' => 'Reconectando...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Intento ${current} de 5',
			'companionRemote.remote.retryNow' => 'Reintentar ahora',
			'companionRemote.remote.tabRemote' => 'Remoto',
			'companionRemote.remote.tabPlay' => 'Reproducir',
			'companionRemote.remote.tabMore' => 'Más',
			'companionRemote.remote.menu' => 'Menú',
			'companionRemote.remote.tabNavigation' => 'Navegación por pestañas',
			'companionRemote.remote.tabDiscover' => 'Descubrir',
			'companionRemote.remote.tabLibraries' => 'Bibliotecas',
			'companionRemote.remote.tabSearch' => 'Buscar',
			'companionRemote.remote.tabDownloads' => 'Descargas',
			'companionRemote.remote.tabSettings' => 'Configuración',
			'companionRemote.remote.previous' => 'Anterior',
			'companionRemote.remote.playPause' => 'Reproducir/Pausar',
			'companionRemote.remote.next' => 'Siguiente',
			'companionRemote.remote.seekBack' => 'Retroceder',
			'companionRemote.remote.stop' => 'Detener',
			'companionRemote.remote.seekForward' => 'Avanzar',
			'companionRemote.remote.volume' => 'Volumen',
			'companionRemote.remote.volumeDown' => 'Bajar',
			'companionRemote.remote.volumeUp' => 'Subir',
			'companionRemote.remote.fullscreen' => 'Pantalla completa',
			'companionRemote.remote.subtitles' => 'Subtítulos',
			'companionRemote.remote.audio' => 'Audio',
			'companionRemote.remote.searchHint' => 'Buscar en escritorio...',
			'companionRemote.errors.noNetworkInterface' => 'No se encontró ninguna interfaz de red',
			'companionRemote.errors.authenticationFailed' => 'Autenticación fallida',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'No se pudo iniciar el servidor remoto: ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'No se pudo enviar el comando remoto: ${error}',
			'companionRemote.errors.joinTimedOut' => 'Se agotó el tiempo al unirse a la sesión',
			'companionRemote.errors.failedToConnectAnyAddress' => 'No se pudo conectar a ninguna dirección',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => 'Conexión perdida tras ${attempts} intentos',
			'companionRemote.errors.connectionLost' => 'Conexión perdida',
			'companionRemote.closedBeforeAuth' => 'La conexión se cerró antes de la autenticación',
			'videoSettings.playbackSpeed' => 'Velocidad de reproducción',
			'videoSettings.normalSpeed' => 'Normal',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'Activo (${duration})',
			'videoSettings.zoom' => 'Zoom',
			'videoSettings.sleepTimer' => 'Temporizador de apagado',
			'videoSettings.audioSync' => 'Sincronización de audio',
			'videoSettings.subtitleSync' => 'Sincronización de subtítulos',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.hdrUnsupported' => 'HDR no está disponible aquí: este compositor de escritorio o esta salida de vídeo no pueden transmitirlo.',
			'videoSettings.hdrToneMapping' => 'Mapeo de tonos HDR',
			'videoSettings.hdrToneMappingCompositor' => 'Compositor',
			'videoSettings.hdrToneMappingCompositorDescription' => 'Transmite los metadatos HDR de la fuente y deja que el compositor de escritorio haga el mapeo.',
			'videoSettings.hdrToneMappingPlayer' => 'Reproductor',
			'videoSettings.hdrToneMappingPlayerDescription' => 'Realiza en el reproductor el mapeo al brillo máximo de la pantalla y luego comunica el resultado al compositor.',
			'videoSettings.hdrToneMappingFailed' => 'No se pudo cambiar el mapeo de tonos HDR; el modo anterior sigue activo.',
			'videoSettings.audioOutput' => 'Salida de audio',
			'videoSettings.performanceOverlay' => 'Indicador de rendimiento',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'Envolvente',
			'videoSettings.audioOutputSpatial' => 'Audio espacial',
			'videoSettings.audioOutputStereo' => 'Estéreo',
			'videoSettings.audioEqualizer' => 'Ecualizador de audio',
			'videoSettings.audioEqualizerDescription' => 'Ajuste cinco bandas de frecuencia para este dispositivo. Disponible en mpv; un EQ activo decoca el audio y desactiva la adaptación.',
			'videoSettings.audioEqualizerFlat' => 'Plano',
			'videoSettings.audioEqualizerActive' => 'Personalizado',
			'videoSettings.audioEqualizerSaveFailed' => 'No podría salvar la configuración de audio equalizer.',
			'videoSettings.backgroundVideoAudio' => 'Video Audio de fondo',
			'videoSettings.backgroundVideoAudioDescription' => 'Mantenga el audio de video cuando abandona el reproductor; la imagen está oculta hasta que vuelva. Android utiliza una notificación de reproducción de medios.',
			'videoSettings.audioNormalization' => 'Normalizar volumen',
			'videoSettings.audioNormalizationDisablesPassthrough' => 'Decodifica el audio a PCM; la transferencia directa está desactivada mientras esta opción esté activa',
			'performanceOverlay.color' => 'Color',
			'performanceOverlay.performance' => 'Rendimiento',
			'performanceOverlay.buffer' => 'Búfer',
			'performanceOverlay.app' => 'App',
			'performanceOverlay.decoder' => 'Decodificador',
			'performanceOverlay.rawDecoder' => 'Decodificador sin procesar',
			'performanceOverlay.tunneling' => 'Túnel',
			'performanceOverlay.passthrough' => 'Transferencia directa',
			'performanceOverlay.aspect' => 'Aspecto',
			'performanceOverlay.rotation' => 'Rotación',
			'performanceOverlay.dvSource' => 'Origen DV',
			'performanceOverlay.dvPath' => 'Ruta DV',
			'performanceOverlay.dvRouteDecoder' => 'Decodificador Dolby Vision',
			'performanceOverlay.dvRouteDecoderP81' => 'Decodificador Dolby Vision (P7→8.1)',
			'performanceOverlay.dvRouteBaseLayer' => 'Capa base',
			'performanceOverlay.dvRouteBaseLayerHdr10' => 'Capa base HDR10',
			'performanceOverlay.dvRouteBaseLayerHlg' => 'Capa base HLG',
			'performanceOverlay.dvRouteBaseLayerSdr' => 'Capa base SDR',
			'performanceOverlay.dvRouteReshaped' => 'Remodelado con RPU (gpu-next)',
			'performanceOverlay.dvRouteFelGraphActive' => 'El gráfico experimental P7 FEL (no cualificado)',
			'performanceOverlay.p7Conversion' => 'Conv. P7',
			'performanceOverlay.sampleRate' => 'Frecuencia de muestreo',
			'performanceOverlay.pixelFormat' => 'Formato de píxel',
			'performanceOverlay.hwFormat' => 'Formato HW',
			'performanceOverlay.matrix' => 'Matriz',
			'performanceOverlay.primaries' => 'Primarios',
			'performanceOverlay.transfer' => 'Transferencia',
			'performanceOverlay.renderFps' => 'FPS render',
			'performanceOverlay.displayFps' => 'FPS pantalla',
			'performanceOverlay.avSync' => 'Sincronía A/V',
			'performanceOverlay.dropped' => 'Descartados',
			'performanceOverlay.dvRpus' => 'DV RPUs',
			'performanceOverlay.dvRpuAverage' => 'Prom. DV RPU',
			'performanceOverlay.dvSampleAverage' => 'Prom. muestra DV',
			'performanceOverlay.maxLuma' => 'Luma máx.',
			'performanceOverlay.minLuma' => 'Luma mín.',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => 'Caché usada',
			'performanceOverlay.cacheLimit' => 'Límite de caché',
			'performanceOverlay.speed' => 'Velocidad',
			'performanceOverlay.player' => 'Reproductor',
			'performanceOverlay.playMethod' => 'El método de juego',
			'performanceOverlay.memory' => 'Memoria',
			'performanceOverlay.uiFps' => 'FPS UI',
			'performanceOverlay.fps' => 'FPS',
			'performanceOverlay.decoderAndroidHw' => 'HW de Android',
			'performanceOverlay.decoderNvidiaHw' => 'HW de NVIDIA',
			'performanceOverlay.decoderQualcommHw' => 'HW de Qualcomm',
			'performanceOverlay.decoderMediatekHw' => 'HW de MediaTek',
			'performanceOverlay.decoderExynosHw' => 'HW de Exynos',
			'performanceOverlay.decoderSoftware' => 'Software',
			'performanceOverlay.decoderHardware' => 'Hardware',
			'performanceOverlay.tunnelingActive' => 'Activo',
			'performanceOverlay.dvRpuFailed' => ({required Object converted, required Object failures}) => '${converted} (${failures} con error)',
			'externalPlayer.title' => 'Reproductor externo',
			'externalPlayer.useExternalPlayer' => 'Usar reproductor externo',
			'externalPlayer.useExternalPlayerDescription' => 'Abrir videos en otra aplicación',
			'externalPlayer.selectPlayer' => 'Seleccionar reproductor',
			'externalPlayer.customPlayers' => 'Reproductores personalizados',
			'externalPlayer.systemDefault' => 'Predeterminado del sistema',
			'externalPlayer.addCustomPlayer' => 'Añadir reproductor personalizado',
			'externalPlayer.playerName' => 'Nombre del reproductor',
			'externalPlayer.playerNameHint' => 'Mi reproductor',
			'externalPlayer.playerCommand' => 'Comando',
			'externalPlayer.playerPackage' => 'Nombre del paquete',
			'externalPlayer.playerUrlScheme' => 'Esquema URL',
			'externalPlayer.off' => 'Desactivado',
			'externalPlayer.launchFailed' => 'No se pudo abrir el reproductor externo',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} no está instalado',
			'externalPlayer.playInExternalPlayer' => 'Reproducir en reproductor externo',
			'externalPlayer.description' => 'Seleccione otra aplicación para abrir videos en. Los jugadores disponibles dependen de su dispositivo y las aplicaciones instaladas.',
			'externalPlayer.systemDefaultDescription' => 'Deja que el sistema operativo abra el vídeo con su aplicación por defecto.',
			'externalPlayer.playerOptionDescription' => ({required Object player}) => 'Abrir videos con ${player}.',
			'externalPlayer.playerNameDescription' => 'La etiqueta que se muestra en la lista de jugadores.',
			'externalPlayer.playerPackageDescription' => 'Introduce el nombre del paquete Android de la aplicación de jugador, como com.example.player.',
			'externalPlayer.playerCommandDescription' => 'Introduce el comando de jugador instalado o la ruta ejecutable para este dispositivo.',
			'externalPlayer.playerUrlSchemeDescription' => 'Introduce el esquema de URL y la plantilla de URL opcional utilizada para lanzar al jugador.',
			'metadataEdit.editMetadata' => 'Editar...',
			'metadataEdit.screenTitle' => 'Editar metadatos',
			'metadataEdit.basicInfo' => 'Información básica',
			'metadataEdit.artwork' => 'Imágenes',
			'metadataEdit.advancedSettings' => 'Ajustes avanzados',
			'metadataEdit.title' => 'Título',
			'metadataEdit.sortTitle' => 'Título de ordenación',
			'metadataEdit.originalTitle' => 'Título original',
			'metadataEdit.releaseDate' => 'Fecha de estreno',
			'metadataEdit.contentRating' => 'Clasificación de contenido',
			'metadataEdit.studio' => 'Estudio',
			'metadataEdit.tagline' => 'Eslogan',
			'metadataEdit.summary' => 'Resumen',
			'metadataEdit.poster' => 'Póster',
			'metadataEdit.background' => 'Fondo',
			'metadataEdit.logo' => 'Logo',
			'metadataEdit.squareArt' => 'Imagen cuadrada',
			'metadataEdit.selectPoster' => 'Seleccionar póster',
			'metadataEdit.selectBackground' => 'Seleccionar fondo',
			'metadataEdit.selectLogo' => 'Seleccionar logo',
			'metadataEdit.selectSquareArt' => 'Seleccionar imagen cuadrada',
			'metadataEdit.fromUrl' => 'Desde URL',
			'metadataEdit.uploadFile' => 'Subir archivo',
			'metadataEdit.enterImageUrl' => 'Introducir URL de imagen',
			'metadataEdit.imageUrl' => 'URL de imagen',
			'metadataEdit.metadataUpdated' => 'Metadatos actualizados',
			'metadataEdit.metadataUpdateFailed' => 'Error al actualizar los metadatos',
			'metadataEdit.artworkUpdated' => 'Imágenes actualizadas',
			'metadataEdit.artworkUpdateFailed' => 'Error al actualizar las imágenes',
			'metadataEdit.noArtworkAvailable' => 'No hay imágenes disponibles',
			'metadataEdit.artworkOption' => ({required Object index}) => 'Opción de imagen ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => 'Opción de imagen ${index}, seleccionada',
			'metadataEdit.notSet' => 'No establecido',
			'metadataEdit.libraryDefault' => 'Predeterminado de biblioteca',
			'metadataEdit.accountDefault' => 'Predeterminado de cuenta',
			'metadataEdit.seriesDefault' => 'Predeterminado de serie',
			'metadataEdit.episodeSorting' => 'Orden de episodios',
			'metadataEdit.oldestFirst' => 'Más antiguos primero',
			'metadataEdit.newestFirst' => 'Más recientes primero',
			'metadataEdit.keep' => 'Conservar',
			'metadataEdit.allEpisodes' => 'Todos los episodios',
			'metadataEdit.latestEpisodes' => ({required Object count}) => '${count} episodios más recientes',
			'metadataEdit.latestEpisode' => 'Episodio más reciente',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => 'Episodios añadidos en los últimos ${count} días',
			'metadataEdit.deleteAfterPlaying' => 'Eliminar episodios después de reproducir',
			'metadataEdit.never' => 'Nunca',
			'metadataEdit.afterADay' => 'Después de un día',
			'metadataEdit.afterAWeek' => 'Después de una semana',
			'metadataEdit.afterAMonth' => 'Después de un mes',
			'metadataEdit.onNextRefresh' => 'En la próxima actualización',
			'metadataEdit.seasons' => 'Temporadas',
			'metadataEdit.show' => 'Mostrar',
			'metadataEdit.hide' => 'Ocultar',
			'metadataEdit.episodeOrdering' => 'Orden de episodios',
			'metadataEdit.tmdbAiring' => 'The Movie Database (Emisión)',
			'metadataEdit.tvdbAiring' => 'TheTVDB (Emisión)',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB (Absoluto)',
			'metadataEdit.metadataLanguage' => 'Idioma de metadatos',
			'metadataEdit.useOriginalTitle' => 'Usar título original',
			'metadataEdit.preferredAudioLanguage' => 'Idioma de audio preferido',
			'metadataEdit.preferredSubtitleLanguage' => 'Idioma de subtítulos preferido',
			'metadataEdit.subtitleMode' => 'Selección automática de subtítulos',
			'metadataEdit.manuallySelected' => 'Seleccionado manualmente',
			'metadataEdit.shownWithForeignAudio' => 'Mostrar con audio extranjero',
			'metadataEdit.alwaysEnabled' => 'Siempre activado',
			'metadataEdit.tags' => 'Etiquetas',
			'metadataEdit.addTag' => 'Añadir etiqueta',
			'metadataEdit.genre' => 'Género',
			_ => null,
		} ?? switch (path) {
			'metadataEdit.director' => 'Director',
			'metadataEdit.writer' => 'Guionista',
			'metadataEdit.producer' => 'Productor',
			'metadataEdit.country' => 'País',
			'metadataEdit.collection' => 'Colección',
			'metadataEdit.label' => 'Etiqueta',
			'metadataEdit.quickTag' => 'Etiqueta rápida...',
			'matchScreen.match' => 'Asociar...',
			'matchScreen.fixMatch' => 'Corregir asociación...',
			'matchScreen.unmatch' => 'Desasociar',
			'matchScreen.unmatchConfirm' => '¿Borrar esta asociación? Plex tratará el elemento como no asociado hasta que vuelvas a asociarlo.',
			'matchScreen.unmatchSuccess' => 'Elemento desasociado',
			'matchScreen.unmatchFailed' => 'No se pudo desasociar el elemento',
			'matchScreen.matchApplied' => 'Asociación aplicada',
			'matchScreen.matchFailed' => 'No se pudo aplicar la asociación',
			'matchScreen.titleHint' => 'Título',
			'matchScreen.yearHint' => 'Año',
			'matchScreen.search' => 'Buscar',
			'matchScreen.noMatchesFound' => 'No se encontraron coincidencias',
			'serverTasks.title' => 'Tareas del servidor',
			'serverTasks.failedToLoad' => 'Error al cargar tareas',
			'serverTasks.noTasks' => 'No hay tareas en ejecución',
			'trakt.title' => 'Trakt',
			'trakt.connected' => 'Conectado',
			'trakt.connectedAs' => ({required Object username}) => 'Conectado como @${username}',
			'trakt.disconnectConfirm' => '¿Desconectar cuenta de Trakt?',
			'trakt.disconnectConfirmBody' => 'PlezyNG dejará de enviar eventos a Trakt. Puedes reconectar cuando quieras.',
			'trakt.scrobble' => 'Scrobbling en tiempo real',
			'trakt.scrobbleDescription' => 'Enviar eventos de reproducción, pausa y parada a Trakt durante la reproducción.',
			'trakt.watchedSync' => 'Sincronizar el estado de visualización',
			'trakt.watchedSyncDescription' => 'Cuando marques contenido como visto en PlezyNG, también se marcará como visto en Trakt.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Conectar Seerr',
			'seerr.serverUrl' => 'URL del servidor',
			'seerr.serverUrlHelper' => 'La dirección de tu instancia de Seerr',
			'seerr.checkServer' => 'Continuar',
			'seerr.signInWithJellyfin' => 'Iniciar sesión con Jellyfin',
			'seerr.signInWithEmby' => 'Iniciar sesión con Emby',
			'seerr.signInWithLocal' => 'Usar una cuenta local',
			'seerr.email' => 'Correo electrónico',
			'seerr.noSignInMethods' => 'Esta instancia de Seerr no ofrece ningún método de inicio de sesión compatible con PlezyNG.',
			'seerr.instance' => 'Instancia',
			'seerr.disconnectConfirm' => '¿Desconectar Seerr?',
			'seerr.disconnectConfirmBody' => 'PlezyNG olvidará esta instancia de Seerr. Reconecta cuando quieras.',
			'seerr.request' => 'Solicitar',
			'seerr.request4k' => 'Solicitar en 4K',
			'seerr.seasons' => 'Temporadas',
			'seerr.allSeasons' => 'Todas las temporadas',
			'seerr.advancedOptions' => 'Avanzado',
			'seerr.destinationServer' => 'Servidor de destino',
			'seerr.qualityProfile' => 'Perfil de calidad',
			'seerr.rootFolder' => 'Carpeta raíz',
			'seerr.languageProfile' => 'Perfil de idioma',
			'seerr.tags' => 'Etiquetas',
			'seerr.noTags' => 'Sin etiquetas',
			'seerr.defaultOption' => ({required Object name}) => '${name} (predeterminado)',
			'seerr.animeNote' => 'Esta serie es un anime.',
			'seerr.requestSubmitted' => 'Solicitud enviada',
			'seerr.requestFailed' => ({required Object error}) => 'La solicitud falló: ${error}',
			'seerr.requestsLoadFailed' => 'No se pudieron cargar las opciones de solicitud',
			'seerr.nothingToRequest' => 'Todo ya está disponible o solicitado.',
			'seerr.statusAvailable' => 'Disponible',
			'seerr.statusPartiallyAvailable' => 'Parcialmente disponible',
			'seerr.statusRequested' => 'Solicitado',
			'seerr.statusProcessing' => 'Procesando',
			'seerr.statusBlocklisted' => 'En la lista de bloqueo',
			'seerr.couldNotReach' => ({required Object url, required Object error}) => 'No se pudo conectar con ${url}: ${error}',
			'seerr.noInstanceAtUrl' => ({required Object url, required Object status}) => 'No hay ninguna instancia de Seerr en ${url} (HTTP ${status})',
			'seerr.behindAuthProxy' => 'Un proxy inverso con autenticación (SSO o autenticación HTTP) respondió en lugar de Seerr. PlezyNG no puede iniciar sesión a través de él: permite que la ruta /api/v1 de Seerr omita el proxy para esta aplicación, o usa una dirección que llegue a Seerr directamente.',
			'seerr.invalidUrl' => 'Introduce una dirección de servidor como https://seerr.example.com',
			'seerr.quickConnectUnsupported' => 'Esta instancia de Seerr no admite Quick Connect. Necesita Seerr 3.4 o más reciente.',
			'seerr.notInitialized' => 'Esta instancia de Seerr no ha completado la configuración inicial',
			'seerr.noPlexTokenForReauth' => 'No hay ningún token de Plex disponible para volver a iniciar sesión',
			'seerr.noStoredCredentials' => 'No hay credenciales guardadas disponibles para volver a iniciar sesión',
			'seerr.signInRejected' => 'Se rechazó el inicio de sesión',
			'seerr.noSessionCookie' => 'Seerr no proporcionó una cookie de sesión',
			'seerr.freshCookieRejected' => 'Seerr rechazó la nueva cookie de sesión',
			'seerr.noUserInformation' => 'Seerr no devolvió información del usuario',
			'seerr.sessionRejectedAfterReauth' => 'La sesión fue rechazada después de volver a iniciar sesión',
			'seerr.permissionDenied' => 'Seerr denegó esta acción: tu cuenta ya no tiene el permiso necesario',
			'seerr.permissionRevoked' => 'Ya no tienes permiso para solicitar esto',
			'services.title' => 'Servicios',
			'services.hubSubtitle' => 'Sincroniza tu progreso de visualización y solicita nuevos títulos.',
			'services.integrations' => 'Integraciones',
			'services.notConnected' => 'No conectado',
			'services.connectedAs' => ({required Object username}) => 'Conectado como @${username}',
			'services.scrobble' => 'Registrar progreso automáticamente',
			'services.scrobbleDescription' => 'Actualiza tu lista cuando termines un episodio o película.',
			'services.disconnectConfirm' => ({required Object service}) => '¿Desconectar ${service}?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'PlezyNG dejará de actualizar ${service}. Reconecta cuando quieras.',
			'services.connectFailed' => ({required Object service}) => 'No se pudo conectar a ${service}. Inténtalo de nuevo.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.simklReconnect.title' => 'Reconectar Simkl',
			'services.simklReconnect.subtitle' => 'Simkl va a retirar el método de inicio de sesión que usa esta conexión. Al reconectar se abre simkl.com para autorizar a PlezyNG — PlezyNG nunca ve tu contraseña. Tu historial de visualización se conserva en Simkl.',
			'services.deviceCode.title' => ({required Object service}) => 'Activar PlezyNG en ${service}',
			'services.deviceCode.instructions' => 'Escanea el código QR o visita la dirección que aparece a continuación e introduce este código:',
			'services.deviceCode.openToActivate' => ({required Object service}) => 'Abrir ${service} para activar',
			'services.deviceCode.copyCode' => 'Copiar código de activación',
			'services.deviceCode.waitingForAuthorization' => 'Esperando autorización…',
			'services.deviceCode.codeCopied' => 'Código copiado',
			'services.oauthProxy.title' => ({required Object service}) => 'Inicia sesión en ${service}',
			'services.oauthProxy.body' => 'Escanea este código QR o abre la URL en cualquier dispositivo.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => 'Abrir ${service} para iniciar sesión',
			'services.pendingAuth.copyUrl' => 'Copiar URL de inicio de sesión',
			'services.pendingAuth.urlCopied' => 'URL copiada',
			'services.libraryFilter.title' => 'Filtro de bibliotecas',
			'services.libraryFilter.subtitleAllSyncing' => 'Sincronizando todas las bibliotecas',
			'services.libraryFilter.subtitleNoneSyncing' => 'No se sincroniza ninguna biblioteca',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} bloqueadas',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} permitidas',
			'services.libraryFilter.mode' => 'Modo de filtro',
			'services.libraryFilter.modeBlacklist' => 'Lista de exclusión',
			'services.libraryFilter.modeWhitelist' => 'Lista de inclusión',
			'services.libraryFilter.modeHintBlacklist' => 'Sincronizar todas las bibliotecas excepto las seleccionadas abajo.',
			'services.libraryFilter.modeHintWhitelist' => 'Sincronizar solo las bibliotecas seleccionadas abajo.',
			'services.libraryFilter.libraries' => 'Bibliotecas',
			'services.libraryFilter.noLibraries' => 'No hay bibliotecas disponibles',
			'services.libraryFilter.modeDescription' => 'Seleccione si las bibliotecas verificadas están bloqueadas de sincronizar o son las únicas bibliotecas que sincronizan.',
			'services.seerrDescription' => 'Conecte a Seerr o Overseerr para buscar títulos y enviar solicitudes de medios.',
			'services.trackerDescriptions.trakt' => 'Sínculo de episodios y películas vistas con su cuenta Trakt.',
			'services.trackerDescriptions.mal' => 'Sync listas de anime y ver el progreso con MyAnimeList.',
			'services.trackerDescriptions.anilist' => 'Sync listas de anime y ver el progreso con AniList.',
			'services.trackerDescriptions.simkl' => 'Sync ha visto películas, programas de televisión y anime con Simkl.',
			'services.trackerDescriptions.mdblist' => 'Mostrar las calificaciones y listas de MDBList en recomendaciones y Explore.',
			'addServer.addMediaBrowserTitle' => ({required Object product}) => 'Añadir servidor ${product}',
			'addServer.serverUrls' => 'Direcciones URL del servidor',
			'addServer.serverUrlsHelper' => 'Se permiten varias URL, separadas por comas.',
			'addServer.findServer' => 'Buscar servidor',
			'addServer.searchingLocalMediaBrowserServers' => ({required Object product}) => 'Buscando servidores ${product} locales...',
			'addServer.localMediaBrowserServers' => ({required Object product}) => 'Servidores ${product} locales',
			'addServer.username' => 'Usuario',
			'addServer.password' => 'Contraseña',
			'addServer.signIn' => 'Iniciar sesión',
			'addServer.change' => 'Cambiar',
			'addServer.required' => 'Obligatorio',
			'addServer.couldNotReachServer' => ({required Object error}) => 'No se pudo conectar con el servidor: ${error}',
			'addServer.signInFailed' => ({required Object error}) => 'Error al iniciar sesión: ${error}',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Quick Connect ha fallado: ${error}',
			'addServer.addPlexTitle' => 'Iniciar sesión con Plex',
			'addServer.pinExpired' => 'El PIN caducó antes de iniciar sesión. Inténtalo de nuevo.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'No se pudo registrar la cuenta: ${error}',
			'addServer.enterMediaBrowserUrlError' => ({required Object product}) => 'Introduce la URL de tu servidor ${product}',
			'addServer.addConnectionTitle' => 'Añadir conexión',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => 'Añadir a ${name}',
			'addServer.signInWithPlexCard' => 'Iniciar sesión con Plex',
			'addServer.signInWithPlexCardSubtitle' => 'Autoriza este dispositivo. Se añaden servidores compartidos.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Autoriza una cuenta Plex. Los usuarios de Home se convierten en perfiles.',
			'addServer.connectToMediaBrowserCard' => ({required Object product}) => 'Conectar a ${product}',
			'addServer.connectToMediaBrowserCardSubtitle' => 'Introduce la URL de tu servidor, el nombre de usuario y la contraseña.',
			'addServer.connectToMediaBrowserCardSubtitleScoped' => ({required Object product, required Object name}) => 'Inicia sesión en tu servidor ${product}. Se vincula a ${name}.',
			'addServer.borrowFromAnotherProfile' => 'Tomar prestado de otro perfil',
			'addServer.borrowFromAnotherProfileSubtitle' => 'Reutiliza la conexión de otro perfil. Los perfiles protegidos con PIN requieren un PIN.',
			'addServer.invalidCredentials' => 'Usuario o contraseña no válidos',
			'addServer.authResponseNotJson' => 'La respuesta de autenticación no era un JSON válido',
			'addServer.authResponseIncomplete' => 'La respuesta de inicio de sesión del servidor estaba incompleta',
			'addServer.quickConnectRejected' => 'Quick Connect fue rechazado por el servidor',
			'addServer.quickConnectNotJson' => 'La respuesta de Quick Connect no era un JSON válido',
			'addServer.quickConnectMissingFields' => 'La respuesta de Quick Connect no incluye el código o el secreto',
			'addServer.quickConnectPollRejected' => 'El servidor rechazó el sondeo de Quick Connect',
			'addServer.serverTimedOut' => 'El servidor no respondió a tiempo',
			'addServer.responseNotJson' => 'La respuesta del servidor no era un JSON válido',
			'addServer.responseMissingIdentity' => ({required Object product}) => 'A la respuesta le falta un ID o el nombre del servidor. ¿Es este un servidor ${product}?',
			'addServer.probeFailed' => ({required Object error}) => 'No se pudo conectar con el servidor: ${error}',
			'addServer.enterAtLeastOneUrl' => ({required Object product}) => 'Introduce al menos una URL de servidor ${product}',
			'addServer.noReachableServer' => ({required Object product}) => 'No se encontró ningún servidor ${product} accesible',
			'addServer.urlsPointToDifferentServers' => ({required Object product}) => 'Estas URL apuntan a servidores ${product} distintos',
			'addServer.urlDoesNotMatchServer' => ({required Object product}) => 'Esta URL no corresponde al servidor ${product}',
			'addServer.redirectUnsupported' => 'El servidor redirigió a una URL no compatible',
			'addServer.redirectDifferentHost' => ({required Object product}) => 'El servidor redirigió a un host diferente. Introduce directamente la URL final de ${product}.',
			'addServer.redirectInsecure' => 'El servidor redirigió de HTTPS a una URL no segura',
			'addServer.redirectUnsupportedEnterFinal' => ({required Object product}) => 'El servidor redirigió a una URL no compatible. Introduce directamente la URL final de ${product}.',
			'addServer.directPlexServerUrl' => 'URL del servidor Plex',
			'addServer.directPlexServerUrlHelper' => 'Introduce la IP y el puerto local de su servidor de medios Plex.',
			'addServer.directPlexServerUrlHint' => 'http://192.168.1.100:32400',
			'addServer.plexToken' => 'Plex Token (opcional)',
			'addServer.plexTokenHelper' => 'Deja blanco si el acceso sin auth está permitido en este servidor.',
			'addServer.plexTokenRequired' => 'Por favor, introduzca su token Plex (X-Plex-Token).',
			'addServer.connectDirectPlexCard' => 'Plex Server de medios (Direct / Local)',
			'addServer.connectDirectPlexCardSubtitle' => 'Conectar directamente con IP o URL local sin cuenta plex.tv.',
			'addServer.connectDirectPlexCardSubtitleScoped' => ({required Object name}) => 'Conecta directamente con la IP local o URL. Enlaza a ${name}.',
			'addServer.insecureTitle' => 'conexión sin cifrado',
			'addServer.insecureDescription' => ({required Object url}) => '${url} usa HTTP. Otras personas de la red pueden leer o modificar tu contraseña, tus tokens y tus archivos multimedia. Usa HTTPS cuando esté disponible. Continúa solo si confías en esta red y aceptas el riesgo.',
			'addServer.allowHttp' => 'Permitir HTTP',
			'addServer.httpsRequired' => 'Uso de HTTPS o permita expresamente una conexión no cifrada.',
			'cast.chooseDevice' => 'Casta a un dispositivo',
			'cast.searching' => 'Buscando los dispositivos de casting...',
			'cast.connectedTo' => ({required Object device}) => 'Conectado a ${device}',
			'cast.device' => 'Dispositivo de Cast',
			'cast.readyToCast' => 'Prepara para lanzar',
			'cast.subtitle' => 'Subtítulos',
			'cast.serverNotAvailable' => 'El servidor de medios no está disponible.',
			'cast.stopCasting' => 'Dejar de casting',
			'cast.castToDevice' => 'Casta en el dispositivo',
			'cast.noEpisodeAvailable' => 'No hay episodio disponible para ser lanzado.',
			'cast.startFailed' => 'No puedo empezar a casting. comprobar el servidor y intentarlo de nuevo.',
			'automation.noActivePlayback' => 'No hay sesión de vídeo activa para controlar.',
			'automation.profileNotFound' => 'El perfil de Plezy no se encontró.',
			'notifications.newEpisodeTitle' => 'Nuevo episodio',
			'notifications.newEpisodeBody' => ({required Object show, required Object episode}) => '${show} · ${episode}',
			'appAccess.title' => 'Tenta cada función gratis durante 7 días',
			'appAccess.description' => 'Comienza un ensayo de siete días con acceso completo a cada función PlezyNG. no hay cargas durante el ensayo y no hay suscripción. Después del ensayo, una compra de vida al precio de su tienda desbloqueará PlezyNG por vida.',
			'appAccess.trialEndedDescription' => 'Desbloquear cada función en PlezyNG para la vida con una compra al precio de su tienda.',
			'appAccess.startTrial' => 'Comienza mi prueba gratuita de 7 días',
			'appAccess.trialActive' => 'Su prueba de 7 días de funcionamiento completo está activa.',
			'appAccess.trialEnded' => 'Su juicio de 7 días ha terminado',
			'appAccess.trialStartFailed' => 'No puedo salvar el ensayo en este dispositivo. por favor, intente de nuevo.',
			'appAccess.lifetimeTitle' => 'PlezyNG desbloqueado para la vida',
			'appAccess.lifetimeBody' => '¡Gracias!Tienes acceso a toda la vida a cada función PlezyNG.',
			'appAccess.manageTitle' => 'PlezyNG Acceso a la vida',
			'appAccess.manageDescription' => 'Proba cada función gratis durante 7 días, luego desbloquea todo por la vida con un solo pago al precio de su tienda.',
			'appAccess.buy' => ({required Object price}) => 'Desbloquear todas las características para ${price}',
			'appAccess.loadingPrice' => 'Precio de la tienda de carga...',
			'appAccess.retryPrice' => 'Retiro de precios Lookup',
			'appAccess.restore' => 'Restaurar la compra de vida',
			'appAccess.pending' => 'Su compra está esperando el pago o la aprobación.El acceso a la vida se desbloqueará tan pronto como la tienda lo completa.',
			'appAccess.storeUnavailable' => 'Verifique que está firmado en el tienda y las compras son permitidas en este dispositivo.',
			'appAccess.productNotFound' => 'El desbloqueo de vida PlezyNG aún no está disponible en esta tienda.',
			'appAccess.productQueryFailed' => 'No podría cargar el precio del almacén. comprobar su conexión y intentarlo de nuevo.',
			'appAccess.purchaseFailed' => 'La compra no ha pasado, vuelve a probar.',
			'appAccess.restoreFailed' => 'No podía llegar a la tienda para restaurar su compra.',
			'appAccess.nothingToRestore' => 'No PlezyNG compra de vida se encontró para esta cuenta de la tienda.',
			'detail.endsAt' => ({required Object time}) => 'Termina a las ${time}',
			'watchLink.serverUnavailable' => 'No podía llegar a un servidor Plex para este enlace.',
			'watchLink.notFound' => 'No podría encontrar este espectáculo o película en sus servidores Plex.',
			'watchLink.ambiguous' => 'Este enlace se ajusta a los elementos en más de un servidor.Añadir un servidor al enlace.',
			'watchLink.plexOnly' => 'Los enlaces de seguimiento actualmente solo soportan los servidores Plex.',
			'watchLink.unsupportedItem' => 'Las ligazones de visualización sólo pueden abrir un espectáculo o una película.',
			'watchLink.menuItem' => 'Ver el enlace',
			'watchLink.dialogTitle' => 'Ver el link',
			'watchLink.dialogShowHint' => 'Abriendo este enlace se juega el siguiente episodio.Añadir &mode=shuffle al final para jugar el espectáculo en shuffle.',
			'watchLink.dialogMovieHint' => 'Abriendo este enlace juega la película.',
			'watchLink.copy' => 'Copia',
			'watchLink.copied' => 'Link copiado',
			'homeLayout.title' => 'Home Layout',
			'homeLayout.resetToast' => 'Home Reset a la versión original de la versión Plezy',
			'homeLayout.resetHeroTitle' => '¿Recuperar el layout de héroe a la stock Plezy?',
			'homeLayout.resetHeroBody' => 'Desvia el ajuste de la hermana de cada ronda y retorna el único banner de rotación en la parte superior de la casa, como antes de que las líneas de la hermano existieran.',
			'homeLayout.removeRowTitle' => '¿Descubrir la línea de casa?',
			'homeLayout.removeRowBody' => ({required Object title}) => '${title} se eliminará. no puede ser negado.',
			'homeLayout.sync' => 'Síntomas',
			'homeLayout.syncAccountTitle' => 'Síntese el diseño con tu cuenta Plex',
			'homeLayout.syncAccountOn' => 'En: este dispositivo comparte orden de línea, líneas, Hero y Auto-slide con sus otros dispositivos.',
			'homeLayout.syncAccountOff' => 'Desactivado: este dispositivo mantiene su propio layout.',
			'homeLayout.syncNow' => 'Síntomas ahora',
			'homeLayout.plexHomeManager' => 'Plex Director de la casa',
			'homeLayout.managePlexRows' => 'Gestión Plex líneas en Plezy',
			'homeLayout.managePlexRowsDescription' => 'Abierto a organizar las líneas seleccionadas por el hogar',
			'homeLayout.organizeHomeRows' => 'Organizar las rutas domésticas',
			'homeLayout.organizeHomeRowsDescription' => ({required Object n}) => '${n} líneas: movimiento, Hero, Auto-slide, eliminación',
			'homeLayout.organizeLibraryRows' => ({required Object library}) => 'Organizar ${library} líneas',
			'homeLayout.organizeLibraryRowsDescription' => ({required Object n}) => 'Continuar Vea + ${n} líneas: movimiento, Biblioteca, Casa, Héroe, Auto-slide',
			'homeLayout.renderAsHero' => 'Render como una tarjeta de héroe',
			'homeLayout.heroOnlySingleCollection' => 'Sólo disponible cuando esta línea se resuelva a los títulos reales de una sola colección',
			'homeLayout.hero' => 'Hermano',
			'homeLayout.autoSlide' => 'Auto-Slide',
			'homeLayout.autoSlideDescription' => 'Las entradas (PC) y d-pad (TV) siempre funcionan y reinicien el timer.',
			'homeLayout.autoSlideEditDescription' => 'También se desliza por sí misma cada pocos segundos. desactivado: sólo se mueve cuando usted haga clic en una pistola (PC) o presiona la izquierda/derecha en la remota (TV).',
			'homeLayout.enableHeroFirst' => 'En primer lugar, el héroe',
			'homeLayout.showOnHome' => 'Mostrando en la pantalla de casa',
			'homeLayout.home' => 'Inicio',
			'homeLayout.removeFromHome' => 'Removir de casa',
			'homeLayout.selectRowsFirst' => 'Seleccione las líneas de inicio debajo primero.',
			'homeLayout.plexManagedRows' => ({required Object n}) => '${n} Plex líneas gestionadas',
			'homeLayout.continueWatching' => 'Seguir viendo',
			'homeLayout.continueWatchingLibraryDescription' => 'La red de resumen de la propia biblioteca',
			'homeLayout.continueWatchingHomeDescription' => 'La línea de progreso de resumen mostrada en Home',
			'homeLayout.nextUpHomeDescription' => 'La siguiente secuencia de episodios no observados se muestra separadamente en Home',
			'homeLayout.library' => 'Biblioteca',
			'homeLayout.showInRecommended' => 'Presentación en Biblioteca Recomendada',
			'homeLayout.customPlexRow' => 'Conexión Plex',
			'homeLayout.heroNeedsLibrary' => 'Véase la biblioteca primero — El héroe necesita algo para mostrar',
			'homeLayout.heroNeedsSurface' => 'Véase la Biblioteca o la Casa primero — El héroe necesita algo para mostrar',
			'homeLayout.removeHub' => 'Descargar Hub',
			'homeLayout.noPlexRows' => 'No Plex líneas gestionadas devueltas para esta biblioteca.',
			'homeLayout.openDetails' => 'Detalles abiertos',
			'homeLayout.heroCards' => 'Cartas de héroe',
			'homeLayout.tapHeroCard' => 'Tapa una tarjeta de héroe',
			'homeLayout.tvPlayFocus' => 'TV remota: botón de juego',
			'homeLayout.tvPlayFocusDescription' => 'D-pad abajo se detiene en el botón de juego antes de moverse a la siguiente línea.',
			'homeLayout.tvWrap' => 'TV remote: tarjetas de héroe de la cinta',
			'homeLayout.tvWrapDescription' => 'Justo en la última tarjeta vuelve a la primera.Después se detiene en la última.La izquierda en la primera tarjeta siempre va a la barra lateral.',
			'homeLayout.castOnHero' => 'Los héroes de los banners',
			'homeLayout.castOnHeroDescription' => 'Mostra el cast a lo largo del fondo de un banner héroe. Después de lo que guarda sólo el título y el resumen.',
			'homeLayout.customRows' => 'Rutas personalizadas',
			'homeLayout.loading' => 'La casa de la Layout...',
			'homeLayout.noCustomRows' => 'No hay rutas de costumbre',
			'homeLayout.addRowHint' => 'Utilice la línea de entrada para crear una.',
			'homeLayout.addHomeRow' => 'Añadir la ronda de casa',
			'homeLayout.addHomeRowDescription' => 'Seleccione una categoría; la nueva línea se añade automáticamente a Organizador',
			'homeLayout.removeRow' => 'Remover la línea',
			'homeLayout.recentlyAdded' => 'Añadido recientemente',
			'homeLayout.recentlyReleased' => 'recientemente liberado',
			'homeLayout.movieCollections' => 'Colecciones de películas',
			'homeLayout.showCollections' => 'Mostrar colecciones',
			'homeLayout.rowTitle' => 'Título Row',
			'homeLayout.content' => 'contenidos',
			'homeLayout.showThisRowIn' => 'Mostrar esta línea en:',
			'homeLayout.libraryRecommended' => 'Biblioteca Recomendada',
			'homeLayout.heroCard' => 'Tarjeta de héroe',
			'homeLayout.heroCardDescription' => 'Mostra como una tarjeta de rotación de ancho en lugar de una esquina de carteles.',
			'homeLayout.heroUnavailableDescription' => 'Sólo está disponible cuando esta línea se resuelva a los títulos reales de una sola colección — con más de una colección seleccionada no hay ningún título para girar.',
			'homeLayout.librariesSelection' => 'Librerías (deja todas las bibliotecas sin verificación para incluir todas las biblioteas)',
			'homeLayout.librariesMergedDescription' => 'Cada biblioteca que se ve aquí se une a esta una línea.',
			'homeLayout.movieCollectionsSelection' => 'Colecciones de películas (deja todas las no verificadas para cada biblioteca seleccionada)',
			'homeLayout.showCollectionsSelection' => 'Mostrar colecciones (deja todas las no verificadas para cada biblioteca seleccionada)',
			'homeLayout.collectionRowsDescription' => 'Si una colección se juega, sus títulos muestran directamente en la línea.Si más de una juega, cada colección se muestran como un solo poster, haga clic en él para abrir esa colección.',
			'homeLayout.allCollections' => 'Todas las colecciones',
			'homeLayout.noRowsHere' => 'No hay líneas aquí todavía.',
			'homeLayout.hideWatchedRows' => 'Esconde los objetos observados en líneas',
			'homeLayout.hideWatchedRowsDescription' => 'Títulos totalmente observados dejan Casa y biblioteca Rías recomendadas.',
			'homeLayout.untitledCollection' => 'Colección sin título',
			'homeLayout.moveRowHint' => 'Up/Down: moverse la línea · Seleccione: descifrarlo aquí · Volver: cancelar',
			'homeLayout.organizeRowsHint' => 'Seleccione en una línea (o mantenerse Seleccione): moverla · Izquierda/derecha: opciones de línea · Volver: hecho',
			'homeLayout.layoutNavDescription' => 'Elegir líneas, bibliotecas y categorías de colección',
			'homeLayout.editHomeRow' => 'Edit Home Rue',
			'homeLayout.resetHeroButton' => 'Reset el layout de héroe a stock Plezy',
			'homeLayout.reorderingUnlocked' => 'Reorganización desbloqueada',
			'homeLayout.reorderingLocked' => 'Reorganización localizada',
			'homeLayout.rowsCanBeDragged' => 'Las rayas pueden ser atraídas — tapar el cierre para evitar que',
			'homeLayout.tapLockToDrag' => 'Toma el cierre para sacar líneas',
			'homeLayout.customRowLabel' => ({required Object title}) => 'Cálculo: ${title}',
			'homeLayout.libraryHubLabel' => ({required Object library, required Object hub}) => '${library}: ${hub}',
			'homeLayout.hide' => 'Ocultar',
			'homeLayout.remove' => 'Eliminar',
			'homeLayout.libraryResumeRow' => 'La red de la biblioteca de esta red',
			'homeLayout.pressAgainToDelete' => 'Presiona de nuevo para eliminar',
			'homeLayout.actionState' => ({required Object action, required Object state}) => '${action}: ${state}',
			'homeLayout.on' => 'En',
			'homeLayout.resetHeroButtonDescription' => 'Desvia el ajuste de la hermana de cada ronda y retorna el único banner de rotación en la parte superior, como antes de que las ramas de hermano existieran.',
			'homeLayout.tapHeroCardDescription' => 'Seleccione si tapando o seleccionando una tarjeta Hero comienza la reproducción o abre sus detalles.',
			'homeLayout.heroTapPlayDescription' => 'Comienza el elemento seleccionado de inmediato.',
			'homeLayout.heroTapDetailsDescription' => 'Abre los detalles del elemento seleccionado antes de elegir una acción.',
			'platform.localNetworkPermission' => 'PlezyNG se conecta a sus servidores de medios y dispositivos de reproducción en su red local.',
			'platform.locationPermission' => 'PlezyNG utiliza el acceso a la ubicación cuando iOS lo requiere para detectar tu red local y conectarse a tus servidores multimedia.',
			'platform.photoLibraryPermission' => 'Elige imágenes de tu fototeca para usarlas como carátulas y otras ilustraciones de tus archivos multimedia.',
			'platform.cameraPermission' => 'Escanear los códigos QR para unir un Companion Remote.',
			'universalMedia.title' => 'Medios abiertos',
			'universalMedia.shortcutHelp' => 'Juega un enlace, playlist o archivo para esta sesión.',
			'universalMedia.intro' => 'Abra un enlace, lista de reproducción o archivo. Playback utiliza el jugador estándar de PlezyNG y no añade historia a su biblioteca.',
			'universalMedia.openWhat' => '¿Qué te gustaría abrir?',
			'universalMedia.stream' => 'Dirección de flujo',
			'universalMedia.playlist' => 'Playlista',
			'universalMedia.files' => 'Archivos de dispositivos',
			'universalMedia.favorites' => 'Los favoritos de los flujos salvos',
			'universalMedia.address' => 'Dirección de los medios',
			'universalMedia.addressHelp' => 'URLs con parámetros de credencia o firma reconocidos se utilizan únicamente para esta sesión y no pueden ser guardados como favoritos.',
			'universalMedia.displayName' => 'Nombre de pantalla (opcional)',
			'universalMedia.displayNameHelp' => 'Seleccione un nombre corto para el jugador y los controles de medios del sistema.',
			'universalMedia.allowHttp' => 'Permite una conexión HTTP sin cifrado',
			'universalMedia.allowHttpHelp' => 'HTTP no cifra la conexión. permita sólo en una red confiada. Use HTTPS cuando sea posible.',
			'universalMedia.advancedProtocols' => 'Solo MPV: introduzca una dirección RTSP, RTMP/RTMPS, UDP o RTP. Estas direcciones no se pueden guardar como favoritos.',
			'universalMedia.liveStream' => 'Tratar como vivo',
			'universalMedia.liveStreamHelp' => 'Utilice esto para video en vivo o radio.La aplicación esconde la barra de tiempo, botones de escape y la opción go-to-time.',
			'universalMedia.privateSession' => 'Solo esta reproducción utiliza la dirección.Save a un flujo elegible favorito para mantenerlo en este perfil.',
			'universalMedia.saveFavorite' => 'Salva los favoritos',
			'universalMedia.playNow' => 'Juega ahora',
			'universalMedia.favoriteSaved' => 'El flujo favorito se salvó a este perfil',
			'universalMedia.skippedEntries' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: 'Descargar ${count} entrada de lista de reproducción no soportada o insegura.', many: 'Descargar ${count} entradas de lista de reproducción no apoyadas o inseguras.', other: 'Descargar ${count} entradas de lista de reproducción no apoyadas o inseguras.', ), 
			'universalMedia.playlistAddress' => 'Dirección Playlist',
			'universalMedia.playlistAddressHelp' => 'Abre una lista de reproducción M3U, M3u8, o PLS desde un enderezo web. enlaces de flujo directo no salvan la lista de reprodución.',
			'universalMedia.choosePlaylist' => 'Elegir el archivo de playlist',
			'universalMedia.openPlaylist' => 'Playlist abierto',
			'universalMedia.playlistFormatsHelp' => 'Una lista de reproducción puede contener hasta 1.000 artículos y 2 MB. HLS se manifiesta abierto como corrientes para que el jugador pueda elegir una calidad.',
			'universalMedia.noFavorites' => 'No se ha salvado el flujo de favoritos aún. los favoritos permanecen en este perfil.',
			'universalMedia.removeFavorite' => 'Eliminar el flujo favorito',
			'universalMedia.filesHelp' => 'Seleccione los archivos de audio, vídeo o ISO para una cueva temporal.Los archivos y las URL no se añaden a la historia de la biblioteca.',
			'universalMedia.chooseFiles' => 'Elegir archivos',
			'universalMedia.fileQueue' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '1 Archivo seleccionado', many: '${count} archivos seleccionados', other: '${count} archivos seleccionados', ), 
			'universalMedia.wifiTransfer' => 'Enviar archivos a través de Wi-Fi',
			'universalMedia.wifiTransferHelp' => 'Transferir archivos apoyados de un navegador en la misma red confiada.',
			'universalMedia.wifiTransferIntro' => 'Abre esta dirección en un navegador en otro dispositivo. Seleccione los archivos para agregarlos a la biblioteca de archivos y libros de este dispositivo.',
			'universalMedia.wifiTransferPrivacy' => 'Este dispositivo recibe archivos a través de su red local.Cualquier persona que conoce esta dirección puede enviar archivos hasta que se detenga la transferencia o la dirección expire después de 15 minutos.Másimo: 100 archivos, 4 GiB por archivo, 10 GiB total.',
			'universalMedia.wifiTransferStarting' => 'La preparación de una transferencia privada, a tiempo limitado...',
			'universalMedia.wifiTransferUnavailable' => 'No puede comenzar la transferencia. comprobar el acceso a la red local y intentarlo de nuevo.',
			'universalMedia.openThisAddress' => 'Abre una de estas direcciones en el dispositivo de envío',
			'universalMedia.copyAddress' => 'Copia de la dirección de transferencia',
			'universalMedia.addressCopied' => 'Dirección de transferencia copiada',
			'universalMedia.transferExpires' => ({required Object time}) => 'Esta dirección expira en ${time}.',
			'universalMedia.uploadCount' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${count} archivo recibido', many: 'Los archivos ${count} recibidos', other: 'Los archivos ${count} recibidos', ), 
			'universalMedia.uploadedData' => ({required Object size}) => 'Recogido por ${size}',
			'universalMedia.stopTransfer' => 'Detener la transferencia y invalidar la dirección',
			'universalMedia.startTransfer' => 'Inicio Transferencia',
			'universalMedia.wifiImportedFiles' => 'Transferencia Wi-Fi',
			'universalMedia.wifiBrowserTitle' => 'Envío de archivos a PlezyNG',
			'universalMedia.wifiBrowserIntro' => 'Seleccione archivos de audio, vídeo, ebook o cómics para enviar. Los archivos se almacenan en la biblioteca de archivos y libros de este dispositivo. Máximo: 100 archivos, 4 GiB por archivo, 10 GiB total.',
			'universalMedia.uploadFilesLabel' => 'Archivos para enviar',
			'universalMedia.uploadSelected' => 'Descargar archivos seleccionados',
			'universalMedia.uploadSelectFirst' => 'Seleccione uno o más archivos primero.',
			'universalMedia.uploading' => 'Envío',
			'universalMedia.uploadComplete' => 'Archivo añadido a PlezyNG.',
			'universalMedia.uploadFailed' => 'El archivo no puede ser añadido. mantenga esta página abierta y trate de nuevo.',
			'universalMedia.liveCue' => 'en vivo',
			'universalMedia.liveSession' => 'Streaming en vivo',
			'universalMedia.liveCueHelp' => 'Para el vídeo o la radio en vivo, la aplicación esconde la barra de tiempo y salta los botones. no salva la dirección o ver historia.',
			'universalMedia.sessionOnly' => 'Este playback es solo sesión',
			'universalMedia.sessionOnlyHelp' => 'Playback nunca salva el progreso o la historia.Save the stream as a favor to keep it in this profile if it is eligible.',
			'universalMedia.pictureAdjustments' => 'Adaptación de imágenes',
			'universalMedia.pictureHelp' => 'Estos cambios de imagen solo afectan a esta reproducción. se resuelven cuando la reproducción termina.',
			'universalMedia.resetPicture' => 'Recuperar la imagen',
			'universalMedia.brightness' => 'brillo',
			'universalMedia.contrast' => 'Contrast',
			'universalMedia.gamma' => 'El Gamma',
			'universalMedia.hue' => 'Hue',
			'universalMedia.saturation' => 'Saturado',
			'universalMedia.view360' => 'Vista plana para 360° de vídeo',
			'universalMedia.view360Help' => 'Utilice esto para un vídeo 360° equirectangular. MPV necesita el filtro v360 de FFmpeg para esta vista.',
			'universalMedia.view360Unavailable' => 'Esta configuración de MPV no podría aplicar el filtro 360°.',
			'universalMedia.view360Yaw' => 'Vista horizontal',
			'universalMedia.view360Pitch' => 'Vista Vertical',
			'universalMedia.view360FieldOfView' => 'El campo de visión',
			'universalMedia.recordStream' => 'Recuerdo en directo',
			'universalMedia.stopRecording' => 'Detener y guardar la grabación',
			'universalMedia.recordingStarted' => 'La grabación está activa. dejar la reproducción se detiene y salva la grabación.',
			'universalMedia.recordingSaved' => 'La grabación terminada y salvada.',
			'universalMedia.recordingActive' => 'Recuerda este dispositivo. dejar el playback se detiene y lo salva.',
			'universalMedia.recordingFormatHelp' => 'Para video, seleccione MKV o MPEG-TS. para audio, selecciona MKA o MKV.',
			'universalMedia.replaceRecordingTitle' => '¿Substituir esta grabación?',
			'universalMedia.replaceRecordingHelp' => 'PlezyNG recupera el archivo existente durante la grabación.Si no puede guardar la nueva grabación, plezyNG restaura la copia de seguridad.',
			'universalMedia.replaceRecording' => 'Reemplazo de archivos',
			'universalMedia.discHelp' => 'Abrir un disco en el disco óptico de este ordenador.También puede abrir una imagen ISO desde los archivos del dispositivo.',
			'universalMedia.discs' => 'Discos ópticos',
			'universalMedia.dvd' => 'DVD',
			'universalMedia.bluray' => 'El Blu-ray',
			'universalMedia.audioCd' => 'CD de audio',
			'universalMedia.discAvailability' => 'La reproducción de discos requiere una configuración MPV compatible, un disco soportado y permiso del sistema operativo. no puede superar la protección comercial del disco.',
			'universalMedia.converterTitle' => 'Convertir un archivo de medios locales',
			'universalMedia.converterHelp' => 'Utilice FFmpeg para hacer una copia de MP4, M4A o MP3.',
			'universalMedia.converterIntro' => 'Convertir un archivo de audio o vídeo local en un formato que funciona en más dispositivos.',
			'universalMedia.converterPrivacy' => 'FFmpeg debe ser instalado en este ordenador.Conversion lee solo los archivos locales.No descarga flujos ni elimina DRM.',
			'universalMedia.converterChooseInput' => 'Seleccione un archivo de medios locales',
			'universalMedia.converterFormat' => 'Formato de salida',
			'universalMedia.converterMp4' => 'MP4 · H.264 y AAC',
			'universalMedia.converterM4a' => 'M4A · AAC audio',
			'universalMedia.converterMp3' => 'MP3 y audio',
			'universalMedia.converterSaveAs' => 'Salva los medios convertidos como',
			'universalMedia.converterExtensionMismatch' => 'Seleccione un nombre de fil con la extensión de salida seleccionada.',
			'universalMedia.converterUnsupportedInput' => 'Seleccione un archivo de audio o vídeo.',
			'universalMedia.converterLocalOnly' => 'El archivo seleccionado no está disponible como vía de dispositivo local.',
			'universalMedia.converterReplaceTitle' => '¿Substituir este archivo?',
			'universalMedia.converterReplaceHelp' => 'El PCC recoge el archivo existente hasta que se salve la copia convertida.',
			'universalMedia.converterStarting' => 'Comenzando con FFmpeg...',
			'universalMedia.converterProgress' => 'Convertir en este ordenador...',
			'universalMedia.converterComplete' => 'Conversión completa.El nuevo archivo está listo.',
			'universalMedia.converterFfmpegMissing' => 'Instalar FFmpeg con soporte H.264, AAC y MP3, luego intente de nuevo.',
			'universalMedia.converterFailed' => 'Verifique que el archivo de fuente se puede leer y el destino tiene suficiente espacio libre.',
			'universalMedia.converterCancelled' => 'La conversión fue cancelada. la salida incompleta fue eliminada.',
			'universalMedia.converterDesktopOnly' => 'La conversión local está disponible en ordenadores de escritorio con FFmpeg instalado.',
			'universalMedia.converterStart' => 'Convertir archivos',
			'universalMedia.mediaToolsTitle' => 'herramientas de medios',
			'universalMedia.mediaToolsShortcut' => 'Capturar o compartir medios, agregar extensiones de búsqueda, o utilizar la línea de comando.',
			'universalMedia.mediaToolsIntro' => 'Seleccione una herramienta enfocada. captura y flujo-out utiliza FFmpeg instalado en este escritorio. Extensiones y comandos CLI utiliza solicitudes HTTPS limitadas y el flujo Open media existente.',
			'universalMedia.mediaToolsAccessibility' => 'Las opciones de herramientas y los controles funcionan con toque, indicador, teclado y foco D-pad. Se anuncian cambios en el estado de grabación, compartir y buscar.',
			'universalMedia.mediaTool' => 'herramientas de medios',
			'universalMedia.captureIntro' => 'Recordar su pantalla o una cámara a un archivo MP4 en este ordenador. FFmpeg debe ser instalado y incluir el codificador H.264.',
			'universalMedia.captureNoDevices' => 'No se encontró ninguna pantalla o cámara. verifique el soporte de captura de FFmpeg y las autorizaciones de privacidad del sistema operativo.',
			'universalMedia.captureSource' => 'pantalla o cámara',
			'universalMedia.captureAudioSource' => 'Introducción de audio (opcional)',
			'universalMedia.captureAudioHelp' => 'Añadir audio desde un micrófono o entrada disponible. Las opciones de dispositivo dependen de FFmpeg y las permisiones del sistema.',
			'universalMedia.captureAudioNone' => 'No hay audio',
			'universalMedia.captureWaylandHelp' => 'Wayland limita esta captura XWayland a X display. Windows fuera de XWayland no puede aparecer.',
			'universalMedia.captureFrameRate' => 'Rate de grabación',
			'universalMedia.capturePrivacy' => 'La grabación se salva únicamente al archivo que usted elige. la captura de micrófonos es opcional. PlezyNG no carga la grabación.',
			'universalMedia.captureSaveAs' => 'Salva la grabación de pantalla como',
			'universalMedia.captureExtensionMismatch' => 'Seleccione un nombre de archivo que termina en .mp4.',
			'universalMedia.captureFfmpegMissing' => 'FFmpeg o el codificador de vídeo de H.264 no está disponible. instalar un edificio de FFmpeg que se apoya, y luego intentarlo de nuevo.',
			'universalMedia.captureFailed' => 'Verificar permiso del dispositivo, almacenamiento disponible, y soporte FFmpeg.',
			'universalMedia.captureSaved' => 'La grabación de pantalla se salvó.',
			'universalMedia.captureElapsedLabel' => 'tiempo de grabación',
			'universalMedia.captureStart' => 'Comienza la grabación',
			'universalMedia.captureStop' => 'Parar y salvar',
			'universalMedia.captureMode' => 'Capturas',
			'universalMedia.shareMode' => 'Compartir',
			'universalMedia.shareIntro' => 'Envíe un archivo de medios locales a otro dispositivo en su red privada. PlezyNG crea un flujo temporal de HLS.',
			'universalMedia.sharePrivacy' => 'Cualquiera en su red local que reciba el enlace privado puede ver mientras está activo.El enlace expire después de 60 minutos.',
			'universalMedia.shareChooseFile' => 'Elegir archivos de medios',
			'universalMedia.shareChooseHelp' => 'Seleccione un archivo de audio o vídeo local.El archivo permanece en este ordenador.',
			'universalMedia.shareFfmpegMissing' => 'FFmpeg o los codificadores H.264/AAC no están disponibles. Instalar FFmpeg con el soporte de codificación H.264 y AAC.',
			'universalMedia.shareFailed' => 'El flujo no pudo comenzar o detenerse inesperadamente. ver FFmpeg y el acceso a la red.',
			'universalMedia.shareActive' => 'El flujo está listo en su red privada.',
			'universalMedia.shareEnded' => 'Los medios han llegado al final y ya no se comparten.',
			'universalMedia.shareStopped' => 'El enlace temporal ya no es válido.',
			'universalMedia.shareUrlCopied' => 'La dirección de flujo se copia.',
			'universalMedia.shareOpenUrl' => 'Abre esta dirección en un jugador en el otro dispositivo',
			'universalMedia.shareCopyUrl' => 'Copia de la dirección de flujo',
			'universalMedia.shareExpiresLabel' => 'El enlace expira en',
			'universalMedia.shareStarting' => 'Preparando el flujo...',
			'universalMedia.shareStart' => 'Comenzar a compartir',
			'universalMedia.shareStop' => 'Dejar de compartir',
			'universalMedia.extensionsMode' => 'Extensiones y CLI',
			'universalMedia.extensionsIntro' => 'Añade una extensión de búsqueda de datos para encontrar medios. Seleccione un resultado para cargarlo en el formulario familiar Open media.',
			'universalMedia.extensionsPrivacy' => 'Un manifiesto puede definir uno de los campos de respuesta de búsqueda y de mapa de HTTPS. no puede ejecutar código, añadir títulos de solicitud, leer archivos o lanzar comandos de shell.',
			'universalMedia.extensionImport' => 'Añadir extension manifesto',
			'universalMedia.extensionEmpty' => 'No hay servicios de búsqueda todavía. Seleccione un archivo manifestado JSON confiable para agregar uno.',
			'universalMedia.extensionChoose' => 'Servicio de búsqueda',
			'universalMedia.extensionSearchConsent' => 'Cada búsqueda envía sus palabras a este servicio de HTTPS. Los resultados se abren sólo después de que seleccione uno.',
			'universalMedia.extensionSearchLabel' => 'Buscar medios',
			'universalMedia.extensionSearch' => 'búsqueda',
			'universalMedia.extensionSearching' => 'Buscando...',
			'universalMedia.extensionNoResults' => 'No se han devuelto resultados de los medios seguros. intenta otra búsqueda.',
			'universalMedia.extensionInstallTitle' => '¿Añadir este servicio de búsqueda?',
			'universalMedia.extensionReplaceTitle' => '¿Actualiza este servicio de búsqueda?',
			'universalMedia.extensionService' => 'Servicio',
			'universalMedia.extensionEndpoint' => 'HTTPS punto final',
			'universalMedia.extensionConsent' => 'Su texto de búsqueda se envía a este servicio.El manifesto no contiene código ejecutable.Sólo continúa si confía en este punto final.',
			'universalMedia.extensionInstall' => 'Añadir servicio',
			'universalMedia.extensionReplace' => 'Servicio de actualización',
			'universalMedia.extensionRemoveTitle' => '¿Elimina este servicio de búsqueda?',
			'universalMedia.extensionRemoveHelp' => 'Esto elimina el servicio de este perfil. PlezyNG no contacta con su punto final.',
			_ => null,
		} ?? switch (path) {
			'universalMedia.extensionRemove' => 'Eliminar el servicio',
			'universalMedia.extensionInvalidManifest' => 'Este archivo no es un manifiesto de extensión apoyado. ver la guía de Open media para el formato.',
			'universalMedia.extensionSaveFailed' => 'La extensión no pudo ser salvada al perfil activo.',
			'universalMedia.extensionSearchFailed' => 'El servicio de búsqueda no devolvió una respuesta válida. ver el punto final y intentarlo de nuevo.',
			'universalMedia.cliTitle' => 'línea de mando',
			'universalMedia.cliHelp' => 'Utilice la guía de plezyctl para validar un manifiesto o buscar la misma extensión. Revise su servicio de HTTPS antes de cada búsqueda. Resultados se abren en el formulario de medios existente; seleccione el botón de reproducción para comenzar.',
			'universalMedia.cliCopyExample' => 'Copia del ejemplo de comando',
			'universalMedia.cliCopied' => 'Exemplos de comandos copiados.',
			'universalMedia.captureScreen' => 'pantalla',
			'universalMedia.captureDefaultAudio' => 'Introducción de audio',
			'universalMedia.shareQrLabel' => 'Código QR para la dirección de flujo temporal',
			'universalMedia.shareQrHelp' => 'Escanear con un jugador compatible conectado a la misma red privada.',
			'universalMedia.shareHttpHint' => 'Esta corriente utiliza HTTP no cifrado. en PlezyNG, permita HTTP antes de abrirlo.',
			'fileSources.title' => 'Archivos y libros',
			'fileSources.subtitle' => 'Leer, escuchar y ver de sus propios archivos.',
			'fileSources.add' => 'añadir fuente',
			'fileSources.importFiles' => 'Importación de archivos',
			'fileSources.localFiles' => 'En este dispositivo',
			'fileSources.source' => 'Fuente',
			'fileSources.name' => 'Nombre',
			'fileSources.endpoint' => 'URL del servidor',
			'fileSources.smbEndpointHint' => 'Ejemplo: smb://nas/Movies',
			'fileSources.smbEndpointInvalid' => 'Introduce un servidor SMB y una carpeta compartida.',
			'fileSources.root' => 'Prefixo o prefixo',
			'fileSources.smbFolderHelp' => 'Déjalo en blanco para usar toda la carpeta compartida o introduce una carpeta dentro de ella.',
			'fileSources.username' => 'Usuario',
			'fileSources.smbDomain' => 'Dominio (opcional)',
			'fileSources.password' => 'Contraseña',
			'fileSources.token' => 'API Título',
			'fileSources.accessKey' => 'Acceso clave ID',
			'fileSources.secretKey' => 'La clave de acceso secreto',
			'fileSources.sessionToken' => 'Toca de sesión (opcional)',
			'fileSources.region' => 'Región',
			'fileSources.clientId' => 'ID de cliente de OAuth',
			'fileSources.clientSecret' => 'OAuth client secreto (sólo Google de escritorio)',
			'fileSources.allowHttp' => 'Permitir HTTP sin cifrar en una red de confianza',
			'fileSources.smbEncryption' => 'Cifrar la conexión SMB3',
			'fileSources.smbEncryptionHint' => 'Usar el cifrado SMB3 cuando el NAS lo admita.',
			'fileSources.connect' => 'Conectar',
			'fileSources.cancel' => 'Cancelar',
			'fileSources.save' => 'Guardar',
			'fileSources.close' => 'Cerrar',
			'fileSources.removeSource' => 'Desconectar fuentes',
			'fileSources.disconnectMessage' => 'Desconectar esta fuente? Los archivos descargados y su historia de lectura y escucha permanecerán en este dispositivo.',
			'fileSources.localFolder' => 'Seleccion de Folder',
			'fileSources.empty' => 'Aquí no hay nada todavía',
			'fileSources.emptyHint' => 'Añadir una fuente o importar un libro, audio, música o vídeo.',
			'fileSources.search' => 'Buscar esta cartera',
			'fileSources.searchCached' => 'Buscar librería salvada',
			'fileSources.refresh' => 'Actualizar',
			'fileSources.loadMore' => 'Carga más',
			'fileSources.offline' => 'Disponible offline',
			'fileSources.download' => 'Mantener offline',
			'fileSources.removeDownload' => 'Descargar copias offline',
			'fileSources.continueReading' => 'Continuar leyendo',
			'fileSources.continueListening' => 'Continuar escuchando',
			'fileSources.continueWatching' => 'Continuar observando',
			'fileSources.read' => 'Leer',
			'fileSources.listen' => 'Escuchando',
			'fileSources.play' => 'Reproducir',
			'fileSources.pause' => 'Pausar',
			'fileSources.stop' => 'Detener',
			'fileSources.startOver' => 'Comenzar por',
			'fileSources.finished' => 'Terminado',
			'fileSources.markFinished' => 'Marca terminó',
			'fileSources.markUnfinished' => 'Marca Infinida',
			'fileSources.editions' => 'Ediciones y archivos',
			'fileSources.chapters' => 'Capítulos',
			'fileSources.bookmarks' => 'Bookmarks y notas',
			'fileSources.bookmark' => 'Añadir Bookmark',
			'fileSources.highlight' => 'El destacamiento',
			'fileSources.note' => 'Nota',
			'fileSources.delete' => 'Eliminar',
			'fileSources.export' => 'Notas de exportación',
			'fileSources.exported' => 'Notas exportadas',
			'fileSources.sync' => 'Síntomas Progreso',
			'fileSources.synced' => 'Progreso sintezo',
			'fileSources.conflict' => 'Otro dispositivo tiene una posición diferente. escoge dónde continuar.',
			'fileSources.useLocal' => 'Utilice este dispositivo',
			'fileSources.useRemote' => 'Utilice otro dispositivo',
			'fileSources.history' => 'Historia de la posición',
			'fileSources.groupAudio' => 'Escucha como un audio',
			'fileSources.groupHint' => 'Combina los archivos de audio que actualmente se cargan en esta cartera. cargue todas las páginas primero.',
			'fileSources.order' => 'Archivo Orden',
			'fileSources.moveUp' => 'Moverse arriba',
			'fileSources.moveDown' => 'Moverse hacia abajo',
			'fileSources.speed' => 'Velocidad de Playback',
			'fileSources.sleep' => 'Temporizador de apagado',
			'fileSources.sleepOff' => 'Desactivado',
			'fileSources.endChapter' => 'Fin del capítulo',
			'fileSources.minutes' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(count, one: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minuto', many: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minutos', other: '${NumberFormat.decimalPattern(LocalePreferences.formattingLocaleName).format(count)} minutos', ), 
			'fileSources.skipBack' => 'Escape de vuelta',
			'fileSources.skipForward' => 'Escape hacia adelante',
			'fileSources.smartRewind' => 'El intento de volver después de una pausa',
			'fileSources.playbackOptions' => 'Opciones de escucha',
			'fileSources.remaining' => ({required Object time}) => '${time} Restos',
			'fileSources.contents' => 'contenidos',
			'fileSources.readerSettings' => 'Lectura de Settings',
			'fileSources.fontSize' => 'Tamaño de texto',
			'fileSources.lineHeight' => 'Línia de espacio',
			'fileSources.margin' => 'Margen',
			'fileSources.font' => 'Tipo de cara',
			'fileSources.serif' => 'Serio',
			'fileSources.sans' => 'Sin serio',
			'fileSources.mono' => 'Monospacio',
			'fileSources.columns' => 'Columnas',
			'fileSources.scroll' => 'Escrever verticalmente',
			'fileSources.justify' => 'Justificar el texto',
			'fileSources.readerTheme' => 'Aparecimiento de página',
			'fileSources.appTheme' => 'Siguiente Aplicación Tema',
			'fileSources.paper' => 'Papel',
			'fileSources.sepia' => 'Sepia',
			'fileSources.night' => 'Noche',
			'fileSources.readAloud' => 'Leer esta página en voz alta',
			'fileSources.readAlong' => 'Leer en',
			'fileSources.stopReading' => 'Deja la narración',
			'fileSources.searchBook' => 'Buscar en libro',
			'fileSources.noMatches' => 'No juegos',
			'fileSources.previousPage' => 'Página anterior',
			'fileSources.nextPage' => 'Siguiente Página',
			'fileSources.page' => ({required Object number}) => 'Página ${number}',
			'fileSources.externalBlocked' => 'Los enlaces de libro externos están desactivados en el lector.',
			'fileSources.loading' => 'Abriendo...',
			'fileSources.narrator' => 'narración',
			'fileSources.audio' => 'Audio',
			'fileSources.video' => 'Video',
			'fileSources.ebooks' => 'Ebooks',
			'fileSources.all' => 'Todos',
			'fileSources.downloads' => 'Archivos offline',
			'fileSources.confirmDelete' => '¿Eliminar la copia sin conexión seleccionada? Tu posición y tus notas se conservarán.',
			'fileSources.errorAuthentication' => 'Recibe la información para conectar esta fuente.',
			'fileSources.errorPermission' => 'Esta fuente no permitió el acceso al archivo solicitado.',
			'fileSources.errorUnavailable' => 'La fuente no está disponible.Tenta de nuevo, o abre una copia offline.',
			'fileSources.errorUnsupported' => 'Este formato o conexión no está supportado en este dispositivo. ver el guía de configuración de fuente.',
			'fileSources.errorInvalidData' => 'Este archivo o respuesta del servidor no puede ser leído de forma segura.',
			'fileSources.errorCancelled' => 'La operación fue cancelada.',
			'fileSources.errorConflict' => 'La posición cambió en otra sesión. reabre el elemento para elegir una posición.',
			'fileSources.signIn' => 'Iniciar sesión',
			'fileSources.reconnect' => 'Reconectar',
			'fileSources.folderHelp' => 'Deja blanco para comenzar en la raíz de la fuente. las URL de S3 incluyen el bucket.',
			'fileSources.preferences' => 'Preferencias',
			'fileSources.timePosition' => 'Posición',
			'fileSources.audioTrack' => 'Audio Track',
			'fileSources.subtitleTrack' => 'Subtítulo Track',
			'fileSources.none' => 'Ninguno',
			'fileSources.fullscreen' => 'pantalla completa',
			'fileSources.syncLocation' => 'Ficheiro de sincronización de progreso (opcional)',
			'fileSources.syncLocationHint' => 'Una cartera dedicada WebDAV para PlezyNG estado. utiliza escritos condicionales; los medios permanecen inalterados.',
			'fileSources.audiobooks' => 'Audioboques',
			'fileSources.comics' => 'Cómics',
			'fileSources.scan' => 'Escanear libros y medios',
			'fileSources.browserReader' => 'El lector abierto',
			'fileSources.browserReaderHelp' => 'El lector está abierto en su navegador.Mantense abierto PlezyNG para salvar su lugar y notas.',
			'fileSources.on' => 'En',
			'fileSources.advancedSetup' => 'Aplicación de registro',
			'fileSources.microsoftSignIn' => 'Inscribe con Microsoft',
			'fileSources.zoomIn' => 'Zoom en',
			'fileSources.zoomOut' => 'Zoom de salida',
			'fileSources.fitPage' => 'Página de FIT',
			'fileSources.fitWidth' => 'La ampliación',
			'fileSources.actualSize' => 'El tamaño actual',
			'fileSources.goToPage' => 'Ir a la página',
			'fileSources.goToSection' => 'Vuelve al capítulo',
			'fileSources.pageRange' => ({required Object count}) => 'Introduce un número de 1 a ${count}',
			'fileSources.pageLayout' => 'Página de layout',
			'fileSources.automatic' => 'Automático',
			'fileSources.singlePage' => 'Página única',
			'fileSources.twoPages' => 'Dos páginas',
			'fileSources.readingDirection' => 'Lectura dirección',
			'fileSources.leftToRight' => 'A la izquierda a la derecha',
			'fileSources.rightToLeft' => 'De derecha a izquierda',
			'fileSources.letterSpacing' => 'La carta espacial',
			'fileSources.wordSpacing' => 'Palabras espaciales',
			'fileSources.readerControlsHelp' => 'Separa dos dedos o usa los controles de zoom para ampliar las páginas. Arrastra para desplazarte por la página. Ctrl/⌘ con + o − ajusta el zoom; Ctrl/⌘ con 0 lo restablece. Page Up y Page Down cambian de página.',
			'fileSources.imagePage' => 'Página de cómic',
			'fileSources.resetReader' => 'Recuperar las preferencias de lectura',
			'fileSources.zoom' => 'Zoom',
			'fileSources.useFiles' => 'Utilice archivos y libros',
			'fileSources.cancelScan' => 'Cancelar el escáner',
			'fileSources.googleDrive' => 'Google Drive',
			'fileSources.offlineQuota' => 'Límite de descarga Offline',
			'fileSources.offlineQuotaHelp' => 'Establece el espacio máximo utilizado por copias offline, archivos importados y descargas que se quedan. La reducción del límite no remove las copias existentes.',
			'fileSources.offlineStorageUsage' => 'almacenamiento offline',
			'fileSources.reservedStorage' => 'reservado',
			'fileSources.downloadQueue' => 'Descarga de Queue',
			'fileSources.downloadRunning' => 'Descargar',
			'fileSources.downloadQueued' => 'Esperando',
			'fileSources.downloadPaused' => 'pausas',
			'fileSources.downloadFailed' => 'Necesidad de retraso',
			'fileSources.importing' => 'Importación',
			'fileSources.importInterrupted' => 'Importación interrumpida · eliminación para limpiar',
			'fileSources.errorQuotaExceeded' => 'El límite de almacenamiento offline se ha alcanzado. Subir el límite o eliminar una copia descargada.',
			'fileSources.errorStorageLow' => 'No hay suficiente almacenamiento gratuito para mantener la reserva protegida.',
			'fileSources.errorStorageUnavailable' => 'PlezyNG no pudo comprobar el almacenamiento del dispositivo gratuito, por lo que se detuvo la escritura.',
			'fileSources.removeDownloadJob' => 'Descargar Eliminar',
			'fileSources.downloadAlreadyComplete' => 'Esta descarga terminó antes de que pudiera ser eliminado. el artículo ahora está disponible offline.',
			'fileSources.confirmRemoveDownloadJob' => 'Eliminar esta descarga y descifrar todos los datos descargados parcialmente? su posición y las notas permanecerán.',
			'lending.title' => 'Bibliotecas Públicas',
			'lending.add' => 'Añadir una biblioteca',
			'lending.other' => 'Otra biblioteca',
			'lending.libraryName' => 'Nombre de la Biblioteca',
			'lending.libraryUrl' => 'Sitio web de la Biblioteca',
			'lending.libraryUrlHint' => 'Utilice el catálogo de su biblioteca o la página de suscripciones.',
			'lending.intro' => 'Encuentra tu biblioteca y mantenga sus libros cerrados.',
			'lending.handoff' => 'Inscribirse, prestar y leer de forma segura con el servicio de su propia biblioteca.',
			'lending.openService' => 'Biblioteca abierta',
			'lending.findLibrary' => 'Encuentra una biblioteca',
			'lending.search' => 'Buscar libros y autores',
			'lending.catalogue' => 'Catálogo',
			'lending.loans' => 'préstamos',
			'lending.holds' => 'Reservas',
			'lending.signIn' => 'Inscribe con tu biblioteca',
			'lending.waiting' => 'Terminar la suscripción en su navegador, y luego volver aquí.',
			'lending.cancel' => 'Cancelar',
			'lending.disconnect' => 'Remover la biblioteca',
			'lending.disconnectMessage' => '¿Quitar esta biblioteca de este perfil? Tus préstamos y reservas se conservarán en la biblioteca.',
			'lending.getBook' => 'Obtenga libro',
			'lending.checkAvailability' => 'Verificar la disponibilidad',
			'lending.available' => 'Disponible para prestar',
			'lending.unavailable' => 'Actualmente inaccesible',
			'lending.borrow' => 'Pedir prestado',
			'lending.placeHold' => 'Reservar',
			'lending.returnBook' => 'Regreso temprano',
			'lending.cancelHold' => 'Cancelar reserva',
			'lending.confirmBorrow' => '¿Quieres prestar este título de tu biblioteca?',
			'lending.confirmReturn' => '¿Devolver este título ahora? Es posible que tengas que volver a pedirlo prestado para continuar.',
			'lending.confirmCancelHold' => '¿Cancelar tu reserva de este título?',
			'lending.email' => 'Mantenerse en correo electrónico de notificación',
			'lending.due' => ({required Object date}) => 'El número de personas ${date}',
			'lending.queue' => ({required Object position}) => 'Posición ${position} en línea',
			'lending.empty' => 'No hay títulos aquí.',
			'lending.openLibraryNote' => 'Explore el catálogo de la Biblioteca Abierta.Las opciones de lectura y préstamo se muestran en la página de cada título.',
			'lending.more' => 'Carga más',
			'lending.gateway' => 'Biblioteca en servicio',
			'lending.gatewayHint' => 'Proporcionado por su biblioteca o el administrador PlezyNG.',
			'lending.advanced' => 'La integración de la biblioteca',
			'lending.loadLibraries' => 'Elegir tu biblioteca',
			'lending.expired' => 'El préstamo ha expirado.',
			'lending.updated' => 'Biblioteca actualizada',
			'lending.continueService' => 'Continuar en servicio',
			'lending.comingSoon' => 'In-app préstamo · Venga pronto',
			'lending.comingSoonDescription' => 'Usted puede usar su biblioteca en Libby mientras terminamos conectándola.',
			'lending.suspendHold' => 'Suspensión de mantenimiento',
			'lending.resumeHold' => 'Resumen de mantenimiento',
			'lending.suspendMessage' => '¿Conservar tu lugar en la cola y permitir que el siguiente lector tome prestado este ejemplar? Puedes reanudar la reserva más adelante.',
			'lending.resumeMessage' => '¿Reanudar esta reserva para que la biblioteca pueda ofrecerte el siguiente ejemplar disponible?',
			'lending.editEmail' => 'Cambiar la notificación de correo electrónico',
			'audiobook.syncTitle' => 'Leer y escuchar Sync',
			'audiobook.syncHelp' => 'Mantenga las posiciones de lectura, las posiciones de escucha, el estado de finalización, las notas y las notas a través de sus dispositivos. Seleccione una cuenta de almacenamiento anexada y utilice el mismo código de sincronización en cada dispositivo.',
			'audiobook.addSyncSource' => 'Añadir Google Drive, OneDrive, Dropbox, WebDAV o S3 en los archivos y libros primero.',
			'audiobook.syncDestination' => 'Conta de almacenamiento de sincronización',
			'audiobook.syncFolder' => 'Sincronización de la pasta o prefixo',
			'audiobook.syncFolderHelp' => 'Utilice una pasta existente separada dentro de su fuente WebDAV, o un prefixo dedicado S3.',
			'audiobook.syncCode' => 'Código de sincronización privada',
			'audiobook.syncCodeHelp' => 'Crea un código en tu primer dispositivo, luego introduzca ese código en tus otros dispositivos. Mantiene una copia privada: es la clave para tu estado cifrado. Utilice un código diferente para cada persona.',
			'audiobook.showCode' => 'Mostrar o ocultar el código de sincronización',
			'audiobook.newSyncCode' => 'Crear un nuevo código de sincronización',
			'audiobook.saveSync' => 'Salvando y sincronizando',
			'audiobook.disableSync' => 'Desactivar la sincronización en este dispositivo',
			'audiobook.syncSourceDisconnect' => 'Eliminar esta fuente dejará de leer y escuchar la sincronización aquí. los archivos de sincronización encriptados permanecerán en el proveedor.',
			'audiobook.syncReconnect' => 'Reconectar la cuenta de almacenamiento',
			'audiobook.lastSynced' => ({required Object time}) => 'Última sincronización en ${time}',
			'audiobook.syncPrivacy' => 'Sólo se almacenan los progresos y notas cifrados. Los archivos de audio y ebook, los tokens de cuenta y las contraseñas no se cargan. Google Drive y OneDrive utilizan el almacenamiento de aplicaciones; Dropbox utiliza PlezyNG Sync. Permite la sincronización puede solicitar acceso adicional a la escritura. Mientras está activado, este destino posee la sincronización del progreso; el progreso del servidor permanece separado.',
			'audiobook.syncConflicts' => 'Elegir dónde volver',
			'audiobook.conflictHelp' => 'Estas modificaciones se hicieron de forma independiente. escoge la posición o la versión de la marca para mantener. Un timestamp posterior o un porcentaje superior no gana automáticamente.',
			'audiobook.syncDevice' => ({required Object device}) => 'Dispositivo ${device}',
			'audiobook.syncUnknownDevice' => 'Dispositivo desconocido',
			'audiobook.deletedBookmark' => 'Bookmark eliminado',
			'audiobook.finished' => 'Finalizado',
			'audiobook.readingPosition' => ({required Object percent}) => 'Leer · ${percent}%',
			'audiobook.chapterTimeline' => 'Capítulo Progreso',
			'audiobook.bookTimeline' => 'Todo el libro Progreso',
			'audiobook.bookRemaining' => ({required Object time}) => 'El tiempo que queda en este libro: ${time}',
			'audiobook.chapterRemaining' => ({required Object time}) => 'Tiempo restante en este capítulo: ${time}',
			'audiobook.unknownRemaining' => 'Tiempo completo disponible a medida que se juegan partes',
			'audiobook.undoSeek' => 'La última búsqueda',
			'audiobook.customSpeed' => 'Velocidad de reproducción personalizada',
			'audiobook.speedHelp' => 'Seleccione una velocidad de 0.25× a 4×.',
			'audiobook.apply' => 'Aplique',
			'audiobook.customSleep' => 'Calendario de sueño personalizado',
			'audiobook.sleepMinutes' => 'Minutos (1 a 1440)',
			'audiobook.sleepChapters' => ({required Object count}) => 'Parar después de ${count} capítulos',
			'audiobook.extendSleep' => 'Añadir 5 minutos',
			'audiobook.sleepRemaining' => ({required Object time}) => 'Horario de sueño: ${time}',
			'audiobook.useDefaults' => 'Utilice estos controles de escucha para nuevos libros',
			'audiobook.librarySort' => 'Sorteos de libros',
			'audiobook.sortTitle' => 'Título',
			'audiobook.sortAuthor' => 'Autor',
			'audiobook.sortNarrator' => 'narración',
			'audiobook.sortSeries' => 'Orden de serie',
			'audiobook.sortRecent' => 'recientemente abierto',
			'audiobook.statusFilter' => 'El estado de lectura',
			'audiobook.statusAll' => 'Todos los libros',
			'audiobook.statusNew' => 'No comenzó',
			'audiobook.statusProgress' => 'En el progreso',
			'audiobook.statusFinished' => 'Finalizado',
			'audiobook.goToTime' => 'Vuelve al tiempo',
			'audiobook.timeHelp' => 'Horas: minutos: segundos o minutos: segundos',
			'audiobook.recoveryHelp' => 'Exportar una copia cifrada reciente antes de mover o reparar los datos de sincronización. las importaciones se fusionan con el estado actual; nunca sustituyen la historia de la sincronía local.',
			'audiobook.recoveryExport' => 'Exportación de archivos de recuperación cifrados',
			'audiobook.recoveryImport' => 'Importación de archivos de recuperación cifrados',
			'audiobook.recoveryImportConfirm' => 'Combinar este archivo de recuperación cifrado con las posiciones de lectura y notas actuales? se conservará el historial existente. no se incluyen los IDs de la biblioteca compartida y del elemento; establezca los identificadores correspondientes en cada dispositivo antes de importar.',
			'audiobook.recoveryExported' => 'El archivo de recuperación encriptado se salvó.',
			'audiobook.recoveryImported' => 'Los datos de recuperación se mezclan.',
			'sourceSetup.savedCertificate' => 'Certificado del servidor guardado',
			'sourceSetup.nfsEndpointInvalid' => 'Introduce una URL NFS, como nfs://nas:2049/export.',
			'sourceSetup.dlnaNone' => 'No se encontraron servidores DLNA. Introduce manualmente la URL de descripción del dispositivo.',
			'sourceSetup.dlnaServers' => 'Servidores multimedia DLNA',
			'sourceSetup.dlnaUnavailable' => 'La detección DLNA no está disponible en esta red. Introduce manualmente la URL de descripción del dispositivo.',
			'sourceSetup.dlnaSearching' => 'Buscando servidores DLNA en la red local',
			'sourceSetup.networkSearching' => 'Buscando en la red local…',
			'sourceSetup.dlnaDiscover' => 'Detectar servidores DLNA',
			'sourceSetup.dlnaHelp' => 'La detección depende de la multidifusión de la red local. Si no aparece ningún servidor, introduce arriba su URL de descripción del dispositivo.',
			'sourceSetup.dlnaRoot' => 'ID de objeto DLNA; déjalo en blanco para usar la raíz del dispositivo.',
			'sourceSetup.passwordOrKey' => 'Introduce una contraseña o añade una clave privada abajo.',
			'sourceSetup.sshFingerprint' => 'Huella SHA256 de la clave de host SSH',
			'sourceSetup.sshFingerprintHelp' => 'Verifícala con el administrador del servidor. En el servidor, ejecuta ssh-keygen -lf /path/to/ssh_host_ed25519_key.pub y usa su valor SHA256.',
			'sourceSetup.sshFingerprintKeep' => 'Déjalo en blanco para mantener la huella fijada actual o introduce una nueva huella del servidor.',
			'sourceSetup.sshAuthentication' => 'Autenticación SSH con clave pública',
			'sourceSetup.sshAuthenticationHelp' => 'Opcional; también se admite la autenticación con contraseña.',
			'sourceSetup.privateKey' => 'Clave privada (formato PEM u OpenSSH)',
			'sourceSetup.privateKeyPassphrase' => 'Frase de contraseña de la clave privada',
			'sourceSetup.nfsMountPort' => 'Puerto TCP del servicio de montaje NFS',
			'sourceSetup.nfsMountPortHelp' => 'Predeterminado: 20048',
			'sourceSetup.nfsUserId' => 'ID de usuario NFS (AUTH_SYS)',
			'sourceSetup.nfsUserIdHelp' => 'Predeterminado: 1000. Usa el ID permitido por el recurso NFS compartido del NAS.',
			'sourceSetup.nfsGroupId' => 'ID de grupo NFS (AUTH_SYS)',
			'sourceSetup.nfsGroupIdHelp' => 'Predeterminado: 1000. Usa el ID de grupo permitido por el recurso NFS compartido del NAS.',
			'sourceSetup.nfsEncryption' => 'Exigir NFS cifrado (RPC-with-TLS)',
			'sourceSetup.nfsEncryptionHelp' => 'Exigir TLS 1.3 para NFS y el servicio de montaje. Si el NAS no lo admite, se rechaza la conexión.',
			'sourceSetup.nfsTrustCertificate' => 'CA de NFS personalizada o certificado del servidor (PEM, opcional)',
			'sourceSetup.nfsTrustHelp' => 'Déjalo en blanco para usar certificados de confianza para este dispositivo. Si hace falta, añade un certificado de una CA privada o un certificado de servidor autofirmado; sus nombres deben coincidir con el host de la URL NFS.',
			'sourceSetup.nfsTrustInvalid' => 'Usa un certificado de CA o de servidor en formato PEM. No incluyas una clave privada.',
			'sourceSetup.addTrustCertificate' => 'Añadir certificado de confianza personalizado',
			'sourceSetup.replaceTrustCertificate' => 'Reemplazar el certificado personalizado guardado',
			'sourceSetup.nfsTlsHelp' => 'RPC-with-TLS usa los puertos habituales de NFS y del servicio de montaje y requiere que el NAS admita RFC 9289. Se exige TLS 1.3. El nombre de host o la IP debe coincidir con el certificado. Los UID/GID de AUTH_SYS siguen aplicándose dentro del canal cifrado.',
			'sourceSetup.clientCertificate' => 'Certificado de cliente (opcional)',
			'sourceSetup.clientCertificateHelp' => 'Permite que el NAS autentique este cliente; los ID de AUTH_SYS siguen sujetos a la política del recurso NFS compartido del NAS.',
			'sourceSetup.savedIdentity' => 'Se usará una identidad de cliente guardada.',
			'sourceSetup.replaceIdentity' => 'Reemplazar la identidad de cliente guardada',
			'sourceSetup.chooseIdentity' => 'Elegir identidad de cliente PKCS#12',
			'sourceSetup.identityPassphrase' => 'Frase de contraseña de la identidad de cliente',
			'sourceSetup.identityPassphraseHelp' => 'Déjalo en blanco si el archivo no tiene frase de contraseña.',
			'sourceSetup.removeIdentity' => 'Eliminar cualquier identidad de cliente guardada',
			'sourceSetup.identityStorageHelp' => 'Las identidades de cliente se guardan en el almacén cifrado de credenciales de la fuente. No cambies esta sección para conservar la identidad guardada.',
			'sourceSetup.nfsLimitations' => 'NFSv3 de solo lectura sobre TCP. Sin RPC-with-TLS, el tráfico NFS no está cifrado. El NAS debe permitir los ID de AUTH_SYS seleccionados y los puertos de cliente sin privilegios (a menudo mediante la opción de exportación «insecure»). No se admiten NFSv4 ni UDP.',
			'sourceSetup.nfsSetupHelp' => 'Ayuda para configurar NFS',
			'sourceSetup.nfsSetupHint' => 'Revisa estos ajustes si no se establece la conexión.',
			'sourceSetup.nfsSetupDetails' => 'Usa un recurso compartido NFSv3 sobre TCP. Si se exige cifrado, tanto el servicio NFS como el de montaje deben admitir RPC-with-TLS. Deja el certificado personalizado en blanco para usar un certificado de servidor de confianza para este dispositivo, o añade el certificado de CA o autofirmado del NAS. El nombre del certificado debe coincidir con el host del punto de conexión. Si el NAS exige TLS mutuo, añade su identidad de cliente PKCS#12. Por último, confirma que el recurso compartido permite los UID/GID de AUTH_SYS configurados y la política de puertos del cliente.',
			'sourceSetup.ftpHelp' => 'FTP usa el modo pasivo. Usa ftp:// para FTP sin cifrar, ftpes:// para TLS explícito o ftps:// para TLS (implícito en el puerto 990; explícito en los demás puertos).',
			'sourceSetup.openSubtitles' => 'OpenSubtitles',
			'sourceSetup.subtitleSetup' => 'Búsqueda opcional de subtítulos para vídeos independientes.',
			'sourceSetup.apiKey' => 'Clave API',
			'sourceSetup.optionalUsername' => 'Nombre de usuario de la cuenta (opcional)',
			'sourceSetup.optionalPassword' => 'Contraseña de la cuenta (opcional)',
			'sourceSetup.subtitlePrivacy' => 'Obtén una clave API en opensubtitles.com. La búsqueda envía el título del vídeo y los ID de IMDb/TMDB disponibles, nunca el archivo de vídeo. La clave y las credenciales opcionales de la cuenta se cifran con esta fuente.',
			'sourceSetup.automaticMetadata' => 'Metadatos de vídeo automáticos en línea',
			'sourceSetup.metadataPrivacy' => 'Solo envía el título/año del nombre del archivo y los números de episodio, o un ID NFO; nunca envía contenido multimedia ni credenciales. Los campos NFO conservan la prioridad.',
			'sourceSetup.nfsEncryptionFailure' => 'Para NFS cifrado, comprueba que ambos servicios del NAS admiten RFC 9289 y TLS 1.3, el nombre del certificado y los UID/GID del recurso compartido. PlezyNG no reintentará esta conexión sin cifrado.',
			'sourceSetup.sourceConnecting' => 'Conectando con la fuente',
			'sourceSetup.metadataSearchPrivacy' => 'Esta búsqueda de títulos se envía a Trakt. Se envía el título que introduces, no el vídeo ni las credenciales de la fuente.',
			'sourceSetup.chooseMatch' => 'Elegir una coincidencia',
			'sourceSetup.metadataMatchHelp' => 'Revisa el título y el año antes de elegir. Trakt recibe el título buscado; el vídeo permanece en su fuente.',
			'sourceSetup.metadataNoMatches' => 'No se encontraron títulos coincidentes en línea. Prueba con otro título.',
			'sourceSetup.metadataSearch' => 'Buscar metadatos en línea',
			'sourceSetup.metadataLoading' => 'Buscando información de películas y series en línea…',
			'sourceSetup.metadataFromTrakt' => 'Metadatos en línea de Trakt',
			'sourceSetup.metadataNoAutomaticMatch' => 'No se encontró una coincidencia automática para el título. Busca el título para elegir una coincidencia.',
			'sourceSetup.metadataFailed' => 'No se pudieron cargar los metadatos en línea. La reproducción y la información local siguen disponibles.',
			'sourceSetup.videoDetailsLoading' => 'Cargando información del vídeo',
			'sourceSetup.subtitleKeyRequired' => 'Se necesita una clave API de OpenSubtitles',
			'sourceSetup.subtitleKeyHelp' => 'Edita esta fuente de archivos y añade una clave API de OpenSubtitles en los ajustes opcionales de subtítulos.',
			'sourceSetup.subtitleSearchFailed' => 'La búsqueda de subtítulos falló. Comprueba la clave API, la conexión y el acceso al servicio.',
			'sourceSetup.subtitleApplyFailed' => 'No se pudieron descargar o aplicar estos subtítulos. Comprueba la conexión y prueba otro resultado.',
			'sourceSetup.subtitleSearch' => 'Buscar en OpenSubtitles',
			'sourceSetup.subtitleSearchPrivacy' => 'La búsqueda usa el título y los ID de IMDb/TMDB disponibles. El archivo de vídeo permanece en su fuente. Antes de elegir, revisa el idioma, los indicadores de subtítulos forzados o para personas con discapacidad auditiva y la valoración.',
			'sourceSetup.movieOrShow' => 'Película o serie',
			'sourceSetup.subtitleTitleHint' => 'Introduce un título para precisar los resultados',
			'sourceSetup.subtitleLanguage' => 'Idioma de los subtítulos',
			'sourceSetup.subtitleSearching' => 'Buscando en OpenSubtitles',
			'sourceSetup.subtitleNoMatches' => 'No se encontraron subtítulos coincidentes. Prueba con otro título o idioma.',
			'sourceSetup.downloadSubtitle' => 'Descargar subtítulos',
			'sourceSetup.subtitle' => 'Subtítulos',
			'sourceSetup.nfsTlsRequired' => 'Se requiere RPC-with-TLS',
			'sourceSetup.nfsUnencrypted' => 'NFS sin cifrar',
			'sourceSetup.tlsEncrypted' => 'Cifrado con TLS',
			'sourceSetup.ftpPlain' => 'FTP sin cifrar',
			'sourceSetup.sshPinned' => 'SSH cifrado · clave de host fijada',
			'sourceSetup.smbEncrypted' => 'Cifrado SMB3 activado',
			'sourceSetup.smbUnencrypted' => 'Cifrado SMB3 desactivado',
			'sourceSetup.httpUnencrypted' => 'HTTP sin cifrado de transporte',
			'sourceSetup.checkEndpointSecurity' => 'Comprobar la seguridad del punto de conexión',
			'sourceSetup.fieldRequired' => ({required Object label}) => 'Se requiere ${label}.',
			'sourceSetup.integerRange' => ({required Object label, required Object min, required Object max}) => 'Introduce ${label} entre ${min} y ${max}.',
			'sourceSetup.replaceFile' => ({required Object name}) => 'Reemplazar ${name}',
			'sourceSetup.selectedIdentity' => ({required Object name}) => 'Identidad de cliente seleccionada: ${name}',
			'sourceSetup.subtitleRating' => ({required Object rating}) => 'Valoración ${rating}',
			'sourceSetup.subtitleDownloading' => ({required Object title}) => 'Descargando subtítulos: ${title}',
			'sourceSetup.sharedEntryPair' => 'Compartir este artículo',
			'sourceSetup.sharedEntryPairHelp' => 'Introduce el mismo ID para este elemento en cada dispositivo. Utilice un identificador compartido estable o generar uno y copiarlo al item que se ajusta. Progreso sólo se paran cuando los tipos de archivo de edición, tamaños y órdenes se ajustan. Blank remove este mapa.',
			'sourceSetup.sharedEntryId' => 'Identificación del elemento compartido',
			'sourceSetup.generateSharedEntryId' => 'Generar el ID del elemento compartido',
			'sourceSetup.sharedLibraryId' => 'ID de biblioteca compartida (opcional)',
			'sourceSetup.sharedLibraryHelp' => 'Utilice el mismo ID en los dispositivos que abren la misma biblioteca.Este ID público ayuda a llevar el progreso de la lectura y las notas a través de diferentes conexiones de fuente; no es una contraseña.Cuando los proveedores usan diferentes identificadores de artículos, se paren esos elementos de sus pantallas detalladas.',
			'sourceSetup.sharedLibraryInvalid' => 'Utilice 8 a 100 letras, números, puntos, subescores o hyphens.',
			'sourceSetup.generateSharedLibraryId' => 'Generar un ID de biblioteca compartido',
			'sourceSetup.nfsReadAhead' => 'Requisitos de read-ahead de NFS',
			'sourceSetup.nfsReadAheadHelp' => 'Más lecturas paralelas pueden mejorar el rendimiento en un NAS o red rápido. Utilice 1 si el servidor limita las solicitudes concurrentes.',
			'sourceSetup.nfsReadTest' => 'Medir el rendimiento de la lectura NFS',
			'sourceSetup.nfsReadTestHelp' => 'Lea hasta 64 MiB desde el archivo más grande para medir esta conexión NAS. Esto utiliza la ancho de banda de red.',
			'sourceSetup.nfsQualificationResult' => 'NFS lectura de medición',
			'sourceSetup.nfsReadBytes' => 'Los datos leyen',
			'sourceSetup.nfsReadSpeed' => 'Velocidad medida',
			'sourceSetup.nfsReadRequests' => 'Leer solicitudes',
			'sourceSetup.sharedEntryConflict' => 'Este ID de elemento compartido ya está asociado con otro elemento en esta biblioteca.',
			'comics.fitHeight' => 'Ajustar a la altura',
			'comics.readingMode' => 'Modo de lectura',
			'comics.paged' => 'Páginas',
			'comics.webtoon' => 'Desplazamiento continuo',
			'comics.coverAlone' => 'Mostrar la portada sola',
			'comics.splitWide' => 'Dividir páginas anchas',
			'comics.splitWideHelp' => 'Muestra cada mitad por separado, en orden de lectura. Mientras esté activado, se pausa la vista de dos páginas juntas.',
			'comics.thumbnails' => 'Miniaturas de páginas',
			'comics.controlsHelp' => 'Desliza para pasar de página. Toca dos veces para cambiar el ajuste. En desplazamiento continuo, desliza verticalmente o usa Re Pág y Av Pág.',
			'comics.savedForComic' => 'Los ajustes de visualización se guardan para este cómic en este perfil.',
			'comics.readLists' => 'Listas de lectura',
			'comics.collections' => 'Colecciones',
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
			_ => null,
		};
	}
}
