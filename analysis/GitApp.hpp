#pragma once

#include "expected.hpp"
#include "rust.hpp"

#include "git2/errors.h"
#include "git2/repository.h"
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

class GitApp {
private:
  Box<Repo> repo;

public:
  static auto init(Box<Repo> &&repo) -> Box<GitApp> { std::terminate(); }
  static auto shutdown(Box<GitApp> &&app) -> void {
    Repo::close(std::move(app->repo));
  }

  ~GitApp() = default;
};
} // namespace diff_analysis
