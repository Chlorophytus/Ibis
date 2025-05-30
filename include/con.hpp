/**
 *  Copyright 2025 Roland Metivier
 *
 *  SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
 *
 *  Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
 *  not use this file except in compliance with the License, or, at your option,
 *  the Apache License version 2.0.
 *
 *  You may obtain a copy of the License at
 *
 *  https://solderpad.org/licenses/SHL-2.1/
 *
 *  Unless required by applicable law or agreed to in writing, any work
 *  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 *  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */
#pragma once
#include "main.hpp"
namespace ibis {
/// @brief Logging functionality
namespace con {
/// @brief RFC 5424 syslog levels
enum class priority : U8 {
  emergency = 0x80,
  alert = 0x40,
  critical = 0x20,
  error = 0x10,
  warning = 0x08,
  notice = 0x04,
  informational = 0x02,
  debug = 0x01,
};

/// @brief An abstract base class for a logger
class listener {
  virtual void _log_one(const priority, const std::string &) const = 0;

  static std::string _convert_one(const char *from) {
    return std::string{from};
  }
  static std::string _convert_one(std::string from) {
    return std::string{from};
  }
  static std::string _convert_one(bool from) {
    return std::string{from ? "true" : "false"};
  }
  static std::string _convert_one(U8 from) { return std::to_string(from); }
  static std::string _convert_one(U16 from) { return std::to_string(from); }
  static std::string _convert_one(U32 from) { return std::to_string(from); }
  static std::string _convert_one(U64 from) { return std::to_string(from); }
  static std::string _convert_one(S8 from) { return std::to_string(from); }
  static std::string _convert_one(S16 from) { return std::to_string(from); }
  static std::string _convert_one(S32 from) { return std::to_string(from); }
  static std::string _convert_one(S64 from) { return std::to_string(from); }
  static std::string _convert_one(F32 from) { return std::to_string(from); }
  static std::string _convert_one(F64 from) { return std::to_string(from); }

  template <typename... Ts> static std::string _convert_all(Ts... t) {
    return (... + _convert_one(t));
  }

  priority _current_priority;

public:
  listener() : _current_priority{priority::debug} {}

  void priority_set(const priority p) { _current_priority = p; }
  priority priority_get() const { return _current_priority; }

  static std::vector<std::unique_ptr<listener>> all;

  template <typename... Ts> static void log_all(const priority p, Ts... t) {
    const std::string converted = _convert_all(t...);
    for (auto &&logger : all) {
      if (static_cast<U8>(p) >= static_cast<U8>(logger->_current_priority)) {
        logger->_log_one(p, converted);
      }
    }
  }

  template <typename... Ts> static void debug(Ts... t) {
    log_all(priority::debug, t...);
  }
  template <typename... Ts> static void informational(Ts... t) {
    log_all(priority::informational, t...);
  }
  template <typename... Ts> static void notice(Ts... t) {
    log_all(priority::notice, t...);
  }
  template <typename... Ts> static void warning(Ts... t) {
    log_all(priority::warning, t...);
  }
  template <typename... Ts> static void error(Ts... t) {
    log_all(priority::error, t...);
  }
  template <typename... Ts> static void critical(Ts... t) {
    log_all(priority::critical, t...);
  }
  template <typename... Ts> static void alert(Ts... t) {
    log_all(priority::alert, t...);
  }
  template <typename... Ts> static void emergency(Ts... t) {
    log_all(priority::emergency, t...);
  }
};
/// @brief A listener that only outputs to stdout.
class listener_stdio : public listener {
  const std::chrono::time_point<std::chrono::steady_clock> t0{
      std::chrono::steady_clock::now()};
  void _log_one(const priority sent_priority,
                const std::string &what) const override {
    const std::chrono::time_point<std::chrono::steady_clock> t1{
        std::chrono::steady_clock::now()};
    const F32 wall_time =
        std::chrono::duration_cast<std::chrono::microseconds>(t1 - t0).count() /
        1000000.0f;
    switch (sent_priority) {
    case priority::debug:
      std::printf("[%0.6f] DEBUG: %s\n", wall_time, what.c_str());
      break;

    case priority::informational:
      std::printf("[%0.6f] INFO: %s\n", wall_time, what.c_str());
      break;

    case priority::notice:
      std::printf("[%0.6f] NOTICE: %s\n", wall_time, what.c_str());
      break;

    case priority::warning:
      std::printf("[%0.6f] WARN: %s\n", wall_time, what.c_str());
      break;

    case priority::error:
      std::printf("[%0.6f] ERROR: %s\n", wall_time, what.c_str());
      break;

    case priority::critical:
      std::printf("[%0.6f] CRITICAL: %s\n", wall_time, what.c_str());
      break;

    case priority::alert:
      std::printf("[%0.6f] ALERT: %s\n", wall_time, what.c_str());
      break;

    case priority::emergency:
      std::printf("[%0.6f] EMERGENCY: %s\n", wall_time, what.c_str());
      break;

    default:
      break;
    }
  }
};

/// @brief Initialize the console framework
void init();
} // namespace con
} // namespace ibis
