#include "dirent.h"

#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

int root_fn(DIR *dir) {
  struct dirent *dirent = NULL;
  while ((dirent = readdir(dir))) {
    switch (dirent->d_type) {
    case DT_DIR:
      if (dirent->d_name[0] == '.') {
        continue;
      }
      printf("%s\n", dirent->d_name);
      DIR *subdir = opendir(dirent->d_name);
      root_fn(subdir);
      break;
    default:
      printf("%s\n", dirent->d_name);
      break;
    }
  }
  if (dir != NULL) {
    closedir(dir);
  }
  return 0;
}

int main(int argc, char* args[]) {
  if (argc < 2) {
    return 1;
  }
  return root_fn(opendir(args[1]));
}
