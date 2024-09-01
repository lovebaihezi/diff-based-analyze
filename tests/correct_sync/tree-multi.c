#include "dirent.h"

#include <bits/pthreadtypes.h>
#include <pthread.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

struct Input {
  DIR *dir;
  int ret;
};

void* root_fn_wrap(void* input) ;
int root_fn(DIR *dir) ;

void* root_fn_wrap(void* arg) {
  struct Input* input = (struct Input*)arg;
  input->ret = root_fn(input->dir);
  input->dir = NULL;
  return &input->ret;
}

int root_fn(DIR *dir) {
  struct dirent *dirent = NULL;
  pthread_t threads[512];
  struct Input inputs[512];
  size_t thread_count = 0;
  while ((dirent = readdir(dir))) {
    switch (dirent->d_type) {
    case DT_DIR:
      if (dirent->d_name[0] == '.') {
        continue;
      }
      printf("%s\n", dirent->d_name);
      DIR *subdir = opendir(dirent->d_name);
      if (thread_count >= 512) {
          root_fn(subdir);
      } else {
          int flag = pthread_create(threads + thread_count, NULL, root_fn_wrap, inputs + thread_count);
          if (flag != 0) {
            return 1;
          }
      }
      break;
    default:
      printf("%s\n", dirent->d_name);
      break;
    }
  }
  for (size_t i = 0;i < thread_count;i += 1) {
    pthread_join(threads[i], NULL);
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
