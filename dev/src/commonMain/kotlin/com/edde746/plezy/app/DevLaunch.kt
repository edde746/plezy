package com.edde746.plezy.app

import com.edde746.plezy.presentation.navigation.TopLevelDestination
import com.edde746.plezy.presentation.navigation.Startup
import com.edde746.plezy.settings.AppLocale
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.strings.InterfaceLocale
import com.edde746.plezy.supporter.SupporterMode
import com.edde746.plezy.watch.WatchPartyRelays

/**
 * A launch's development options, the same on every platform, as [parse] reads them: the desktop harness launcher's
 * arguments, the Apple apps' launch arguments (`xcrun simctl launch booted com.edde746.plezy --dev …`, a UI test's
 * `launchArguments`) and Android's `dev` launch extra, a string array of the same arguments
 * (`am start --esa dev --dev,--dev-open,home`).
 *
 * [dev] starts a development session instead of the product: [AppBootstrap.local]'s graph on an in-memory database
 * (or the one kept under [data]), which [applyDevSettings] and [devAppSession] set up, on [open], or playing [url] or
 * [play] in the player over it. Every other session option needs it. [slowStartMillis] tests the product's start
 * instead, so it refuses it.
 *
 * A platform that can't do an option it is given fails the launch saying so, as [parse] fails on an option it doesn't
 * know: a launch never runs without an option it asked for.
 */
class DevLaunch private constructor(
    /** `--dev`: a development session instead of the product. */
    val dev: Boolean,
    /**
     * `--dev-open <destination>`: where the session starts: a top-level destination by its lowercase name, `live_tv`
     * (Live TV over Home) or `downloads` (Libraries' downloads); Home without it.
     */
    val open: Startup,
    /**
     * `--dev-setting <key>=<value>`, repeatable: this device's settings to start with ([DevSetting]); `--dev-language
     * <tag>` (a tag of [InterfaceLocale.available]) is the Language setting's, last.
     */
    val settings: List<DevSetting>,
    /**
     * `--dev-server <kind>=<user>:<password>@<url>`, repeatable: media servers the session signs into once it starts
     * ([DevServer], [signInDevServers]), logging each one's libraries; a sign-in that fails ends the launch.
     */
    val servers: List<DevServer>,
    /**
     * `--dev-download <title>`, repeatable: once the session signed into its [servers], the items of these titles on the
     * first of them (matched without case, `_` standing for a space: a launch extra can't carry spaces through every
     * shell; `<show>/<season>` for a season) are downloaded in order, as their Download buttons would
     * ([queueDevDownloads]); needs `--dev-server`.
     */
    val downloads: List<String>,
    /**
     * `--dev-discord <application id>`: Discord's Rich Presence shows as this Discord application (a test one: the
     * tests' fake Discord takes any); without it the session has none, whatever the build's.
     */
    val discord: String?,
    /**
     * `--dev-crash-reports <dsn>`: the session's crash reports go to this Sentry DSN (a fake Sentry's) while
     * `crash_reporting` is on; without it the session sends none, whatever the build's.
     */
    val crashReports: String?,
    /**
     * `--dev-data <name>`: the session's database kept on the device under this name (letters, digits, `-` and `_`),
     * so the next launch with the same name continues the session; in memory without it. Its tokens are not kept: a
     * development session's secrets are in memory ([AppBootstrap.local]), never in the device's keychain or credential
     * store, so the next launch signs its `--dev-server`s in again (offline it keeps their stored connections,
     * [signInDevServers]).
     */
    val data: String?,
    /** `--dev-slow-start <seconds>`, in milliseconds: the product's start takes this much longer ([Startup]). */
    val slowStartMillis: Long,
    /** `--url <http url>`: the session opens the player on this video ([com.edde746.plezy.playback.session.PlayRequest.Url]). */
    val url: String?,
    /**
     * `--dev-play <server>:<item>`: the session opens the player on this item of a signed-in server ([DevPlay]); with
     * [url], one of the two.
     */
    val play: DevPlay?,
    /**
     * `--dev-trackers <url>`: the tracker services' calls (Trakt, Simkl, MDBList, MyAnimeList, AniList and the OAuth
     * relay) go to the fake tracker server at this http(s) URL (`tools/media/test_trackers.py`) instead of their hosts.
     */
    val trackers: String?,
    /**
     * `--dev-trackers-connected`, a flag: the session starts with every tracker service connected to [trackers]'s fake
     * with a fake session, without signing in. Needs `--dev-trackers`.
     */
    val trackersConnected: Boolean,
    /**
     * `--dev-entry <main|boot>`: `boot` enters the session as the product enters the app (the sign-in on fresh data, the
     * profile picker when asked); `main` (the default) starts on the main screen.
     */
    val entry: DevEntry,
    /** `--dev-plex fixture|expired`: plex.tv answered from recorded responses ([httpClient]); the real plex.tv without it. */
    val plex: DevPlex?,
    /**
     * `--dev-music-url <url>[,<url>…]`, repeatable: the music session plays these streams (http(s) or file URLs) as one
     * queue, in the order given, once the session starts, each URL as it is, with no server.
     */
    val musicUrls: List<String>,
    /**
     * `--dev-open-music library|artist=<title>|album=<title>|playlist=<title>`: once [servers] are signed in, the first
     * server's music library, or the artist, album or audio playlist of that title on it (a playlist's `_` standing for
     * a space), opens over [open].
     */
    val openMusic: DevOpenMusic?,
    /**
     * `--dev-open-item <title>`: once [servers] are signed in, the detail screen of the first server's item of that
     * title opens over [open]: a movie, a show, an episode, a collection, `<show>/<season>` for a season and
     * `<show>/<season>/<episode>` for an episode, each matched without case, `_` standing for a space, as
     * `--dev-download`'s ([findDevTitle]).
     */
    val openItem: String?,
    /**
     * `--dev-open-show-schedule <show title>`: once [servers] are signed in, the live TV schedule of that show on the
     * first server opens over [open], as What's On opens it for a show. `_` stands for a space (`Morning_News`), for
     * launchers that split arguments at spaces.
     */
    val openShowSchedule: String?,
    /**
     * `--dev-seerr <email>:<password>@<url>`: the session's profile signs in to this Seerr instance with its local
     * account as the session starts, so Explore shows its rows. The URL starts at the last `@http`; the password is
     * everything after the email's first `:`.
     */
    val seerr: DevSeerr?,
    /**
     * `--dev-supporter <off|iap|unlocked|msstore|build>`: the session's Supporter mode ([SupporterMode]), over the
     * platform's store and icon switcher; `build` (null) keeps the build's own mode and donation link, as a product
     * launch has them; [SupporterMode.UNLOCKED] (every perk free) without it.
     */
    val supporter: SupporterMode?,
    /**
     * `--dev-edit <server>:<item>`: the session opens the metadata editor of this item of a signed-in server once the
     * servers are bound (the [DevPlay] syntax).
     */
    val edit: DevPlay? = null,
    /** `--dev-playlist <server>:<playlist>`: the session opens this playlist's screen once the servers are bound ([DevPlaylist]). */
    val playlist: DevPlaylist?,
    /**
     * `--dev-watch-room <code>`: once the profile is active (a local profile "Dev" made when there is none), the Watch
     * Together screen opens and joins the room of this code as a recent room does: the user hosts it when nobody is in
     * it, else joins as a guest. The relay is `watch_party_relay_url`'s (`--dev-setting`).
     */
    val watchRoom: String?,
    /**
     * `--dev-automotive`: the session lays out as on an Android Automotive head unit whatever the device
     * ([com.edde746.plezy.app.AppPlatform.automotive]): the car's interface scale and list rows.
     */
    val automotive: Boolean,
    /**
     * `--dev-revoke-token`, a flag: once signed in, the session ends its first server's sign-in on that server
     * (Jellyfin's and Emby's `Sessions/Logout`), so the server refuses the token from then on (HTTP 401) and the app
     * says "Session expired" ([revokeDevToken]). Needs `--dev-server`.
     */
    val revokeToken: Boolean,
    /**
     * `--dev-server-tasks`, a flag: Home's Server Tasks come from a made-up Plex server running a few tasks
     * ([DevServerTasks]) instead of the online Plex servers.
     */
    val serverTasks: Boolean,
    /**
     * `--dev-no-audio`, a flag: the session plays with no audio output (`ao=null`) and never tries to win one back, so
     * playback runs silently on a host with no audio device. The desktop engine's only.
     */
    val noAudio: Boolean,
) {
    companion object {
        /**
         * The options in [args], in any order. Arguments that aren't options of this type ([isOption]) are the
         * platform's own, and are skipped.
         *
         * @throws IllegalArgumentException for an unknown `--dev…` option, an option without its value or with one it
         *   doesn't take, or options that don't go together, with the message to show.
         */
        @Throws(IllegalArgumentException::class)
        fun parse(args: List<String>): DevLaunch {
            var dev = false
            var open = Startup(TopLevelDestination.HOME)
            var language: DevSetting? = null
            val settings = mutableListOf<DevSetting>()
            val servers = mutableListOf<DevServer>()
            val downloads = mutableListOf<String>()
            var discord: String? = null
            var crashReports: String? = null
            var data: String? = null
            var slowStartMillis = 0L
            var url: String? = null
            var play: DevPlay? = null
            var trackers: String? = null
            var trackersConnected = false
            var entry = DevEntry.MAIN
            var plex: DevPlex? = null
            var musicUrls = emptyList<String>()
            var openMusic: DevOpenMusic? = null
            var openShowSchedule: String? = null
            var openItem: String? = null
            var seerr: DevSeerr? = null
            var supporter: SupporterMode? = SupporterMode.UNLOCKED
            var edit: DevPlay? = null
            var playlist: DevPlaylist? = null
            var watchRoom: String? = null
            var automotive = false
            var revokeToken = false
            var serverTasks = false
            var noAudio = false
            val given = linkedSetOf<String>()
            var i = 0
            while (i < args.size) {
                val name = args[i++]
                if (!isOption(name)) continue
                given += name
                if (name == DEV) {
                    dev = true
                    continue
                }
                if (name in FLAGS) {
                    when (name) {
                        TRACKERS_CONNECTED -> trackersConnected = true
                        REVOKE_TOKEN -> revokeToken = true
                        SERVER_TASKS -> serverTasks = true
                        NO_AUDIO -> noAudio = true
                        AUTOMOTIVE -> automotive = true
                        else -> Unit
                    }
                    continue
                }
                val next = args.getOrNull(i++)
                fun value(): String = next ?: throw IllegalArgumentException("$name needs a value")
                when (name) {
                    OPEN -> open = read(name, value(), ::destination)
                    LANGUAGE -> language = read(name, value(), ::interfaceLanguage)
                    SETTING -> settings += read(name, value()) { DevSetting.parse(it) }
                    SERVER -> servers += read(name, value()) { DevServer.parse(it) }
                    DOWNLOAD -> downloads += value().trim().ifEmpty { throw IllegalArgumentException("$name needs an item's title") }
                    DISCORD -> discord = read(name, value(), ::discordApplication)
                    CRASH_REPORTS -> crashReports = read(name, value(), ::sentryDsn)
                    DATA -> data = read(name, value(), ::dataName)
                    SLOW_START -> slowStartMillis = read(name, value(), ::seconds)
                    URL -> url = read(name, value(), ::httpUrl)
                    PLAY -> play = read(name, value(), DevPlay::parse)
                    TRACKERS -> trackers = read(name, value(), ::httpUrl)
                    ENTRY -> entry = read(name, value()) { v -> oneOf(DevEntry.entries, v) }
                    PLEX -> plex = read(name, value()) { v -> oneOf(DevPlex.entries, v) }
                    MUSIC_URL -> musicUrls = musicUrls + read(name, value(), ::streamUrls)
                    OPEN_MUSIC -> openMusic = read(name, value(), DevOpenMusic::parse)
                    OPEN_SHOW_SCHEDULE -> openShowSchedule = value().replace('_', ' ').trim().ifEmpty { throw IllegalArgumentException("$name needs a show's title") }
                    OPEN_ITEM -> openItem = value().trim().ifEmpty { throw IllegalArgumentException("$name needs an item's title") }
                    SEERR -> seerr = read(name, value(), ::seerrAccount)
                    SUPPORTER -> supporter = read(name, value()) { v -> if (v == BUILD_SUPPORTER) null else oneOf(SupporterMode.entries, v) }
                    EDIT -> edit = read(name, value(), DevPlay::parse)
                    PLAYLIST -> playlist = read(name, value(), DevPlaylist::parse)
                    WATCH_ROOM -> watchRoom = read(name, value(), ::roomCode)
                    else -> throw IllegalArgumentException("unknown option $name")
                }
            }
            val session = given.filter { it != DEV && it !in PRODUCT }
            require(dev || session.isEmpty()) { "${session.joinToString()} need $DEV" }
            val product = given.filter { it in PRODUCT }
            require(!dev || product.isEmpty()) { "${product.joinToString()} test the product's start, which $DEV replaces: not with $DEV" }
            require(url == null || play == null) { "$URL and $PLAY are two different plays: pass one" }
            require(!trackersConnected || trackers != null) { "$TRACKERS_CONNECTED needs $TRACKERS" }
            require(openMusic == null || servers.isNotEmpty()) { "$OPEN_MUSIC needs $SERVER" }
            require(openShowSchedule == null || servers.isNotEmpty()) { "$OPEN_SHOW_SCHEDULE needs $SERVER" }
            require(openItem == null || servers.isNotEmpty()) { "$OPEN_ITEM needs $SERVER: it opens the first server's item" }
            require(downloads.isEmpty() || servers.isNotEmpty()) { "$DOWNLOAD needs $SERVER: it downloads from the first server" }
            require(!revokeToken || servers.isNotEmpty()) { "$REVOKE_TOKEN needs $SERVER: it signs out of the first server" }
            return DevLaunch(
                dev, open, settings + listOfNotNull(language), servers, downloads, discord, crashReports, data, slowStartMillis, url, play,
                trackers, trackersConnected, entry, plex, musicUrls, openMusic, openItem, openShowSchedule, seerr, supporter, edit, playlist, watchRoom,
                automotive,
                revokeToken, serverTasks, noAudio,
            )
        }

        /**
         * Whether the argument [name] is an option [parse] reads: `--url`, or any argument starting with `--dev`, known
         * or not. A platform's own parser hands these to [parse], with their values ([takesValue]).
         */
        fun isOption(name: String): Boolean = name == URL || name.startsWith(DEV)

        /** Whether the option [name] ([isOption]) takes a value, the argument after it: every option but the flags. */
        fun takesValue(name: String): Boolean = name !in FLAGS

        /** [value] of the option [name] as [parse] reads it, its refusal's message naming the option. */
        private fun <T> read(name: String, value: String, parse: (String) -> T): T = try {
            parse(value)
        } catch (e: IllegalArgumentException) {
            throw IllegalArgumentException("$name ${e.message}", e)
        }

        /** A destination by its lowercase name, or `live_tv` (Live TV over Home) and `downloads` (Libraries' section). */
        private fun destination(name: String): Startup {
            val starts = TopLevelDestination.entries.associate { it.name.lowercase() to Startup(it) } +
                mapOf("live_tv" to Startup.LIVE_TV, "downloads" to Startup.DOWNLOADS)
            return starts[name] ?: throw IllegalArgumentException("needs one of ${starts.keys.joinToString()}, got '$name'")
        }

        private fun <E : Enum<E>> oneOf(entries: List<E>, name: String): E =
            entries.firstOrNull { it.name.lowercase() == name }
                ?: throw IllegalArgumentException("needs one of ${entries.joinToString { it.name.lowercase() }}, got '$name'")

        private fun interfaceLanguage(tag: String): DevSetting {
            val locale = requireNotNull(AppLocale.entries.firstOrNull { it.tag == tag }) {
                "needs an interface language this build has strings for (${InterfaceLocale.available.joinToString()}), got '$tag'"
            }
            return DevSetting.Value(AppSettings.appLocale, locale.storedName, locale.storedName)
        }

        private fun discordApplication(id: String): String {
            require(id.isNotBlank()) { "needs a Discord application id" }
            return id
        }

        private fun sentryDsn(dsn: String): String {
            require(dsn.startsWith("http://") || dsn.startsWith("https://")) { "needs a Sentry DSN (http://<key>@<host>/<project>), got '$dsn'" }
            return dsn
        }

        private fun httpUrl(url: String): String {
            require((url.startsWith("http://") || url.startsWith("https://")) && url.substringAfter("://").isNotEmpty()) {
                "needs an http or https URL, got '$url'"
            }
            return url
        }

        private fun dataName(name: String): String {
            require(name.isNotEmpty() && name.all { it in 'a'..'z' || it in 'A'..'Z' || it in '0'..'9' || it == '-' || it == '_' }) {
                "needs a name of letters, digits, - and _, got '$name'"
            }
            return name
        }

        private fun seerrAccount(spec: String): DevSeerr {
            val at = spec.lastIndexOf("@http")
            val url = if (at < 0) "" else spec.substring(at + 1)
            val credentials = if (at < 0) "" else spec.substring(0, at)
            val email = credentials.substringBefore(':', "")
            val password = credentials.substringAfter(':', "")
            require((url.startsWith("http://") || url.startsWith("https://")) && email.isNotBlank() && password.isNotEmpty()) {
                "needs <email>:<password>@<url> with an http(s) URL"
            }
            return DevSeerr(url, email, password)
        }

        private fun roomCode(code: String): String =
            requireNotNull(WatchPartyRelays.normalizeRoomCode(code)) { "needs a room code: 6 letters and digits without 0, 1, I, L or O, got '$code'" }

        private fun seconds(spec: String): Long {
            val seconds = spec.toDoubleOrNull()?.takeIf { it > 0 && it.isFinite() }
                ?: throw IllegalArgumentException("needs a positive number of seconds, got '$spec'")
            return (seconds * 1000).toLong()
        }

        private fun streamUrls(spec: String): List<String> {
            val urls = spec.split(',').map { it.trim() }
            require(urls.all { it.startsWith("http://") || it.startsWith("https://") || it.startsWith("file://") }) {
                "needs http(s) or file URLs separated by commas, got '$spec'"
            }
            return urls
        }

        private const val DEV = "--dev"
        private const val OPEN = "--dev-open"
        private const val LANGUAGE = "--dev-language"
        private const val SETTING = "--dev-setting"
        private const val SERVER = "--dev-server"
        private const val DOWNLOAD = "--dev-download"
        private const val DISCORD = "--dev-discord"
        private const val CRASH_REPORTS = "--dev-crash-reports"
        private const val DATA = "--dev-data"
        private const val SLOW_START = "--dev-slow-start"
        private const val URL = "--url"
        private const val PLAY = "--dev-play"
        private const val EDIT = "--dev-edit"
        private const val TRACKERS = "--dev-trackers"
        private const val TRACKERS_CONNECTED = "--dev-trackers-connected"
        private const val MUSIC_URL = "--dev-music-url"
        private const val OPEN_MUSIC = "--dev-open-music"
        private const val OPEN_SHOW_SCHEDULE = "--dev-open-show-schedule"
        private const val OPEN_ITEM = "--dev-open-item"
        private const val SEERR = "--dev-seerr"
        private const val WATCH_ROOM = "--dev-watch-room"
        private const val AUTOMOTIVE = "--dev-automotive"
        private const val REVOKE_TOKEN = "--dev-revoke-token"
        private const val SERVER_TASKS = "--dev-server-tasks"
        private const val NO_AUDIO = "--dev-no-audio"

        /** The options that take no value. */
        private val FLAGS = setOf(DEV, TRACKERS_CONNECTED, AUTOMOTIVE, REVOKE_TOKEN, SERVER_TASKS, NO_AUDIO)
        private const val ENTRY = "--dev-entry"
        private const val PLEX = "--dev-plex"
        private const val SUPPORTER = "--dev-supporter"

        /** `--dev-supporter`'s value that keeps the build's own Supporter mode. */
        private const val BUILD_SUPPORTER = "build"
        private const val PLAYLIST = "--dev-playlist"

        /** The options that test the product's start, not a development session's. */
        private val PRODUCT = setOf(SLOW_START)
    }
}

/** A music screen a development session opens once signed in ([DevLaunch.openMusic]). */
sealed interface DevOpenMusic {
    /** The first server's first music library. */
    data object Library : DevOpenMusic

    /** The artist named [title] on the first server. */
    data class Artist(val title: String) : DevOpenMusic

    /** The album named [title] on the first server. */
    data class Album(val title: String) : DevOpenMusic

    /** The audio playlist named [title] on the first server, on the music playlist screen. */
    data class Playlist(val title: String) : DevOpenMusic

    companion object {
        /** `library`, `artist=<title>`, `album=<title>` or `playlist=<title>`. */
        fun parse(spec: String): DevOpenMusic {
            if (spec == "library") return Library
            val kind = spec.substringBefore('=')
            val title = spec.substringAfter('=', "")
            val needs = "needs library, artist=<title>, album=<title> or playlist=<title>, got '$spec'"
            require(title.isNotBlank()) { needs }
            return when (kind) {
                "artist" -> Artist(title)
                "album" -> Album(title)
                "playlist" -> Playlist(title)
                else -> throw IllegalArgumentException(needs)
            }
        }
    }
}

/** A Seerr instance and the local account a development session signs in with (`--dev-seerr`, [DevLaunch.seerr]). */
class DevSeerr(val url: String, val email: String, val password: String) {
    override fun toString(): String = "DevSeerr($url, $email)"
}
