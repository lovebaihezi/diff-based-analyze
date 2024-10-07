#include <stdio.h>
#include <unistd.h>

size_t i;

int main(int argc, char* argv[]) {
  for (i = 1;i < argc;i += 1) {
    printf("%zu\n", i);
  }
  return 0;
}
