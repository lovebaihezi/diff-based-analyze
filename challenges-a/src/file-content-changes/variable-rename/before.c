#include <stdio.h>
#include <unistd.h>

size_t arg_index;

int main(int argc, char* argv[]) {
  for (arg_index = 1;arg_index < argc;arg_index += 1) {
    printf("%zu\n", arg_index);
  }
  return 0;
}
