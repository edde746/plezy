package com.edde746.plezy

import android.app.Application
import android.content.Context
import androidx.multidex.MultiDex

class GkuiApplication : Application() {
    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)
        MultiDex.install(this)
    }
}
