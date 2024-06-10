#ifndef LIBCompile2IR_H
#define LIBCompile2IR_H

#include <cstddef>
#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

struct IRResult;

void decomposeIRResult(IRResult *res);

const char* getIR(IRResult *res);
const IRResult *compileC2IR(const char *code_input, size_t len, size_t *output_len);

#ifdef __cplusplus
} /* extern "C" */
#endif /* __cplusplus */

#endif /* LIBCompile2IR_H */
