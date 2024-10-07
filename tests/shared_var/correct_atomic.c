// This is a personal academic project. Dear PVS-Studio, please check it.
// PVS-Studio Static Code Analyzer for C, C++, C#, and Java:
// https://pvs-studio.com

// Consider a function that will gain some data from OS and process them in
// different thread

#include <assert.h>
#include <pthread.h>
#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>

typedef struct {
  atomic_int *shared_array;
  size_t len;
  size_t index;
} Data;

// if modify two atomic and compare them in atomic way then free some data

void *modify(void *arg) {
  Data *data = (Data *)arg;
  for (size_t i = 0; i < data->len; i++) {
    atomic_store(data->shared_array + i, i + data->index % 2);
  }
  return data;
}

int main(int argc, char *argv[]) {
  pthread_t threads[31];

  size_t len = argc > 1 ? atoi(argv[1]) : 10;

  atomic_int *arrays = arrays = malloc(sizeof(atomic_int) * len);

  for (size_t i = 0; i < len; i += 1) {
    arrays[i] = 0;
  }

  for (size_t i = 0; i < sizeof(threads) / sizeof(pthread_t); i += 1) {
    Data *each_data = (Data *)malloc(sizeof(Data));

    assert(each_data != NULL);

    each_data->len = argc > 1 ? atoi(argv[1]) : 10;
    each_data->index = i;
    each_data->shared_array = arrays;

    pthread_create(&threads[i], NULL, modify, (void *)each_data);
  }

  for (size_t i = 0; i < sizeof(threads) / sizeof(pthread_t); i += 1) {
    Data *returned = NULL;

    pthread_join(threads[i], (void *)&returned);

    if (returned != NULL) {
      free(returned);
    }
  }

  long long sum = 0;

  for (size_t i = 0; i < len; i += 1) {
    sum += arrays[i];
  }

  free(arrays);

  printf("%lld", sum);

  return 0;
}
