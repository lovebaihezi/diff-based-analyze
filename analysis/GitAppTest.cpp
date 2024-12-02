#include "catch2/catch_test_macros.hpp"
#include "git2/refs.h"

#include "GitApp.hpp"

#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <string>

namespace diff_analysis {
namespace fs = std::filesystem;

class TestSetup {
public:
  static void setup_test_repo() {
    // Create test directory
    fs::create_directory("diff-based-analysis-test");

    // Copy initial file
    std::ifstream src("tests/challenges-a/add_inst-before.c", std::ios::binary);
    std::ofstream dst("diff-based-analysis-test/main.c", std::ios::binary);
    dst << src.rdbuf();
    src.close();
    dst.close();

    // Initialize git repo and make first commit
    std::system("cd diff-based-analysis-test && git init && git add main.c && "
                "git commit -m \"Initial commit\"");
  }

  static void update_test_file() {
    // Copy updated file
    std::ifstream src("tests/challenges-a/add_inst-after.c", std::ios::binary);
    std::ofstream dst("diff-based-analysis-test/main.c", std::ios::binary);
    dst << src.rdbuf();
    src.close();
    dst.close();

    // Commit changes
    std::system("cd diff-based-analysis-test && git add main.c && git commit "
                "-m \"Update main.c\"");
  }

  static void cleanup() { fs::remove_all("diff-based-analysis-test"); }
};

TEST_CASE("GitApp initialization and basic operations", "[gitapp]") {
  TestSetup::setup_test_repo();

  SECTION("Repository initialization") {
    auto repo = diff_analysis::Repo::init("diff-based-analysis-test");
    REQUIRE(repo.has_value());

    auto app = diff_analysis::GitApp::init(std::move(repo.value()));
    REQUIRE(app != nullptr);
    REQUIRE(app->get_repo() != nullptr);
  }

  SECTION("HEAD reference") {
    auto repo = diff_analysis::Repo::init("diff-based-analysis-test").value();
    auto app = diff_analysis::GitApp::init(std::move(repo));

    auto head_ref = app->head();
    REQUIRE(head_ref.has_value());
    REQUIRE(head_ref.value() != nullptr);

    git_reference_free(head_ref.value());
  }

  SECTION("First commit") {
    auto repo = diff_analysis::Repo::init("diff-based-analysis-test").value();
    auto app = diff_analysis::GitApp::init(std::move(repo));

    auto first = app->first_commit();
    REQUIRE(first.has_value());
    REQUIRE(first.value() != nullptr);

    git_object_free(first.value());
  }

  SECTION("Commit lookup and tree operations") {
    auto repo = diff_analysis::Repo::init("diff-based-analysis-test").value();
    auto app = diff_analysis::GitApp::init(std::move(repo));

    // Get HEAD reference
    auto head_ref = app->head().value();
    const git_oid *head_oid = git_reference_target(head_ref);

    // Look up commit
    auto commit_result = app->commit(head_oid);
    REQUIRE(commit_result.has_value());

    // Get commit tree
    auto tree_result = app->commit_tree(commit_result.value());
    REQUIRE(tree_result.has_value());

    // Look up main.c in tree
    auto entry_result = app->tree_entry_byname(tree_result.value(), "main.c");
    REQUIRE(entry_result.has_value());

    // Cleanup
    git_tree_free(tree_result.value());
    git_commit_free(commit_result.value());
    git_reference_free(head_ref);
  }

  SECTION("Test with updated file") {
    TestSetup::update_test_file();

    auto repo = diff_analysis::Repo::init("diff-based-analysis-test").value();
    auto app = diff_analysis::GitApp::init(std::move(repo));

    // Verify HEAD reference after update
    auto head_ref = app->head();
    REQUIRE(head_ref.has_value());

    // Check commit and tree operations with updated file
    const git_oid *head_oid = git_reference_target(head_ref.value());
    auto commit_result = app->commit(head_oid);
    REQUIRE(commit_result.has_value());

    auto tree_result = app->commit_tree(commit_result.value());
    REQUIRE(tree_result.has_value());

    auto entry_result = app->tree_entry_byname(tree_result.value(), "main.c");
    REQUIRE(entry_result.has_value());

    // Cleanup
    git_tree_free(tree_result.value());
    git_commit_free(commit_result.value());
    git_reference_free(head_ref.value());
  }

  // Cleanup
  TestSetup::cleanup();
}
} // namespace diff_analysis
