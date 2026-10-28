// SPDX-License-Identifier: GPL-3.0-or-later
#include <windows.h>
#include <winsock2.h>
#include <ws2tcpip.h>

#include <cassert>
#include <cstring>
#include <future>

#include "steam_runtime.h"
extern "C" {
#include "ihs_buffer.h"
#include "ihs_clock.h"
#include "ihs_thread.h"
#include "ihs_udp.h"
}

struct Signal {
  IHS_Mutex* mutex = IHS_MutexCreate();
  IHS_Cond* ready = IHS_CondCreate();
  bool done = false;
};
void signal(void* context) {
  auto* s = static_cast<Signal*>(context);
  assert(IHS_MutexLock(s->mutex));
  assert(IHS_MutexLock(s->mutex));  // The timer requires recursive locking.
  s->done = true;
  assert(IHS_MutexUnlock(s->mutex));
  IHS_CondSignal(s->ready);
  assert(IHS_MutexUnlock(s->mutex));
}
int main() {
  Signal s;
  assert(s.mutex && s.ready);
  assert(IHS_MutexLock(s.mutex));
  auto* thread = IHS_ThreadCreate(signal, "test", &s);
  assert(thread);
  while (!s.done) assert(IHS_CondWait(s.ready, s.mutex));
  assert(IHS_MutexUnlock(s.mutex));
  IHS_ThreadJoin(thread);
  IHS_CondDestroy(s.ready);
  IHS_MutexDestroy(s.mutex);
  const auto before = IHS_MonotonicNanos();
  IHS_SleepMicros(2000);
  assert(IHS_MonotonicNanos() > before);

  IHS_IPAddress ip{};
  assert(!IHS_IPAddressFromString(&ip, "999.0.0.1"));
  assert(IHS_IPAddressFromString(&ip, "::1"));
  char* ipv6 = IHS_IPAddressToString(&ip);
  assert(ipv6 && std::strcmp(ipv6, "::1") == 0);
  free(ipv6);
  auto* client = IHS_UDPSocketOpen(false);
  assert(client && IHS_UDPSocketSetRecvTimeout(client, 50000));
  SOCKET server = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
  assert(server != INVALID_SOCKET);
  sockaddr_in address{};
  address.sin_family = AF_INET;
  address.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
  assert(bind(server, reinterpret_cast<const sockaddr*>(&address), sizeof(address)) == 0);
  int size = sizeof(address);
  assert(getsockname(server, reinterpret_cast<sockaddr*>(&address), &size) == 0);
  DWORD timeout = 1000;
  assert(setsockopt(server, SOL_SOCKET, SO_RCVTIMEO, reinterpret_cast<const char*>(&timeout), sizeof(timeout)) == 0);
  IHS_UDPPacket packet{};
  IHS_BufferInit(&packet.buffer, 0, 2048);
  assert(IHS_IPAddressFromString(&packet.address.ip, "127.0.0.1"));
  packet.address.port = ntohs(address.sin_port);
  const uint8_t payload[] = {1, 2, 3, 4};
  IHS_BufferWriteMem(&packet.buffer, 0, payload, sizeof(payload));
  assert(IHS_UDPSocketSend(client, &packet));
  sockaddr_in sender{};
  size = sizeof(sender);
  char data[16];
  assert(recvfrom(server, data, sizeof(data), 0, reinterpret_cast<sockaddr*>(&sender), &size) == 4);
  assert(std::memcmp(data, payload, 4) == 0);
  std::array<char, 2049> oversized{};
  assert(
      sendto(server, oversized.data(), int(oversized.size()), 0, reinterpret_cast<sockaddr*>(&sender), size) == 2049);
  assert(IHS_UDPSocketReceive(client, &packet) == 0);
  assert(sendto(server, data, 4, 0, reinterpret_cast<sockaddr*>(&sender), size) == 4);
  assert(IHS_UDPSocketReceive(client, &packet) == 1);
  assert(packet.buffer.size == 4 && std::memcmp(IHS_BufferPointer(&packet.buffer), payload, 4) == 0);
  assert(IHS_UDPSocketReceive(client, &packet) == 0);  // Receive timeout is not fatal.
  assert(IHS_UDPSocketSetBlocking(client, false));
  assert(IHS_UDPSocketReceive(client, &packet) == 0);
  IHS_BufferClear(&packet.buffer, true);
  closesocket(server);
  IHS_UDPSocketClose(client);

  plezy::steam::Runtime runtime;
  plezy::steam::Credentials credentials;
  credentials.device = 1;
  auto pairing = std::async(std::launch::async, [&] { return runtime.pair({"127.0.0.1", 9, 1}, credentials, "1234"); });
  runtime.cancel();
  assert(pairing.wait_for(std::chrono::seconds(3)) == std::future_status::ready);
  assert(pairing.get() == -2);
}
