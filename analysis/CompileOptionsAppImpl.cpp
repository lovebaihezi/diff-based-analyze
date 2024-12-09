
#include "CompileOptionsApp.hpp"
#include <algorithm>
#include <format>
#include <fstream>
#include <json/json.h>
#include <ranges>
#include <span>

class CompileOptionsApp::Impl {
public:
  struct LibraryData {
    std::string name;
    std::filesystem::path path;
  };

  std::vector<LibraryData> libraries;

  static constexpr std::array<std::string_view, 3> defaultSearchPaths = {
      "/usr/lib", "/usr/local/lib", "/lib"};

  [[nodiscard]] std::optional<std::filesystem::path>
  findLibraryPath(std::string_view libName,
                  std::span<const std::string_view> searchPaths =
                      defaultSearchPaths) const {

    for (const auto &basePath : searchPaths) {
      auto fullPath =
          std::filesystem::path(basePath) / std::format("lib{}.so", libName);

      if (std::filesystem::exists(fullPath)) {
        return fullPath;
      }
    }
    return std::nullopt;
  }

  bool parseLibraryFlags(std::string_view command) {
    std::string_view remaining = command;
    while (!remaining.empty()) {
      auto space_pos = remaining.find(' ');
      auto token = remaining.substr(0, space_pos);

      if (token == "-l") {
        if (space_pos != std::string_view::npos) {
          remaining = remaining.substr(space_pos + 1);
          space_pos = remaining.find(' ');
          auto libName = remaining.substr(0, space_pos);

          if (auto path = findLibraryPath(libName)) {
            libraries.push_back({std::string(libName), *path});
          }
        }
      } else if (token.starts_with("-l")) {
        auto libName = token.substr(2);
        if (auto path = findLibraryPath(libName)) {
          libraries.push_back({std::string(libName), *path});
        }
      }

      if (space_pos == std::string_view::npos) {
        break;
      }
      remaining = remaining.substr(space_pos + 1);
    }
    return true;
  }
};

CompileOptionsApp::CompileOptionsApp() : pImpl(std::make_unique<Impl>()) {}
CompileOptionsApp::~CompileOptionsApp() = default;

CompileOptionsApp::CompileOptionsApp(CompileOptionsApp &&) noexcept = default;
CompileOptionsApp &
CompileOptionsApp::operator=(CompileOptionsApp &&) noexcept = default;

bool CompileOptionsApp::parseCompileCommands(std::string_view jsonPath) {
  Json::Value root;
  std::ifstream file{std::string(jsonPath)};

  if (!file.is_open()) {
    throw std::runtime_error(
        std::format("Failed to open compile_commands.json at {}", jsonPath));
  }

  try {
    file >> root;

    for (const auto &command : root) {
      if (command.isMember("command")) {
        pImpl->parseLibraryFlags(command["command"].asString());
      }
    }
  } catch (const std::exception &e) {
    throw std::runtime_error(std::format("Error parsing JSON: {}", e.what()));
  }

  return true;
}

std::vector<CompileOptionsApp::LibraryInfo>
CompileOptionsApp::getLinkedLibraries() const {
  std::vector<LibraryInfo> result;
  result.reserve(pImpl->libraries.size());

  std::ranges::transform(pImpl->libraries, std::back_inserter(result),
                         [](const Impl::LibraryData &data) {
                           return LibraryInfo{data.name, data.path};
                         });

  return result;
}

std::vector<std::filesystem::path>
CompileOptionsApp::getLibraryPaths(std::string_view libName) const {

  std::vector<std::filesystem::path> result;

  auto matchingLibs =
      pImpl->libraries |
      std::views::filter([libName](const Impl::LibraryData &data) {
        return data.name == libName;
      }) |
      std::views::transform(
          [](const Impl::LibraryData &data) { return data.path; });

  std::ranges::copy(matchingLibs, std::back_inserter(result));
  return result;
}
