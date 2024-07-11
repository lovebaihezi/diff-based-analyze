#include <stdio.h>
#include <string.h>

// Split stdin to stdout, output each seq in a new line.
// Use improved KMP
// Stdin will be seen as a string, and the splitter will be seen as a pattern.
int main(int argc, char *argv[]) {
    if (argc < 2) {
        return 1;
    }
    char* splitter = argv[1];
    size_t splitter_len = strlen(splitter);
    size_t index = 0;
    // KMP
    while (1) {
        char c = fgetc(stdin);
        if (c == EOF) {
            break;
        }
        if (c == splitter[index]) {
            index += 1;
            if (index == splitter_len) {
                printf("\n");
                index = 0;
            }
        } else {
            // output splitter content and current char
            for (size_t i = 0;i < index;i += 1) {
                printf("%c", splitter[i]);
            }
            printf("%c", c);
            // Reset index
            index = 0;
        }
    }
}
