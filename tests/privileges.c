// This is a personal academic project. Dear PVS-Studio, please check it.
// PVS-Studio Static Code Analyzer for C, C++, C#, and Java:
// https://pvs-studio.com

#include <dirent.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include "thpool.h"
#include "types.h"

void thread_set_mask(void *arg) {
  NotAtomicProtect *data = (NotAtomicProtect *)arg;
  if (data->names == 0x0 || data->len == 0) {
    return;
  }
  // thread safe
  mode_t mask = umask(0);
  for (size_t i = 0; i < data->len; i += 1) {
    char *name = data->names[i];
    if (strcmp(name, "a_special_name")) {
      mkdir("non special", umask(mask));
    }
  }
  free(data);
  return;
}

int main(int argc, char *args[]) {
  threadpool pool = thpool_init(31);
  DIR** dirs = (DIR**)malloc(sizeof(DIR*) * argc);
  for (int i = 1; i < argc; i += 1) {
    NotAtomicProtect *data =
        (NotAtomicProtect *)malloc(sizeof(NotAtomicProtect));
    data->len = 1;
    DIR *dir = opendir(args[i]);
    dirs[i - 1] = dir;
    struct dirent *dir_ent = readdir(dir);
    char **names = (char **)malloc(sizeof(char *) * data->len);
    size_t cap = 1;
    while (dir_ent != NULL) {
      data->len += 1;
      char *name = dir_ent->d_name;
      if (data->len >= cap) {
        char **new_names = (char **)malloc(sizeof(char *) * cap * 2);
        memcpy(names, new_names, cap);
        free(names);
        names = new_names;
      } else {
        names[data->len] = name;
      }
    }
    thpool_add_work(pool, thread_set_mask, data);
  }
  thpool_wait(pool);
  for (int i = 0;i < argc;i += 1) {
    DIR* dir = dirs[i];
    closedir(dir);
  }
  free(dirs);
  thpool_destroy(pool);
  return 0;
}
