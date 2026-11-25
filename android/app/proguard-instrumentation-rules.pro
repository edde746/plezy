# The harness build while the device tests instrument it (-Pplezy.testBuildType=harness); no shipped build has these.
# The test APK leaves out the classes the app has and calls the app's: what it calls stays as it is written.
# The instrumentation runner's tracing.
-keep class androidx.tracing.** { *; }
# The Kotlin runtime the tests and androidx.test call.
-keep class kotlin.jvm.internal.** { *; }
-keep class kotlin.jvm.functions.** { *; }
-keep class kotlin.io.CloseableKt { *; }
-keep class kotlin.text.Charsets { *; }
-keep class kotlin.LazyKt** { *; }
# The app's API the tests call (src/androidTest), not what native code reaches: that is what they check.
-keep class com.edde746.plezy.mpv.MpvPlayerEngine { public <init>(...); public long load(...); public void release(); }
-keep class com.edde746.plezy.data.settings.DeviceSettings { public static ** Companion; }
-keep class com.edde746.plezy.data.settings.DeviceSettings$Companion { public ** getDEFAULT(); }
-keep class com.edde746.plezy.playback.LoadRequest { <init>(...); }
-keep class com.edde746.plezy.playback.PlaybackOptions { public static ** Companion; }
-keep class com.edde746.plezy.playback.PlaybackOptions$Companion { public ** of(...); }
-keep class com.edde746.plezy.playback.HardwareDecoder { public static ** ANDROID; }
