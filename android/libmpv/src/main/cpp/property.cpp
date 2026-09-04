#include <jni.h>
#include <mpv/client.h>

#include <cstdlib>
#include <string>

#include "globals.h"
#include "jni_utils.h"
#include "log.h"

extern "C" {
jni_func(jint, nativeSetOptionString, jstring option, jstring value);

jni_func(jobject, nativeGetPropertyInt, jstring property);
jni_func(void, nativeSetPropertyInt, jstring property, jint value);
jni_func(jobject, nativeGetPropertyDouble, jstring property);
jni_func(void, nativeSetPropertyDouble, jstring property, jdouble value);
jni_func(jobject, nativeGetPropertyBoolean, jstring property);
jni_func(void, nativeSetPropertyBoolean, jstring property, jboolean value);
jni_func(jstring, nativeGetPropertyString, jstring jproperty);
jni_func(void, nativeSetPropertyString, jstring jproperty, jstring jvalue);

jni_func(void, nativeObserveProperty, jstring property, jint format);
}

jni_func(jint, nativeSetOptionString, jstring joption, jstring jvalue) {
  CHECK_MPV_INIT_RET(0);

  const char* option = env->GetStringUTFChars(joption, NULL);
  const std::string value = java_string_to_utf8(env, jvalue);

  int result = mpv_set_option_string(g_mpv, option, value.c_str());

  env->ReleaseStringUTFChars(joption, option);

  return result;
}

static int common_get_property(JNIEnv* env, jstring jproperty, mpv_format format, void* output) {
  CHECK_MPV_INIT_RET(-1);

  const char* prop = env->GetStringUTFChars(jproperty, NULL);
  int result = mpv_get_property(g_mpv, prop, format, output);
  if (result < 0) ALOGE("mpv_get_property(%s) format %d returned error %s", prop, format, mpv_error_string(result));
  env->ReleaseStringUTFChars(jproperty, prop);

  return result;
}

static int common_set_property(JNIEnv* env, jstring jproperty, mpv_format format, void* value) {
  CHECK_MPV_INIT_RET(-1);

  const char* prop = env->GetStringUTFChars(jproperty, NULL);
  int result = mpv_set_property(g_mpv, prop, format, value);
  if (result < 0)
    ALOGE("mpv_set_property(%s, %p) format %d returned error %s", prop, value, format, mpv_error_string(result));
  env->ReleaseStringUTFChars(jproperty, prop);

  return result;
}

jni_func(jobject, nativeGetPropertyInt, jstring jproperty) {
  int64_t value = 0;
  if (common_get_property(env, jproperty, MPV_FORMAT_INT64, &value) < 0) return NULL;
  return env->NewObject(java_Integer, java_Integer_init, (jint)value);
}

jni_func(jobject, nativeGetPropertyDouble, jstring jproperty) {
  double value = 0;
  if (common_get_property(env, jproperty, MPV_FORMAT_DOUBLE, &value) < 0) return NULL;
  return env->NewObject(java_Double, java_Double_init, (jdouble)value);
}

jni_func(jobject, nativeGetPropertyBoolean, jstring jproperty) {
  int value = 0;
  if (common_get_property(env, jproperty, MPV_FORMAT_FLAG, &value) < 0) return NULL;
  return env->NewObject(java_Boolean, java_Boolean_init, (jboolean)value);
}

jni_func(jstring, nativeGetPropertyString, jstring jproperty) {
  char* value;
  if (common_get_property(env, jproperty, MPV_FORMAT_STRING, &value) < 0) return NULL;
  jstring jvalue = new_java_string(env, value);
  mpv_free(value);
  return jvalue;
}

jni_func(void, nativeSetPropertyInt, jstring jproperty, jint jvalue) {
  int64_t value = static_cast<int64_t>(jvalue);
  common_set_property(env, jproperty, MPV_FORMAT_INT64, &value);
}

jni_func(void, nativeSetPropertyDouble, jstring jproperty, jdouble jvalue) {
  double value = static_cast<double>(jvalue);
  common_set_property(env, jproperty, MPV_FORMAT_DOUBLE, &value);
}

jni_func(void, nativeSetPropertyBoolean, jstring jproperty, jboolean jvalue) {
  int value = jvalue == JNI_TRUE ? 1 : 0;
  common_set_property(env, jproperty, MPV_FORMAT_FLAG, &value);
}

jni_func(void, nativeSetPropertyString, jstring jproperty, jstring jvalue) {
  const std::string value = java_string_to_utf8(env, jvalue);
  const char* value_ptr = value.c_str();
  common_set_property(env, jproperty, MPV_FORMAT_STRING, &value_ptr);
}

jni_func(void, nativeObserveProperty, jstring property, jint format) {
  CHECK_MPV_INIT();
  const char* prop = env->GetStringUTFChars(property, NULL);
  int result = mpv_observe_property(g_mpv, 0, prop, (mpv_format)format);
  if (result < 0) ALOGE("mpv_observe_property(%s) format %d returned error %s", prop, format, mpv_error_string(result));
  env->ReleaseStringUTFChars(property, prop);
}
