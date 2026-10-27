// SPDX-License-Identifier: GPL-3.0-or-later
// App-owned POSIX backend: the transport does not need an SDL UI/event loop.
#include <pthread.h>
#include <stdlib.h>

#include "ihs_thread.h"

struct IHS_Thread {
  pthread_t handle;
  IHS_ThreadFunction* function;
  void* context;
};
struct IHS_Mutex {
  pthread_mutex_t handle;
};
struct IHS_Cond {
  pthread_cond_t handle;
};

static void* thread_entry(void* argument) {
  IHS_Thread* thread = argument;
  thread->function(thread->context);
  return NULL;
}

IHS_Thread* IHS_ThreadCreate(IHS_ThreadFunction* function, const char* name, void* context) {
  (void)name;
  IHS_Thread* thread = calloc(1, sizeof(*thread));
  if (thread == NULL) return NULL;
  thread->function = function;
  thread->context = context;
  if (pthread_create(&thread->handle, NULL, thread_entry, thread) != 0) {
    free(thread);
    return NULL;
  }
  return thread;
}

void IHS_ThreadJoin(IHS_Thread* thread) {
  if (thread == NULL) return;
  pthread_join(thread->handle, NULL);
  free(thread);
}

IHS_Mutex* IHS_MutexCreate(void) {
  IHS_Mutex* mutex = calloc(1, sizeof(*mutex));
  if (mutex == NULL) return NULL;
  // ihslib's timer callbacks can reenter the owning client/session lock.
  pthread_mutexattr_t attributes;
  pthread_mutexattr_init(&attributes);
  pthread_mutexattr_settype(&attributes, PTHREAD_MUTEX_RECURSIVE);
  int result = pthread_mutex_init(&mutex->handle, &attributes);
  pthread_mutexattr_destroy(&attributes);
  if (result != 0) {
    free(mutex);
    return NULL;
  }
  return mutex;
}

void IHS_MutexDestroy(IHS_Mutex* mutex) {
  if (mutex != NULL) {
    pthread_mutex_destroy(&mutex->handle);
    free(mutex);
  }
}
bool IHS_MutexLock(IHS_Mutex* mutex) { return pthread_mutex_lock(&mutex->handle) == 0; }
bool IHS_MutexUnlock(IHS_Mutex* mutex) { return pthread_mutex_unlock(&mutex->handle) == 0; }

IHS_Cond* IHS_CondCreate(void) {
  IHS_Cond* cond = calloc(1, sizeof(*cond));
  if (cond == NULL) return NULL;
  if (pthread_cond_init(&cond->handle, NULL) != 0) {
    free(cond);
    return NULL;
  }
  return cond;
}
void IHS_CondDestroy(IHS_Cond* cond) {
  if (cond != NULL) {
    pthread_cond_destroy(&cond->handle);
    free(cond);
  }
}
void IHS_CondSignal(IHS_Cond* cond) { pthread_cond_broadcast(&cond->handle); }
bool IHS_CondWait(IHS_Cond* cond, IHS_Mutex* mutex) { return pthread_cond_wait(&cond->handle, &mutex->handle) == 0; }
