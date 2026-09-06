#include <jni.h>
#include <mpv/client.h>

#include <cstdlib>
#include <string>

#include "globals.h"
#include "jni_utils.h"
#include "log.h"

extern "C" {
jni_func(jint, nativeSetOptionString, jlong session, jstring option, jstring value);

jni_func(jobject, nativeGetPropertyInt, jlong session, jstring property);
jni_func(void, nativeSetPropertyInt, jlong session, jstring property, jint value);
jni_func(jobject, nativeGetPropertyDouble, jlong session, jstring property);
jni_func(void, nativeSetPropertyDouble, jlong session, jstring property, jdouble value);
jni_func(jobject, nativeGetPropertyBoolean, jlong session, jstring property);
jni_func(void, nativeSetPropertyBoolean, jlong session, jstring property, jboolean value);
jni_func(jstring, nativeGetPropertyString, jlong session, jstring jproperty);
jni_func(void, nativeSetPropertyString, jlong session, jstring jproperty, jstring jvalue);

jni_func(void, nativeObserveProperty, jlong session, jstring property, jint format);
}

jni_func(jint, nativeSetOptionString, jlong session, jstring joption, jstring jvalue) {
  SessionGuard guard(session);
  if (!guard.mpv) return MPV_ERROR_UNINITIALIZED;

  const char* option = env->GetStringUTFChars(joption, NULL);
  const std::string value = java_string_to_utf8(env, jvalue);

  int result = mpv_set_option_string(guard.mpv, option, value.c_str());

  env->ReleaseStringUTFChars(joption, option);

  return result;
}

// A retired session reads as "no value" and writes nowhere: the in-flight
// hook handler of a torn-down player must not learn about, or reconfigure,
// its successor.
static int common_get_property(JNIEnv* env, jlong session, jstring jproperty, mpv_format format, void* output) {
  SessionGuard guard(session);
  if (!guard.mpv) return MPV_ERROR_UNINITIALIZED;

  const char* prop = env->GetStringUTFChars(jproperty, NULL);
  int result = mpv_get_property(guard.mpv, prop, format, output);
  if (result < 0) ALOGE("mpv_get_property(%s) format %d returned error %s", prop, format, mpv_error_string(result));
  env->ReleaseStringUTFChars(jproperty, prop);

  return result;
}

static int common_set_property(JNIEnv* env, jlong session, jstring jproperty, mpv_format format, void* value) {
  SessionGuard guard(session);
  if (!guard.mpv) return MPV_ERROR_UNINITIALIZED;

  const char* prop = env->GetStringUTFChars(jproperty, NULL);
  int result = mpv_set_property(guard.mpv, prop, format, value);
  if (result < 0)
    ALOGE("mpv_set_property(%s, %p) format %d returned error %s", prop, value, format, mpv_error_string(result));
  env->ReleaseStringUTFChars(jproperty, prop);

  return result;
}

jni_func(jobject, nativeGetPropertyInt, jlong session, jstring jproperty) {
  int64_t value = 0;
  if (common_get_property(env, session, jproperty, MPV_FORMAT_INT64, &value) < 0) return NULL;
  return env->NewObject(java_Integer, java_Integer_init, (jint)value);
}

jni_func(jobject, nativeGetPropertyDouble, jlong session, jstring jproperty) {
  double value = 0;
  if (common_get_property(env, session, jproperty, MPV_FORMAT_DOUBLE, &value) < 0) return NULL;
  return env->NewObject(java_Double, java_Double_init, (jdouble)value);
}

jni_func(jobject, nativeGetPropertyBoolean, jlong session, jstring jproperty) {
  int value = 0;
  if (common_get_property(env, session, jproperty, MPV_FORMAT_FLAG, &value) < 0) return NULL;
  return env->NewObject(java_Boolean, java_Boolean_init, (jboolean)value);
}

jni_func(jstring, nativeGetPropertyString, jlong session, jstring jproperty) {
  char* value;
  if (common_get_property(env, session, jproperty, MPV_FORMAT_STRING, &value) < 0) return NULL;
  jstring jvalue = new_java_string(env, value);
  mpv_free(value);
  return jvalue;
}

jni_func(void, nativeSetPropertyInt, jlong session, jstring jproperty, jint jvalue) {
  int64_t value = static_cast<int64_t>(jvalue);
  common_set_property(env, session, jproperty, MPV_FORMAT_INT64, &value);
}

jni_func(void, nativeSetPropertyDouble, jlong session, jstring jproperty, jdouble jvalue) {
  double value = static_cast<double>(jvalue);
  common_set_property(env, session, jproperty, MPV_FORMAT_DOUBLE, &value);
}

jni_func(void, nativeSetPropertyBoolean, jlong session, jstring jproperty, jboolean jvalue) {
  int value = jvalue == JNI_TRUE ? 1 : 0;
  common_set_property(env, session, jproperty, MPV_FORMAT_FLAG, &value);
}

jni_func(void, nativeSetPropertyString, jlong session, jstring jproperty, jstring jvalue) {
  const std::string value = java_string_to_utf8(env, jvalue);
  const char* value_ptr = value.c_str();
  common_set_property(env, session, jproperty, MPV_FORMAT_STRING, &value_ptr);
}

jni_func(void, nativeObserveProperty, jlong session, jstring property, jint format) {
  SessionGuard guard(session);
  if (!guard.mpv) return;
  const char* prop = env->GetStringUTFChars(property, NULL);
  int result = mpv_observe_property(guard.mpv, 0, prop, (mpv_format)format);
  if (result < 0) ALOGE("mpv_observe_property(%s) format %d returned error %s", prop, format, mpv_error_string(result));
  env->ReleaseStringUTFChars(property, prop);
}
