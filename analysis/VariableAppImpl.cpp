#include "App.hpp"
#include "VariableApp.hpp"
#include "expected.hpp"
#include "types.hpp"

#include <llvm/IR/Instruction.h>
#include <llvm/Support/SourceMgr.h>

#include "quill/LogMacros.h"
#include "llvm/IR/DebugProgramInstruction.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Support/Casting.h"

namespace diff_analysis {
auto VariableApp::getMap(const llvm::Module &currentModule) -> Variables {
  Variables variables;
  for (const auto &global_var : currentModule.globals()) {
    if (!global_var.getName().empty() && !global_var.isConstant() &&
        !global_var.getName().starts_with(".")) {
      variables.emplace(global_var.getName(), VariableInstMap{});
    }
  }

  for (const auto &function : currentModule) {
    for (const auto &function_arg : function.args()) {
      if (!function_arg.getName().empty() &&
          !function_arg.getName().starts_with(".")) {
        variables.emplace(function_arg.getName(), VariableInstMap{});
      }
    }

    // Local variables and global variables
    for (const auto &basic_block : function) {
      for (const auto &inst : basic_block) {
        for (llvm::DbgVariableRecord &dvr :
             llvm::filterDbgVars(inst.getDbgRecordRange())) {
          auto variable = dvr.getVariable();
          if (dvr.isDbgValue()) {
            auto value = dvr.getValue();
            auto variableName = variable->getName();
            if (!variableName.empty() && !variableName.starts_with(".")) {
              auto name_str = variableName.str();
              auto insts = VariableInstMap{};

              for (const auto &user : value->users()) {
                if (auto inst = llvm::cast<llvm::Instruction>(user)) {
                  insts.emplace(inst);
                }
              }
              variables.emplace(variableName, insts);
            }
          }
        }
      }
    }
  }
  return variables;
}

auto VariableApp::run(std::string_view ir_path)
    -> tl::expected<Variables, llvm::SMDiagnostic> {
  llvm::SMDiagnostic err;
  llvm::LLVMContext ctx;
  std::unique_ptr<llvm::Module> module = llvm::parseIRFile(ir_path, err, ctx);

  if (!module) {
    LOG_CRITICAL(App::logger(), "FAILED TO PARSE MODULE FROM IR FILE: {}",
                 ir_path);
    return tl::unexpected{err};
  } else {
    auto variableNames = getMap(*module);
    return variableNames;
  }
}
} // namespace diff_analysis
