package com.edde746.plezy.crash

import com.edde746.plezy.log.Log
import kotlinx.coroutines.CoroutineExceptionHandler
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlin.coroutines.AbstractCoroutineContextElement
import kotlin.coroutines.CoroutineContext

private const val TAG = "coroutines"

/**
 * The app process's coroutine failure boundary: the exception handler of its main scope
 * ([com.edde746.plezy.app.AppBootstrap]), which every store's and manager's scope inherits, since each is built from
 * that scope's context. Each of those scopes is a supervisor, so a coroutine that throws ends alone: the other screens,
 * playback and sync go on, and the database transaction it was in rolls back.
 *
 * The boundary logs the exception at ERROR. In the product it then hands it to [failures], which the platform's crash
 * reporter sends while this device's crash reports are on ([CrashReports.failures]), and the app runs on: the screen
 * whose coroutine ended keeps what it showed until it is opened again, which costs the user less than losing playback
 * and every other screen with the process. In a development build or session ([crash]) it rethrows the exception
 * instead, which kotlinx.coroutines hands to the platform's handler for uncaught exceptions: the process ends where the
 * fault happened, with a crash report while reports are on.
 */
internal class FailureBoundary(private val crash: Boolean) :
    AbstractCoroutineContextElement(CoroutineExceptionHandler),
    CoroutineExceptionHandler {
    private val reported = MutableSharedFlow<Throwable>(extraBufferCapacity = 16, onBufferOverflow = BufferOverflow.DROP_OLDEST)

    /** Each exception the product survived, as it happens: one that comes while nothing collects is not kept. */
    val failures: SharedFlow<Throwable> = reported.asSharedFlow()

    override fun handleException(context: CoroutineContext, exception: Throwable) {
        Log.e(TAG, exception) { "a coroutine failed (${exception::class.simpleName})" }
        if (crash) throw exception
        reported.tryEmit(exception)
    }
}
