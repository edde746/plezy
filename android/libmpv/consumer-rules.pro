# JNI exports bind by name (Java_com_edde746_plezy_libmpv_MpvPlayer_native*); keep the names stable.
-keepclasseswithmembernames class com.edde746.plezy.libmpv.* {
    native <methods>;
}

# jni_utils.cpp caches MpvPlayer with FindClass and resolves these static callbacks
# with GetStaticMethodID on the native event thread. R8 sees no reference to the
# class name or the member names, so both must stay alive and un-renamed.
# Match callback names, return type and static access without duplicating JNI
# argument descriptors here: adding the session token made the old signatures
# silently stop matching. Native initialization resolves every exact descriptor.
-keep class com.edde746.plezy.libmpv.MpvPlayer {
    public static void onPropertyChanged(...);
    public static void onEvent(...);
    public static void onEndFile(...);
    public static void onLogMessage(...);
    public static void onHook(...);
}
