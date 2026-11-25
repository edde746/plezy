package com.edde746.plezy.ui.app

import androidx.compose.runtime.Composable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Modifier
import com.edde746.plezy.app.AppPlatform
import com.edde746.plezy.image.ArtworkDevice
import com.edde746.plezy.playback.PlayerEngine
import com.edde746.plezy.presentation.player.PictureInPictureHost
import com.edde746.plezy.ui.updates.PlatformUpdates
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.emptyFlow
import com.edde746.plezy.updates.Installation
import java.io.File

/**
 * What the Compose app needs from the platform it runs on (Android, desktop), beyond what the shared app sessions need
 * ([AppPlatform]): the video, picture in picture, the share sheet, a folder picker, the file dialogs and key presses
 * made by the app itself. Called on the main thread.
 */
interface PlezyPlatform : AppPlatform {
    /** The video of [engine] (a playback's, [AppPlatform.createPlayback]), filling [modifier]'s bounds under the controls. */
    @Composable
    fun VideoSurface(engine: PlayerEngine, modifier: Modifier)

    /** The app shows in a picture-in-picture window (Android): the player shows only its video. Compose state. */
    val inPictureInPicture: Boolean get() = false

    /** The status and navigation bars' icons contrast the theme: light icons over a [dark] one, dark over a light one. */
    fun tintSystemBars(dark: Boolean) {}

    /**
     * The platform's picture in picture where the device has it (Android phones and tablets), else null: the player's
     * button starts it (`PictureInPictureRules.toggle`).
     */
    val pictureInPicture: PictureInPictureHost? get() = null

    /**
     * The app's window is on screen: false while it is minimized (desktop). The player lets the display sleep meanwhile
     * (`PlayerStore.onVisibleChanged`). Android needs none: its keep-screen-on flag acts only while the window shows, and
     * the player pauses when its surface goes. Compose state.
     */
    val windowVisible: Boolean get() = true

    /**
     * An assistive technology that moves through the controls one at a time runs (Android: TalkBack's touch
     * exploration): the player keeps its controls up meanwhile (`PlayerStore.onAssistiveTechnologyChanged`). Compose
     * state.
     */
    val assistiveTechnology: Boolean get() = false

    /**
     * The user asked for less motion (Android: Remove animations, transition scale 0): backdrops hold still and the
     * hero's art doesn't drift. Compose state.
     */
    val reducedMotion: Boolean get() = false

    /**
     * What the artwork budgets read from the device (`ArtworkDisplay.of`): the display's size in pixels and, on Android,
     * the hardware signals of the reduced tier. Read once per frame.
     */
    val artworkDevice: ArtworkDevice get() = ArtworkDevice()

    /**
     * Where artwork is cached on disk: a folder of this app's, for this user alone, which nothing else writes
     * ([ProvideImageLoader][com.edde746.plezy.ui.image.ProvideImageLoader]).
     */
    val artworkCacheDirectory: File

    /** The platform has a share sheet ([share]): Android phones and tablets; not TV or desktop. */
    val canShare: Boolean get() = false

    /** Opens the platform's share sheet with [text] (a watch-together invite); nothing where [canShare] is false. */
    fun share(text: String) {}

    /**
     * Shows the system's save dialog for a JSON file, [fileName] proposed, writes [text] into the chosen file as UTF-8
     * off the main thread, then reports how it went to [done] on the main thread. Only where [hasFileDialogs] is true.
     * Never logs the file's contents or where it went.
     */
    fun saveFile(fileName: String, text: String, done: (SaveResult) -> Unit)

    /**
     * Shows the system's open dialog for any file (one saved under another type is still offered), reads the chosen
     * file off the main thread and decodes it strictly as UTF-8, then hands its display name and text to [opened] on the
     * main thread, or calls [failed] when it can't be read or isn't UTF-8 text; nothing when the user cancels. Only
     * where [hasFileDialogs] is true (the player's shader import). Never logs the file's
     * contents or where it is.
     */
    fun openFile(opened: (name: String, text: String) -> Unit, failed: () -> Unit)

    /**
     * Shows the system's open dialog for an image, reads the chosen file off the main thread, then hands its display
     * name and bytes to [opened] on the main thread, or calls [failed] when it can't be read; nothing when the user
     * cancels. Only where [hasFileDialogs] is true (the metadata editor's artwork upload).
     */
    fun openImage(opened: (name: String, bytes: ByteArray) -> Unit, failed: () -> Unit) {}

    /**
     * The home-screen icon [id] (`AppIconCatalog`) as this device's launcher draws it, filling [modifier]'s bounds, for
     * the app icon picker: Android draws the alternates' thumbnails and the default as its launcher does; elsewhere
     * (no alternate icons) nothing.
     */
    @Composable
    fun AppIconPreview(id: String, modifier: Modifier) {}

    /**
     * How the product app updates itself here, one for the process ([PlezyRoot] runs its launch check and shows its
     * dialog); null where it doesn't check (a debug or test launch).
     */
    val updates: PlatformUpdates? get() = null

    /**
     * Input the platform reads itself that moves through the app without a key event of the window's own showing it (a
     * game controller's press or stick on the desktop, [com.edde746.plezy.input.GamepadAction.NonPointerInput]): each
     * shows focus, as a key does. None by default.
     */
    val nonPointerInput: Flow<Unit> get() = emptyFlow()
    /** Settings → Updates checks this install's updates ([PlatformUpdates.installation]). */
    override val installation: Installation? get() = updates?.installation
}

/** How a save dialog ([PlezyPlatform.saveFile]) ended. */
enum class SaveResult {
    SAVED,

    /** A file was chosen but couldn't be written. */
    FAILED,

    /** The user closed the dialog without saving. */
    CANCELLED,
}

/** The platform of the app on screen, provided by the app's frame. */
val LocalPlezyPlatform = staticCompositionLocalOf<PlezyPlatform> { error("no PlezyPlatform provided") }
