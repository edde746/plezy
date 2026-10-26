// Copyright 2022 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "secure_storage.h"
#include "log.h"

#include <cstdlib>
#include <filesystem>
#include <string>
#include <system_error>

#ifdef TAG
#undef TAG
#endif
#define TAG "SecureStorage::"

namespace {
constexpr const char* kRowKey = "flutter_secure_storage";
constexpr const char* kDbName = "flutter_secure_storage.db";
}  // namespace

SecureStorage::SecureStorage() = default;

SecureStorage::~SecureStorage() {
  if (db_) {
    sqlite3_close(db_);
    db_ = nullptr;
  }
}

bool SecureStorage::ResolveDbPath(std::string* out_path) const {
  const char* base = std::getenv("FLUTTER_APPDATA_HOME");
  const char* app_id = std::getenv("FLUTTER_APP_ID");
  if (!base || !*base || !app_id || !*app_id) {
    LogError(TAG) << "FLUTTER_APPDATA_HOME / FLUTTER_APP_ID not set";
    return false;
  }
  std::string dir = std::string(base) + "/" + app_id;
  std::error_code ec;
  std::filesystem::create_directories(dir, ec);
  if (ec) {
    LogError(TAG) << "create_directories(" << dir
                  << ") error: " << ec.message();
    return false;
  }
  *out_path = dir + "/" + kDbName;
  return true;
}

bool SecureStorage::EnsureOpen() {
  if (initialized_) return db_ != nullptr;
  initialized_ = true;

  std::string path;
  if (!ResolveDbPath(&path)) return false;

  if (sqlite3_open(path.c_str(), &db_) != SQLITE_OK) {
    LogError(TAG) << "sqlite3_open error: "
                  << (db_ ? sqlite3_errmsg(db_) : "<no db>");
    if (db_) {
      sqlite3_close(db_);
      db_ = nullptr;
    }
    return false;
  }

  const char* sql =
      "CREATE TABLE IF NOT EXISTS SecureStorage("
      "Key TEXT, Keys TEXT, Datas TEXT)";
  char* err_msg = nullptr;
  if (sqlite3_exec(db_, sql, nullptr, nullptr, &err_msg) != SQLITE_OK) {
    LogError(TAG) << "CREATE TABLE error: " << (err_msg ? err_msg : "");
    sqlite3_free(err_msg);
    sqlite3_close(db_);
    db_ = nullptr;
    return false;
  }
  return true;
}

SecureStorage::Row SecureStorage::Load() {
  Row row;
  if (!EnsureOpen()) return row;

  sqlite3_stmt* stmt = nullptr;
  const char* sql =
      "SELECT Keys, Datas FROM SecureStorage WHERE Key = ? LIMIT 1";
  if (sqlite3_prepare_v2(db_, sql, -1, &stmt, nullptr) != SQLITE_OK) {
    LogError(TAG) << "Load prepare error: " << sqlite3_errmsg(db_);
    return row;
  }
  sqlite3_bind_text(stmt, 1, kRowKey, -1, SQLITE_STATIC);

  if (sqlite3_step(stmt) == SQLITE_ROW) {
    const unsigned char* keys = sqlite3_column_text(stmt, 0);
    const unsigned char* datas = sqlite3_column_text(stmt, 1);
    if (keys) row.keys = std::string(reinterpret_cast<const char*>(keys));
    if (datas) row.datas = std::string(reinterpret_cast<const char*>(datas));
  }
  sqlite3_finalize(stmt);
  return row;
}

bool SecureStorage::Store(const std::string& keys, const std::string& datas) {
  if (!EnsureOpen()) return false;

  // The legacy schema doesn't declare Key as UNIQUE, so we can't use
  // sqlite UPSERT. Try UPDATE first; if no rows changed, INSERT.
  sqlite3_stmt* stmt = nullptr;
  const char* update_sql =
      "UPDATE SecureStorage SET Keys = ?, Datas = ? WHERE Key = ?";
  if (sqlite3_prepare_v2(db_, update_sql, -1, &stmt, nullptr) != SQLITE_OK) {
    LogError(TAG) << "Store prepare(update) error: " << sqlite3_errmsg(db_);
    return false;
  }
  sqlite3_bind_text(stmt, 1, keys.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(stmt, 2, datas.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(stmt, 3, kRowKey, -1, SQLITE_STATIC);
  int rc = sqlite3_step(stmt);
  sqlite3_finalize(stmt);
  if (rc != SQLITE_DONE) {
    LogError(TAG) << "Store update step error: " << sqlite3_errmsg(db_);
    return false;
  }

  if (sqlite3_changes(db_) > 0) return true;

  const char* insert_sql =
      "INSERT INTO SecureStorage(Key, Keys, Datas) VALUES(?, ?, ?)";
  if (sqlite3_prepare_v2(db_, insert_sql, -1, &stmt, nullptr) != SQLITE_OK) {
    LogError(TAG) << "Store prepare(insert) error: " << sqlite3_errmsg(db_);
    return false;
  }
  sqlite3_bind_text(stmt, 1, kRowKey, -1, SQLITE_STATIC);
  sqlite3_bind_text(stmt, 2, keys.c_str(), -1, SQLITE_TRANSIENT);
  sqlite3_bind_text(stmt, 3, datas.c_str(), -1, SQLITE_TRANSIENT);
  rc = sqlite3_step(stmt);
  sqlite3_finalize(stmt);
  if (rc != SQLITE_DONE) {
    LogError(TAG) << "Store insert step error: " << sqlite3_errmsg(db_);
    return false;
  }
  return true;
}
