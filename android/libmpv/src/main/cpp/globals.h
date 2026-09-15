#pragma once

#include <jni.h>

// The process's JavaVM, published once by the first nativeCreate (see
// prepare_environment) and read by every thread that needs a JNIEnv.
extern JavaVM* g_vm;
