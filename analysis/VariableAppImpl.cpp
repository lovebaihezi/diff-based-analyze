#include "App.hpp"
#include "VariableApp.hpp"
#include "expected.hpp"
#include "types.hpp"

#include <llvm/IR/Instruction.h>
#include <llvm/Support/SourceMgr.h>

#include "quill/LogMacros.h"

namespace diff_analysis {
auto VariableApp::getMap(const llvm::Module &currentModule) -> Variables {
  Variables variables;
  // Global variables
  // for (const auto &globalVariable : currentModule.globals()) {
  //   if (!globalVariable.getName().empty() && !globalVariable.isConstant() &&
  //       !globalVariable.getName().starts_with(".")) {
  //     variables.emplace(globalVariable.getName(), VariableInstMap{});
  //   }
  // }

  for (const auto &function : currentModule) {
    // Function arguments
    // for (const auto &functionArg : function.args()) {
    //   if (!functionArg.getName().empty() &&
    //       !functionArg.getName().starts_with(".")) {
    //     variables.emplace(functionArg.getName(), VariableInstMap{});
    //   }
    // }

    // Local variables and global variables
    for (const auto &basic_block : function) {
      for (const auto &inst : basic_block) {
        if (auto dbg = llvm::dyn_cast<llvm::DbgValueInst>(&inst)) {
          auto variable = dbg->getVariable();
          auto name = variable->getName();
          LOG_INFO(App::logger(),
                   "Add Variable from debug value instruction: {}", name.str());
          if (!name.empty() && !name.starts_with(".")) {
            auto nameStr = name.str();
            auto insts = VariableInstMap{};
            for (const auto &value : dbg->getValues()) {
              for (const auto &use : value->users()) {
                auto casted_inst = llvm::dyn_cast<llvm::Instruction>(use);
                insts.instructions.insert(casted_inst);
              }
            }
            variables.emplace(name, insts);
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
