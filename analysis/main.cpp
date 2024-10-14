#include "argparse.hpp"

#include <cassert>
#include <llvm/ADT/MapVector.h>
#include <llvm/ADT/SetVector.h>
#include <llvm/ADT/SmallVector.h>
#include <llvm/ADT/StringRef.h>
#include <llvm/IR/Instruction.h>
#include <memory>

#include "llvm/IR/DebugInfo.h"
#include "llvm/IR/DebugInfoMetadata.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Support/SourceMgr.h"

struct VariableInstMap {
  llvm::StringRef variableName{};
  std::vector<llvm::Instruction *> instructions{};

  ~VariableInstMap() {
  }
};

using Variables = std::vector<VariableInstMap>;

auto variables(const llvm::Module &M) -> Variables {
  Variables variables;
  // Global variables
  for (const auto &globalVariable : M.globals()) {
    if (!globalVariable.getName().empty()) {
      variables.emplace_back(
          VariableInstMap{.variableName = globalVariable.getName()});
    }
  }

  for (const auto &F : M) {
    // Function arguments
    for (const auto &Arg : F.args()) {
      if (!Arg.getName().empty()) {
        variables.emplace_back(VariableInstMap{.variableName = Arg.getName()});
      }
    }

    // Local variables and global variables
    for (const auto &BB : F) {
      for (const auto &I : BB) {
        if (auto dbg = llvm::dyn_cast<llvm::DbgValueInst>(&I)) {
          auto name = dbg->getVariable()->getName();
          if (!name.empty()) {
            variables.emplace_back(VariableInstMap{.variableName = name});
          }
        }
      }
    }
  }

  return variables;
}

int main(int argc, char **argv) {
  argparse::ArgumentParser program("variables");

  program.add_argument("project")
      .help("The path to the project for analysis")
      .default_value(std::string());

  program.parse_args(argc, argv);

  llvm::SMDiagnostic Err;
  llvm::LLVMContext Context;
  std::unique_ptr<llvm::Module> module =
      llvm::parseIRFile(program.get<std::string>("project"), Err, Context);

  if (!module) {
    Err.print(argv[0], llvm::errs());
    return 1;
  }

  auto variableNames = variables(*module);

  return 0;
}
