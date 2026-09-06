#pragma once

#include <mpv/client.h>

#include <cstdint>

// Names the session the next event_thread serves. Called under the lifecycle
// write lock before pthread_create, which publishes the values to the thread;
// the thread then never reads the globals, so a successor session replacing
// them cannot redirect it.
void event_thread_bind(mpv_handle* mpv, uint64_t session);

void* event_thread(void* arg);
