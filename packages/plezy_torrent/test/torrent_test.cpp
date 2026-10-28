#include "../src/plezy_torrent.h"
#include <libtorrent/session.hpp>
#include <libtorrent/torrent_status.hpp>
#include <libtorrent/peer_info.hpp>
#include <libtorrent/alert_types.hpp>
#include <libtorrent/create_torrent.hpp>
#include <libtorrent/torrent_info.hpp>
#include <libtorrent/add_torrent_params.hpp>
#include <libtorrent/magnet_uri.hpp>
#include <libtorrent/settings_pack.hpp>
#include <libtorrent/file_storage.hpp>
#include <algorithm>
#include <cassert>
#include <chrono>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <thread>

namespace lt = libtorrent;
namespace fs = std::filesystem;
using namespace std::chrono_literals;
void verify_transfer(bool multiple_files) {
  assert(pt_abi_version() == 1);
  assert(pt_open("invalid", "/tmp", -1, 1LL << 26, 16384) == nullptr);
  const auto root = fs::temp_directory_path() / ("plezy-p2p-test-" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
  fs::create_directories(root / "seed"); fs::create_directories(root / "read");
  std::vector<char> data(2 * 1024 * 1024 + 271);
  for (size_t i = 0; i < data.size(); ++i) data[i] = static_cast<char>((i * 31 + i / 251) % 256);
  fs::create_directories(root / "seed" / "pack");
  std::ofstream out(root / "seed" / "pack" / "fixture.mp4", std::ios::binary);
  out.write(data.data(), data.size()); out.close();
  lt::file_storage files;
  if (multiple_files) {
    // Selected media starts in the middle of a piece; adjacent files must
    // never leak into the player's zero-based range address space.
    std::ofstream prefix(root / "seed" / "pack" / "readme.txt", std::ios::binary);
    std::string padding(12345, 'x'); prefix << padding; prefix.close();
    files.add_file("pack/readme.txt", padding.size());
  }
  files.add_file("pack/fixture.mp4", data.size());
  lt::create_torrent create(files, 16 * 1024, lt::create_torrent::v1_only);
  lt::set_piece_hashes(create, (root / "seed").string());
  auto metadata = std::make_shared<lt::torrent_info>(create.generate());
  lt::settings_pack settings;
  settings.set_str(lt::settings_pack::listen_interfaces, "127.0.0.1:0");
  settings.set_bool(lt::settings_pack::enable_dht, false);
  settings.set_bool(lt::settings_pack::enable_lsd, false);
  settings.set_bool(lt::settings_pack::enable_ip_notifier, false);
  settings.set_bool(lt::settings_pack::enable_upnp, false);
  settings.set_bool(lt::settings_pack::enable_natpmp, false);
  settings.set_int(lt::settings_pack::alert_mask, lt::alert_category::all);
  lt::session seed(settings);
  lt::add_torrent_params params;
  params.ti = metadata; params.save_path = (root / "seed").string();
  params.flags &= ~(lt::torrent_flags::paused | lt::torrent_flags::auto_managed);
  params.flags |= lt::torrent_flags::seed_mode;
  auto source = seed.add_torrent(params);
  for (int n = 0; seed.listen_port() == 0 && n < 100; ++n) std::this_thread::sleep_for(50ms);
  const auto magnet = lt::make_magnet_uri(source) + "&x.pe=127.0.0.1:" + std::to_string(seed.listen_port());
  const auto parsed = lt::parse_magnet_uri(magnet);
  assert(!parsed.peers.empty());
  void* stream = pt_open(magnet.c_str(), (root / "read").string().c_str(), multiple_files ? 1 : -1, 1LL << 26, 16384);
  assert(stream);
  auto deadline = std::chrono::steady_clock::now() + 40s;
  int64_t size = -2;
  while (size == -2 && std::chrono::steady_clock::now() < deadline) { size = pt_size(stream); std::this_thread::sleep_for(50ms); }
  if (size != static_cast<int64_t>(data.size())) {
    std::vector<lt::alert*> alerts; seed.pop_alerts(&alerts); for (auto* alert : alerts) std::cerr << alert->message() << std::endl;
    auto status = source.status();
    std::cerr << "size=" << size << " seed peers=" << status.num_peers << " error=" << status.errc.message() << " port=" << seed.listen_port() << std::endl;
  }
  assert(size == static_cast<int64_t>(data.size()));
  char name[256]; assert(pt_name(stream, name, sizeof(name)) > 0); assert(std::string(name) == "fixture.mp4");
  std::vector<uint8_t> buffer(64 * 1024);
  // Tail first, then cross a piece boundary, then seek backwards.
  for (int64_t position : {size - 100, int64_t(16380), int64_t(0), size / 2}) {
    const auto end = std::min<int64_t>(position + buffer.size(), size);
    while (position < end) {
      int read = -2;
      deadline = std::chrono::steady_clock::now() + 40s;
      while (read == -2 && std::chrono::steady_clock::now() < deadline) {
        read = pt_read(stream, position, buffer.data(), end - position); std::this_thread::sleep_for(50ms);
      }
      assert(read > 0);
      assert(std::equal(buffer.begin(), buffer.begin() + read, reinterpret_cast<uint8_t*>(data.data()) + position));
      position += read;
    }
  }
  assert(pt_read(stream, size, buffer.data(), buffer.size()) == 0);
  assert(pt_read(stream, -1, buffer.data(), buffer.size()) == -1);
  pt_close(stream);
  seed.remove_torrent(source);
  fs::remove_all(root);
}
int main() {
  verify_transfer(false);
  verify_transfer(true);
  std::cout << "verified single/multi-file transfer, metadata, seeking, EOF and invalid input passed\n";
}
