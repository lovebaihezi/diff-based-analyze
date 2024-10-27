#pragma once

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
#include <set>

namespace diff_analysis {
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
  auto find(const key_type &key) const -> const_iterator {
    return inner.find(key);
  }
  auto count(const key_type &key) const -> size_type {
    return inner.count(key);
  }
  auto insert(const value_type &value) -> std::pair<iterator, bool> {
    return inner.insert(value);
  }
  auto emplace(const value_type &value) -> std::pair<iterator, bool> {
    return inner.emplace(value);
  }
  auto erase(const key_type &key) -> size_type { return inner.erase(key); }
  auto clear() -> void { inner.clear(); }
};
} // namespace diff_analysis
