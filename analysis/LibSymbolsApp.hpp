
#pragma once

#include "expected.hpp"
#include <concepts>
#include <filesystem>
#include <string>
#include <system_error>
#include <vector>

namespace diff_analysis {

enum class SymbolType { Function, Variable, Undefined, Common, Other };

struct Symbol {
  std::string name;
  SymbolType type;
  bool isGlobal;
  uint64_t address;
  size_t size;
  bool operator==(const Symbol &other) const {
    return name == other.name && type == other.type &&
           isGlobal == other.isGlobal && address == other.address &&
           size == other.size;
  }
};

struct LibraryInfo {
  std::filesystem::path path;
  std::vector<Symbol> symbols;
  std::string architecture;
  bool isDynamic;
};

class LibSymbolsApp {
public:
  LibSymbolsApp();
  ~LibSymbolsApp();

  // Use std::error_code for error handling
  tl::expected<LibraryInfo, std::error_code>
  parseLibrary(const std::filesystem::path &libPath);

  struct SymbolDiff {
    std::vector<Symbol> added;
    std::vector<Symbol> removed;
    std::vector<Symbol> modified;
    std::vector<Symbol> common;
  };

  // Keep std::string for comparison errors as they're application-specific
  tl::expected<SymbolDiff, std::string>
  compareLibraries(const LibraryInfo &lib1, const LibraryInfo &lib2);

  template <typename Predicate>
    requires std::predicate<Predicate, const Symbol &>
  std::vector<Symbol> filterSymbols(const std::vector<Symbol> &symbols,
                                    Predicate pred);

  std::vector<Symbol> getExportedSymbols(const LibraryInfo &lib);
  std::vector<Symbol> getImportedSymbols(const LibraryInfo &lib);

private:
  class Impl;
  std::unique_ptr<Impl> pImpl;
};

} // namespace diff_analysis
