#include <stdio.h>
#include <stdlib.h>

enum Kind {
  A,
  B,
  C
};

struct Param {
  enum Kind kind;
  int value;
};

const char* functionA(struct Param* input, int flag) {
  if (input && flag) {
    char* buf = (char*)malloc(sizeof(char) + sizeof(int) + 1);
    switch (input->kind) {
      case A:
        sprintf(buf, "A%d", input->value);
      case B:
        sprintf(buf, "B%d", input->value);
      case C:
        sprintf(buf, "C%d", input->value);
    }
    return buf;
  } else if (input) {
    switch (input->kind) {
      case A:
        return "A";
      case B:
        return "B";
      case C:
        return "C";
    }
  } else {
    return "null";
  }
}
