#include "App.hpp"
#include "VariableApp.hpp"
#include "expected.hpp"
#include "quill/LogMacros.h"
#include "types.hpp"

#include "llvm/IR/DebugProgramInstruction.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/SourceMgr.h"
#include <string_view>
#include <tuple>

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

auto VariableApp::getVariables(llvm::LLVMContext &ctx, std::string_view ir_path)
    -> tl::expected<std::tuple<Variables, Box<llvm::Module>>, llvm::SMDiagnostic> {
  llvm::SMDiagnostic err;
  std::unique_ptr<llvm::Module> module = llvm::parseIRFile(ir_path, err, ctx);

  if (!module) {
    LOG_CRITICAL(App::logger(), "FAILED TO PARSE MODULE FROM IR FILE: {}",
                 ir_path);
    return tl::unexpected{err};
  } else {
    auto variableNames = getMap(*module);
    return std::make_tuple(variableNames, std::move(module));
  }
}

auto VariableApp::run(llvm::LLVMContext& ctx, std::string_view ir_path)
    -> tl::expected<std::tuple<Variables, Box<llvm::Module>>, llvm::SMDiagnostic> {
  llvm::SMDiagnostic err;
  std::unique_ptr<llvm::Module> module = llvm::parseIRFile(ir_path, err, ctx);

  if (!module) {
    LOG_CRITICAL(App::logger(), "FAILED TO PARSE MODULE FROM IR FILE: {}",
                 ir_path);
    return tl::unexpected{err};
  } else {
    auto variableNames = getMap(*module);
    return std::make_tuple(variableNames, std::move(module));
  }
}

auto VariableApp::diff(llvm::LLVMContext& ctx, std::string_view previous_ir_path,
                       std::string_view current_ir_path)
    -> tl::expected<Diffs, llvm::SMDiagnostic> {

  auto previous_variables = getVariables(ctx, previous_ir_path);
  auto current_variables = getVariables(ctx, current_ir_path);

  if (!previous_variables) {
    return tl::unexpected{previous_variables.error()};
  }

  if (!current_variables) {
    return tl::unexpected{current_variables.error()};
  }

  auto&& [previous, prev_m] = previous_variables.value();
  auto&& [current, cur_m] = current_variables.value();

  return previous - current;
}
} // namespace diff_analysis
