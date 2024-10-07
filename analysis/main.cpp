#include <iostream>
#include <memory>
#include <string>
#include <vector>

#include "llvm/IR/DebugInfo.h"
#include "llvm/IR/DebugInfoMetadata.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"

std::vector<std::string> getVariableNames(const llvm::Module &M) {
  std::vector<std::string> variableNames;

  for (const auto &F : M) {
    // Function arguments
    for (const auto &Arg : F.args()) {
      if (!Arg.getName().empty()) {
        variableNames.push_back(Arg.getName().str());
      }
    }

    // Local variables and global variables
    for (const auto &BB : F) {
      for (const auto &I : BB) {
        if (auto dbg = llvm::dyn_cast<llvm::DbgValueInst>(&I)) {
          auto name = dbg->getVariable()->getName();
          if (!name.empty()) {
            variableNames.push_back(name.str());
          }
        }
      }
    }
  }

  // Global variables
  for (const auto &GV : M.globals()) {
    if (!GV.getName().empty()) {
      variableNames.push_back(GV.getName().str());
    }
  }

  return variableNames;
}

int main(int argc, char **argv) {
  if (argc < 2) {
    std::cerr << "Usage: " << argv[0] << " <IR file>\n";
    return 1;
  }

  llvm::SMDiagnostic Err;
  llvm::LLVMContext Context;
  std::unique_ptr<llvm::Module> M = llvm::parseIRFile(argv[1], Err, Context);

  if (!M) {
    Err.print(argv[0], llvm::errs());
    return 1;
  }

  std::vector<std::string> variableNames = getVariableNames(*M);

  std::cout << "Variable names found:\n";
  for (const auto &name : variableNames) {
    std::cout << name << "\n";
  }

  return 0;
}
