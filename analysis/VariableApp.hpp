#pragma once

#include "expected.hpp"
#include "types.hpp"

#include <string_view>

namespace diff_analysis {
class VariableApp {
private:
  auto getMap(const llvm::Module &currentModule) -> Variables;
  auto getVariables(llvm::LLVMContext &ctx, std::string_view ir_path)
      -> tl::expected<Variables, llvm::SMDiagnostic>;

public:
  auto
  run(std::string_view ir_path) -> tl::expected<Variables, llvm::SMDiagnostic>;
  auto diff(std::string_view previous_version_ir_path,
            std::string_view current_version_ir_path)
      -> tl::expected<Diffs, llvm::SMDiagnostic>;
};
} // namespace diff_analysis
