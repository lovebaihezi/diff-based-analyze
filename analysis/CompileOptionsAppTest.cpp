
#include "CompileOptionsApp.hpp"
#include "catch2/catch_test_macros.hpp"
#include <filesystem>

namespace diff_analysis {

TEST_CASE("CompileOptionsApp can parse compile commands and find libraries",
          "[compile_options]") {
  CompileOptionsApp app;

  auto cwd = std::filesystem::current_path();

  auto json_path = cwd / "build" / "compile_commands.json ";
  auto parse_result = app.parseCompileCommands(json_path.string());
  REQUIRE(parse_result);

  SECTION("Verify libgit2 linking") {
    // Get all linked libraries
    auto libraries = app.getLinkedLibraries();
    REQUIRE(libraries);
    REQUIRE_FALSE(libraries->empty());

    // Check if libgit2 is among the linked libraries
    bool found_git2 = false;
    for (const auto &lib : *libraries) {
      if (lib.name == "git2") {
        found_git2 = true;
        REQUIRE(std::filesystem::exists(lib.path));
        REQUIRE(lib.path.filename() == "libgit2.so");
        break;
      }
    }
    REQUIRE(found_git2);

    // Test getLibraryPaths specifically for libgit2
    auto git2_paths = app.getLibraryPaths("git2");
    REQUIRE(git2_paths);
    REQUIRE_FALSE(git2_paths->empty());
    REQUIRE(std::filesystem::exists((*git2_paths)[0]));
    REQUIRE((*git2_paths)[0].filename() == "libgit2.so");
  }
}

TEST_CASE("CompileOptionsApp handles missing files", "[compile_options]") {
  CompileOptionsApp app;

  SECTION("Non-existent file") {
    auto result = app.parseCompileCommands("nonexistent.json");
    REQUIRE_FALSE(result);
    REQUIRE_FALSE(result.error().message.empty());
  }
}

} // namespace diff_analysis
