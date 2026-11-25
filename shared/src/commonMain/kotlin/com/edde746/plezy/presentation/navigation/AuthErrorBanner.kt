package com.edde746.plezy.presentation.navigation

import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.MultiServerState
import com.edde746.plezy.strings.T

/**
 * The banner over the app's screens for servers that answered and refused the account, unlike an offline server: a
 * reachable server's empty hubs need the reason. [sessionExpired] (a rejected token, HTTP 401: "Session expired for
 * …") comes with Sign in again ([signInAgain]), which opens the expired server's sign-in; not while that sign-in is
 * already open for every expired server. [accessDenied] (a refused account, HTTP 403: "… refused access for this
 * account") has no action: signing in again gets the same refusal. Each names its one server, or counts several.
 */
data class AuthErrorBannerUi(val sessionExpired: String?, val accessDenied: String?, val signInAgain: Boolean = sessionExpired != null)

/** The banner for [state]'s refused servers, [reauthOpen] those whose Sign in again is open; null when none refuses. */
fun authErrorBanner(state: MultiServerState, reauthOpen: Set<ServerId> = emptySet()): AuthErrorBannerUi? {
    val expired = state.authErrorServers
    val denied = state.accessDeniedServers
    if (expired.isEmpty() && denied.isEmpty()) return null
    return AuthErrorBannerUi(
        sessionExpired = when (expired.size) {
            0 -> null
            1 -> T.connections.sessionExpiredOne(expired.single().displayName)
            else -> T.connections.sessionExpiredMany(expired.size.toString())
        },
        accessDenied = when (denied.size) {
            0 -> null
            1 -> T.connections.accessDeniedOne(denied.single().displayName)
            else -> T.connections.accessDeniedMany(denied.size.toString())
        },
        signInAgain = expired.any { it.serverId !in reauthOpen },
    )
}
