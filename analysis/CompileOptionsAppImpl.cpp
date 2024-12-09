#include "CompileOptionsApp.hpp"
#include <cassert>
#include <format>
#include <fstream>
#include <nlohmann/json.hpp>
#include <ranges>
#include <span>

using json = nlohmann::json;

namespace diff_analysis {

class CompileOptionsApp::Impl {
public:
  struct LibraryData {
    std::string name;
    std::filesystem::path path;
  };

  std::vector<LibraryData> libraries;

  static constexpr std::array<std::string_view, 3> defaultSearchPaths = {
      "/usr/lib", "/usr/local/lib", "/lib"};

  [[nodiscard]] auto findLibraryPath(
      std::string_view libName,
      std::span<const std::string_view> searchPaths = defaultSearchPaths) const
      -> tl::expected<std::filesystem::path, ParseError> {

    for (const auto &basePath : searchPaths) {
      auto fullPath =
          std::filesystem::path(basePath) / std::format("lib{}.so", libName);

      if (std::filesystem::exists(fullPath)) {
        return fullPath;
      }
    }
    return tl::unexpected{ParseError{
        std::format("Could not find library {} in search paths", libName)}};
  }

  auto parseLibraryFlags(std::string_view command)
      -> tl::expected<void, ParseError> {
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

      if (space_pos == std::string_view::npos)
        break;
      remaining = remaining.substr(space_pos + 1);
    }
    return {};
  }
};

CompileOptionsApp::CompileOptionsApp() : pImpl(std::make_unique<Impl>()) {}
CompileOptionsApp::~CompileOptionsApp() = default;

CompileOptionsApp::CompileOptionsApp(CompileOptionsApp &&) noexcept = default;
CompileOptionsApp &
CompileOptionsApp::operator=(CompileOptionsApp &&) noexcept = default;

auto CompileOptionsApp::parseCompileCommands(std::string_view jsonPath)
    -> tl::expected<void, ParseError> {
  try {
    std::ifstream file{std::string(jsonPath)};
    if (!file.is_open()) {
      return tl::unexpected{ParseError{
          std::format("Failed to open compile_commands.json at {}", jsonPath)}};
    }

    json commands = json::parse(file);

    for (const auto &command : commands) {
      if (command.contains("command")) {
        auto command_value = command["command"];
        assert(command_value.is_string());
        auto str = command_value.get<std::string_view>();
        if (auto result = pImpl->parseLibraryFlags(str); !result) {
          return tl::unexpected{result.error()};
        }
      }
    }

    return {};
  } catch (const json::parse_error &e) {
    return tl::unexpected{
        ParseError{std::format("JSON parse error: {}", e.what())}};
  } catch (const std::exception &e) {
    return tl::unexpected{ParseError{
        std::format("Error processing compile commands: {}", e.what())}};
  }
}

auto CompileOptionsApp::getLinkedLibraries() const
    -> tl::expected<std::vector<LibraryInfo>, ParseError> {
  std::vector<LibraryInfo> result;
  result.reserve(pImpl->libraries.size());

  std::ranges::transform(pImpl->libraries, std::back_inserter(result),
                         [](const Impl::LibraryData &data) {
                           return LibraryInfo{data.name, data.path};
                         });

  return result;
}

auto CompileOptionsApp::getLibraryPaths(std::string_view libName) const
    -> tl::expected<std::vector<std::filesystem::path>, ParseError> {
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

} // namespace diff_analysis
