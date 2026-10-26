package com.bbflight.background_downloader

import android.content.Context
import androidx.work.WorkerParameters

class DownloadTaskWorker(context: Context, params: WorkerParameters) :
    TaskWorker(context, params) {

    override fun createRunner(): TaskRunner {
        return DownloadTaskRunner(this)
    }
}
