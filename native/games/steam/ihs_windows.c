// SPDX-License-Identifier: GPL-3.0-or-later
// App-owned backend: no SDL event loop or process-global socket replacement.
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <winsock2.h>
#include <ws2tcpip.h>

// Keep Winsock2 before all dependent Windows SDK and Flutter headers.
#include <iphlpapi.h>
#include <process.h>
#include <stdlib.h>
#include <string.h>
#include <windows.h>

#include "ihs_buffer.h"
#include "ihs_thread.h"
#include "ihs_udp.h"

struct IHS_Thread {
  HANDLE handle;
  IHS_ThreadFunction* function;
  void* context;
};
struct IHS_Mutex {
  CRITICAL_SECTION handle;
};
struct IHS_Cond {
  CONDITION_VARIABLE handle;
};
struct IHS_UDPSocket {
  SOCKET handle;
  IHS_Mutex* mutex;
};

static unsigned __stdcall thread_entry(void* context) {
  IHS_Thread* thread = context;
  thread->function(thread->context);
  return 0;
}
IHS_Thread* IHS_ThreadCreate(IHS_ThreadFunction* function, const char* name, void* context) {
  (void)name;
  IHS_Thread* thread = calloc(1, sizeof(*thread));
  if (!thread) return NULL;
  thread->function = function;
  thread->context = context;
  thread->handle = (HANDLE)_beginthreadex(NULL, 0, thread_entry, thread, 0, NULL);
  if (!thread->handle) {
    free(thread);
    return NULL;
  }
  return thread;
}
void IHS_ThreadJoin(IHS_Thread* thread) {
  if (!thread) return;
  WaitForSingleObject(thread->handle, INFINITE);
  CloseHandle(thread->handle);
  free(thread);
}
IHS_Mutex* IHS_MutexCreate(void) {
  IHS_Mutex* mutex = calloc(1, sizeof(*mutex));
  // Critical sections are recursive, as required by IHS timer re-entry.
  if (mutex && !InitializeCriticalSectionEx(&mutex->handle, 0, 0)) {
    free(mutex);
    return NULL;
  }
  return mutex;
}
void IHS_MutexDestroy(IHS_Mutex* mutex) {
  if (mutex) {
    DeleteCriticalSection(&mutex->handle);
    free(mutex);
  }
}
bool IHS_MutexLock(IHS_Mutex* mutex) {
  EnterCriticalSection(&mutex->handle);
  return true;
}
bool IHS_MutexUnlock(IHS_Mutex* mutex) {
  LeaveCriticalSection(&mutex->handle);
  return true;
}
IHS_Cond* IHS_CondCreate(void) {
  IHS_Cond* cond = calloc(1, sizeof(*cond));
  if (cond) InitializeConditionVariable(&cond->handle);
  return cond;
}
void IHS_CondDestroy(IHS_Cond* cond) { free(cond); }
void IHS_CondSignal(IHS_Cond* cond) { WakeAllConditionVariable(&cond->handle); }
bool IHS_CondWait(IHS_Cond* cond, IHS_Mutex* mutex) {
  return SleepConditionVariableCS(&cond->handle, &mutex->handle, INFINITE) != 0;
}

bool IHS_IPAddressFromString(IHS_IPAddress* address, const char* value) {
  if (!address || !value) return false;
  IHS_IPAddress parsed = {0};
  bool v6 = strchr(value, ':') != NULL;
  if (InetPtonA(v6 ? AF_INET6 : AF_INET, value, v6 ? (void*)parsed.v6.data : (void*)parsed.v4.data) != 1) return false;
  parsed.family = v6 ? IHS_IPAddressFamilyIPv6 : IHS_IPAddressFamilyIPv4;
  *address = parsed;
  return true;
}
char* IHS_IPAddressToString(const IHS_IPAddress* address) {
  char buffer[INET6_ADDRSTRLEN];
  if (!address) return NULL;
  bool v6 = address->family == IHS_IPAddressFamilyIPv6;
  if (!v6 && address->family != IHS_IPAddressFamilyIPv4) return NULL;
  if (!InetNtopA(
          v6 ? AF_INET6 : AF_INET, v6 ? (void*)address->v6.data : (void*)address->v4.data, buffer, sizeof(buffer)))
    return NULL;
  size_t size = strlen(buffer) + 1;
  char* result = malloc(size);
  if (result) memcpy(result, buffer, size);
  return result;
}
IHS_UDPSocket* IHS_UDPSocketOpen(bool broadcast) {
  WSADATA data;
  if (WSAStartup(MAKEWORD(2, 2), &data)) return NULL;
  IHS_UDPSocket* s = calloc(1, sizeof(*s));
  if (!s) {
    WSACleanup();
    return NULL;
  }
  s->handle = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
  s->mutex = IHS_MutexCreate();
  if (s->handle == INVALID_SOCKET || !s->mutex) {
    IHS_UDPSocketClose(s);
    return NULL;
  }
  int size = 4 * 1024 * 1024;
  setsockopt(s->handle, SOL_SOCKET, SO_RCVBUF, (const char*)&size, sizeof(size));
  if (broadcast) {
    BOOL enabled = TRUE;
    if (setsockopt(s->handle, SOL_SOCKET, SO_BROADCAST, (const char*)&enabled, sizeof(enabled))) {
      IHS_UDPSocketClose(s);
      return NULL;
    }
  }
  return s;
}
void IHS_UDPSocketClose(IHS_UDPSocket* s) {
  if (!s) return;
  if (s->handle != INVALID_SOCKET) closesocket(s->handle);
  IHS_MutexDestroy(s->mutex);
  free(s);
  WSACleanup();
}
int IHS_UDPSocketReceive(IHS_UDPSocket* s, IHS_UDPPacket* packet) {
  struct sockaddr_in sender = {0};
  int senderSize = sizeof(sender);
  IHS_BufferEnsureMaxSize(&packet->buffer, 2048);
  // The protocol's datagram limit is 2048, independent of previous buffer capacity.
  int length =
      recvfrom(s->handle, (char*)IHS_BufferPointer(&packet->buffer), 2048, 0, (struct sockaddr*)&sender, &senderSize);
  if (length == 0) return 0;
  if (length == SOCKET_ERROR) {
    switch (WSAGetLastError()) {
      case WSAEWOULDBLOCK:
      case WSAETIMEDOUT:
      case WSAEINTR:
      case WSAECONNRESET:
      case WSAECONNREFUSED:
      case WSAENETUNREACH:
      case WSAEHOSTUNREACH:
      case WSAEMSGSIZE:
        return 0;  // Discard oversized packets, never deliver truncated payloads.
      default:
        return -1;
    }
  }
  if (senderSize != sizeof(sender) || sender.sin_family != AF_INET) return 0;
  packet->buffer.size = (size_t)length;
  packet->address.ip.family = IHS_IPAddressFamilyIPv4;
  memcpy(packet->address.ip.v4.data, &sender.sin_addr, 4);
  packet->address.port = ntohs(sender.sin_port);
  return 1;
}
bool IHS_UDPSocketSend(IHS_UDPSocket* s, const IHS_UDPPacket* packet) {
  if (packet->address.ip.family != IHS_IPAddressFamilyIPv4 || !packet->buffer.size || packet->buffer.size > 65507)
    return false;
  struct sockaddr_in address = {0};
  address.sin_family = AF_INET;
  address.sin_port = htons(packet->address.port);
  memcpy(&address.sin_addr, packet->address.ip.v4.data, 4);
  IHS_MutexLock(s->mutex);
  int sent = sendto(
      s->handle, (const char*)IHS_BufferPointer(&packet->buffer), (int)packet->buffer.size, 0,
      (const struct sockaddr*)&address, sizeof(address));
  IHS_MutexUnlock(s->mutex);
  return sent == (int)packet->buffer.size;
}
bool IHS_UDPSocketSetBlocking(IHS_UDPSocket* s, bool blocking) {
  u_long nonblocking = blocking ? 0 : 1;
  return ioctlsocket(s->handle, FIONBIO, &nonblocking) == 0;
}
bool IHS_UDPSocketSetRecvTimeout(IHS_UDPSocket* s, uint32_t micros) {
  DWORD millis = (DWORD)(((uint64_t)micros + 999) / 1000);
  return setsockopt(s->handle, SOL_SOCKET, SO_RCVTIMEO, (const char*)&millis, sizeof(millis)) == 0;
}
size_t IHS_UDPBroadcastAddresses(IHS_IPAddress* out, size_t max) {
  if (!out || !max) return 0;
  ULONG size = 16384;
  IP_ADAPTER_ADDRESSES* list = NULL;
  ULONG result = ERROR_BUFFER_OVERFLOW;
  for (int attempt = 0; attempt < 3 && result == ERROR_BUFFER_OVERFLOW && size <= 1024 * 1024; ++attempt) {
    free(list);
    list = malloc(size);
    if (!list) return 0;
    result = GetAdaptersAddresses(
        AF_INET, GAA_FLAG_SKIP_ANYCAST | GAA_FLAG_SKIP_MULTICAST | GAA_FLAG_SKIP_DNS_SERVER, NULL, list, &size);
  }
  size_t count = 0;
  if (result == NO_ERROR)
    for (IP_ADAPTER_ADDRESSES* adapter = list; adapter && count < max; adapter = adapter->Next) {
      if (adapter->OperStatus != IfOperStatusUp || adapter->IfType == IF_TYPE_SOFTWARE_LOOPBACK ||
          adapter->IfType == IF_TYPE_TUNNEL)
        continue;
      for (IP_ADAPTER_UNICAST_ADDRESS* ip = adapter->FirstUnicastAddress; ip && count < max; ip = ip->Next) {
        if (!ip->Address.lpSockaddr || ip->Address.lpSockaddr->sa_family != AF_INET || ip->OnLinkPrefixLength == 0 ||
            ip->OnLinkPrefixLength >= 31)
          continue;
        uint32_t address = ntohl(((struct sockaddr_in*)ip->Address.lpSockaddr)->sin_addr.s_addr);
        if (!address || (address >> 24) == 127 || (address >> 28) >= 14) continue;
        uint32_t broadcast = htonl(address | (UINT32_MAX >> ip->OnLinkPrefixLength));
        size_t index = 0;
        while (index < count && memcmp(out[index].v4.data, &broadcast, 4)) ++index;
        if (index != count) continue;
        out[count].family = IHS_IPAddressFamilyIPv4;
        memcpy(out[count++].v4.data, &broadcast, 4);
      }
    }
  free(list);
  return count;
}
