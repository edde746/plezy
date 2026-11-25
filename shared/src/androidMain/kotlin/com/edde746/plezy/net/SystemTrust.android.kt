package com.edde746.plezy.net

import okhttp3.OkHttpClient

// Android's own trust store (with the user's CAs as the app's network security config allows) and proxy apply already.
internal actual fun OkHttpClient.Builder.useSystemTrust() = Unit
