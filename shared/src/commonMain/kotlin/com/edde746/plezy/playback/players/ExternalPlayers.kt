package com.edde746.plezy.playback.players

import com.edde746.plezy.log.Log
import com.edde746.plezy.net.UriComponent
import com.edde746.plezy.playback.players.ExternalPlayerPlatform.ANDROID
import com.edde746.plezy.playback.players.ExternalPlayerPlatform.IOS
import com.edde746.plezy.playback.players.ExternalPlayerPlatform.LINUX
import com.edde746.plezy.playback.players.ExternalPlayerPlatform.MACOS
import com.edde746.plezy.playback.players.ExternalPlayerPlatform.TVOS
import com.edde746.plezy.playback.players.ExternalPlayerPlatform.WINDOWS
import com.edde746.plezy.settings.CustomPlayerType
import com.edde746.plezy.settings.ExternalPlayerChoice
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope

/** The platforms whose external players differ. iPhone and iPad are [IOS], Apple TV [TVOS]. */
enum class ExternalPlayerPlatform { ANDROID, IOS, TVOS, MACOS, WINDOWS, LINUX }

/**
 * A player Plezy knows ([KnownPlayers]): its stored [id] (`selected_external_player`'s), its [name], the platforms it
 * is offered on and its icon's asset name ([icon]: `vlc.svg`, `infuse.png`; null for the system default).
 */
data class KnownPlayer(val id: String, val name: String, val platforms: Set<ExternalPlayerPlatform>, val icon: String? = null) {
    fun availableOn(platform: ExternalPlayerPlatform): Boolean = platform in platforms

    /** This player as `selected_external_player` stores it. */
    val choice: ExternalPlayerChoice get() = ExternalPlayerChoice(id = id, name = name)
}

/** Extras for players whose URL scheme carries more than the stream's URL ([XCallbackPlayer.playUri]). */
data class ExternalPlayerLaunchOptions(
    val startPositionMs: Long? = null,
    val returnLinks: ExternalPlayerReturnLinks? = null,
    /** A descriptive file name (`Show - S01E02 - Title.mkv`, [playerFilename]) for players that identify media by name. */
    val filename: String? = null,
)

/** The x-callback-url links a player opens to hand control back to Plezy, one per way playback can end. */
data class ExternalPlayerReturnLinks(val success: String, val cancel: String, val error: String)

/**
 * A player launched through `<scheme>://x-callback-url/<action>`, and which of the optional parameters it understands.
 *
 * @param supportsStartPosition it takes `position`, the start in whole seconds.
 * @param successMeansFinished `x-success` without a position means the video played to its end, rather than that it
 *   stopped somewhere unknown.
 * @param decodesCallbackUrls it percent-decodes `x-success`/`x-cancel`/`x-error` before opening them. Players that
 *   don't get the return links unencoded: they hold no `&` or `=`, so they survive a naive query split.
 */
data class XCallbackPlayer(
    val scheme: String,
    val action: String = "play",
    val supportsCancel: Boolean = false,
    val supportsFilename: Boolean = false,
    val supportsStartPosition: Boolean = true,
    val successMeansFinished: Boolean = true,
    val decodesCallbackUrls: Boolean = true,
) {
    /** The play link for [url]: every value percent-encoded as `encodeURIComponent` does (spaces as `%20`). */
    fun playUri(url: String, options: ExternalPlayerLaunchOptions): String {
        val startSeconds = if (supportsStartPosition) (options.startPositionMs ?: 0) / 1000 else 0
        val filename = if (supportsFilename) options.filename else null
        fun returnLink(link: String) = if (decodesCallbackUrls) UriComponent.encode(link) else link
        val query = buildList {
            add("url=" + UriComponent.encode(url))
            filename?.let { add("filename=" + UriComponent.encode(it)) }
            if (startSeconds > 0) add("position=$startSeconds")
            options.returnLinks?.let { links ->
                add("x-success=" + returnLink(links.success))
                if (supportsCancel) add("x-cancel=" + returnLink(links.cancel))
                add("x-error=" + returnLink(links.error))
            }
        }.joinToString("&")
        return "$scheme://x-callback-url/$action?$query"
    }
}

/**
 * The host lookups behind [KnownPlayers.detect], one platform's answers: each asks the question its launcher asks, so a
 * listed player is one that can be started.
 */
interface PlayerInstallProbe {
    /** The process environment (Windows' `ProgramFiles` and friends). */
    val environment: Map<String, String>

    /** [command] resolves on `PATH`: `sh -c 'command -v "$1"'` on Linux and macOS, `where.exe` on Windows. */
    suspend fun commandExists(command: String): Boolean

    suspend fun fileExists(path: String): Boolean

    /** macOS: Launch Services knows the application [bundleId] (what `open -a` resolves through). */
    suspend fun applicationInstalled(bundleId: String): Boolean

    /** An app handles URLs of [scheme] (`vlc://`, `potplayer://`). */
    suspend fun schemeHasHandler(scheme: String): Boolean
}

/** One way to start a player off Android, tried in order ([ExternalPlayerLaunch.attempts]) until one starts. */
sealed interface ExternalPlayerAttempt {
    /**
     * Hand [url] to the app that handles it. [checkHandler]: first ask whether an app handles it, and fail without
     * one (iPhone, iPad and Apple TV don't ask: the answer is false for any scheme the app didn't declare, which is
     * every custom player's; the open itself reports a missing handler).
     */
    data class OpenUrl(val url: String, val checkHandler: Boolean) : ExternalPlayerAttempt {
        override fun toString(): String = "OpenUrl(<redacted>, checkHandler=$checkHandler)"
    }

    /** Start the program [command] with its arguments, detached; it started when its process did. */
    data class Command(val command: List<String>) : ExternalPlayerAttempt {
        override fun toString(): String = "Command(${command.first()})"
    }
}

/** The players Plezy knows, on which platforms each is offered, how each starts and how each is detected. */
object KnownPlayers {
    const val SYSTEM_DEFAULT_ID: String = "system_default"

    /** Hands the stream to whatever the OS opens it with. Apple TV has no handler for http(s): not offered there. */
    val systemDefault: KnownPlayer = KnownPlayer(SYSTEM_DEFAULT_ID, "System Default", setOf(ANDROID, IOS, MACOS, WINDOWS, LINUX))

    /** Every known player, in the order the settings list them. */
    val all: List<KnownPlayer> = listOf(
        systemDefault,
        KnownPlayer("vlc", "VLC", setOf(ANDROID, IOS, TVOS, MACOS, LINUX, WINDOWS), "vlc.svg"),
        KnownPlayer("mpv", "mpv", setOf(ANDROID, MACOS, LINUX, WINDOWS), "mpv.svg"),
        KnownPlayer("iina", "IINA", setOf(MACOS), "iina.png"),
        KnownPlayer("mx_player", "MX Player", setOf(ANDROID), "mx_player.svg"),
        KnownPlayer("just_player", "Just Player", setOf(ANDROID), "just_player.png"),
        KnownPlayer("infuse", "Infuse", setOf(IOS, TVOS), "infuse.png"),
        KnownPlayer("outplayer", "Outplayer", setOf(IOS), "outplayer.png"),
        KnownPlayer("potplayer", "PotPlayer", setOf(WINDOWS), "potplayer.png"),
        KnownPlayer("celluloid", "Celluloid", setOf(LINUX), "celluloid.svg"),
    )

    fun findById(id: String): KnownPlayer? = all.firstOrNull { it.id == id }

    /** The known players offered on [platform], in order. */
    fun supportedOn(platform: ExternalPlayerPlatform): List<KnownPlayer> = all.filter { it.availableOn(platform) }

    /** [choice] can be launched on [platform]: a custom player always, a known one where it is offered. */
    fun isAvailable(choice: ExternalPlayerChoice, platform: ExternalPlayerPlatform): Boolean =
        choice.isCustom || findById(choice.id)?.availableOn(platform) == true

    private val androidPackages = mapOf(
        "vlc" to listOf("org.videolan.vlc"),
        "mpv" to listOf("is.xyz.mpv"),
        "mx_player" to listOf("com.mxtech.videoplayer.ad", "com.mxtech.videoplayer.pro"),
        "just_player" to listOf("com.brouken.player"),
    )

    /**
     * The Android packages [choice] is tried as, in order: a known player's, a custom command player's package; none for
     * the system default and the rest (the system resolves the intent).
     */
    fun androidPackageCandidates(choice: ExternalPlayerChoice): List<String> {
        androidPackages[choice.id]?.let { return it }
        if (choice.isCustom && choice.customType == CustomPlayerType.COMMAND) {
            return listOfNotNull(choice.customValue?.trim()?.takeIf { it.isNotEmpty() })
        }
        return emptyList()
    }

    private val xCallbackPlayers = mapOf(
        "outplayer" to XCallbackPlayer(scheme = "outplayer", supportsCancel = true),
        // No x-cancel: Infuse calls x-success with the position once playback ends. It matches metadata by `filename`.
        "infuse" to XCallbackPlayer(scheme = "infuse", supportsFilename = true),
        // VLC calls x-success on every stop, finished or not, and appends nothing: no position comes back, and it takes no
        // start position either. VLC 3.7.x opens the return links as `URL(string:)` without decoding them.
        "vlc" to XCallbackPlayer(
            scheme = "vlc-x-callback",
            action = "stream",
            supportsStartPosition = false,
            successMeansFinished = false,
            decodesCallbackUrls = false,
        ),
    )

    /** How [playerId] is launched through x-callback-url, or null. */
    fun xCallbackPlayer(playerId: String): XCallbackPlayer? = xCallbackPlayers[playerId]

    /** The x-callback-url play link for [playerId], or null for players not launched that way. */
    fun callbackPlayUri(playerId: String, url: String, options: ExternalPlayerLaunchOptions): String? =
        xCallbackPlayers[playerId]?.playUri(url, options)

    /**
     * [playerId] is launched with a start position and return links on [platform]: VLC, Infuse and Outplayer on iPhone
     * and iPad. Apple TV has no handler for the return links.
     */
    fun launchesWithCallback(playerId: String, platform: ExternalPlayerPlatform): Boolean =
        platform == IOS && playerId in xCallbackPlayers

    /**
     * How [choice] plays [url] on [platform] (not Android, where every player gets the intent hand-off), in order:
     * [callbackUrl], when set, is the x-callback-url play link to open instead.
     */
    fun attempts(
        choice: ExternalPlayerChoice,
        platform: ExternalPlayerPlatform,
        url: String,
        environment: Map<String, String>,
        callbackUrl: String? = null,
    ): List<ExternalPlayerAttempt> {
        val apple = platform == IOS || platform == TVOS
        fun open(target: String) = ExternalPlayerAttempt.OpenUrl(target, checkHandler = !apple)
        fun scheme(prefix: String) = open(urlSchemeTarget(prefix, url))
        fun command(vararg command: String) = ExternalPlayerAttempt.Command(command.toList())
        if (callbackUrl != null) return listOf(open(callbackUrl))
        if (choice.isCustom) {
            val value = choice.customValue.orEmpty()
            return when {
                choice.customType == CustomPlayerType.URL_SCHEME -> listOf(scheme(value))
                // A program on PATH first (mpv), else an application by name (VLC).
                platform == MACOS -> listOf(command(value, url), command("open", "-a", value, url))
                else -> listOf(command(value, url))
            }
        }
        return when (choice.id) {
            SYSTEM_DEFAULT_ID -> listOf(ExternalPlayerAttempt.OpenUrl(url, checkHandler = false))
            "vlc" -> when (platform) {
                IOS, TVOS -> listOf(scheme("vlc://"))
                MACOS -> listOf(command("open", "-a", "VLC", url))
                WINDOWS -> windowsVlcCommands(environment).map { command(it, url) }
                else -> listOf(command("vlc", url))
            }
            "mpv" -> listOf(command("mpv", url))
            "iina" -> listOf(scheme("iina://weblink?url="))
            "infuse" -> listOf(scheme("infuse://x-callback-url/play?url="))
            "outplayer" -> listOf(open(callbackPlayUri("outplayer", url, ExternalPlayerLaunchOptions())!!))
            "potplayer" -> listOf(scheme("potplayer://"), command("PotPlayerMini64", url))
            "celluloid" -> listOf(command("celluloid", url))
            else -> emptyList()
        }
    }

    /** A URL-scheme player's link: [url] percent-encoded after a scheme that ends in `url=`, else appended as it is. */
    fun urlSchemeTarget(scheme: String, url: String): String =
        if ("url=" in scheme) scheme + UriComponent.encode(url) else scheme + url

    /** VLC on Windows: `vlc` on PATH, then where its installer puts it under each Program Files folder. */
    fun windowsVlcCommands(environment: Map<String, String>): List<String> {
        val candidates = mutableListOf("vlc")
        fun addInstallPath(programFiles: String?) {
            val trimmed = programFiles?.trim()
            if (trimmed.isNullOrEmpty()) return
            candidates += trimmed.trimEnd('\\', '/') + "\\VideoLAN\\VLC\\vlc.exe"
        }
        addInstallPath(environment["ProgramW6432"])
        addInstallPath(environment["ProgramFiles"])
        addInstallPath(environment["ProgramFiles(x86)"])
        addInstallPath("C:\\Program Files")
        addInstallPath("C:\\Program Files (x86)")
        val seen = mutableSetOf<String>()
        return candidates.filter { seen.add(it.lowercase()) }
    }

    /**
     * The players offered on [platform] minus the ones [probe] can positively tell are missing, in [all]'s order.
     * Detectors run concurrently and fail open: a lookup that throws lists its player, since hiding a working player is
     * worse than listing a missing one. Android probes nothing.
     */
    suspend fun detect(platform: ExternalPlayerPlatform, probe: PlayerInstallProbe): List<KnownPlayer> {
        val supported = supportedOn(platform)
        val detectors: Map<String, suspend () -> Boolean> = when (platform) {
            LINUX -> mapOf(
                "vlc" to { probe.commandExists("vlc") },
                "mpv" to { probe.commandExists("mpv") },
                "celluloid" to { probe.commandExists("celluloid") },
            )
            MACOS -> mapOf(
                "vlc" to { probe.applicationInstalled("org.videolan.vlc") },
                "iina" to { probe.applicationInstalled("com.colliderli.iina") },
                "mpv" to { probe.commandExists("mpv") },
            )
            WINDOWS -> mapOf(
                "vlc" to { windowsVlcExists(probe) },
                "mpv" to { probe.commandExists("mpv") },
                "potplayer" to { probe.schemeHasHandler("potplayer://") || probe.commandExists("PotPlayerMini64") },
            )
            IOS -> mapOf(
                "vlc" to { probe.schemeHasHandler("vlc://") },
                "infuse" to { probe.schemeHasHandler("infuse://") },
                "outplayer" to { probe.schemeHasHandler("outplayer://") },
            )
            TVOS -> mapOf(
                "vlc" to { probe.schemeHasHandler("vlc://") },
                "infuse" to { probe.schemeHasHandler("infuse://") },
            )
            ANDROID -> emptyMap()
        }
        if (detectors.isEmpty()) return supported
        val missing = coroutineScope {
            detectors.map { (id, detector) -> async { id to detected(id, detector) } }.awaitAll()
        }.filterNot { it.second }.map { it.first }.toSet()
        return supported.filterNot { it.id in missing }
    }

    private suspend fun detected(id: String, detector: suspend () -> Boolean): Boolean = try {
        detector()
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "detecting $id failed; listing it anyway" }
        true
    }

    /** As VLC launches on Windows: any of its concrete install paths, else `vlc` on PATH. */
    private suspend fun windowsVlcExists(probe: PlayerInstallProbe): Boolean {
        for (candidate in windowsVlcCommands(probe.environment)) {
            if ('\\' in candidate && probe.fileExists(candidate)) return true
        }
        return probe.commandExists("vlc")
    }

    private const val TAG = "ExternalPlayers"
}
