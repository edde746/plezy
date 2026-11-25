package com.edde746.plezy.ui.onboarding

import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.ui.settings.SettingsSplit

/**
 * The sign-in, profile and connection screens of [app], by [route]: each gets its store from [AppSession] (kept while
 * the route is on a stack), and draws nothing for a route that is on no stack. Back on a pushed one pops it. Opened from
 * Settings, they show beside its list on wide windows ([SettingsSplit]).
 */
@Composable
fun OnboardingRoute(app: AppSession, route: Route) = SettingsSplit(app, route) {
    val navigator = app.navigator
    val back: () -> Unit = { navigator.back() }
    when (route) {
        Route.SignIn -> remember(route) { app.signIn(route) }?.let { SignInScreen(it) }
        is Route.ProfilePicker -> remember(route) { app.profilePicker(route) }?.let { ProfilePickerScreen(it) }
        Route.AddProfile -> remember(route) { app.addProfile(route) }?.let { AddProfileScreen(it, onBack = back) }
        is Route.ProfileDetail -> remember(route) { app.profileDetail(route) }?.let {
            ProfileDetailScreen(it, onBack = back, onGone = { navigator.pop(route) })
        }
        is Route.AddConnection -> remember(route) { app.addConnection(route) }?.let { (title, options) ->
            AddConnectionScreen(title, options, onOpen = navigator::navigate, onBack = back)
        }
        is Route.AddPlexAccount -> remember(route) { app.addPlexAccount(route) }?.let { AddPlexAccountScreen(it, onBack = back) }
        is Route.AddMediaBrowser -> remember(route) { app.addMediaBrowser(route) }?.let { AddMediaBrowserScreen(it, onBack = back) }
        is Route.EditConnection -> remember(route) { app.editConnection(route) }?.let { EditConnectionScreen(it, onBack = back) }
        is Route.BorrowConnection -> remember(route) { app.borrowConnection(route) }?.let { BorrowConnectionScreen(it, onBack = back) }
        else -> Unit
    }
}
