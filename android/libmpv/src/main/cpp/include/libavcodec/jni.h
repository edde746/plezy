/*
 * JNI public API functions
 *
 * Copyright (c) 2015-2016 Matthieu Bouron <matthieu.bouron stupeflix.com>
 *
 * This file is part of FFmpeg.
 *
 * FFmpeg is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * FFmpeg is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with FFmpeg; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

#ifndef AVCODEC_JNI_H
#define AVCODEC_JNI_H

/*
 * Manually set a Java virtual machine which will be used to retrieve the JNI
 * environment. Once a Java VM is set it cannot be changed afterwards, meaning
 * you can call multiple times av_jni_set_java_vm with the same Java VM pointer
 * however it will error out if you try to set a different Java VM.
 *
 * @param vm Java virtual machine
 * @param log_ctx context used for logging, can be NULL
 * @return 0 on success, < 0 otherwise
 */
int av_jni_set_java_vm(void *vm, void *log_ctx);

/*
 * Get the Java virtual machine which has been set with av_jni_set_java_vm.
 *
 * @param vm Java virtual machine
 * @return a pointer to the Java virtual machine
 */
void *av_jni_get_java_vm(void *log_ctx);

/*
 * Set the Android application context which will be used to retrieve the Android
 * content resolver to handle content uris.
 *
 * This function is only available on Android.
 *
 * @param app_ctx global JNI reference to the Android application context
 * @return 0 on success, < 0 otherwise
 */
int av_jni_set_android_app_ctx(void *app_ctx, void *log_ctx);

/*
 * Get the Android application context that has been set with
 * av_jni_set_android_app_ctx.
 *
 * This function is only available on Android.
 *
 * @return a pointer the the Android application context
 */
void *av_jni_get_android_app_ctx(void);

/*
 * Register the application's MediaCodec callback bridge class. The Java
 * MediaCodec wrapper needs a Java object to receive MediaCodec.Callback and
 * MediaCodec.OnFrameRenderedListener events, and a library cannot ship one;
 * without this class the Java wrapper decodes synchronously and reports no
 * rendered frames (the NDK wrapper is unaffected).
 *
 * The class extends android.media.MediaCodec.Callback, implements
 * android.media.MediaCodec.OnFrameRenderedListener and declares:
 *
 *   <init>(long codec)                creates the object and the Looper thread
 *                                     its callbacks run on
 *   android.os.Handler handler()      the Handler on that thread
 *   void release()                    returns only once no callback will
 *                                     touch native again; stops the thread
 *
 * and forwards every callback to these static natives, which libavcodec
 * registers on the class (RegisterNatives) when the first codec uses it:
 *
 *   static native void nativeOnInputAvailable(long codec, int index)
 *   static native void nativeOnOutputAvailable(long codec, int index,
 *           int offset, int size, long presentationTimeUs, int flags)
 *   static native void nativeOnFormatChanged(long codec,
 *           android.media.MediaFormat format)
 *   static native void nativeOnError(long codec, int errorCode,
 *           String diagnosticInfo)
 *   static native void nativeOnFrameRendered(long codec,
 *           long presentationTimeUs, long nanoTime)
 *
 * `codec` is the value the constructor received. release() must serialize
 * against the callbacks (a callback that observes release is dropped), since
 * the native side frees `codec` right after release() returns.
 *
 * This function is only available on Android.
 *
 * @param callback_class global JNI reference to the class
 * @return 0 on success, < 0 otherwise
 */
int av_jni_set_mediacodec_callback_class(void *callback_class, void *log_ctx);

#endif /* AVCODEC_JNI_H */
