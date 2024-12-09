
#include "GitApp.hpp"
#include "catch2/catch_test_macros.hpp"
#include "git2/refs.h"
#include "uuidv4.hpp"

#include <cstdlib>
#include <filesystem>
#include <fstream>

namespace diff_analysis {
namespace fs = std::filesystem;

class TestSetup {
private:
  fs::path temp_dir_;
  fs::path test_dir_;

public:
  TestSetup() {
    // Create temporary directory
    UUID uuid = UUID::generate();
    std::string unique_id = uuid.toString();

    // Create temporary directory with UUID
    temp_dir_ = fs::temp_directory_path() / ("git-analysis-test-" + unique_id);
    fs::create_directory(temp_dir_);
    // Create test directory inside temp directory
    test_dir_ = temp_dir_ / "diff-based-analysis-test";
  }

  ~TestSetup() { cleanup(); }

  void setup_test_repo() {
    // Create test directory
    fs::create_directory(test_dir_);

    // Copy initial file
    fs::path src_path =
        fs::current_path() / "tests/challenges-a/add_inst-before.c";
    fs::path dst_path = test_dir_ / "main.c";

    std::ifstream src(src_path, std::ios::binary);
    std::ofstream dst(dst_path, std::ios::binary);
    dst << src.rdbuf();
    src.close();
    dst.close();

    // Initialize git repo and make first commit
    std::string cmd =
        "cd " + test_dir_.string() +
        " && git init && git add main.c && git commit -m \"Initial commit\"";
    std::system(cmd.c_str());
  }

  void update_test_file() {
    // Copy updated file
    fs::path src_path =
        fs::current_path() / "tests/challenges-a/add_inst-after.c";
    fs::path dst_path = test_dir_ / "main.c";

    std::ifstream src(src_path, std::ios::binary);
    std::ofstream dst(dst_path, std::ios::binary);
    dst << src.rdbuf();
    src.close();
    dst.close();

    // Commit changes
    std::string cmd = "cd " + test_dir_.string() +
                      " && git add main.c && git commit -m \"Update main.c\"";
    std::system(cmd.c_str());
  }

  void cleanup() {
    if (fs::exists(temp_dir_)) {
      fs::remove_all(temp_dir_);
    }
  }

  fs::path get_test_dir() const { return test_dir_; }
};

TEST_CASE("GitApp initialization and basic operations", "[gitapp]") {
  TestSetup test_setup;
  test_setup.setup_test_repo();

  SECTION("Repository initialization") {
    auto repo = diff_analysis::Repo::init(test_setup.get_test_dir().string());
    REQUIRE(repo.has_value());

    auto app = diff_analysis::GitApp::init(std::move(repo.value()));
    REQUIRE(app != nullptr);
    REQUIRE(app->get_repo() != nullptr);
  }

  SECTION("HEAD reference") {
    auto repo =
        diff_analysis::Repo::init(test_setup.get_test_dir().string()).value();
    auto app = diff_analysis::GitApp::init(std::move(repo));

    auto head_ref = app->head();
    REQUIRE(head_ref.has_value());
    REQUIRE(head_ref.value() != nullptr);

    git_reference_free(head_ref.value());
  }

  SECTION("First commit") {
    auto repo =
        diff_analysis::Repo::init(test_setup.get_test_dir().string()).value();
    auto app = diff_analysis::GitApp::init(std::move(repo));

    auto first = app->first_commit();
    REQUIRE(first.has_value());
    REQUIRE(first.value() != nullptr);

    git_object_free(first.value());
  }

  SECTION("Commit lookup and tree operations") {
    auto repo =
        diff_analysis::Repo::init(test_setup.get_test_dir().string()).value();
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
    test_setup.update_test_file();

    auto repo =
        diff_analysis::Repo::init(test_setup.get_test_dir().string()).value();
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
}
} // namespace diff_analysis
