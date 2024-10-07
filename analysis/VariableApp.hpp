#pragma once

#include "expected.hpp"
#include "types.hpp"

#include <string_view>

namespace diff_analysis {
class VariableApp {
public:
  auto
  run(std::string_view ir_path) -> tl::expected<Variables, llvm::SMDiagnostic>;

private:
  auto getMap(const llvm::Module &currentModule) -> Variables;
};
} // namespace diff_analysis
