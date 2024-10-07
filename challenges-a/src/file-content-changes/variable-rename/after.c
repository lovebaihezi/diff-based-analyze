#include <stdio.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
  for (size_t i = 1; i < argc; i += 1) {
    printf("%zu\n", i);
  }
  return 0;
}
