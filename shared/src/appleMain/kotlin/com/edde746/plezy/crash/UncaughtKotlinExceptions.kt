package com.edde746.plezy.crash

import kotlin.experimental.ExperimentalNativeApi
import kotlin.native.getStackTraceAddresses
import kotlin.native.setUnhandledExceptionHook
import kotlin.native.terminateWithUnhandledException

/**
 * A Kotlin exception as a native crash report records it: the exception's qualified class name, its message followed
 * by a `Caused by: <class>: <message>` line for each cause, and the return addresses of the stack it was created on
 * without the frames of its own constructors, so the report's top frame is the throw site.
 */
class KotlinExceptionReport internal constructor(
    val name: String,
    val reason: String?,
    val returnAddresses: List<Long>,
) {
    companion object {
        /** [throwable] as a report records it: one the app survived ([CrashReports.failures]). */
        fun of(throwable: Throwable): KotlinExceptionReport = throwable.report()
    }
}

object UncaughtKotlinExceptions {
    /**
     * Hands each Kotlin exception nothing caught (one thrown into Swift by a function without `@Throws`, or one that
     * ends a coroutine outside the app's failure boundary, or inside it in a development build: [FailureBoundary]) to
     * [record] on the crashing thread, then terminates the process as Kotlin/Native would have without the hook. A
     * later call replaces [record].
     */
    @OptIn(ExperimentalNativeApi::class)
    fun record(record: (KotlinExceptionReport) -> Unit) {
        setUnhandledExceptionHook { throwable ->
            record(throwable.report())
            terminateWithUnhandledException(throwable)
        }
    }
}

internal fun Throwable.report(): KotlinExceptionReport {
    val causes = buildList {
        val seen = mutableSetOf<Throwable>()
        var next = cause
        while (next != null && seen.add(next)) {
            add(next)
            next = next.cause
        }
    }
    val reason = buildString {
        message?.let(::append)
        for (cause in causes) {
            if (isNotEmpty()) append('\n')
            append("Caused by: ").append(cause.className)
            cause.message?.let { append(": ").append(it) }
        }
    }
    return KotlinExceptionReport(className, reason.ifEmpty { null }, throwSiteAddresses())
}

private val Throwable.className: String get() = this::class.qualifiedName ?: "kotlin.Throwable"

/**
 * The stack's return addresses from the throw site down. The stack starts in the constructors of the exception and of
 * its superclasses; `getStackTrace` names each frame (`kfun:<class>#<init>…`), so the frames up to the last of this
 * class's own constructors are dropped. Where the names are gone (a stripped binary), every frame stays.
 */
@OptIn(ExperimentalNativeApi::class)
private fun Throwable.throwSiteAddresses(): List<Long> {
    val addresses = getStackTraceAddresses()
    val init = "kfun:$className#<init>"
    val frames = getStackTrace()
    var lastInit = -1
    for (index in frames.indices) {
        if (init in frames[index]) lastInit = index else if (lastInit >= 0) break
    }
    return addresses.drop(lastInit + 1)
}
