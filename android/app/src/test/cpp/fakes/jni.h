#pragma once

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

class JNIEnv {
 public:
  bool exception_pending = false;
  bool fail_next_write = false;

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
