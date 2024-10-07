#include <stdio.h>

int main(int argc, char *argv[]) {
  for (int i = 1; i < argc; i += 1) {
    FILE *file = fopen(argv[i], "r");
    if (file == NULL) {
      return 1;
    }
    char c;
    while ((c = fgetc(file)) != EOF) {
      printf("%c", c);
    }
    fclose(file);
  }
}
