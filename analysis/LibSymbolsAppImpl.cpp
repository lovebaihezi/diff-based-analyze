
#include "LibSymbolsApp.hpp"
#include <algorithm>
#include <array>
#include <cstdio>
#include <memory>
#include <sstream>
#include <string>
#include <unordered_map>

namespace diff_analysis {

class LibSymbolsApp::Impl {
public:
  Impl() = default;

  tl::expected<LibraryInfo, std::error_code>
  parseElfFile(const std::filesystem::path &path) {
    // Initialize library info
    LibraryInfo info;
    info.path = path;
    info.isDynamic = path.extension() == ".so";

    // Run llvm-readelf for header information
    std::string headerCmd = "llvm-readelf -h " + path.string();
    auto headerOutput = executeCommand(headerCmd);
    if (!headerOutput) {
      return tl::unexpected(std::make_error_code(std::errc::io_error));
    }
    info.architecture = parseArchitecture(*headerOutput);

    // Run llvm-readelf for symbol information
    std::string symbolCmd = "llvm-readelf -s -W " + path.string();
    auto symbolOutput = executeCommand(symbolCmd);
    if (!symbolOutput) {
      return tl::unexpected(std::make_error_code(std::errc::io_error));
    }

    auto parsedSymbols = parseSymbols(*symbolOutput);
    if (!parsedSymbols) {
      return tl::unexpected(std::make_error_code(std::errc::invalid_argument));
    }
    info.symbols = std::move(*parsedSymbols);

    return info;
  }

private:
  tl::expected<std::string, std::error_code>
  executeCommand(const std::string &cmd) {
    std::array<char, 128> buffer;
    std::string result;
    std::unique_ptr<FILE, decltype(&pclose)> pipe(popen(cmd.c_str(), "r"),
                                                  pclose);

    if (!pipe) {
      return tl::unexpected(std::make_error_code(std::errc::io_error));
    }

    while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr) {
      result += buffer.data();
    }

    if (result.empty()) {
      return tl::unexpected(std::make_error_code(std::errc::io_error));
    }

    return result;
  }

  std::string parseArchitecture(const std::string &output) {
    std::stringstream ss(output);
    std::string line;
    while (std::getline(ss, line)) {
      if (line.find("Machine:") != std::string::npos) {
        auto pos = line.find(':');
        if (pos != std::string::npos) {
          auto arch = line.substr(pos + 1);
          // Trim whitespace
          arch.erase(0, arch.find_first_not_of(" \t"));
          arch.erase(arch.find_last_not_of(" \t") + 1);
          return arch;
        }
      }
    }
    return "unknown";
  }

  tl::expected<std::vector<Symbol>, std::error_code>
  parseSymbols(const std::string &output) {
    std::vector<Symbol> symbols;
    std::stringstream ss(output);
    std::string line;

    // Find symbol table section
    while (std::getline(ss, line)) {
      if (line.find("Symbol table") != std::string::npos) {
        break;
      }
    }

    // Skip header line
    std::getline(ss, line);

    while (std::getline(ss, line)) {
      if (line.empty() || line.find("Symbol table") != std::string::npos) {
        continue;
      }

      try {
        Symbol sym = parseSymbolLine(line);
        symbols.push_back(std::move(sym));
      } catch (...) {
        continue; // Skip malformed entries
      }
    }

    return symbols;
  }

  Symbol parseSymbolLine(const std::string &line) {
    std::stringstream ss(line);
    Symbol sym;

    // Parse fields: [Num] Value Size Type Bind Vis Ndx Name
    size_t num;
    std::string value, size, type, bind, vis, ndx, name;

    ss >> num >> value >> size >> type >> bind >> vis >> ndx;
    std::getline(ss, name); // Rest of line is name
    name = name.substr(name.find_first_not_of(" \t"));

    // Set symbol properties
    sym.name = name;
    sym.address = std::stoull(value, nullptr, 16);
    sym.size = std::stoull(size);
    sym.isGlobal = (bind == "GLOBAL");

    // Set symbol type
    if (type == "FUNC") {
      sym.type = SymbolType::Function;
    } else if (type == "OBJECT") {
      sym.type = SymbolType::Variable;
    } else if (type == "COMMON") {
      sym.type = SymbolType::Common;
    } else if (type == "NOTYPE" && ndx == "UND") {
      sym.type = SymbolType::Undefined;
    } else {
      sym.type = SymbolType::Other;
    }

    return sym;
  }
};

// Constructor and destructor
LibSymbolsApp::LibSymbolsApp() : pImpl(std::make_unique<Impl>()) {}
LibSymbolsApp::~LibSymbolsApp() = default;

// Public member functions
tl::expected<LibraryInfo, std::error_code>
LibSymbolsApp::parseLibrary(const std::filesystem::path &libPath) {
  std::error_code ec;
  if (!std::filesystem::exists(libPath, ec)) {
    return tl::unexpected(
        ec ? ec : std::make_error_code(std::errc::no_such_file_or_directory));
  }
  return pImpl->parseElfFile(libPath);
}

tl::expected<LibSymbolsApp::SymbolDiff, std::string>
LibSymbolsApp::compareLibraries(const LibraryInfo &lib1,
                                const LibraryInfo &lib2) {
  SymbolDiff diff;

  std::unordered_map<std::string, const Symbol *> symbolMap1;
  std::unordered_map<std::string, const Symbol *> symbolMap2;

  // Build maps
  for (const auto &sym : lib1.symbols)
    symbolMap1[sym.name] = &sym;
  for (const auto &sym : lib2.symbols)
    symbolMap2[sym.name] = &sym;

  // Find added, modified, and common symbols
  for (const auto &sym : lib2.symbols) {
    auto it = symbolMap1.find(sym.name);
    if (it == symbolMap1.end()) {
      diff.added.push_back(sym);
    } else if (*it->second == sym) {
      diff.common.push_back(sym);
    } else {
      diff.modified.push_back(sym);
    }
  }

  // Find removed symbols
  for (const auto &sym : lib1.symbols) {
    if (symbolMap2.find(sym.name) == symbolMap2.end()) {
      diff.removed.push_back(sym);
    }
  }

  return diff;
}

template <typename Predicate>
  requires std::predicate<Predicate, const Symbol &>
std::vector<Symbol>
LibSymbolsApp::filterSymbols(const std::vector<Symbol> &symbols,
                             Predicate pred) {
  std::vector<Symbol> result;
  std::copy_if(symbols.begin(), symbols.end(), std::back_inserter(result),
               pred);
  return result;
}

std::vector<Symbol> LibSymbolsApp::getExportedSymbols(const LibraryInfo &lib) {
  return filterSymbols(lib.symbols, [](const Symbol &sym) {
    return sym.isGlobal && sym.type != SymbolType::Undefined;
  });
}

std::vector<Symbol> LibSymbolsApp::getImportedSymbols(const LibraryInfo &lib) {
  return filterSymbols(lib.symbols, [](const Symbol &sym) {
    return sym.type == SymbolType::Undefined;
  });
}

} // namespace diff_analysis
