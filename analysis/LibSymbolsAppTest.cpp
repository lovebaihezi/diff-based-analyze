#include "LibSymbolsApp.hpp"

#include "catch2/catch_test_macros.hpp"
#include <filesystem>
#include <fstream>

using namespace diff_analysis;

// Helper function to create test ELF files
void createTestElf(const std::filesystem::path &path,
                   const std::string &content) {
  std::ofstream file(path);
  file << content;
  file.close();
  // Make file executable
  std::filesystem::permissions(path,
                               std::filesystem::perms::owner_exec |
                                   std::filesystem::perms::owner_write |
                                   std::filesystem::perms::owner_read,
                               std::filesystem::perm_options::add);
}

SCENARIO("LibSymbolsApp can parse and compare ELF files", "[libsymbols]") {
  GIVEN("A LibSymbolsApp instance") {
    LibSymbolsApp app;

    WHEN("Parsing a non-existent file") {
      auto result = app.parseLibrary("nonexistent.so");

      THEN("It should return a file not found error") {
        REQUIRE_FALSE(result.has_value());
        REQUIRE(result.error() ==
                std::make_error_code(std::errc::no_such_file_or_directory));
      }
    }

    WHEN("Parsing a valid ELF file") {
      // Create a temporary test ELF file
      std::filesystem::path testFile =
          std::filesystem::temp_directory_path() / "test.so";
      std::string elfOutput = R"(
ELF Header:
  Machine: Advanced Micro Devices X86-64

Symbol table '.symtab' contains 5 entries:
   Num:    Value          Size Type    Bind   Vis      Ndx Name
     0: 0000000000000000     0 NOTYPE  LOCAL  DEFAULT  UND
     1: 0000000000000000    64 FUNC    GLOBAL DEFAULT    2 function1
     2: 0000000000001000    32 OBJECT  GLOBAL DEFAULT    3 variable1
     3: 0000000000002000     0 NOTYPE  GLOBAL DEFAULT  UND external_func
     4: 0000000000003000    16 COMMON  GLOBAL DEFAULT  COM common_var
)";
      createTestElf(testFile, elfOutput);

      auto result = app.parseLibrary(testFile);

      THEN("It should successfully parse the file") {
        REQUIRE(result.has_value());
        const auto &info = result.value();

        REQUIRE(info.path == testFile);
        REQUIRE(info.isDynamic == true);
        REQUIRE(info.architecture == "Advanced Micro Devices X86-64");

        REQUIRE(info.symbols.size() == 4); // Excluding entry 0

        // Check function1
        const auto &func1 = info.symbols[0];
        REQUIRE(func1.name == "function1");
        REQUIRE(func1.type == SymbolType::Function);
        REQUIRE(func1.isGlobal == true);
        REQUIRE(func1.size == 64);

        // Check variable1
        const auto &var1 = info.symbols[1];
        REQUIRE(var1.name == "variable1");
        REQUIRE(var1.type == SymbolType::Variable);
        REQUIRE(var1.size == 32);

        // Check external_func
        const auto &extFunc = info.symbols[2];
        REQUIRE(extFunc.name == "external_func");
        REQUIRE(extFunc.type == SymbolType::Undefined);

        // Check common_var
        const auto &commonVar = info.symbols[3];
        REQUIRE(commonVar.name == "common_var");
        REQUIRE(commonVar.type == SymbolType::Common);
        REQUIRE(commonVar.size == 16);
      }

      std::filesystem::remove(testFile);
    }
  }
}

SCENARIO("LibSymbolsApp can compare libraries", "[libsymbols]") {
  GIVEN("Two library infos with different symbols") {
    LibraryInfo lib1;
    lib1.symbols = {{"func1", SymbolType::Function, true, 0x1000, 64},
                    {"var1", SymbolType::Variable, true, 0x2000, 32},
                    {"old_func", SymbolType::Function, true, 0x3000, 128}};

    LibraryInfo lib2;
    lib2.symbols = {
        {"func1", SymbolType::Function, true, 0x1000, 64},    // unchanged
        {"var1", SymbolType::Variable, true, 0x2000, 64},     // modified size
        {"new_func", SymbolType::Function, true, 0x4000, 256} // new
    };

    LibSymbolsApp app;

    WHEN("Comparing the libraries") {
      auto result = app.compareLibraries(lib1, lib2);

      THEN("It should correctly identify changes") {
        REQUIRE(result.has_value());
        const auto &diff = result.value();

        REQUIRE(diff.common.size() == 1);
        REQUIRE(diff.common[0].name == "func1");

        REQUIRE(diff.modified.size() == 1);
        REQUIRE(diff.modified[0].name == "var1");

        REQUIRE(diff.removed.size() == 1);
        REQUIRE(diff.removed[0].name == "old_func");

        REQUIRE(diff.added.size() == 1);
        REQUIRE(diff.added[0].name == "new_func");
      }
    }
  }
}

SCENARIO("LibSymbolsApp can filter symbols", "[libsymbols]") {
  GIVEN("A library with various symbols") {
    LibraryInfo lib;
    lib.symbols = {{"func1", SymbolType::Function, true, 0x1000, 64},
                   {"var1", SymbolType::Variable, true, 0x2000, 32},
                   {"ext_func", SymbolType::Undefined, true, 0, 0},
                   {"local_var", SymbolType::Variable, false, 0x3000, 16}};

    LibSymbolsApp app;

    WHEN("Getting exported symbols") {
      auto exported = app.getExportedSymbols(lib);

      THEN("It should return only global, defined symbols") {
        REQUIRE(exported.size() == 2);
        REQUIRE(exported[0].name == "func1");
        REQUIRE(exported[1].name == "var1");
      }
    }

    WHEN("Getting imported symbols") {
      auto imported = app.getImportedSymbols(lib);

      THEN("It should return only undefined symbols") {
        REQUIRE(imported.size() == 1);
        REQUIRE(imported[0].name == "ext_func");
      }
    }
  }
}
