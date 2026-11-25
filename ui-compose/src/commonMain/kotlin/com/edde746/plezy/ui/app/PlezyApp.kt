package com.edde746.plezy.ui.app

import androidx.compose.animation.AnimatedContentTransitionScope
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.EnterTransition
import androidx.compose.animation.ExitTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import com.edde746.plezy.ui.downloads.DownloadOverlays
import com.edde746.plezy.ui.downloads.DownloadsScreen
import com.edde746.plezy.ui.downloads.SyncRulesScreen
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.withFrameNanos
import androidx.compose.runtime.saveable.rememberSaveableStateHolder
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.platform.LocalWindowInfo
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.navigation3.runtime.NavEntry
import androidx.navigation3.runtime.NavEntryDecorator
import androidx.navigation3.scene.Scene
import androidx.navigation3.ui.NavDisplay
import com.edde746.plezy.app.AppGraph
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.app.afterFirstFrame
import com.edde746.plezy.app.playDownloaded
import com.edde746.plezy.image.ArtworkDiagnosticsLog
import com.edde746.plezy.image.ArtworkDisplay
import com.edde746.plezy.image.ImageMemoryBudget
import com.edde746.plezy.image.describeDisplay
import com.edde746.plezy.image.describeEffects
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.navigation.BackStackLayout
import com.edde746.plezy.presentation.navigation.PlezyNavigator
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.navigation.ShellBack
import com.edde746.plezy.presentation.navigation.TopLevelDestination
import com.edde746.plezy.presentation.theme.Appearance
import com.edde746.plezy.presentation.theme.Palette
import com.edde746.plezy.settings.VisualEffects
import com.edde746.plezy.strings.InterfaceLocale
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.adaptive.NavigationKind
import com.edde746.plezy.ui.catalog.CatalogDetailScreen
import com.edde746.plezy.ui.explore.CatalogSearchScreen
import com.edde746.plezy.ui.explore.ExploreRowScreen
import com.edde746.plezy.ui.explore.ExploreScreen
import com.edde746.plezy.ui.seerr.SeerrConnectScreen
import com.edde746.plezy.ui.seerr.SeerrPersonScreen
import com.edde746.plezy.ui.seerr.SeerrRequestSheet
import com.edde746.plezy.ui.seerr.SeerrSettingsScreen
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import com.edde746.plezy.presentation.metadata.UnmatchConfirm
import com.edde746.plezy.ui.components.ConfirmDialog
import com.edde746.plezy.ui.components.LocalAppVisible
import com.edde746.plezy.ui.components.LocalOpenRoute
import com.edde746.plezy.ui.components.OverlayHostBox
import com.edde746.plezy.ui.components.appArea
import com.edde746.plezy.ui.components.beyond
import com.edde746.plezy.ui.components.SystemBackHandler
import com.edde746.plezy.ui.components.backOnKeyUp
import com.edde746.plezy.ui.components.TimedToast
import com.edde746.plezy.ui.focus.FocusVisibility
import com.edde746.plezy.ui.focus.LocalFocusVisibility
import com.edde746.plezy.ui.focus.LocalScreenFocus
import com.edde746.plezy.ui.focus.ScreenFocus
import com.edde746.plezy.ui.focus.arrowKeyFocus
import com.edde746.plezy.ui.focus.focusGate
import com.edde746.plezy.ui.focus.trackFocusVisibility
import com.edde746.plezy.ui.home.HomeScreen
import com.edde746.plezy.ui.detail.CollectionScreen
import com.edde746.plezy.ui.detail.MediaDetailScreen
import com.edde746.plezy.ui.detail.PersonScreen
import com.edde746.plezy.ui.search.SearchScreen
import com.edde746.plezy.ui.home.HubDetailScreen
import com.edde746.plezy.ui.menu.MediaMenuHost
import com.edde746.plezy.ui.menu.MenuAnchor
import com.edde746.plezy.ui.menu.LocalMenuAnchor
import com.edde746.plezy.ui.menu.trackMenuAnchor
import com.edde746.plezy.ui.ratings.RatingSheet
import com.edde746.plezy.ui.playlists.PlaylistDetailScreen
import com.edde746.plezy.ui.image.LocalArtworkDisplay
import com.edde746.plezy.ui.image.ProvideImageLoader
import com.edde746.plezy.ui.image.reducedEffects
import com.edde746.plezy.ui.cast.CastBar
import com.edde746.plezy.ui.cast.CastOverlays
import com.edde746.plezy.ui.cast.LocalCastSender
import com.edde746.plezy.ui.cast.castIntents
import com.edde746.plezy.ui.cast.castRailItem
import com.edde746.plezy.ui.music.AlbumScreen
import com.edde746.plezy.ui.music.ArtistScreen
import com.edde746.plezy.ui.music.MiniPlayer
import com.edde746.plezy.ui.music.MusicPlaylistScreen
import com.edde746.plezy.ui.music.NowPlayingScreen
import com.edde746.plezy.ui.music.nowPlayingRailItem
import com.edde746.plezy.ui.livetv.LiveTvScreen
import com.edde746.plezy.ui.livetv.ShowScheduleScreen
import com.edde746.plezy.ui.libraries.LibrariesDestination
import com.edde746.plezy.ui.navigation.LocalStatusBarOverlap
import com.edde746.plezy.ui.navigation.NavigationScaffold
import com.edde746.plezy.ui.navigation.statusBarOverlap
import androidx.compose.foundation.layout.Column
import com.edde746.plezy.ui.onboarding.OnboardingRoute
import com.edde746.plezy.ui.onboarding.PinPrompt
import com.edde746.plezy.ui.player.PlayerRoute
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.trackers.LibraryFilterScreen
import com.edde746.plezy.ui.trackers.ServicesScreen
import com.edde746.plezy.ui.trackers.TrackerSettingsScreen
import com.edde746.plezy.ui.metadata.MetadataEditScreen
import com.edde746.plezy.ui.metadata.PlexMatchScreen
import com.edde746.plezy.ui.metadata.QuickTagHost
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.PlezyTheme
import com.edde746.plezy.ui.watch.WatchNotices
import com.edde746.plezy.ui.watch.WatchTogetherRoute
import com.edde746.plezy.ui.settings.SettingsScreen
import com.edde746.plezy.ui.settings.listBeside
import com.edde746.plezy.ui.settings.swapsSettingsPane

/**
 * A development session's app: [app] alone, without the product's splash ([PlezyRoot] runs the product), on
 * [platform].
 */
@Composable
fun PlezyApp(app: AppSession, platform: PlezyPlatform, modifier: Modifier = Modifier) {
    val appearance by app.appearance.collectAsState()
    PlezyFrame(app.graph, platform, appearance, modifier, transparent = playerShown(app)) { AppContent(app) }
}

/** [app] shows the player: the frame leaves the window transparent for the video under it ([PlezyFrame]). */
@Composable
internal fun playerShown(app: AppSession): Boolean = app.navigator.backStack.collectAsState().value.lastOrNull() == Route.Player

/**
 * The palette a frame paints: [appearance]'s theme (System following [systemDark]); without one (before the stored
 * settings are read, or when they can't be) the device's default, OLED on a TV ([formFactor]), else the system's light
 * or dark.
 */
fun framePalette(appearance: Appearance?, formFactor: FormFactor, systemDark: Boolean): Palette =
    appearance?.theme?.paletteFor(systemDark) ?: when {
        formFactor == FormFactor.TV -> Palette.OLED
        systemDark -> Palette.DARK
        else -> Palette.LIGHT
    }

/**
 * The theme, image loading and adaptive layout every screen of the app sits in, with [platform] provided to the
 * screens and the dialogs and sheets drawn over all of them ([OverlayHostBox]). [appearance] (the running app's, or
 * the one it will start in; null before it is known) picks the theme ([framePalette]) and the layout's form factor
 * (Force TV mode lays a phone or a desktop out as a TV); without it the device's default theme and form factor.
 * The arrow keys move focus as a D-pad does ([arrowKeyFocus]); focus shows after a key press, not after a click or a
 * tap ([FocusVisibility]; on phones, tablets and desktop it starts hidden until the first key, TV shows it from the
 * start). The harness name `app` is the place [modifier] leaves the app: on Android the window's safe area. While
 * [transparent] the frame paints no background: the player, whose video surface lies under the window's content (mpv's
 * child window on Windows, the video plane on Linux, the SurfaceView on Android) and shows through, and Android's
 * splash, which leaves the launch screen on display. While [playerShown] the system bars are tinted for the dark video.
 * On a car the whole frame draws at the car's interface scale ([scaledDensity]): every screen, the dialogs, sheets and
 * notices over them, and the safe area [modifier] keeps beside the system bars, on every side, for every route.
 */
@Composable
internal fun PlezyFrame(
    graph: AppGraph,
    platform: PlezyPlatform,
    appearance: Appearance?,
    modifier: Modifier,
    transparent: Boolean = false,
    playerShown: Boolean = transparent,
    content: @Composable () -> Unit,
) {
    val formFactor = appearance?.formFactor ?: platform.formFactor
    val focusVisibility = remember(formFactor) { FocusVisibility(initial = formFactor == FormFactor.TV) }
    // A game controller the platform reads itself shows focus as a key does.
    LaunchedEffect(platform, focusVisibility) { platform.nonPointerInput.collect { focusVisibility.reportNonPointerInput() } }
    val palette = framePalette(appearance, formFactor, isSystemInDarkTheme())
    // The video under the player is dark whatever the theme.
    val darkBars = palette.isDark || playerShown
    SideEffect { platform.tintSystemBars(darkBars) }
    // The interface language: the strings are read as the screens compose, so a new language composes them all again;
    // a right-to-left language lays out right to left.
    val language by InterfaceLocale.tag.collectAsState()
    val direction = if (InterfaceLocale.isRightToLeft(language)) LayoutDirection.Rtl else LayoutDirection.Ltr
    // The display artwork is sized for: the window's density, the TV floor, the visual effects tier, the display.
    val density = LocalDensity.current.density
    val visualEffects = appearance?.visualEffects ?: VisualEffects.AUTO
    val artworkDisplay = remember(density, formFactor, visualEffects, platform) {
        ArtworkDisplay.of(density.toDouble(), formFactor == FormFactor.TV, visualEffects, platform.artworkDevice)
    }
    val imageMemory = remember(platform, formFactor, artworkDisplay) {
        ImageMemoryBudget.of(platform.formFactor == FormFactor.DESKTOP, formFactor == FormFactor.TV, artworkDisplay)
    }
    // The tier and the display in the log and the logs' header, once the window has a size and whenever either changes.
    val window = LocalWindowInfo.current.containerSize
    LaunchedEffect(artworkDisplay, window.width > 0) {
        if (window.width == 0) return@LaunchedEffect
        val device = platform.artworkDevice
        ArtworkDiagnosticsLog.log(
            effects = describeEffects(visualEffects, device, artworkDisplay),
            display = describeDisplay(window.width, window.height, density.toDouble(), device, artworkDisplay),
        )
    }
    CompositionLocalProvider(
        LocalPlezyPlatform provides platform,
        LocalFocusVisibility provides focusVisibility,
        LocalLayoutDirection provides direction,
        LocalArtworkDisplay provides artworkDisplay,
        LocalDensity provides scaledDensity(LocalDensity.current, appearance?.uiScale ?: 1.0),
    ) {
        key(language) {
            PlezyTheme(palette) {
                ProvideImageLoader(graph.http, reduced = artworkDisplay.reduced, memory = imageMemory, directory = platform.artworkCacheDirectory)
                // The theme's background drawn before [modifier]'s insets: under the system bars too.
                val background = if (transparent) Color.Transparent else MaterialTheme.colorScheme.background
                val frame = Modifier.background(background).then(modifier)
                AdaptiveLayout(formFactor, frame.trackFocusVisibility(focusVisibility, tv = formFactor == FormFactor.TV).arrowKeyFocus()) {
                    CompositionLocalProvider(LocalAppearance provides (appearance ?: LocalAppearance.current)) {
                        OverlayHostBox(Modifier.fillMaxSize().layoutProbe("app", reportsFocus = false)) { content() }
                    }
                }
            }
        }
    }
}

/**
 * [density] [scale] times larger (a car's interface scale, [Appearance.uiScale]): every dp and sp draws that much
 * larger, so the screens lay out in a window [scale] times smaller in dp. The system bars' insets are in pixels and
 * keep their size, so the safe area still keeps the controls off the bars. At 1, [density] itself.
 */
internal fun scaledDensity(density: Density, scale: Double): Density =
    if (scale == 1.0) density else Density(density.density * scale.toFloat(), density.fontScale)

/**
 * The running app. While the sign-in or the required profile picker holds the shown stack ([accountGate]) it is that
 * alone, the account shell ([AccountShell]), outside the navigation chrome and without a cross-fade. Otherwise the
 * navigation frame over the shell's destinations ([AppSession.shell]) with the running profile's avatar at the foot of
 * the rail and the TV column ([ProfileButton]), and the shown destination's back stack of [app] in the navigation
 * container, each screen drawn by its route ([RouteContent]); over the screen a line while the device is offline or a
 * server refuses the account ([OfflineLine], [AuthLine]).
 *
 * Every screen but the player paints the theme background; the player stays transparent, so the platform's video
 * surface under the window content shows through. Back pops the stack; at a destination's root it goes through the
 * shell ([com.edde746.plezy.presentation.navigation.ShellStore.back]): to the first destination, then "Press back
 * again to exit" for 3 s, then out of the app. A desktop keyboard's Escape at the first destination's root only takes
 * the window out of fullscreen. A profile switch ([AppSession.profileSession]) makes every screen anew. A desktop window
 * has its own shortcuts and the mouse's back button ([desktopShortcuts]). Once the app has drawn its first frame, the
 * start's remaining work runs ([afterFirstFrame]). Casting's overlays lie over all of it ([CastOverlays]), and its
 * sender is the cast buttons' ([LocalCastSender]).
 */
@Composable
internal fun AppContent(app: AppSession) {
    val profileSession by app.profileSession.collectAsState()
    CompositionLocalProvider(LocalCastSender provides app.castSender) {
        key(profileSession) { ProfileContent(app) }
        CastOverlays(app)
    }
}

@Composable
private fun ProfileContent(app: AppSession) {
    val gate = app.navigator.backStack.collectAsState().value.let(::accountGate)
    if (gate) AccountShell(app) else ChromeContent(app)
}

/** The sign-in or the required profile picker holds [backStack]: the app isn't entered yet. */
private fun accountGate(backStack: List<Route>): Boolean = backStack.first().let { it == Route.SignIn || it == Route.ProfilePicker(required = true) }

/**
 * The account shell: the sign-in or the required profile picker and the screens pushed over it, each alone in the
 * window, switching without a cross-fade. Back pops them; at the root it goes through the shell as the app's does.
 */
@Composable
private fun AccountShell(app: AppSession) {
    val platform = LocalPlezyPlatform.current
    val backStack by app.navigator.backStack.collectAsState()
    val shell by app.shell.state.collectAsState()
    val tv = LocalWindowLayout.current.formFactor == FormFactor.TV
    // As the app's: a desktop keyboard's Escape at the root only takes the window out of fullscreen.
    val backKeys = Modifier.backOnKeyUp(escapeIsBack = { tv || backStack.size > 1 }, onEscape = { platform.setFullscreen(false) })
    Box(Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background).then(backKeys)) {
        SystemBackHandler {
            if (backStack.size > 1) app.navigator.back() else if (app.shell.back() == ShellBack.EXIT) platform.exit()
        }
        val top = backStack.last()
        androidx.compose.runtime.key(top) { RouteContent(app, top) }
        ExitPrompt(shell.exitPrompt, Modifier.align(Alignment.BottomCenter))
    }
    PinPrompt(app.onboarding.pin)
}

@Composable
private fun ChromeContent(app: AppSession) {
    val navigator = app.navigator
    val platform = LocalPlezyPlatform.current
    val stacks by navigator.stacks.collectAsState()
    val shell by app.shell.state.collectAsState()
    val appearance by app.appearance.collectAsState()
    val reconnect by app.reconnect.state.collectAsState()
    val backStack = stacks.current
    val layout = remember(backStack) { BackStackLayout.of(backStack) }
    val screen = layout.screens.last()
    // The screen focus may enter (focusGate): the top one with no sheet or required profile picker over it, read as
    // focus moves.
    val focusScreen by rememberUpdatedState(screen.takeIf { layout.sheet == null && layout.overPlayer == null })
    val tv = LocalWindowLayout.current.formFactor == FormFactor.TV
    val compact = LocalWindowLayout.current.navigation == NavigationKind.BAR
    val banner by app.authErrorBanner.collectAsState()
    val still = reducedEffects
    // The start's work that waits for the app's first frame.
    LaunchedEffect(app) {
        withFrameNanos { }
        afterFirstFrame(app.graph, platform)
    }
    val menuAnchor = remember { MenuAnchor() }
    // A card's title and season links open their detail through the navigator; artwork timers run only while visible.
    val openRoute = remember(navigator) { { route: Route -> navigator.navigate(route) } }
    val visible by app.graph.visible.collectAsState(true)
    // A desktop keyboard's Escape at the first destination's root (outside TV mode, where Escape is the remote's Back)
    // never asks to exit: it only takes the window out of fullscreen.
    val backKeys = Modifier.backOnKeyUp(escapeIsBack = { tv || !app.shell.atFirstRoot }, onEscape = { platform.setFullscreen(false) })
    val cast by app.castSender.state.collectAsState()
    val castActions = remember(app) { castIntents(app.castSender) }
    val castRail = castRailItem(cast, castActions.openControls)
    val musicRailItem = nowPlayingRailItem(app.musicMiniPlayer)
    // The navigation highlights the destination the screen on top belongs to (a movie opened from Home: Libraries),
    // Libraries with the icon of the library it stands for: the one highlighted, else the one its own stack shows.
    // Libraries' store is read once Libraries has shown (made earlier, it would load a library at the app's start), and
    // only for its selection.
    val highlighted = TopLevelDestination.highlightedIn(layout.screens, shell.destinations) ?: shell.selected
    val serverLibraries by remember(app) { app.servers.libraries.state.map { it.libraries }.distinctUntilChanged() }
        .collectAsState(app.servers.libraries.libraries)
    val librariesStore = if (TopLevelDestination.LIBRARIES in stacks.stacks) remember(app) { app.libraries() } else null
    val librariesState = librariesStore?.state?.collectAsState()
    val selectedLibrary by remember(librariesState) { derivedStateOf { librariesState?.value?.selected } }
    val libraryKind = TopLevelDestination.highlightedLibrary(
        if (highlighted == TopLevelDestination.LIBRARIES) layout.screens else stacks.stack(TopLevelDestination.LIBRARIES).orEmpty(),
        shell.destinations,
        serverLibraries,
        stacks.libraries,
        selectedLibrary,
    )?.kind
    Box(Modifier.fillMaxSize().trackMenuAnchor(menuAnchor).then(backKeys).desktopShortcuts(app)) {
        // The navigation container hands Back on only at a stack's root.
        SystemBackHandler(enabled = backStack.size == 1) {
            if (app.shell.back() == ShellBack.EXIT) platform.exit()
        }
        NavigationScaffold(
            destinations = shell.destinations,
            selected = highlighted,
            onSelect = app.shell::select,
            // Phones keep the bar to top-level screens; wider windows keep the rail beside every screen.
            showNavigation = screen != Route.Player && screen != Route.NowPlaying && TopLevelDestination.of(backStack.first()) != null &&
                (!compact || TopLevelDestination.of(screen) != null),
            libraryKind = libraryKind,
            barLabels = appearance.showNavBarLabels,
            railExtra = castRail?.takeIf { tv } ?: musicRailItem,
            // While casting, the cast bar over the music mini-player on every screen but the players (TV: the rail's item).
            bottomAccessory = {
                Column {
                    if (!tv && screen != Route.Player && screen != Route.NowPlaying) CastBar(cast, castActions)
                    MiniPlayer(app.musicMiniPlayer, app.mediaActions.menu)
                }
            },
            atRoot = backStack.size == 1,
            footer = { expanded -> ProfileButton(app, shell.offline, expanded) },
        ) {
            val lined = screen != Route.Player && screen != Route.NowPlaying
            val offlineLine = lined && shell.offline
            val authLine = banner?.takeIf { lined && !shell.offline }
            Column(Modifier.fillMaxSize()) {
                if (offlineLine) OfflineLine(reconnect.reconnecting, app.reconnect::reconnect, Modifier.padding(top = statusBarOverlap))
                authLine?.let { AuthLine(it, app::signInAgain, Modifier.padding(top = statusBarOverlap)) }
                // Under a line the screen starts below the status bar.
                CompositionLocalProvider(LocalStatusBarOverlap provides if (offlineLine || authLine != null) null else LocalStatusBarOverlap.current) {
            BoxWithConstraints(Modifier.weight(1f).fillMaxWidth()) {
                // A pushed screen is drawn over the one under it, a popped one over the one it returns to. TV boxes animate
                // that one layer (the pushed screen fades in, the popped one fades out); elsewhere the two cross-fade. The
                // player opens at once ([PlayerOpensAtOnce]), and so does every screen on the reduced effects tier, and a
                // screen opened from Settings' list beside it in place of the one there ([swapsSettingsPane]).
                val besideList = listBeside(maxWidth, tv)
                val atOnce: AnimatedContentTransitionScope<Scene<Route>>.() -> Boolean = {
                    still || besideList && swapsSettingsPane(initialState.routes(), targetState.routes())
                }
                NavDisplay(
                    backStack = layout.screens,
                    modifier = Modifier.fillMaxSize(),
                    onBack = { navigator.back() },
                    entryDecorators = listOf(rememberScreenStates(navigator)),
                    transitionSpec = {
                        when {
                            atOnce() -> EnterTransition.None togetherWith ExitTransition.None
                            tv -> fadeIn(tween(SCREEN_FADE_IN_MILLIS)) togetherWith ExitTransition.None
                            else -> fadeIn(tween(SCREEN_FADE_IN_MILLIS)) togetherWith fadeOut(tween(180))
                        }
                    },
                    popTransitionSpec = {
                        when {
                            atOnce() -> EnterTransition.None togetherWith ExitTransition.None
                            tv -> EnterTransition.None togetherWith fadeOut(tween(180))
                            else -> fadeIn(tween(SCREEN_FADE_IN_MILLIS)) togetherWith fadeOut(tween(180))
                        }
                    },
                    predictivePopTransitionSpec = {
                        if (atOnce()) EnterTransition.None togetherWith ExitTransition.None else fadeIn(tween(SCREEN_FADE_IN_MILLIS)) togetherWith fadeOut(tween(180))
                    },
                    entryProvider = { route ->
                        val focusGate = Modifier.focusGate { focusScreen == route }
                        if (route == Route.Player) {
                            NavEntry(route, contentKey = screenKey(route), metadata = PlayerOpensAtOnce + (ScreenRoute to route)) { Box(focusGate) { RouteContent(app, route) } }
                        } else {
                            NavEntry(route, contentKey = screenKey(route), metadata = mapOf(ScreenRoute to route)) {
                                // Focus that drops on the screen goes back into it (the player has a home of its own).
                                val screenFocus = remember { ScreenFocus { focusScreen == route } }
                                Box(Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background).then(screenFocus.modifier).then(focusGate)) {
                                    CompositionLocalProvider(
                                        LocalScreenFocus provides screenFocus,
                                        LocalOpenRoute provides openRoute,
                                        LocalAppVisible provides visible,
                                        LocalMenuAnchor provides menuAnchor,
                                    ) {
                                        RouteContent(app, route)
                                    }
                                }
                            }
                        }
                    },
                )
            }
                }
            }
        }
        // The required profile picker a return to the app asked for, over the player: the player stays up, paused, under
        // it, its video surface kept. The player's video reaches under the display cutout and system bars the app keeps
        // clear of (Android), so the picker's background does too; its content stays inside.
        layout.overPlayer?.let { route ->
            val pickerFocus = remember(route) { ScreenFocus { true } }
            Box(Modifier.fillMaxSize().beyond(WindowInsets.appArea).background(MaterialTheme.colorScheme.background))
            Box(Modifier.fillMaxSize().then(pickerFocus.modifier)) {
                CompositionLocalProvider(LocalScreenFocus provides pickerFocus, LocalOpenRoute provides openRoute, LocalAppVisible provides visible) {
                    androidx.compose.runtime.key(route) { RouteContent(app, route) }
                }
            }
        }
        // A sheet's parting message ("Request submitted") is the app's notice, shown over the screen it closed back to.
        layout.sheet?.let { SheetContent(app, it, onNotice = app::notify) }
        ExitPrompt(shell.exitPrompt, Modifier.align(Alignment.BottomCenter))
        reconnect.message?.let { TimedToast(it, "offline.message", app.reconnect::messageShown, Modifier.align(Alignment.BottomCenter).padding(bottom = 88.dp)) }
        app.downloads?.let { DownloadOverlays(it.dialogs, it.deletion, it.warning, menuAnchor) }
        // What a plezy:// link couldn't do.
        val linkMessage by app.links.message.collectAsState()
        linkMessage?.let { message ->
            TimedToast(message, "app.linkMessage", { app.links.dismissMessage(message) }, Modifier.align(Alignment.BottomCenter))
        }
        val notice by app.notice.collectAsState()
        notice?.let { TimedToast(it.text, "app.notice", app::noticeShown, Modifier.align(Alignment.BottomCenter).padding(16.dp).padding(bottom = 72.dp), isError = it.isError) }
        MediaMenuHost(app.mediaActions.menu, menuAnchor, Modifier.fillMaxSize())
        // The rating sheet an item menu's Rate opened.
        app.ratingSheet.collectAsState().value?.let { RatingSheet(it.store, it.backend, onDismiss = app::closeRatingSheet) }
        // An item menu's Quick Tag and Unmatch, over the screen the menu opened on.
        val quickTag by app.metadata.quickTag.collectAsState()
        quickTag?.let { QuickTagHost(it, app.metadata::quickTagDone) }
        val unmatch by app.metadata.unmatchPrompt.collectAsState()
        unmatch?.let { item ->
            ConfirmDialog(
                UnmatchConfirm.title,
                UnmatchConfirm.message,
                UnmatchConfirm.confirm,
                onConfirm = {
                    app.metadata.dismissUnmatch()
                    app.metadata.unmatch(item)
                },
                onCancel = app.metadata::dismissUnmatch,
                probe = "metadata.unmatch",
                cancelLabel = UnmatchConfirm.cancel,
            )
        }
    }
    // The room's notices, over every screen but the player, which shows them itself.
    WatchNotices(app, playerOnTop = screen == Route.Player)
    // Over every screen, the sign-in and the picker too.
    PinPrompt(app.onboarding.pin)
}

/** "Press back again to exit", floating at the window's foot while [shown]. Harness name `app.exitPrompt`. */
@Composable
private fun ExitPrompt(shown: Boolean, modifier: Modifier) {
    AnimatedVisibility(shown, modifier.padding(16.dp).padding(bottom = 72.dp), enter = fadeIn(tween(150)), exit = fadeOut(tween(150))) {
        Surface(
            Modifier.layoutProbe("app.exitPrompt"),
            shape = MaterialTheme.shapes.medium,
            color = MaterialTheme.colorScheme.surface,
            contentColor = MaterialTheme.colorScheme.onSurface,
            shadowElevation = 6.dp,
        ) {
            Text(T.common.pressBackAgainToExit, Modifier.padding(horizontal = 16.dp, vertical = 14.dp), style = MaterialTheme.typography.bodyMedium)
        }
    }
}

/** How long a screen takes to fade in. */
internal const val SCREEN_FADE_IN_MILLIS = 220

/** The player's entry: on every device it replaces the screen it opens over at once, without a fade. */
private val PlayerOpensAtOnce = NavDisplay.transitionSpec { EnterTransition.None togetherWith ExitTransition.None }

/** An entry's route in its metadata, which the transitions read ([routes]). */
private const val ScreenRoute = "plezy.route"

/** The stack a scene draws, bottom to top. */
private fun Scene<Route>.routes(): List<Route> = (previousEntries + entries).map { it.metadata.getValue(ScreenRoute) as Route }

/**
 * Each screen's saved state (what it keeps with `rememberSaveable`: its scroll position, its focus memory), kept while
 * its route is on a stack, forgotten once the route has left every stack
 * ([PlezyNavigator.addRemovalListener]): a destination shown again finds its screens as they were.
 */
@Composable
private fun rememberScreenStates(navigator: PlezyNavigator): NavEntryDecorator<Route> {
    val states = rememberSaveableStateHolder()
    DisposableEffect(navigator, states) {
        val forget: (Route) -> Unit = { states.removeState(screenKey(it)) }
        navigator.addRemovalListener(forget)
        onDispose { navigator.removeRemovalListener(forget) }
    }
    return remember(states) {
        NavEntryDecorator(decorate = { entry -> states.SaveableStateProvider(entry.contentKey) { entry.Content() } })
    }
}

/** A screen's key for its saved state ([rememberScreenStates]): its route's text, one per route, which Android saves. */
private fun screenKey(route: Route): String = route.toString()

/** The screen of [route] in [app]; the player shows the app's current playback ([PlayerRoute]). */
@Composable
private fun RouteContent(app: AppSession, route: Route) {
    when (route) {
        Route.Home -> HomeScreen(app)
        Route.Libraries -> LibrariesDestination(app)
        Route.LiveTv -> LiveTvScreen(app)
        Route.Search -> SearchScreen(app)
        Route.SyncRules -> app.syncRulesStore()?.let { store -> SyncRulesScreen(store, onBack = { app.navigator.back() }) }
        Route.Settings, is Route.SettingsPage -> SettingsScreen(app, route)
        Route.Services -> ServicesScreen(app)
        is Route.TrackerSettings -> TrackerSettingsScreen(app, route)
        is Route.TrackerLibraryFilter -> LibraryFilterScreen(app, route)
        Route.Explore -> ExploreScreen(app)
        is Route.CatalogDetail -> CatalogDetailScreen(app, route)
        is Route.CatalogSearch -> CatalogSearchScreen(app, route)
        is Route.ExploreRow -> ExploreRowScreen(app, route)
        is Route.SeerrPerson -> SeerrPersonScreen(app, route)
        Route.SeerrConnect -> SeerrConnectScreen(app)
        Route.SeerrSettings -> SeerrSettingsScreen(app)
        is Route.SeerrRequest -> SheetContent(app, route, onNotice = { _, _ -> })
        is Route.LiveTvShowSchedule -> ShowScheduleScreen(app, route)
        Route.Player -> PlayerRoute(app)
        Route.SignIn, is Route.ProfilePicker, Route.AddProfile, is Route.ProfileDetail, is Route.AddConnection, is Route.AddPlexAccount,
        is Route.AddMediaBrowser, is Route.EditConnection, is Route.BorrowConnection,
        -> OnboardingRoute(app, route)
        Route.NowPlaying -> app.musicNowPlaying()?.let { store ->
            val castingFrom = app.castReceiver.state.collectAsState().value.castingFrom
            NowPlayingScreen(store, app.mediaActions.menu, onClose = { app.navigator.back() }, castingFrom = castingFrom)
        }
        is Route.MusicArtist -> app.musicArtist(route)?.let { ArtistScreen(it, app.mediaActions.menu, onBack = { app.navigator.back() }) }
        is Route.MusicAlbum -> app.musicAlbum(route)?.let { AlbumScreen(it, app.mediaActions.menu, onBack = { app.navigator.back() }) }
        is Route.MusicPlaylist -> app.musicPlaylist(route)?.let { MusicPlaylistScreen(it, app.mediaActions.menu, onBack = { app.navigator.back() }) }
        is Route.MediaDetail -> MediaDetailScreen(app, route)
        is Route.Person -> PersonScreen(app, route)
        is Route.CollectionDetail -> CollectionScreen(app, route)
        is Route.MetadataEdit -> MetadataEditScreen(app, route)
        is Route.PlexMatch -> PlexMatchScreen(app, route)
        is Route.HubDetail -> HubDetailScreen(app, route)
        is Route.PlaylistDetail -> PlaylistDetailScreen(app, route)
        Route.WatchTogether -> WatchTogetherRoute(app)
    }
}

/**
 * The sheet of [route] over the screen below it; a sheet's parting message goes to [onNotice]. Alone on a stack (a
 * development session opened on it) the sheet has no screen to speak to.
 */
@Composable
private fun SheetContent(app: AppSession, route: Route, onNotice: (text: String, isError: Boolean) -> Unit) {
    when (route) {
        is Route.SeerrRequest -> SeerrRequestSheet(app, route, onNotice)
        else -> RouteContent(app, route)
    }
}
