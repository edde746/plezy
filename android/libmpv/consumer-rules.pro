# JNI exports bind by name (Java_com_edde746_plezy_libmpv_MpvPlayer_native*); keep the names stable.
-keepclasseswithmembernames class com.edde746.plezy.libmpv.* {
    native <methods>;
}

# jni_utils.cpp caches MpvPlayer with FindClass and resolves these static callbacks
# with GetStaticMethodID on the native event thread. R8 sees no reference to the
# class name or the member names, so both must stay alive and un-renamed.
-keep class com.edde746.plezy.libmpv.MpvPlayer {
    public static void onPropertyChanged(java.lang.String, long, boolean);
    public static void onPropertyChanged(java.lang.String, boolean, long, boolean);
    public static void onPropertyChanged(java.lang.String, long, long, boolean);
    public static void onPropertyChanged(java.lang.String, double, long, boolean);
    public static void onPropertyChanged(java.lang.String, java.lang.String, long, boolean);
    public static void onEvent(int, long, boolean, double, boolean);
    public static void onEndFile(int, long, boolean);
    public static void onLogMessage(java.lang.String, int, java.lang.String);
}
