package com.edde746.plezy.app

import com.edde746.plezy.strings.T
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlin.concurrent.Volatile
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds

/** A step of the product's start, in the order the steps run. */
enum class StartupStep {
    /** The database opens (and is created on a fresh install). */
    DATABASE,

    /** The database moves to this version's schema (the first start after an update). */
    MIGRATION,
}

/**
 * What the splash shows under its loader.
 *
 * @param step the step the start is on; null once it is done.
 * @param status the line naming [step], once the start has taken longer than [Startup.STATUS_DELAY]; null before
 *   then and once the start is done.
 */
data class StartupUiState(val step: StartupStep?, val status: String?)

/**
 * The product's start, from the moment the platform begins it (before it builds the shared core) to the first screen
 * after the splash, and the splash's status line ([state]); every UI draws [StartupUiState.status] under its loader.
 *
 * The steps run in [StartupStep]'s order: [AppBootstrap.product] opens the database, reporting a migration;
 * [RootSession] [finish]es the start once the database is open. A start that is done within [STATUS_DELAY] shows the
 * loader alone. Steps may be reported from any thread.
 *
 * @param scope where the [STATUS_DELAY] timer runs.
 * @param slowStart a debug launch's slow start (`--dev-slow-start`, `DevLaunch`):
 *   the start takes this much longer, so a harness can see and shoot the status line. Zero in the product.
 */
class Startup internal constructor(scope: CoroutineScope, internal val slowStart: Duration) {
    /** A start that takes [slowStartMillis] longer (a debug launch's slow start; 0 in the product). */
    constructor(slowStartMillis: Long = 0) : this(CoroutineScope(Dispatchers.Default), slowStartMillis.milliseconds)

    /** The start has taken longer than [STATUS_DELAY]. Set before the state's update that reads it. */
    @Volatile private var late = false

    private val mutableState = MutableStateFlow(StartupUiState(StartupStep.DATABASE, status = null))
    val state: StateFlow<StartupUiState> = mutableState.asStateFlow()

    private val timer = scope.launch {
        delay(STATUS_DELAY)
        late = true
        mutableState.update { state(it.step) }
    }

    /** The start moved on to [step]. */
    fun begin(step: StartupStep) {
        mutableState.update { if (it.step == null) it else state(step) }
    }

    /** The start is done: the splash goes. Later steps change nothing. */
    fun finish() {
        timer.cancel()
        mutableState.value = StartupUiState(null, null)
    }

    // Reads [late] on every attempt: an update that lost a race with the timer's runs again and sees it.
    private fun state(step: StartupStep?) = StartupUiState(step, step?.takeIf { late }?.let(::status))

    companion object {
        /** How long the start runs before the splash names its step. */
        val STATUS_DELAY: Duration = 500.milliseconds

        private fun status(step: StartupStep): String = when (step) {
            StartupStep.DATABASE -> T.app.startup.database
            StartupStep.MIGRATION -> T.app.startup.migration
        }
    }
}
