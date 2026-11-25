package com.edde746.plezy.presentation.onboarding

import com.edde746.plezy.app.BrowserMode
import com.edde746.plezy.backend.MediaServerAuthException
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.MediaServerPinExpiredException
import com.edde746.plezy.backend.localizedErrorReason
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.plex.tv.PlexAuthService
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.profiles.PlexSignInResult
import com.edde746.plezy.profiles.ProfileServices
import com.edde746.plezy.profiles.stored
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/** Where a Plex PIN sign-in is ([PlexPinUiState.phase]). */
enum class PlexPinPhase {
    /** The buttons: Sign in with Plex (the browser) and Show QR Code. */
    IDLE,

    /** Waiting for the sign-in in the browser: a spinner, Retry and Cancel. */
    BROWSER,

    /**
     * A code to enter at plex.tv/link ([PlexPinUiState.code]) and the QR code of that page with it filled in
     * ([PlexPinUiState.qrUrl]), both null while the PIN is made; expired ([PlexPinUiState.expired]) neither, the expiry
     * shown instead. Retry and Cancel throughout.
     */
    QR,

    /** The token came; the account is being stored. */
    REGISTERING,
}

/**
 * A Plex PIN sign-in's state. [ready]: the sign-in service is made (the buttons are disabled until then); [error]: the
 * last attempt's failure, under the buttons or the code.
 */
data class PlexPinUiState(
    val phase: PlexPinPhase = PlexPinPhase.IDLE,
    val qrUrl: String? = null,
    val code: String? = null,
    val expired: Boolean = false,
    val error: String? = null,
    val ready: Boolean = false,
)

/**
 * Plex sign-in by PIN through plex.tv, polled until claimed (two minutes), then [onToken]: a strong PIN whose auth link
 * opens in the browser ([startBrowser]), or a short PIN whose 4-character code is entered at plex.tv/link, shown with
 * the QR code of that page with the code filled in ([startQr]). Every start, retry and cancel begins a new attempt; an
 * earlier attempt's result is dropped and its polling stops. A code that expires stays shown as expired, for Retry.
 *
 * The browser hand-off asks [host] for a web view on TV and the in-app browser elsewhere, then for the browser outside
 * the app; when nothing opens the link, the attempt shows a code instead. Once the PIN is claimed, the in-app view it
 * opened is closed.
 */
class PlexPinFlow(
    private val auth: suspend () -> PlexAuthService,
    private val host: AccountsHost,
    private val onToken: suspend (String) -> Unit,
    private val scope: CoroutineScope,
    /** Called as each attempt starts. */
    private val onStart: () -> Unit = {},
) {
    private val mutableState = MutableStateFlow(PlexPinUiState())
    private var service: PlexAuthService? = null
    private var attempt: Job? = null
    private var retrying: Job? = null

    val state: StateFlow<PlexPinUiState> = mutableState.asStateFlow()

    init {
        scope.launch {
            service = auth()
            mutableState.value = mutableState.value.copy(ready = true)
        }
    }

    fun startBrowser() = start(useQr = false)

    fun startQr() = start(useQr = true)

    /** Starts again in the same mode, after 100 ms. */
    fun retry() {
        val useQr = mutableState.value.phase == PlexPinPhase.QR
        attempt?.cancel()
        retrying?.cancel()
        retrying = scope.launch {
            delay(100)
            start(useQr)
        }
    }

    /** Abandons the attempt and returns to the buttons. */
    fun cancel() {
        attempt?.cancel()
        retrying?.cancel()
        mutableState.value = PlexPinUiState(ready = service != null)
    }

    /** Back to the buttons, the attempt left to finish (the parent, after the token). */
    fun reset() {
        mutableState.value = PlexPinUiState(ready = service != null)
    }

    /** Shows [message] under the buttons (the parent's failure after the token). */
    fun fail(message: String) {
        mutableState.value = PlexPinUiState(error = message, ready = service != null)
    }

    private fun start(useQr: Boolean) {
        val svc = service ?: return
        onStart()
        attempt?.cancel()
        mutableState.value = PlexPinUiState(phase = if (useQr) PlexPinPhase.QR else PlexPinPhase.BROWSER, ready = true)
        attempt = scope.launch {
            var inApp = false
            var qr = useQr
            val token = try {
                if (qr) {
                    showCode(svc)
                } else {
                    val pin = svc.createPin(strong = true)
                    val url = svc.authUrl(pin.code)
                    inApp = host.openUrl(url, if (host.tv) BrowserMode.IN_APP_WEB_VIEW else BrowserMode.IN_APP_BROWSER)
                    if (inApp || host.openUrl(url, BrowserMode.EXTERNAL)) {
                        svc.pollPinUntilClaimed(pin.id)
                    } else {
                        Log.w(TAG) { "Nothing opened the Plex sign-in; showing a code instead" }
                        qr = true
                        showCode(svc)
                    }
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: MediaServerPinExpiredException) {
                if (qr) expire() else fail(pinErrorMessage(e))
                return@launch
            } catch (e: Exception) {
                Log.w(TAG, e) { "Plex PIN sign-in failed" }
                fail(pinErrorMessage(e))
                return@launch
            }
            if (token == null) {
                if (qr) expire() else fail(T.auth.authenticationTimeout)
                return@launch
            }
            if (inApp) host.closeBrowser()
            mutableState.value = PlexPinUiState(phase = PlexPinPhase.REGISTERING, ready = true)
            onToken(token)
        }
    }

    /** Shows a short PIN's code and its plex.tv/link QR code, then waits for the PIN's token. */
    private suspend fun showCode(svc: PlexAuthService): String? {
        val pin = svc.createPin(strong = false)
        mutableState.value = mutableState.value.copy(phase = PlexPinPhase.QR, qrUrl = svc.linkUrl(pin.code), code = pin.code)
        return svc.pollPinUntilClaimed(pin.id)
    }

    /** The QR phase without its code, which can no longer be claimed, and the expiry under it. */
    private fun expire() {
        mutableState.value = PlexPinUiState(phase = PlexPinPhase.QR, expired = true, error = T.auth.codeExpired, ready = true)
    }

    private companion object {
        const val TAG = "PlexPinFlow"
    }
}

/** The text a failed PIN sign-in shows. */
internal fun pinErrorMessage(e: Exception): String = when (e) {
    is MediaServerPinExpiredException -> T.addServer.pinExpired
    is MediaServerAuthException -> e.display ?: T.addServer.signInFailed(localizedErrorReason(e))
    is MediaServerHttpException -> e.display ?: T.addServer.couldNotReachServer(localizedErrorReason(e))
    else -> T.addServer.signInFailed(localizedErrorReason(e))
}

/**
 * The first sign-in ([Route.SignIn]): Plex by PIN ([plex]; on TV the QR code first), or a Jellyfin or Emby server
 * ([connect]). After a Plex token: the account is stored with its Home users, a lone Home user without a PIN made
 * active, then the picker or the app. [notice] says the device's accounts were lost, until a sign-in starts.
 */
class SignInStore(
    private val profiles: ProfileServices,
    private val host: AccountsHost,
    recoveryRequired: Boolean,
    parentScope: CoroutineScope,
) {
    private val scope = parentScope.childScope()
    private val mutableNotice = MutableStateFlow(if (recoveryRequired) T.auth.localDataRecoveryRequired else null)

    /** The recovery notice, shown under the buttons until a sign-in starts. */
    val notice: StateFlow<String?> = mutableNotice.asStateFlow()

    /** On TV the QR code is the first button and the browser hand-off the second (none on Apple TV). */
    val tv: Boolean get() = host.tv

    val plex = PlexPinFlow(profiles.plexAuth, host, ::signIn, scope) { mutableNotice.value = null }

    /** The server form opened last: Back from it finds focus on its button. Null before one opened. */
    var opened: MediaBrowserDialect? = null
        private set

    /** Opens the Jellyfin or Emby server form. */
    fun connect(dialect: MediaBrowserDialect) {
        mutableNotice.value = null
        opened = dialect
        host.open(Route.AddMediaBrowser(dialect, profileId = null))
    }

    fun close() = scope.cancel()

    private suspend fun signIn(token: String) {
        val result = try {
            profiles.signInWithPlex(token)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e(TAG, e) { "Storing the Plex account failed" }
            plex.fail(T.serverSelection.failedToLoadServers(localizedErrorReason(e)))
            return
        }
        when (result) {
            is PlexSignInResult.NoServers -> plex.fail(T.serverSelection.noServersFoundForAccount(result.username, result.email))
            PlexSignInResult.HomeUsersUnavailable -> plex.fail(T.profiles.failedToLoadHomeUsers)
            is PlexSignInResult.SignedIn -> host.connectionAdded(Route.SignIn, result.pickProfile)
        }
    }

    private companion object {
        const val TAG = "SignIn"
    }
}

/**
 * Adds a Plex account from inside the app ([Route.AddPlexAccount]). For a profile ([Route.AddPlexAccount.profileId])
 * the borrow screen follows, to pick which Home user the profile uses; otherwise the active profile is bound again when
 * it uses this account.
 */
class AddPlexAccountStore(
    private val route: Route.AddPlexAccount,
    private val profiles: ProfileServices,
    private val host: AccountsHost,
    parentScope: CoroutineScope,
) {
    private val scope = parentScope.childScope()

    val plex = PlexPinFlow(profiles.plexAuth, host, ::register, scope)

    fun close() = scope.cancel()

    private suspend fun register(token: String) {
        val registration = try {
            profiles.registerPlexAccountFromToken(token)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e(TAG, e) { "Registering the Plex account failed" }
            plex.fail(T.addServer.failedToRegisterAccount(localizedErrorReason(e)))
            return
        }
        val profileId = route.profileId
        if (profileId != null) {
            // From inside the attempt: back to the buttons without cancelling the attempt this runs in.
            plex.reset()
            if (host.borrowInto(profileId)) {
                host.connectionAdded(route, pickProfile = false)
                return
            }
            // The user left without picking whose connection the profile gets: an account this attempt added goes again.
            if (!registration.existedBefore) {
                try {
                    profiles.teardown.removePlexAccountConnection(registration.connection.stored())
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    Log.e(TAG, e) { "Removing the Plex account a declined attach added failed" }
                }
            }
            host.back()
            return
        }
        profiles.rebindActiveIfUses(registration.connection.id)
        host.connectionAdded(route, pickProfile = false)
    }

    private companion object {
        const val TAG = "AddPlexAccount"
    }
}
