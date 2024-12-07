#pragma once

#include "expected.hpp"
#include "rust.hpp"

#include "git2/diff.h"
#include "git2/errors.h"
#include "git2/repository.h"
#include "git2/tree.h"
#include "git2/types.h"

#include <cstdio>
#include <exception>
#include <memory>
#include <string_view>

namespace diff_analysis {
class Repo {
private:
public:
  git_repository *ptr = nullptr;

  Repo() = default;

  static auto init(std::string_view repo_path)
      -> tl::expected<Box<Repo>, const git_error *> {
    Repo repo{};
    int open_ret = 0;

    if (repo_path.empty()) {
      open_ret = git_repository_open(&repo.ptr, ".");
    } else {
      if (*repo_path.end() != '\0') {
        fprintf(stderr, "repo_path must be null-terminated\n");
        std::terminate();
      } else {
        open_ret = git_repository_open(&repo.ptr, repo_path.data());
      }
    }

    if (open_ret != 0) {
      const auto *err = git_error_last();
      return tl::unexpected{err};
    }

    return std::make_unique<Repo>(repo);
  }

  static auto close(Box<Repo> &&repo) -> void {
    git_repository_free(repo->ptr);
  }

  ~Repo() = default;
};

class GitApp final {
private:
  Box<Repo> repo;

public:
  static auto init(Box<Repo> &&repo) -> Box<GitApp>;
  static auto shutdown(Box<GitApp> &&app) -> void;

  // Get HEAD reference
  auto head() const -> tl::expected<git_reference *, const git_error *>;

  // Get first commit
  auto first_commit() const -> tl::expected<git_object *, const git_error *>;

  // Look up a commit by its id
  auto commit(const git_oid *commit_id) const
      -> tl::expected<git_commit *, const git_error *>;

  // Get the tree from a commit
  auto commit_tree(git_commit *commit) const
      -> tl::expected<git_tree *, const git_error *>;

  // Look up tree entry by name
  auto tree_entry_byname(git_tree *tree, const char *filename) const
      -> tl::expected<const git_tree_entry *, const git_error *>;

  // Repo ptr
  auto get_repo() const -> git_repository *;

  ~GitApp() = default;
};

class GitTree final {
private:
  git_tree *tree_ = nullptr;

public:
  GitTree() = default;
  explicit GitTree(git_tree *tree);
  GitTree(GitTree &&other) noexcept;
  GitTree &operator=(GitTree &&other) noexcept;

  auto entry_bypath(const char *path) const
      -> tl::expected<const git_tree_entry *, const git_error *>;
  auto entry_byindex(size_t idx) const
      -> tl::expected<const git_tree_entry *, const git_error *>;
  auto entry_byname(const char *filename) const
      -> tl::expected<const git_tree_entry *, const git_error *>;
  auto entrycount() const -> size_t;

  template <typename F>
  auto walk(git_treewalk_mode mode,
            F &&callback) const -> tl::expected<void, const git_error *>;

  auto diff_tree(const GitTree *new_tree, git_repository *repo) const
      -> tl::expected<git_diff *, const git_error *>;

  auto get() const -> git_tree *;

  static auto entry_dup(const git_tree_entry *entry)
      -> tl::expected<git_tree_entry *, const git_error *>;
  static auto entry_free(git_tree_entry *entry) -> void;

  ~GitTree();

  GitTree(const GitTree &) = delete;
  GitTree &operator=(const GitTree &) = delete;
};

} // namespace diff_analysis
