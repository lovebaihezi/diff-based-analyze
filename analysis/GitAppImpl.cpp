#include "GitApp.hpp"

#include "git2/commit.h"
#include "git2/errors.h"
#include "git2/global.h"
#include "git2/revparse.h"
#include "git2/tree.h"

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

} // namespace diff_analysis
