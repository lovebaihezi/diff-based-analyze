#pragma once

#include "expected.hpp"
#include <filesystem>
#include <memory>
#include <string_view>
#include <vector>

namespace diff_analysis {

// Forward declare error types
struct ParseError {
  std::string message;
};

class CompileOptionsApp {
public:
  struct LibraryInfo {
    std::string_view name;
    std::filesystem::path path;

    auto operator<=>(const LibraryInfo &) const = default;
  };

  CompileOptionsApp();
  ~CompileOptionsApp();

  // Delete copy operations due to pImpl
  CompileOptionsApp(const CompileOptionsApp &) = delete;
  CompileOptionsApp &operator=(const CompileOptionsApp &) = delete;

  // Enable move operations
  CompileOptionsApp(CompileOptionsApp &&) noexcept;
  CompileOptionsApp &operator=(CompileOptionsApp &&) noexcept;

  // Parse compile_commands.json file
  [[nodiscard]] auto parseCompileCommands(std::string_view jsonPath)
      -> tl::expected<void, ParseError>;

  // Get library information
  [[nodiscard]] auto getLinkedLibraries() const
      -> tl::expected<std::vector<LibraryInfo>, ParseError>;

  // Get library paths by name
  [[nodiscard]] auto getLibraryPaths(std::string_view libName) const
      -> tl::expected<std::vector<std::filesystem::path>, ParseError>;

private:
  class Impl;
  std::unique_ptr<Impl> pImpl;
};

} // namespace diff_analysis
