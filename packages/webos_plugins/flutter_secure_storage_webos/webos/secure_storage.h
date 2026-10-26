// Copyright 2022 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_PLUGIN_SECURE_STORAGE_H_
#define FLUTTER_PLUGIN_SECURE_STORAGE_H_

#include <optional>
#include <string>

#include <sqlite3.h>

class SecureStorage {
 public:
  struct Row {
    std::optional<std::string> keys;
    std::optional<std::string> datas;
  };

  SecureStorage();
  ~SecureStorage();

  // Returns the row keyed `flutter_secure_storage`. Both fields are nullopt
  // when the row is missing (first run on a clean device). Opens the DB and
  // creates the table on first call.
  Row Load();

  // Upserts the row keyed `flutter_secure_storage` with the given two columns.
  bool Store(const std::string& keys, const std::string& datas);

 private:
  bool EnsureOpen();
  bool ResolveDbPath(std::string* out_path) const;

  sqlite3* db_ = nullptr;
  bool initialized_ = false;
};

#endif  // FLUTTER_PLUGIN_SECURE_STORAGE_H_
