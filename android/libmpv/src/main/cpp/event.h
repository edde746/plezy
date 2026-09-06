#pragma once

#include <mpv/client.h>

#include <cstdint>

// Names the session the next event_thread serves. Called under L and S before
// pthread_create publishes the binding. L prevents rebinding until that thread
// is joined; the thread never reads the live admission slots and can safely
// finish a callback after revocation. Callbacks must never acquire L.
void event_thread_bind(mpv_handle* mpv, uint64_t session);

void* event_thread(void* arg);
