#pragma once

#include "expected.hpp"
#include "rust.hpp"
#include "types.hpp"
#include "llvm/IR/LLVMContext.h"

#include <string_view>

namespace diff_analysis {
class VariableApp {
private:
  auto getMap(const llvm::Module &currentModule) -> Variables;
  auto getVariables(llvm::LLVMContext &ctx, std::string_view ir_path)
      -> tl::expected<std::tuple<Variables, Box<llvm::Module>>,
                      llvm::SMDiagnostic>;

public:
  auto run(llvm::LLVMContext &ctx, std::string_view ir_path)
      -> tl::expected<std::tuple<Variables, Box<llvm::Module>>,
                      llvm::SMDiagnostic>;
};
} // namespace diff_analysis
