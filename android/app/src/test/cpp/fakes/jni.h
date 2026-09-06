#pragma once

#include <cstdarg>
#include <cstdint>
#include <cstring>
#include <string>
#include <vector>

#define JNIEXPORT
#define JNICALL
#define JNI_TRUE 1
#define JNI_FALSE 0

using jboolean = uint8_t;
using jbyte = int8_t;
using jint = int32_t;
using jsize = jint;
using jlong = int64_t;
using jdouble = double;
using jobject = void*;
using jmethodID = void*;

struct _jclass {};
using jclass = _jclass*;

struct _jbyteArray {
  std::vector<jbyte> bytes;
};
using jbyteArray = _jbyteArray*;

struct _jstring {
  std::string value;
};
using jstring = _jstring*;

struct _jobjectArray {
  std::vector<jobject> objects;
};
using jobjectArray = _jobjectArray*;

class JavaVM {
 public:
  void (*on_detach)() = nullptr;

  jint DetachCurrentThread() {
    if (on_detach) on_detach();
    return 0;
  }
};

class JNIEnv {
 public:
  bool exception_pending = false;
  bool fail_next_write = false;

  JavaVM* vm = nullptr;
  jobject (*on_new_global_ref)(jobject) = nullptr;
  void (*on_delete_global_ref)(jobject) = nullptr;
  void (*on_static_void_method)(jmethodID, va_list) = nullptr;

  jint GetJavaVM(JavaVM** result) {
    *result = vm;
    return 0;
  }

  jobject NewGlobalRef(jobject object) { return on_new_global_ref ? on_new_global_ref(object) : object; }

  void DeleteGlobalRef(jobject object) {
    if (on_delete_global_ref) on_delete_global_ref(object);
  }

  void DeleteLocalRef(jobject) {}

  void CallStaticVoidMethod(jclass, jmethodID method, ...) {
    va_list args;
    va_start(args, method);
    if (on_static_void_method) on_static_void_method(method, args);
    va_end(args);
  }

  jsize GetArrayLength(jobjectArray array) { return static_cast<jsize>(array->objects.size()); }
  jobject GetObjectArrayElement(jobjectArray array, jsize index) { return array->objects.at(index); }
  jsize GetArrayLength(jbyteArray array) { return static_cast<jsize>(array->bytes.size()); }

  void GetByteArrayRegion(jbyteArray array, jsize offset, jsize length, jbyte* destination) {
    if (offset < 0 || length < 0 || offset > GetArrayLength(array) || length > GetArrayLength(array) - offset) {
      exception_pending = true;
      return;
    }
    std::memcpy(destination, array->bytes.data() + offset, static_cast<size_t>(length));
  }

  void SetByteArrayRegion(jbyteArray array, jsize offset, jsize length, const jbyte* source) {
    if (fail_next_write) {
      fail_next_write = false;
      exception_pending = true;
      return;
    }
    if (offset < 0 || length < 0 || offset > GetArrayLength(array) || length > GetArrayLength(array) - offset) {
      exception_pending = true;
      return;
    }
    std::memcpy(array->bytes.data() + offset, source, static_cast<size_t>(length));
  }

  jboolean ExceptionCheck() const { return exception_pending ? JNI_TRUE : JNI_FALSE; }

  jstring NewStringUTF(const char* value) { return new _jstring{value}; }
};
