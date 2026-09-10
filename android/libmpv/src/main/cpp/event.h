#pragma once

/**
 * The session's event loop. [arg] is the `Session*` that nativeInit started it
 * for; the thread borrows that session's immutable handle and id until the
 * retirement that frees it joins this thread.
 */
void* event_thread(void* arg);
