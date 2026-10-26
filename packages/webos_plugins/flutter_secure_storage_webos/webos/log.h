// SPDX-FileCopyrightText: Copyright 2024 LG Electronics Inc.
// SPDX-License-Identifier: LicenseRef-LGE-Proprietary

#ifndef LOG_H_
#define LOG_H_
#include <cstdint>
#include <list>
#include <string>
#include <sstream>

class Log {
public:
  static const uint32_t VERBOSE = 1;
  static const uint32_t DEBUG = 2;
  static const uint32_t INFO = 3;
  static const uint32_t WARN = 4;
  static const uint32_t ERROR = 5;

  template <typename T> Log& operator<<(const T& value) {
    out_ << value;
    return *this;
  }

protected:
  Log(const uint32_t logLevel,const std::string& tag);
  virtual ~Log();

private:
  typedef void(*LogCb)(uint32_t logLevel,const char* tag,const char* msg);

  static void init();
  static void addLogListener(LogCb callback);

  static LogCb logCb_;
  uint32_t level_;
  std::string tag_;
  std::ostringstream out_;
};

// C++ style
class LogVerbose : public Log {
public:
  LogVerbose(const std::string& tag) : Log(VERBOSE,tag) {}
  virtual ~LogVerbose() {}
};

class LogDebug : public Log {
public:
  LogDebug(const std::string& tag) : Log(DEBUG,tag) {}
  virtual ~LogDebug() {}
};

class LogInfo : public Log {
public:
  LogInfo(const std::string& tag) : Log(INFO,tag) {}
  virtual ~LogInfo() {}
};

class LogWarn : public Log {
public:
  LogWarn(const std::string& tag) : Log(WARN,tag) {}
  virtual ~LogWarn() {}
};

class LogError : public Log {
public:
  LogError(const std::string& tag) : Log(ERROR,tag) {}
  virtual ~LogError() {}
};
#endif
