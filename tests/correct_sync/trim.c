#include <stdio.h>
// Trim stdin to stdout, removing leading and trailing whitespace.
int main(int argc, char *argv[]) {
  while (1) {
    char c = fgetc(stdin);
    if (c == EOF) {
      break;
    }
    if (c == ' ' || c == '\t' || c == '\n') {
      continue;
    }
    printf("%c", c);
    while (1) {
      c = fgetc(stdin);
      if (c == EOF) {
        break;
      }
      if (c == ' ' || c == '\t' || c == '\n') {
        break;
      }
      printf("%c", c);
    }
    printf("\n");
  }
}
