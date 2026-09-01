# JNI exports bind by name (Java_com_edde746_plezy_libmpv_MpvPlayer_native*); keep the names stable.
-keepclasseswithmembernames class com.edde746.plezy.libmpv.* {
    native <methods>;
}

# jni_utils.cpp caches MpvPlayer with FindClass and resolves these static callbacks
# with GetStaticMethodID on the native event thread. R8 sees no reference to the
# class name or the member names, so both must stay alive and un-renamed.
-keep class com.edde746.plezy.libmpv.MpvPlayer {
    public static void onPropertyChanged(...);
    public static void onEvent(int);
    public static void onEndFile(int);
    public static void onLogMessage(java.lang.String, int, java.lang.String);
}
