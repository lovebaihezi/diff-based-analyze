#pragma once

#include "App.hpp"
#include "quill/LogMacros.h"
#include <cassert>
#include <llvm/ADT/MapVector.h>
#include <llvm/ADT/SetVector.h>
#include <llvm/ADT/SmallVector.h>
#include <llvm/ADT/StringRef.h>
#include <llvm/IR/DebugInfo.h>
#include <llvm/IR/DebugInfoMetadata.h>
#include <llvm/IR/Function.h>
#include <llvm/IR/Instruction.h>
#include <llvm/IR/Instructions.h>
#include <llvm/IR/Module.h>
#include <llvm/IRReader/IRReader.h>
#include <llvm/Support/SourceMgr.h>

#include <map>
#include <optional>
#include <set>
#include <span>
#include <string_view>

namespace diff_analysis {
struct Delta {
  std::string var_name;
  std::vector<const llvm::Instruction *> insts;
  // [0..split_index) means removed insts, [split_index..end) means added insts
  std::size_t split_index;
};
class Diffs {
private:
  using Rel = std::vector<
      std::pair<std::optional<std::string>, std::optional<std::string>>>;

  Rel nameChanges;
  std::vector<Delta> deltas;

public:
  auto getNameChanges() -> Rel & { return nameChanges; }
  auto getAdds(std::string_view key)
      -> std::optional<std::span<const llvm::Instruction *>> {
    auto it = std::find_if(std::begin(deltas), std::end(deltas),
                           [key](const auto &d) { return d.var_name == key; });
    if (it == std::end(deltas)) {
      return {};
    } else {
      auto begin = std::begin(it->insts);
      auto end = std::end(it->insts);
      return std::span(begin + it->split_index, end);
    }
  }
  auto getChangedVariablesNames() -> std::vector<std::string_view> {
    std::vector<std::string_view> res;
    for (const auto &delta : deltas) {
      res.push_back(delta.var_name);
    }
    return res;
  }
  auto getRemoves(std::string_view key)
      -> std::optional<std::span<const llvm::Instruction *>> {
    auto it = std::find_if(std::begin(deltas), std::end(deltas),
                           [key](const auto &d) { return d.var_name == key; });
    if (it == std::end(deltas)) {
      return {};
    } else {
      auto begin = std::begin(it->insts);
      auto end = std::end(it->insts);
      return std::span(begin, begin + it->split_index);
    }
  }
  auto insertChanges(const std::string &&old,
                     const std::string &&new_name) -> void {
    nameChanges.emplace_back(old, new_name);
  }
  auto insertRemoved(const std::string &&var_name,
                     const llvm::Instruction *inst) -> void {
    auto it = std::find_if(
        std::begin(deltas), std::end(deltas),
        [var_name](const auto &d) { return d.var_name == var_name; });
    if (it == std::end(deltas)) {
      deltas.push_back({var_name, {inst}, 0});
    } else {
      it->insts.push_back(inst);
    }
  }
  auto insertAdded(const std::string &&var_name,
                   const llvm::Instruction *inst) -> void {}
};
class VariableInstMap {
private:
  std::set<llvm::Instruction *> instructions{};

public:
  using iterator = decltype(instructions)::iterator;
  using const_iterator = decltype(instructions)::const_iterator;
  using size_type = decltype(instructions)::size_type;
  using value_type = decltype(instructions)::value_type;
  using reference = decltype(instructions)::reference;
  using const_reference = decltype(instructions)::const_reference;

  auto begin() -> iterator { return instructions.begin(); }
  auto end() -> iterator { return instructions.end(); }
  auto begin() const -> const_iterator { return instructions.begin(); }
  auto end() const -> const_iterator { return instructions.end(); }
  auto cbegin() const -> const_iterator { return instructions.cbegin(); }
  auto cend() const -> const_iterator { return instructions.cend(); }
  auto size() const -> size_type { return instructions.size(); }
  auto empty() const -> bool { return instructions.empty(); }
  auto find(const value_type &value) -> iterator {
    return instructions.find(value);
  }
  auto find(const value_type &value) const -> const_iterator {
    return instructions.find(value);
  }
  auto count(const value_type &value) const -> size_type {
    return instructions.count(value);
  }
  auto insert(const value_type &value) -> std::pair<iterator, bool> {
    return instructions.insert(value);
  }
  auto emplace(const value_type &value) -> std::pair<iterator, bool> {
    return instructions.emplace(value);
  }
  auto erase(const value_type &value) -> size_type {
    return instructions.erase(value);
  }
  auto clear() -> void { instructions.clear(); }
};

class Variables {
private:
  std::map<std::string, VariableInstMap> inner;

public:
  using iterator = decltype(inner)::iterator;
  using const_iterator = decltype(inner)::const_iterator;
  using size_type = decltype(inner)::size_type;
  using value_type = decltype(inner)::value_type;
  using key_type = decltype(inner)::key_type;
  using mapped_type = decltype(inner)::mapped_type;
  using reference = decltype(inner)::reference;
  using const_reference = decltype(inner)::const_reference;

  auto begin() -> iterator { return inner.begin(); }
  auto end() -> iterator { return inner.end(); }
  auto begin() const -> const_iterator { return inner.begin(); }
  auto end() const -> const_iterator { return inner.end(); }
  auto cbegin() const -> const_iterator { return inner.cbegin(); }
  auto cend() const -> const_iterator { return inner.cend(); }
  auto size() const -> size_type { return inner.size(); }
  auto empty() const -> bool { return inner.empty(); }
  auto find(const key_type &key) -> iterator { return inner.find(key); }
  auto at(const key_type &key) -> VariableInstMap & { return inner.at(key); }
  auto at(const key_type &key) const -> const VariableInstMap & {
    return inner.at(key);
  }
  auto find(const key_type &key) const -> const_iterator {
    return inner.find(key);
  }
  auto count(const key_type &key) const -> size_type {
    return inner.count(key);
  }
  auto insert(const value_type &value) -> std::pair<iterator, bool> {
    return inner.insert(value);
  }
  template <typename... Args>
  auto emplace(Args &&...args) -> std::pair<iterator, bool> {
    return inner.emplace(std::forward<Args>(args)...);
  }
  auto erase(const key_type &key) -> size_type { return inner.erase(key); }
  auto clear() -> void { inner.clear(); }
  auto operator[](const std::string &key) -> const VariableInstMap & {
    return inner[key];
  }

  auto operator-(const Variables &rhs) const -> Diffs {
    Diffs diff;
    auto keys = std::vector<std::reference_wrapper<const std::string>>{};
    for (const auto &[k, v] : inner) {
      keys.push_back(std::ref(k));
    }
    for (auto i = 0; i < keys.size(); i += 1) {
      const auto &left_key = keys[i];
      // Name Not changed, inst got changed
      // TODO: Not only name, but also bb, function
      const auto &[_left_key, left_value] = *inner.find(left_key);
      auto rhs_iter = rhs.inner.find(left_key);
      if (rhs_iter != rhs.inner.end()) {
        for (const auto &left_inst : left_value) {
          // inst that occurs in left but not in right, which means it got
          // removed
          auto is_removed = true;
          for (const auto &right_inst : rhs.inner.at(left_key)) {
            if (left_inst->isSameOperationAs(right_inst)) {
              is_removed = false;
            }
          }
          if (is_removed) {
            const std::string copied_key = left_key;
            diff.insertRemoved(std::move(copied_key), left_inst);
          }
        }
        // inst that occurs in right but not in left, which means it got added
        for (const auto &right_inst : rhs.inner.at(left_key)) {
          auto is_added = true;
          for (const auto &left_inst : left_value) {
            assert(left_inst != nullptr);
            if (right_inst->isSameOperationAs(left_inst)) {
              is_added = false;
              break;
            }
          }
          if (is_added) {
            const std::string copied_key = left_key;
            diff.insertAdded(std::move(copied_key), right_inst);
          }
        }
      } else {
        LOG_WARNING(App::logger(),
                    "TODO: Got Variable from right not exists in left");
        // TODO
        // Name Changed or Variable added/deleted
        // for (const auto &[rhs_k, rhs_v] : rhs.inner) {
        //   for (const auto &rhs_inst : rhs_v) {
        //     for (const auto &left_inst : left_value) {
        //     }
        //   }
        // }
      }
    }
    return diff;
  }
};
} // namespace diff_analysis
