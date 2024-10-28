#include <stdio.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
  for (size_t index = 1; index < argc; index += 1) {
    {
      size_t index = argc;
      printf("%zu", index % 3);
    }
    printf("%zu\n", index);
  }
  return 0;
}
