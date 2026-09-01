#include "log.h"

#include "globals.h"
#include "jni_utils.h"

void die(const char* msg) {
  ALOGE("%s", msg);
  JNIEnv* env = nullptr;
  if (g_vm && acquire_jni_env(g_vm, &env) && env) {
    jclass cls = env->FindClass("java/lang/RuntimeException");
    if (cls) env->ThrowNew(cls, msg);
  }
}
