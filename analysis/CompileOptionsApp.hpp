#pragma once

#include <filesystem>
#include <memory>
#include <string_view>
#include <vector>

class CompileOptionsApp {
public:
  struct LibraryInfo {
    std::string_view name;
    std::filesystem::path path;

    // Comparison operator for std::ranges
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
  [[nodiscard]] bool parseCompileCommands(std::string_view jsonPath);

  // Get library information
  [[nodiscard]] std::vector<LibraryInfo> getLinkedLibraries() const;

  // Get library paths by name
  [[nodiscard]] std::vector<std::filesystem::path>
  getLibraryPaths(std::string_view libName) const;

private:
  class Impl;
  std::unique_ptr<Impl> pImpl;
};
