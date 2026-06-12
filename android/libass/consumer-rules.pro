# Constructed from JNI via FindClass/NewObject (AssKt.c).
-keep class com.edde746.plezy.libass.AssAtlasFrame { *; }
# JNI exports bind by name (Java_com_edde746_plezy_libass_*); keep the names stable.
-keepclasseswithmembernames class com.edde746.plezy.libass.* {
    native <methods>;
}
