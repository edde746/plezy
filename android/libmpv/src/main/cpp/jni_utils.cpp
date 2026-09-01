#define UTIL_EXTERN
#include "jni_utils.h"

#include <jni.h>

#include <cstdlib>

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
  mpv_MpvPlayer_onPropertyChanged_S =
      env->GetStaticMethodID(mpv_MpvPlayer, "onPropertyChanged", "(Ljava/lang/String;)V");
  mpv_MpvPlayer_onPropertyChanged_Sb =
      env->GetStaticMethodID(mpv_MpvPlayer, "onPropertyChanged", "(Ljava/lang/String;Z)V");
  mpv_MpvPlayer_onPropertyChanged_Sl =
      env->GetStaticMethodID(mpv_MpvPlayer, "onPropertyChanged", "(Ljava/lang/String;J)V");
  mpv_MpvPlayer_onPropertyChanged_Sd =
      env->GetStaticMethodID(mpv_MpvPlayer, "onPropertyChanged", "(Ljava/lang/String;D)V");
  mpv_MpvPlayer_onPropertyChanged_SS =
      env->GetStaticMethodID(mpv_MpvPlayer, "onPropertyChanged", "(Ljava/lang/String;Ljava/lang/String;)V");
  mpv_MpvPlayer_onEvent = env->GetStaticMethodID(mpv_MpvPlayer, "onEvent", "(I)V");
  mpv_MpvPlayer_onEndFile = env->GetStaticMethodID(mpv_MpvPlayer, "onEndFile", "(I)V");
  mpv_MpvPlayer_onLogMessage =
      env->GetStaticMethodID(mpv_MpvPlayer, "onLogMessage", "(Ljava/lang/String;ILjava/lang/String;)V");

  methods_initialized = true;
}
