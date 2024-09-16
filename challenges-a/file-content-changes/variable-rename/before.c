#include <stdio.h>
#include <unistd.h>

int main(int argc, char* argv[]) {
  for (size_t index = 1;index < argc;index += 1) {
    printf("%zu\n", index);
  }
  return 0;
}
