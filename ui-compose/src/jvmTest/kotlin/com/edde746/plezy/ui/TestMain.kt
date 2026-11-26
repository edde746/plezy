package com.edde746.plezy.ui

import coil3.SingletonImageLoader
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.asCoroutineDispatcher
import kotlinx.coroutines.test.setMain
import java.util.concurrent.Executors

/**
 * The tests' main thread, as the product has one: a single thread for the whole test run, installed as
 * [Dispatchers.Main] by each test that runs an app graph, and never reset.
 *
 * A graph's scope runs on Main, and closing a graph cancels its coroutines without waiting for them: one that was off
 * Main at the time (a database read, a request) resumes on Main once that work returns, after its test has ended. The
 * test JVM has no platform Main, so with Main reset that resumption fails, and the failure is reported in whichever
 * test runs then. With Main never reset, it ends on this thread like any other cancelled coroutine.
 */
@OptIn(ExperimentalCoroutinesApi::class)
object TestMain {
    /** The one main thread; a daemon, so it never holds the test JVM open. */
    val dispatcher: CoroutineDispatcher =
        Executors.newSingleThreadExecutor { task -> Thread(task, "test-main").apply { isDaemon = true } }.asCoroutineDispatcher()

    /**
     * Makes [dispatcher] Main for the calling test and every test after it, and drops Coil's singleton loader: a closed
     * graph's coroutine resuming after its test (above) can load an image and so make that loader, which the next app
     * frame's image setup ([com.edde746.plezy.ui.image.ProvideImageLoader]) may no longer replace.
     */
    fun install() {
        Dispatchers.setMain(dispatcher)
        SingletonImageLoader.reset()
    }
}
