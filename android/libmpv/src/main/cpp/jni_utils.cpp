#define UTIL_EXTERN
#include "jni_utils.h"

#include <jni.h>

#include <cstdlib>

#include "utf8_convert.h"

jstring new_java_string(JNIEnv* env, const char* utf8) {
  if (!utf8) return NULL;
  const std::u16string u16 = plezy::utf8::ToUtf16(utf8);
  return env->NewString(reinterpret_cast<const jchar*>(u16.data()), static_cast<jsize>(u16.size()));
}

std::string java_string_to_utf8(JNIEnv* env, jstring jstr) {
  if (!jstr) return std::string();
  const jsize len = env->GetStringLength(jstr);
  const jchar* chars = env->GetStringChars(jstr, NULL);
  if (!chars) return std::string();
  std::string out = plezy::utf8::FromUtf16(reinterpret_cast<const char16_t*>(chars), static_cast<size_t>(len));
  env->ReleaseStringChars(jstr, chars);
  return out;
}

bool acquire_jni_env(JavaVM* vm, JNIEnv** env) {
  int ret = vm->GetEnv((void**)env, JNI_VERSION_1_6);
  if (ret == JNI_EDETACHED)
    return vm->AttachCurrentThread(env, NULL) == 0;
  else
    return ret == JNI_OK;
}

void init_methods_cache(JNIEnv* env) {
  static bool methods_initialized = false;
  if (methods_initialized) return;

  // Plain assignments straight from env->FindClass, promoted to global refs
  // on the following line, keep every Get*MethodID owner traceable for
  // scripts/checks/check_shrinker_rules.py.
  java_Integer = env->FindClass("java/lang/Integer");
  java_Integer = reinterpret_cast<jclass>(env->NewGlobalRef(java_Integer));
  java_Integer_init = env->GetMethodID(java_Integer, "<init>", "(I)V");
  java_Double = env->FindClass("java/lang/Double");
  java_Double = reinterpret_cast<jclass>(env->NewGlobalRef(java_Double));
  java_Double_init = env->GetMethodID(java_Double, "<init>", "(D)V");
  java_Boolean = env->FindClass("java/lang/Boolean");
  java_Boolean = reinterpret_cast<jclass>(env->NewGlobalRef(java_Boolean));
  java_Boolean_init = env->GetMethodID(java_Boolean, "<init>", "(Z)V");

  mpv_MpvPlayer = env->FindClass("com/edde746/plezy/libmpv/MpvPlayer");
  mpv_MpvPlayer = reinterpret_cast<jclass>(env->NewGlobalRef(mpv_MpvPlayer));
  mpv_MpvPlayer_onPropertyChanged_SJZ =
      env->GetStaticMethodID(mpv_MpvPlayer, "onPropertyChanged", "(Ljava/lang/String;JZ)V");
  mpv_MpvPlayer_onPropertyChanged_SZJZ =
      env->GetStaticMethodID(mpv_MpvPlayer, "onPropertyChanged", "(Ljava/lang/String;ZJZ)V");
  mpv_MpvPlayer_onPropertyChanged_SJJZ =
      env->GetStaticMethodID(mpv_MpvPlayer, "onPropertyChanged", "(Ljava/lang/String;JJZ)V");
  mpv_MpvPlayer_onPropertyChanged_SDJZ =
      env->GetStaticMethodID(mpv_MpvPlayer, "onPropertyChanged", "(Ljava/lang/String;DJZ)V");
  mpv_MpvPlayer_onPropertyChanged_SSJZ =
      env->GetStaticMethodID(mpv_MpvPlayer, "onPropertyChanged", "(Ljava/lang/String;Ljava/lang/String;JZ)V");
  mpv_MpvPlayer_onEvent = env->GetStaticMethodID(mpv_MpvPlayer, "onEvent", "(IJZDZ)V");
  mpv_MpvPlayer_onEndFile = env->GetStaticMethodID(mpv_MpvPlayer, "onEndFile", "(IJZ)V");
  mpv_MpvPlayer_onLogMessage =
      env->GetStaticMethodID(mpv_MpvPlayer, "onLogMessage", "(Ljava/lang/String;ILjava/lang/String;)V");
  mpv_MpvPlayer_onHook = env->GetStaticMethodID(mpv_MpvPlayer, "onHook", "(Ljava/lang/String;J)V");

  methods_initialized = true;
}
