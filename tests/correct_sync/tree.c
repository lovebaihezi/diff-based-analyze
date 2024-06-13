#include "dirent.h"

#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

int root_fn(DIR *dir, size_t level) {
  struct dirent *dirent = NULL;
  while ((dirent = readdir(dir))) {
    switch (dirent->d_type) {
    case DT_DIR:
      if (dirent->d_name[0] == '.') {
        continue;
      }
      for (size_t i = 0; i < level; i++) {
        printf("\t");
      }
      printf("%s\n", dirent->d_name);
      DIR *subdir = opendir(dirent->d_name);
      root_fn(subdir, level + 1);
      break;
    default:
      for (size_t i = 0; i < level + 1; i++) {
        printf("\t");
      }
      printf("%s\n", dirent->d_name);
      break;
    }
  }
  if (dir != NULL) {
    closedir(dir);
  }
  return 0;
}

int main(int argc, char *argv[]) {
  DIR *dir = opendir(argv[1]);
  root_fn(dir, 0);
  return 0;
}
