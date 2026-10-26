package com.bbflight.background_downloader

import android.content.Context
import androidx.work.WorkerParameters

class DataTaskWorker(context: Context, params: WorkerParameters) :
    TaskWorker(context, params) {

    override fun createRunner(): TaskRunner {
        return DataTaskRunner(this)
    }
}
