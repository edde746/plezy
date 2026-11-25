package com.edde746.plezy.presentation.seerr

import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.localizedErrorReason
import com.edde746.plezy.log.Log
import com.edde746.plezy.seerr.SeerrAccounts
import com.edde746.plezy.seerr.SeerrException
import com.edde746.plezy.seerr.SeerrMediaServerType
import com.edde746.plezy.seerr.SeerrProduct
import com.edde746.plezy.seerr.SeerrPublicSettings
import com.edde746.plezy.seerr.SeerrSession
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.strings.T
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * The connect screen ([title]: "Connect Seerr"): [step], an inline [error] under it, and [busy] while a probe or
 * sign-in runs (the active button shows a spinner and the controls are disabled). [done] is set once the session is
 * kept: the screen closes.
 */
data class SeerrConnectUiState(
    val title: String,
    val step: SeerrConnectStep,
    val busy: Boolean,
    val error: String?,
    val done: Boolean,
)

sealed interface SeerrConnectStep {
    /**
     * The instance address: a URL field ([label], the example [hint], [helper]) and [continueLabel]. The field takes
     * focus on entry; its keyboard's go action and the button both call [SeerrConnectStore.probe].
     */
    data class Url(val url: String, val label: String, val hint: String, val helper: String, val continueLabel: String) : SeerrConnectStep

    /**
     * Signing in to the instance that answered: its card ([instanceLabel], [baseUrl], [changeLabel] back to the URL
     * step), then the Plex button ([plexLabel], null when Plex isn't offered), the open credential [form], the other
     * [methods], or [noMethodsMessage] (error-coloured) when the instance offers nothing the app supports.
     */
    data class SignIn(
        val instanceLabel: String,
        val baseUrl: String,
        val changeLabel: String,
        val plexLabel: String?,
        val form: SeerrCredentialForm?,
        val methods: List<SeerrSignInMethod>,
        val noMethodsMessage: String?,
    ) : SeerrConnectStep

    /** The Quick Connect code panel in place of the form, focused on [cancelLabel]; it waits without a spinner. */
    data class QuickConnect(val code: String, val cancelLabel: String) : SeerrConnectStep
}

enum class SeerrCredentialKind { JELLYFIN, EMBY, LOCAL }

/** A button opening another credential form. */
data class SeerrSignInMethod(val kind: SeerrCredentialKind, val label: String)

/**
 * A credential form. The identifier is an email (email keyboard) for a local account, else a username; the password is
 * obscured. Enter on the identifier moves to the password, Enter on the password submits. The field errors show after
 * a submission that failed validation.
 *
 * @param quickConnectLabel "Use Quick Connect", offered on the Jellyfin form only.
 */
data class SeerrCredentialForm(
    val kind: SeerrCredentialKind,
    val identifier: String,
    val password: String,
    val identifierLabel: String,
    val identifierIsEmail: Boolean,
    val passwordLabel: String,
    val identifierError: String?,
    val passwordError: String?,
    val signInLabel: String,
    val quickConnectLabel: String?,
)

/**
 * The Seerr connect flow: probe the address (schemeless input tries HTTPS first, plain HTTP only when HTTPS can't
 * connect at all), then sign in by a method the instance offers (Plex with the profile's token, Jellyfin or Emby
 * credentials, Jellyfin Quick Connect, a local account). The finished session takes the probed instance's label and
 * product and is kept as the active profile's ([SeerrAccounts.adoptSession]).
 *
 * One action runs at a time; Quick Connect's wait is cancellable. Call everything on the main thread; [release] ends it.
 */
class SeerrConnectStore internal constructor(private val accounts: SeerrAccounts, parentScope: CoroutineScope) {
    private val scope = parentScope.childScope()

    private var url = ""
    private var instance: SeerrPublicSettings? = null
    private var baseUrl = ""
    private var plexTokenAvailable = false
    private var form: SeerrCredentialKind? = null
    private var identifier = ""
    private var password = ""
    private var validated = false
    private var quickConnectCode: String? = null
    private var quickConnectJob: Job? = null

    private var busy = false
    private var error: String? = null
    private var done = false

    private val mutableState = MutableStateFlow(build())

    val state: StateFlow<SeerrConnectUiState> = mutableState.asStateFlow()

    fun setUrl(text: String) {
        url = text
        publish()
    }

    fun setIdentifier(text: String) {
        identifier = text
        publish()
    }

    fun setPassword(text: String) {
        password = text
        publish()
    }

    /** Continue: probes the typed address. With exactly one credential form on offer the method list is skipped. */
    fun probe() {
        val input = url.trim()
        if (input.isEmpty()) {
            error = T.addServer.required
            publish()
            return
        }
        perform {
            val reached = accounts.auth.probeFirstReachable(input)
            val token = accounts.resolvePlexToken()
            instance = reached.settings
            baseUrl = reached.baseUrl
            plexTokenAvailable = !token.isNullOrEmpty()
            val mediaForm = mediaServerForm
            form = when {
                !offersPlex && mediaForm != null && !reached.settings.localLogin -> mediaForm
                !offersPlex && mediaForm == null && reached.settings.localLogin -> SeerrCredentialKind.LOCAL
                else -> null
            }
            clearCredentials()
        }
    }

    /** Change: back to the URL step, forgetting the instance and the credentials. */
    fun changeServer() {
        if (busy) return
        instance = null
        form = null
        clearCredentials()
        publish()
    }

    /** Opens another credential form, emptied; the UI focuses its identifier field. */
    fun chooseForm(kind: SeerrCredentialKind) {
        if (busy) return
        form = kind
        clearCredentials()
        publish()
    }

    fun signInWithPlex() {
        if (!offersPlex) return
        perform {
            val token = accounts.resolvePlexToken()
            if (token.isNullOrEmpty()) throw SeerrException.Auth("No Plex token available", T.seerr.noPlexTokenForReauth)
            finish(accounts.auth.signInWithPlex(baseUrl, token))
        }
    }

    /** Signs in with the open form: the identifier trimmed (required), the password as typed (required). */
    fun signIn() {
        val kind = form ?: return
        if (busy) return
        validated = true
        if (identifier.trim().isEmpty() || password.isEmpty()) {
            publish()
            return
        }
        val name = identifier.trim()
        val secret = password
        perform {
            val session = when (kind) {
                SeerrCredentialKind.JELLYFIN, SeerrCredentialKind.EMBY ->
                    accounts.auth.signInWithJellyfin(baseUrl, name, secret, emby = kind == SeerrCredentialKind.EMBY)
                SeerrCredentialKind.LOCAL -> accounts.auth.signInWithLocal(baseUrl, name, secret)
            }
            finish(session)
        }
    }

    /**
     * Shows a Quick Connect code and waits for its approval inside Jellyfin. An expired code brings the form back with
     * an error; any failure brings it back with the failure.
     */
    fun startQuickConnect() {
        if (busy || form != SeerrCredentialKind.JELLYFIN) return
        busy = true
        error = null
        publish()
        quickConnectJob = scope.launch {
            try {
                val initiation = accounts.auth.initiateQuickConnect(baseUrl)
                quickConnectCode = initiation.code
                busy = false
                publish()
                val session = accounts.auth.signInWithQuickConnect(baseUrl, initiation.secret)
                if (session == null) {
                    quickConnectCode = null
                    error = T.auth.quickConnectExpired
                } else {
                    busy = true
                    finish(session)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                quickConnectCode = null
                error = describe(e)
            }
            busy = false
            publish()
        }
    }

    /** Dismisses the code panel: the wait ends without an error and the form comes back. */
    fun cancelQuickConnect() {
        val job = quickConnectJob ?: return
        if (quickConnectCode == null) return
        job.cancel()
        quickConnectJob = null
        quickConnectCode = null
        busy = false
        publish()
    }

    fun release() {
        scope.cancel()
    }

    /** Overseerr reports no `mediaServerType`: it is always Plex-backed. */
    private val offersPlex: Boolean
        get() {
            val settings = instance ?: return false
            val plexBacked = settings.mediaServerType == SeerrMediaServerType.PLEX || settings.product == SeerrProduct.OVERSEERR
            return settings.mediaServerLogin && plexBacked && plexTokenAvailable
        }

    private val mediaServerForm: SeerrCredentialKind?
        get() {
            val settings = instance ?: return null
            if (!settings.mediaServerLogin) return null
            return when (settings.mediaServerType) {
                SeerrMediaServerType.JELLYFIN -> SeerrCredentialKind.JELLYFIN
                SeerrMediaServerType.EMBY -> SeerrCredentialKind.EMBY
                else -> null
            }
        }

    private fun clearCredentials() {
        identifier = ""
        password = ""
        validated = false
    }

    /** Runs [body] busy, clearing the last error first and showing its failure after. */
    private fun perform(body: suspend () -> Unit) {
        if (busy) return
        busy = true
        error = null
        publish()
        scope.launch {
            try {
                body()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                error = describe(e)
            }
            busy = false
            publish()
        }
    }

    /** Keeps [session] with the probed instance's label and product; the screen then closes. */
    private suspend fun finish(session: SeerrSession) {
        val settings = instance
        accounts.adoptSession(
            if (settings == null) session else session.copy(instanceLabel = settings.instanceLabel, product = settings.product),
        )
        done = true
    }

    /** The failure's own localized text, else why it failed: never the exception's or Seerr's own text. */
    private fun describe(e: Exception): String {
        (e as? SeerrException)?.display?.let { return it }
        Log.w(TAG, e) { "Seerr connect failed" }
        if (e is SeerrException.Api) {
            return T.addServer.signInFailed(if (e.statusCode >= 500) T.errors.reasonServerError else T.errors.reasonRefused)
        }
        return T.addServer.couldNotReachServer(localizedErrorReason(MediaServerHttpException.from(e)))
    }

    private fun publish() {
        mutableState.value = build()
    }

    private fun build(): SeerrConnectUiState {
        val settings = instance
        val code = quickConnectCode
        val step = when {
            code != null -> SeerrConnectStep.QuickConnect(code, T.common.cancel)
            settings == null -> SeerrConnectStep.Url(url, T.seerr.serverUrl, URL_HINT, T.seerr.serverUrlHelper, T.seerr.checkServer)
            else -> signInStep(settings)
        }
        return SeerrConnectUiState(title = T.seerr.connectTitle, step = step, busy = busy, error = error, done = done)
    }

    private fun signInStep(settings: SeerrPublicSettings): SeerrConnectStep.SignIn {
        val mediaForm = mediaServerForm
        val noMethods = !offersPlex && mediaForm == null && !settings.localLogin
        val methods = buildList {
            if (noMethods) return@buildList
            if (mediaForm != null && form != mediaForm) {
                add(SeerrSignInMethod(mediaForm, if (mediaForm == SeerrCredentialKind.EMBY) T.seerr.signInWithEmby else T.seerr.signInWithJellyfin))
            }
            if (settings.localLogin && form != SeerrCredentialKind.LOCAL) add(SeerrSignInMethod(SeerrCredentialKind.LOCAL, T.seerr.signInWithLocal))
        }
        return SeerrConnectStep.SignIn(
            instanceLabel = settings.instanceLabel,
            baseUrl = baseUrl,
            changeLabel = T.addServer.change,
            plexLabel = if (offersPlex) T.auth.signInWithPlex else null,
            form = if (noMethods) null else form?.let(::credentialForm),
            methods = methods,
            noMethodsMessage = if (noMethods) T.seerr.noSignInMethods else null,
        )
    }

    private fun credentialForm(kind: SeerrCredentialKind): SeerrCredentialForm {
        val local = kind == SeerrCredentialKind.LOCAL
        return SeerrCredentialForm(
            kind = kind,
            identifier = identifier,
            password = password,
            identifierLabel = if (local) T.seerr.email else T.addServer.username,
            identifierIsEmail = local,
            passwordLabel = T.addServer.password,
            identifierError = if (validated && identifier.trim().isEmpty()) T.addServer.required else null,
            passwordError = if (validated && password.isEmpty()) T.addServer.required else null,
            signInLabel = T.addServer.signIn,
            quickConnectLabel = if (kind == SeerrCredentialKind.JELLYFIN) T.auth.useQuickConnect else null,
        )
    }

    private companion object {
        const val TAG = "seerr"

        /** An address example, the same in every language. */
        const val URL_HINT = "https://seerr.example.com"
    }
}
