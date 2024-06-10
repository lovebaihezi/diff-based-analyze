#include <clang/Basic/DiagnosticOptions.h>
#include <clang/CodeGen/CodeGenAction.h>
#include <clang/Frontend/CompilerInstance.h>
#include <clang/Frontend/TextDiagnosticPrinter.h>
#include <clang/Lex/PreprocessorOptions.h>
#include <llvm/IR/Module.h>
#include <llvm/Support/Host.h>
#include <llvm/Support/TargetSelect.h>
#include <string>
#include "compile2ir.h"

using namespace clang;
using namespace llvm;

struct IRResult {
  std::string *data;
  IRResult() { this->data = new std::string(); }
  ~IRResult() {
    if (this->data) {
      delete data;
    }
  }
};

extern "C" void decomposeIRResult(IRResult *res) { delete res; }

extern "C" const char* getIR(IRResult *res) {
  if (res == nullptr || res->data == nullptr) {
    return nullptr;
  }
  return res->data->c_str();
}

extern "C" const IRResult *compileC2IR(const char *code_input, size_t len,
                                       size_t *output_len) {
  auto *file_name = "temp.c";
  // Setup custom diagnostic options.
  IntrusiveRefCntPtr<DiagnosticOptions> diag_opts(new DiagnosticOptions());
  diag_opts->ShowColors = 1;

  // Setup custom diagnostic consumer.
  std::unique_ptr<DiagnosticConsumer> diag_print =
      std::make_unique<TextDiagnosticPrinter>(errs(), diag_opts.get());

  // Create custom diagnostics engine.
  auto diag_eng = std::make_unique<DiagnosticsEngine>(nullptr, diag_opts,
                                                      diag_print.get(), false);

  // Create compiler instance.
  CompilerInstance cc;

  // Setup compiler invocation.
  if (!CompilerInvocation::CreateFromArgs(
          cc.getInvocation(), ArrayRef<const char *>({file_name}), *diag_eng)) {
    std::puts("Failed to create CompilerInvocation!");
    return nullptr;
  }

  // Setup diagnostics.
  cc.createDiagnostics(diag_print.get(), false);

  // Create in-memory readonly buffer with pointing to our C code.
  std::unique_ptr<MemoryBuffer> code_buffer =
      MemoryBuffer::getMemBuffer(code_input);

  // Configure remapping from pseudo file name to in-memory code buffer.
  cc.getPreprocessorOpts().addRemappedFile(file_name, code_buffer.release());

  // Create action to generate LLVM IR.
  EmitLLVMOnlyAction action;

  // Run action against our compiler instance.
  if (!cc.ExecuteAction(action)) {
    // std::puts("Failed to run EmitLLVMOnlyAction!");
    return nullptr;
  }

  // Take generated LLVM IR module and print to stdout.
  if (auto mod = action.takeModule()) {
    // mod->print(outs(), nullptr);
    auto *irRes = new IRResult();
    raw_string_ostream BufferStream(*(irRes->data));
    mod->print(BufferStream, nullptr);
    *output_len = irRes->data->length();
    return irRes;
  }
  return nullptr;
}
