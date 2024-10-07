#pragma once

#include "quill/Backend.h"
#include "quill/Frontend.h"
#include "quill/Logger.h"
#include "quill/core/LogLevel.h"
#include "quill/sinks/ConsoleSink.h"

#include <memory>

#include "argparse.hpp"
#include "rust.hpp"

namespace diff_analysis {
class App {
private:
  quill::Logger *logger_inst;
  argparse::ArgumentParser program;

public:
  App() = delete;
  App(quill::Logger *logger) : program("diff-analysis") {
    App::logger_inst = logger;
  }

  auto args() -> argparse::ArgumentParser & { return program; }

  static auto logger() -> quill::Logger * {
    return quill::Frontend::get_logger("root");
  }

  static auto init(int argc, const char *const argv[]) -> Box<App> {
    quill::Backend::start();

    quill::Logger *logger = quill::Frontend::create_or_get_logger(
        "root", quill::Frontend::create_or_get_sink<quill::ConsoleSink>("app"));

    auto app = std::make_unique<App>(logger);

    app->args()
        .add_argument("project")
        .help("The path to the project for analysis")
        .default_value(std::string());

    app->args().parse_args(argc, argv);

    logger->set_log_level(quill::LogLevel::Debug);

    return app;
  }

  static auto shutdown() -> void { quill::Backend::stop(); }
};
} // namespace diff_analysis
