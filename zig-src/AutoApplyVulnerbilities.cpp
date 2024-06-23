#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/raw_ostream.h"

auto main() -> int {
    // Create an LLVM context
    llvm::LLVMContext context;

    // Read the LLVM IR from stdin
    llvm::SMDiagnostic err;
    auto buffer = llvm::MemoryBuffer::getSTDIN();
    if (!buffer) {
        llvm::errs() << "Error reading from stdin\n";
        return 1;
    }

    // Parse the memory buffer into an LLVM module
    auto module = llvm::parseIR(*buffer->get(), err, context);
    if (!module) {
        err.print("llvm-read-stdin", llvm::errs());
        return 1;
    }

    // Iterate over the functions in the module
    for (auto &func : *module) {
        llvm::outs() << "Function: " << func.getName() << "\n";
        for (auto &bb : func) {
            for (auto &inst : bb) {
                llvm::outs() << inst << "\n";
            }
        }
    }

    return 0;
}
