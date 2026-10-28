#include "plezy_torrent.h"
#include <libtorrent/add_torrent_params.hpp>
#include <libtorrent/alert_types.hpp>
#include <libtorrent/download_priority.hpp>
#include <libtorrent/magnet_uri.hpp>
#include <libtorrent/session.hpp>
#include <libtorrent/settings_pack.hpp>
#include <libtorrent/torrent_info.hpp>
#include <libtorrent/torrent_status.hpp>
#include <algorithm>
#include <cstring>
#include <map>
#include <memory>
#include <set>
#include <string>
#include <vector>

namespace lt = libtorrent;
namespace {
lt::settings_pack settings(int upload) {
  lt::settings_pack s;
  s.set_str(lt::settings_pack::user_agent, "PlezyNG/1");
  s.set_str(lt::settings_pack::listen_interfaces, "0.0.0.0:0,[::]:0");
  s.set_str(lt::settings_pack::dht_bootstrap_nodes,
            "router.bittorrent.com:6881,router.utorrent.com:6881,dht.transmissionbt.com:6881");
  s.set_bool(lt::settings_pack::enable_dht, true);
  s.set_bool(lt::settings_pack::enable_lsd, false);
  // App sandboxes can deny route-notification sockets (including netlink).
  // Binding wildcard interfaces keeps peer I/O available without that privilege.
  s.set_bool(lt::settings_pack::enable_ip_notifier, false);
  s.set_bool(lt::settings_pack::enable_upnp, false);
  s.set_bool(lt::settings_pack::enable_natpmp, false);
  s.set_int(lt::settings_pack::connections_limit, 64);
  // Zero initial file priorities can briefly make metadata-only magnets look
  // complete. Reconnect promptly after the chosen file becomes wanted.
  s.set_int(lt::settings_pack::min_reconnect_time, 1);
  s.set_bool(lt::settings_pack::close_redundant_connections, false);
  s.set_int(lt::settings_pack::upload_rate_limit, std::max(upload, 16384));
#ifdef PLEZY_TORRENT_TEST_LOOPBACK
  s.set_str(lt::settings_pack::listen_interfaces, "127.0.0.1:0");
  s.set_bool(lt::settings_pack::enable_dht, false);
  s.set_bool(lt::settings_pack::enable_outgoing_utp, false);
  s.set_bool(lt::settings_pack::enable_incoming_utp, false);
#endif
  s.set_int(lt::settings_pack::active_downloads, 1);
  s.set_int(lt::settings_pack::active_seeds, 0);
  s.set_int(lt::settings_pack::alert_mask, lt::alert_category::error | lt::alert_category::storage | lt::alert_category::status);
  return s;
}
bool video(std::string name) {
  std::transform(name.begin(), name.end(), name.begin(), [](unsigned char c) { return std::tolower(c); });
  auto dot = name.rfind('.');
  if (dot == std::string::npos) return false;
  static const std::set<std::string> types{ ".mkv", ".mp4", ".m4v", ".avi", ".mov", ".webm", ".ts", ".m2ts", ".mpeg", ".mpg" };
  return types.count(name.substr(dot)) != 0;
}
struct Stream {
  lt::session session;
  lt::torrent_handle torrent;
  std::shared_ptr<const lt::torrent_info> info;
  std::map<int, std::vector<char>> pieces;
  std::set<int> requested, prioritized;
  int index;
  int64_t quota, size = -2, offset = 0;
  bool failed = false, priority_ready = false, ready = false;
  std::set<int> renaming;
  std::string name;
  Stream(int file, int64_t limit, int upload) : session(settings(upload)), index(file), quota(limit) {}
  void poll() {
    std::vector<lt::alert*> alerts;
    session.pop_alerts(&alerts);
    for (auto* alert : alerts) {
      if (info && lt::alert_cast<lt::file_prio_alert>(alert)) {
        priority_ready = true;
      } else if (auto* renamed = lt::alert_cast<lt::file_renamed_alert>(alert)) {
        renaming.erase(static_cast<int>(renamed->index));
      } else if (lt::alert_cast<lt::file_rename_failed_alert>(alert)) {
        failed = true;
      } else if (auto* read = lt::alert_cast<lt::read_piece_alert>(alert)) {
        const int piece = static_cast<int>(read->piece);
        requested.erase(piece);
        if (read->error || !read->buffer) { failed = true; continue; }
        if (pieces.size() >= 8) pieces.erase(pieces.begin());
        pieces[piece] = std::vector<char>(read->buffer.get(), read->buffer.get() + read->size);
      } else if (lt::alert_cast<lt::torrent_error_alert>(alert) || lt::alert_cast<lt::file_error_alert>(alert) || lt::alert_cast<lt::session_error_alert>(alert)) {
        failed = true;
      }
    }
    if (failed) return;
    if (info) {
      if (!ready && priority_ready && renaming.empty()) {
        torrent.resume();
        ready = true;
      }
      return;
    }
    auto metadata = torrent.torrent_file();
    if (!metadata) return;
    const auto& files = metadata->files();
    if (files.num_files() > 10000 || metadata->piece_length() > 16 * 1024 * 1024) { failed = true; return; }
    if (index < 0) {
      // Never guess between episodes in a pack. A single video is unambiguous.
      for (int i = 0; i < files.num_files(); ++i) {
        if (video(files.file_name(lt::file_index_t(i)).to_string()) && !files.pad_file_at(lt::file_index_t(i))) {
          if (index >= 0) { failed = true; return; }
          index = i;
        }
      }
    }
    if (index < 0 || index >= files.num_files() || files.pad_file_at(lt::file_index_t(index))) { failed = true; return; }
    const auto selected = lt::file_index_t(index);
    size = files.file_size(selected);
    if (size <= 0 || size + 2LL * metadata->piece_length() > quota) { failed = true; return; }
    name = files.file_name(selected).to_string();
    if (!video(name)) { failed = true; return; }
    offset = files.file_offset(selected);
    info = metadata;
    torrent.pause();
    std::vector<lt::download_priority_t> priorities(files.num_files(), lt::dont_download);
    priorities[index] = lt::default_priority;
    torrent.prioritize_files(priorities);
    torrent.set_flags(lt::torrent_flags::sequential_download);
    // Names from peers are never filesystem paths in our private spool.
    for (int i = 0; i < files.num_files(); ++i) {
      renaming.insert(i);
      torrent.rename_file(lt::file_index_t(i), "file-" + std::to_string(i));
    }
  }
};
}
int32_t pt_abi_version() { return 1; }
void* pt_open(const char* magnet, const char* directory, int32_t index, int64_t quota, int32_t upload) {
  try {
    if (!magnet || !directory || index < -1 || quota < 16 * 1024 * 1024) return nullptr;
    lt::error_code error;
    auto params = lt::parse_magnet_uri(magnet, error);
    if (error || !params.info_hashes.has_v1()) return nullptr;
    auto stream = std::make_unique<Stream>(index, quota, upload);
    params.save_path = directory;
    params.flags &= ~(lt::torrent_flags::auto_managed | lt::torrent_flags::paused);
    // Fetch metadata without payload; selection is committed to disk before
    // exposing a stream or setting any read deadlines.
    params.file_priorities.assign(10000, lt::dont_download);
    stream->torrent = stream->session.add_torrent(params, error);
    if (error) return nullptr;
    return stream.release();
  } catch (...) { return nullptr; }
}
int64_t pt_size(void* handle) {
  try {
    if (!handle) return -1;
    auto& s = *static_cast<Stream*>(handle);
    s.poll();

    return s.failed ? -1 : s.ready ? s.size : -2;
  } catch (...) { return -1; }
}
int32_t pt_name(void* handle, char* destination, int32_t capacity) {
  try {
    if (!handle || !destination || capacity <= 0) return -1;
    const auto& name = static_cast<Stream*>(handle)->name;
    if (name.size() >= static_cast<size_t>(capacity)) return -1;
    std::memcpy(destination, name.c_str(), name.size() + 1);
    return static_cast<int32_t>(name.size());
  } catch (...) { return -1; }
}
int32_t pt_read(void* handle, int64_t position, uint8_t* destination, int32_t capacity) {
  try {
    if (!handle || !destination || position < 0 || capacity <= 0) return -1;
    auto& s = *static_cast<Stream*>(handle);
    s.poll();
    if (s.failed) return -1;
    if (!s.ready) return -2;
    if (position >= s.size) return 0;
    const auto absolute = s.offset + position;
    const int piece = static_cast<int>(absolute / s.info->piece_length());
    const int within = static_cast<int>(absolute % s.info->piece_length());
    auto found = s.pieces.find(piece);
    if (found == s.pieces.end()) {
      if (s.torrent.have_piece(lt::piece_index_t(piece))) {
        if (s.requested.insert(piece).second) s.torrent.read_piece(lt::piece_index_t(piece));
      } else if (s.prioritized.insert(piece).second) {
        if (s.prioritized.size() > 8) {
          s.torrent.clear_piece_deadlines(); s.prioritized.clear(); s.prioritized.insert(piece);
        }
        // Read only after have_piece confirms verified data reached disk. A
        // deadline's alert can precede the final partial-piece disk write.
        s.torrent.set_piece_deadline(lt::piece_index_t(piece), 0);
        for (int n = 1; n <= 4 && piece + n < s.info->num_pieces(); ++n) {
          if ((piece + n) * int64_t(s.info->piece_length()) >= s.offset + s.size) break;
          s.torrent.set_piece_deadline(lt::piece_index_t(piece + n), n * 1000);
        }
      }
      return -2;
    }
    const int count = static_cast<int>(std::min<int64_t>({capacity, s.size - position, int64_t(found->second.size()) - within}));
    if (count <= 0) return -1;
    std::memcpy(destination, found->second.data() + within, count);
    return count;
  } catch (...) { return -1; }
}
void pt_close(void* handle) { try { delete static_cast<Stream*>(handle); } catch (...) {} }
