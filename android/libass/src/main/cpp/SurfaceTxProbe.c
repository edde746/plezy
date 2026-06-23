// EXPERIMENTAL SPIKE — does the codec VIDEO plane's actual present time differ from a
// GL OSD overlay's, and is that difference measurable in-app? (See the memory note
// project_libass_present_time_instrumentation.)
//
// Android exposes no present time for a codec-owned video layer. The one runtime lead is
// API 34 `SurfaceView.applyTransactionToFrame()`: it merges an otherwise-empty,
// callback-bearing transaction with the codec's *next buffer* transaction. The completion
// stats then carry, per surface, the PREVIOUS-RELEASE fence — the moment the buffer the new
// frame replaced stopped being read by the display ≈ when the new codec frame actually
// reached the video plane. Compared in Kotlin to that frame's `releaseTimeNs` target (the
// overlay's own present error is ~0), the delta is the inter-plane lag.
//
// The SurfaceControl transaction-stats / fromJava APIs are API 29/34 while this module's
// minSdk is 21; clang's __builtin_available doesn't guard the Android availability domain in
// this toolchain. So the libandroid entry points are resolved by dlsym (no
// availability-attributed declarations get compiled). Every call site is additionally
// hard-gated to API >= 34 in Kotlin (VideoLayerLatencyProbe).
//
// Fence timestamps are read with the raw SYNC_IOC_FILE_INFO ioctl rather than libsync:
// libsync.so is NOT a public NDK library, so an app's linker namespace blocks dlopen of it.
//
// Compiled into the libass "asskt" .so; called from app Kotlin SurfaceTxProbe.
#include <android/log.h>
#include <dlfcn.h>
#include <jni.h>
#include <poll.h>
#include <pthread.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <time.h>
#include <unistd.h>

#define LOG_TAG "SurfaceTxProbe"
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)

#ifndef SYNC_IOC_MAGIC
#define SYNC_IOC_MAGIC '>'
#endif
struct stp_fence_info {
  char obj_name[32];
  char driver_name[32];
  int32_t status;
  uint32_t flags;
  uint64_t timestamp_ns;
};
struct stp_file_info {
  char name[32];
  int32_t status;
  uint32_t flags;
  uint32_t num_fences;
  uint32_t pad;
  uint64_t sync_fence_info;
};
#ifndef SYNC_IOC_FILE_INFO
#define SYNC_IOC_FILE_INFO _IOWR(SYNC_IOC_MAGIC, 4, struct stp_file_info)
#endif

// libsync is hidden from app linker namespaces, so use the kernel ioctl directly.
static int64_t readFenceTimeNs(int fd, int* outStatus) {
  *outStatus = -1;
  if (fd < 0) return -1;
  struct stp_file_info probe;
  memset(&probe, 0, sizeof(probe));
  if (ioctl(fd, SYNC_IOC_FILE_INFO, &probe) < 0) return -1;
  *outStatus = probe.status;
  if (probe.status != 1 || probe.num_fences == 0) return -1;
  struct stp_fence_info* arr =
      (struct stp_fence_info*)calloc(probe.num_fences, sizeof(struct stp_fence_info));
  if (!arr) return -1;
  struct stp_file_info req;
  memset(&req, 0, sizeof(req));
  req.num_fences = probe.num_fences;
  req.sync_fence_info = (uint64_t)(uintptr_t)arr;
  int64_t t = -1;
  if (ioctl(fd, SYNC_IOC_FILE_INFO, &req) == 0) {
    for (uint32_t i = 0; i < req.num_fences; i++) {
      if ((int64_t)arr[i].timestamp_ns > t) t = (int64_t)arr[i].timestamp_ns;
    }
  }
  free(arr);
  return t;
}

typedef struct ASurfaceTransaction ASurfaceTransaction;
typedef struct ASurfaceControl ASurfaceControl;
typedef struct ASurfaceTransactionStats ASurfaceTransactionStats;
typedef void (*OnCompleteFn)(void* context, ASurfaceTransactionStats* stats);

typedef ASurfaceTransaction* (*pf_fromJava)(JNIEnv*, jobject);
typedef void (*pf_setOnComplete)(ASurfaceTransaction*, void*, OnCompleteFn);
typedef int64_t (*pf_latchTime)(ASurfaceTransactionStats*);
typedef void (*pf_getControls)(ASurfaceTransactionStats*, ASurfaceControl***, size_t*);
typedef int (*pf_prevRelease)(ASurfaceTransactionStats*, ASurfaceControl*);
typedef void (*pf_releaseControls)(ASurfaceControl**);

static pf_fromJava p_fromJava = NULL;
static pf_setOnComplete p_setOnComplete = NULL;
static pf_latchTime p_latchTime = NULL;
static pf_getControls p_getControls = NULL;
static pf_prevRelease p_prevRelease = NULL;
static pf_releaseControls p_releaseControls = NULL;
static int gScResolved = 0;
static int gScOk = 0;
static int gScWarningLogged = 0;

// Runtime lookup keeps this API-34 probe buildable with the module's minSdk 21.
static int resolveSc(void) {
  if (gScResolved) return gScOk;
  gScResolved = 1;
  void* h = dlopen("libandroid.so", RTLD_NOW | RTLD_GLOBAL);
  if (!h) return 0;
  p_fromJava = (pf_fromJava)dlsym(h, "ASurfaceTransaction_fromJava");
  p_setOnComplete = (pf_setOnComplete)dlsym(h, "ASurfaceTransaction_setOnComplete");
  p_latchTime = (pf_latchTime)dlsym(h, "ASurfaceTransactionStats_getLatchTime");
  p_getControls = (pf_getControls)dlsym(h, "ASurfaceTransactionStats_getASurfaceControls");
  p_prevRelease = (pf_prevRelease)dlsym(h, "ASurfaceTransactionStats_getPreviousReleaseFenceFd");
  p_releaseControls = (pf_releaseControls)dlsym(h, "ASurfaceTransactionStats_releaseASurfaceControls");
  gScOk = (p_fromJava && p_setOnComplete && p_latchTime && p_getControls && p_prevRelease &&
           p_releaseControls)
              ? 1
              : 0;
  return gScOk;
}

// The completion context is pointer-width, so 32-bit devices need an index side-channel.
#define TAG_RING_SIZE 256
static int64_t gTagRing[TAG_RING_SIZE];
static int gSrcRing[TAG_RING_SIZE];
static int gTagSeq = 0;

static JavaVM* gVm = NULL;
static jclass gProbeClass = NULL;
static jmethodID gOnResult = NULL;
static int gCallbackLookupAttempted = 0;
static pthread_mutex_t gInitLock = PTHREAD_MUTEX_INITIALIZER;

static int64_t nowMonoNs(void) {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return (int64_t)ts.tv_sec * 1000000000LL + ts.tv_nsec;
}

static void reportResult(JNIEnv* env, int64_t tag, int64_t latchNs, int64_t releaseNs, int count,
                         int fenceState, int source, int64_t cbNs) {
  if (!env || !gProbeClass || !gOnResult) return;
  (*env)->CallStaticVoidMethod(env, gProbeClass, gOnResult, (jlong)tag, (jlong)latchNs,
                               (jlong)releaseNs, (jint)count, (jint)fenceState, (jint)source,
                               (jlong)cbNs);
  if ((*env)->ExceptionCheck(env)) (*env)->ExceptionClear(env);
}

// Previous-release fences can still be pending in the binder callback; a worker
// thread keeps SurfaceFlinger's callback dispatch unblocked.
struct fenceJob {
  int fd;
  int64_t tag;
  int64_t latch;
  int count;
  int source;
};
#define JOB_RING 64
static struct fenceJob gJobs[JOB_RING];
static int gJobHead = 0, gJobTail = 0;
static int gJobDrops = 0;
static pthread_mutex_t gJobLock = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t gJobCond = PTHREAD_COND_INITIALIZER;
static pthread_t gReader;
static int gReaderStarted = 0;

static void* readerMain(void* arg);

static int ensureProbeInit(JNIEnv* env, jclass clazz) {
  int scOk = 0;
  pthread_mutex_lock(&gInitLock);
  if (!gVm && (*env)->GetJavaVM(env, &gVm) != JNI_OK) {
    LOGW("GetJavaVM failed — transaction probe disabled");
    pthread_mutex_unlock(&gInitLock);
    return 0;
  }
  if (!gProbeClass) {
    gProbeClass = (*env)->NewGlobalRef(env, clazz);
    if (!gProbeClass) {
      LOGW("NewGlobalRef(SurfaceTxProbe) failed — transaction probe disabled");
      pthread_mutex_unlock(&gInitLock);
      return 0;
    }
  }
  if (!gCallbackLookupAttempted) {
    gCallbackLookupAttempted = 1;
    gOnResult = (*env)->GetStaticMethodID(env, clazz, "onResult", "(JJJIIIJ)V");
    if (!gOnResult) {
      (*env)->ExceptionClear(env);
      LOGW("onResult(JJJIIIJ)V not found — JNI callback disabled (R8 stripped it?)");
    }
  }
  if (!gOnResult) {
    pthread_mutex_unlock(&gInitLock);
    return 0;
  }
  scOk = resolveSc();
  if (!scOk) {
    if (!gScWarningLogged) {
      gScWarningLogged = 1;
      LOGW("libandroid SurfaceControl transaction-stats API unavailable");
    }
    pthread_mutex_unlock(&gInitLock);
    return 0;
  }
  if (!gReaderStarted) {
    const int rc = pthread_create(&gReader, NULL, readerMain, NULL);
    if (rc != 0) {
      LOGW("fence reader thread start failed: %d", rc);
      pthread_mutex_unlock(&gInitLock);
      return 0;
    }
    gReaderStarted = 1;
  }
  pthread_mutex_unlock(&gInitLock);
  return scOk;
}

static void* readerMain(void* arg) {
  (void)arg;
  JNIEnv* env = NULL;
  if ((*gVm)->AttachCurrentThread(gVm, &env, NULL) != JNI_OK) return NULL;
  for (;;) {
    pthread_mutex_lock(&gJobLock);
    while (gJobHead == gJobTail) pthread_cond_wait(&gJobCond, &gJobLock);
    struct fenceJob job = gJobs[gJobTail];
    gJobTail = (gJobTail + 1) % JOB_RING;
    pthread_mutex_unlock(&gJobLock);

    int64_t releaseNs = -1;
    int fenceState;
    struct pollfd pfd = {.fd = job.fd, .events = POLLIN, .revents = 0};
    int pr = poll(&pfd, 1, 250);
    if (pr > 0 && (pfd.revents & POLLIN)) {
      int st = -1;
      releaseNs = readFenceTimeNs(job.fd, &st);
      fenceState = (releaseNs > 0) ? 3 : 1;
    } else {
      fenceState = 2;
    }
    close(job.fd);
    reportResult(env, job.tag, job.latch, releaseNs, job.count, fenceState, job.source, nowMonoNs());
  }
  return NULL;
}

static void onComplete(void* context, ASurfaceTransactionStats* stats) {
  int slot = (int)(intptr_t)context;
  __atomic_thread_fence(__ATOMIC_ACQUIRE);
  int64_t tag = gTagRing[slot & (TAG_RING_SIZE - 1)];
  int source = gSrcRing[slot & (TAG_RING_SIZE - 1)];
  int64_t latchNs = p_latchTime ? p_latchTime(stats) : -1;

  // Display-global present fences are abort-prone; per-surface release fences are stable here.
  int chosenFd = -1;
  int count = 0;
  ASurfaceControl** controls = NULL;
  size_t n = 0;
  if (p_getControls) p_getControls(stats, &controls, &n);
  count = (int)n;
  for (size_t i = 0; i < n; i++) {
    int rfd = p_prevRelease ? p_prevRelease(stats, controls[i]) : -1;
    if (rfd < 0) continue;
    if (chosenFd < 0)
      chosenFd = rfd;
    else
      close(rfd);
  }
  if (controls && p_releaseControls) p_releaseControls(controls);

  if (chosenFd < 0) {
    JNIEnv* env = NULL;
    int didAttach = 0;
    if ((*gVm)->GetEnv(gVm, (void**)&env, JNI_VERSION_1_6) != JNI_OK) {
      if ((*gVm)->AttachCurrentThread(gVm, &env, NULL) != JNI_OK) return;
      didAttach = 1;
    }
    reportResult(env, tag, latchNs, -1, count, 0, source, nowMonoNs());
    if (didAttach) (*gVm)->DetachCurrentThread(gVm);
    return;
  }

  pthread_mutex_lock(&gJobLock);
  int next = (gJobHead + 1) % JOB_RING;
  if (next == gJobTail) {
    close(chosenFd);
    if (gJobDrops++ == 0) LOGW("fence job ring full — dropping samples (slow fence reader?)");
  } else {
    gJobs[gJobHead].fd = chosenFd;
    gJobs[gJobHead].tag = tag;
    gJobs[gJobHead].latch = latchNs;
    gJobs[gJobHead].count = count;
    gJobs[gJobHead].source = source;
    gJobHead = next;
    pthread_cond_signal(&gJobCond);
  }
  pthread_mutex_unlock(&gJobLock);
}

JNIEXPORT void JNICALL Java_com_edde746_plezy_exoplayer_SurfaceTxProbe_nativeAttach(
    JNIEnv* env, jclass clazz, jobject jtransaction, jlong tag, jint source) {
  if (!ensureProbeInit(env, clazz)) return;
  int slot = __atomic_fetch_add(&gTagSeq, 1, __ATOMIC_RELAXED) & (TAG_RING_SIZE - 1);
  gTagRing[slot] = (int64_t)tag;
  gSrcRing[slot] = (int)source;
  // Binder carries only the slot index, so the ring write has to win publication.
  __atomic_thread_fence(__ATOMIC_RELEASE);

  ASurfaceTransaction* tx = p_fromJava(env, jtransaction);
  if (!tx) {
    LOGW("ASurfaceTransaction_fromJava returned null");
    return;
  }
  p_setOnComplete(tx, (void*)(intptr_t)slot, onComplete);
}
