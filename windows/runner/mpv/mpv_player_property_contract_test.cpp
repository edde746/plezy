#include <cstdlib>
#include <iostream>
#include <utility>

#include "mpv_player.h"

namespace mpv {

class MpvPlayerPropertyContractTestPeer {
 public:
  static void RegisterPendingPropertyWrite(MpvPlayer& player, MpvPlayer::StatusCallback callback) {
    player.pending_requests_.RegisterStatus(std::move(callback));
  }
};

namespace {

void Check(bool condition, const char* message) {
  if (!condition) {
    std::cerr << "mpv_player_property_contract_test: " << message << '\n';
    std::exit(1);
  }
}

void TestUnavailablePropertyWriteFails() {
  MpvPlayer player;
  int callback_count = 0;
  int status = MPV_ERROR_SUCCESS;

  player.SetPropertyAsync("pause", "yes", [&](int error) {
    ++callback_count;
    status = error;
  });

  Check(callback_count == 1, "a property write without an mpv handle must complete exactly once");
  Check(status == MPV_ERROR_UNINITIALIZED, "a property write without an mpv handle must fail as uninitialized");
}

void TestPendingPropertyWriteFailsOnDispose() {
  MpvPlayer player;
  int callback_count = 0;
  int status = MPV_ERROR_SUCCESS;
  MpvPlayerPropertyContractTestPeer::RegisterPendingPropertyWrite(player, [&](int error) {
    ++callback_count;
    status = error;
  });

  player.Dispose();
  Check(callback_count == 1, "dispose must complete a pending property write exactly once");
  Check(status < 0, "dispose must fail a pending property write");

  player.Dispose();
  Check(callback_count == 1, "repeated dispose must not complete a property write twice");
}

}  // namespace
}  // namespace mpv

int main() {
  mpv::TestUnavailablePropertyWriteFails();
  mpv::TestPendingPropertyWriteFailsOnDispose();
  std::cout << "mpv_player_property_contract_test: PASS\n";
  return 0;
}
