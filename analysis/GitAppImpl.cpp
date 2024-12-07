#include "GitApp.hpp"

#include "git2/commit.h"
#include "git2/errors.h"
#include "git2/global.h"
#include "git2/revparse.h"
#include "git2/tree.h"
#include <git2/types.h>

namespace diff_analysis {

auto GitApp::init(Box<Repo> &&repo) -> Box<GitApp> {
  // Initialize libgit2
  git_libgit2_init();

  // Create new GitApp instance
  auto app = std::make_unique<GitApp>();
  app->repo = std::move(repo);
  return app;
}

auto GitApp::shutdown(Box<GitApp> &&app) -> void {
  // Clean up repository
  Repo::close(std::move(app->repo));

  // Shutdown libgit2
  git_libgit2_shutdown();
}

auto GitApp::head() const -> tl::expected<git_reference *, const git_error *> {
  git_reference *ref = nullptr;
  int error = git_repository_head(&ref, repo->ptr);

  if (error != 0) {
    return tl::unexpected{git_error_last()};
  }
  return ref;
}

// 2. Implement first_commit() function
auto GitApp::first_commit() const
    -> tl::expected<git_object *, const git_error *> {
  git_object *obj = nullptr;
  int error = git_revparse_single(&obj, repo->ptr, "HEAD^{commit}");

  if (error != 0) {
    return tl::unexpected{git_error_last()};
  }
  return obj;
}

// 3. Implement commit() function
auto GitApp::commit(const git_oid *commit_id) const
    -> tl::expected<git_commit *, const git_error *> {
  git_commit *commit = nullptr;
  int error = git_commit_lookup(&commit, repo->ptr, commit_id);

  if (error != 0) {
    return tl::unexpected{git_error_last()};
  }
  return commit;
}

// 4. Implement commit_tree() function
auto GitApp::commit_tree(git_commit *commit) const
    -> tl::expected<git_tree *, const git_error *> {
  git_tree *tree = nullptr;
  int error = git_commit_tree(&tree, commit);

  if (error != 0) {
    return tl::unexpected{git_error_last()};
  }
  return tree;
}

// 5. Implement tree_entry_byname() function
auto GitApp::tree_entry_byname(git_tree *tree, const char *filename) const
    -> tl::expected<const git_tree_entry *, const git_error *> {
  const git_tree_entry *entry = git_tree_entry_byname(tree, filename);

  if (entry == nullptr) {
    return tl::unexpected{git_error_last()};
  }
  return entry;
}

auto GitApp::get_repo() const -> git_repository * { return repo->ptr; }

GitTree::GitTree(git_tree *tree) : tree_(tree) {}

GitTree::GitTree(GitTree &&other) noexcept : tree_(other.tree_) {
  other.tree_ = nullptr;
}

GitTree &GitTree::operator=(GitTree &&other) noexcept {
  if (this != &other) {
    if (tree_)
      git_tree_free(tree_);
    tree_ = other.tree_;
    other.tree_ = nullptr;
  }
  return *this;
}

auto GitTree::entry_bypath(const char *path) const
    -> tl::expected<const git_tree_entry *, const git_error *> {
  git_tree_entry *entry = nullptr;
  int error = git_tree_entry_bypath(&entry, tree_, path);
  if (error < 0) {
    return tl::unexpected{git_error_last()};
  }
  return entry;
}

auto GitTree::entry_byindex(size_t idx) const
    -> tl::expected<const git_tree_entry *, const git_error *> {
  const git_tree_entry *entry = git_tree_entry_byindex(tree_, idx);
  if (!entry) {
    return tl::unexpected{git_error_last()};
  }
  return entry;
}

auto GitTree::entry_byname(const char *filename) const
    -> tl::expected<const git_tree_entry *, const git_error *> {
  const git_tree_entry *entry = git_tree_entry_byname(tree_, filename);
  if (!entry) {
    return tl::unexpected{git_error_last()};
  }
  return entry;
}

auto GitTree::entrycount() const -> size_t {
  return git_tree_entrycount(tree_);
}

auto GitTree::diff_tree(const GitTree *new_tree, git_repository *repo) const
    -> tl::expected<git_diff *, const git_error *> {
  git_diff *diff = nullptr;
  int error = git_diff_tree_to_tree(
      &diff, repo, tree_, new_tree ? new_tree->tree_ : nullptr, nullptr);
  if (error < 0) {
    return tl::unexpected{git_error_last()};
  }
  return diff;
}

auto GitTree::get() const -> git_tree * { return tree_; }

auto GitTree::entry_dup(const git_tree_entry *entry)
    -> tl::expected<git_tree_entry *, const git_error *> {
  git_tree_entry *new_entry = nullptr;
  int error = git_tree_entry_dup(&new_entry, entry);
  if (error < 0) {
    return tl::unexpected{git_error_last()};
  }
  return new_entry;
}

auto GitTree::entry_free(git_tree_entry *entry) -> void {
  git_tree_entry_free(entry);
}

GitTree::~GitTree() {
  if (tree_)
    git_tree_free(tree_);
}

} // namespace diff_analysis
