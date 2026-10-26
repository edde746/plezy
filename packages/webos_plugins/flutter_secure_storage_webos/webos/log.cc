// SPDX-FileCopyrightText: Copyright 2024 LG Electronics Inc.
// SPDX-License-Identifier: LicenseRef-LGE-Proprietary

#include <string>
#include <iostream>
#include <algorithm>
#include <chrono>
#include <fcntl.h>
#include <unistd.h>
#include <stdarg.h>

#include <PmLogLib.h>
#include "log.h"

static void defaultLogCb(uint32_t logLevel,const char* tag,const char* msg) {
  (void)logLevel;
  static int fd = 0;
  if (fd == 0) {
    fd = ::open("/tmp/secure_storage_webos.log", O_WRONLY | O_CREAT | O_TRUNC, 0644);
  }
  std::string str = tag;
  str += " ";
  str += msg;
  str += "\n";
  ::write(fd,str.c_str(),str.length());
}

Log::LogCb Log::logCb_ = defaultLogCb;

void Log::init() {
  static PmLogContext context = nullptr;
  if (context) {
    return;
  }
  context = PmLogGetContextInline("secure_storage_webos");
  Log::addLogListener([](uint32_t logLevel,const char* tag,const char* msg) {
    if (logLevel == Log::VERBOSE || logLevel == Log::DEBUG) {
      PmLogDebug(context, tag, 0, "%s", msg);
    } else if (logLevel == Log::INFO) {
      PmLogInfo(context, tag, 0, "%s", msg);
    } else if (logLevel == Log::WARN) {
      PmLogWarning(context, tag, 0, "%s", msg);
    } else if (logLevel == Log::ERROR) {
      PmLogError(context, tag, 0, "%s", msg);
    } else {
      PmLogCritical(context, tag, 0, "%s", msg);
    }
  });
}

void Log::addLogListener(LogCb listener) {
  logCb_ = listener;
}

Log::Log(const uint32_t logLevel,const std::string& tag)
  : level_(logLevel)
  , tag_(tag) {}

Log::~Log() {
  init();
  logCb_(level_,tag_.c_str(),out_.str().c_str());
}
