# ProGuard's rules for the release image (createReleaseDistributable), beside Compose's (Kotlin, Skiko, coroutines,
# kotlinx.serialization). ProGuard only shrinks (desktop/app/build.gradle.kts): names stay, and so do line numbers, so
# crash reports read as written.
-keepattributes SourceFile,LineNumberTable,Signature,InnerClasses,EnclosingMethod,*Annotation*

# Plezy's own code, whole: it reaches much by name (FFM upcalls through MethodHandles, D-Bus interfaces, AWT and
# Skiko internals by reflection), and the harness launcher, which runs on these jars, calls into all of it.
-keep class com.edde746.plezy.** { *; }

# Fields that atomicfu's and the JDK's field updaters find by name.
-keepclassmembers class * {
    volatile <fields>;
}
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ServiceLoader's implementations (META-INF/services), which ProGuard doesn't keep by itself.
-keep class * implements io.ktor.client.HttpClientEngineContainer
-keep class * implements coil3.util.FetcherServiceLoaderTarget { *; }
-keep class * implements coil3.util.DecoderServiceLoaderTarget { *; }
-keep class * implements dev.whyoleg.cryptography.CryptographyProviderContainer { *; }

# The SQLite JDBC driver (java.sql.Driver's service), whose native library calls into its Java classes by name.
-keep class org.sqlite.** { *; }
# Sentry's Java SDK, which finds its integrations and serializers by name.
-keep class io.sentry.** { *; }
# dbus-java (Linux only: MPRIS, the portals, the Secret Service): its transports by service loader, its proxies and
# exported objects by reflection. Absent from the Windows image.
-keep class org.freedesktop.dbus.** { *; }
-dontwarn org.freedesktop.dbus.**
# JetBrains Runtime's API, bound to the runtime by name.
-keep class com.jetbrains.** { *; }

# MethodHandle.invokeExact's signature-polymorphic calls (FFM downcalls), which no library class declares.
-dontwarn java.lang.invoke.MethodHandle
# Optional providers OkHttp and cryptography-kotlin look for at run time; the app ships none of them.
-dontwarn org.bouncycastle.**
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**
# OkHttp's GraalVM native-image feature.
-dontwarn com.oracle.svm.**
-dontwarn org.graalvm.**
