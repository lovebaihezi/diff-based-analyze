#include <assert.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>

long long shared_variable = 0;

void *increment_thread(void *arg) {
  int *data = (int *)arg;
  for (int i = 0; i < *data; i++) {
    if (shared_variable % 2 == 0) {
      shared_variable += 2;
    } else {
      shared_variable = shared_variable - 1;
    }
  }
  return NULL;
}

int main(int argc, char *argv[]) {
  pthread_t threads[31];

  int *data = (int *)malloc(sizeof(int));

  assert(data != NULL);

  *data = argc > 1 ? atoi(argv[1]) : 10;

  for (int i = 0; i < sizeof(threads) / sizeof(pthread_t); i += 1) {
    pthread_create(&threads[i], NULL, increment_thread, (void *)data);
  }

  for (int i = 0; i < sizeof(threads) / sizeof(pthread_t); i += 1) {
    pthread_join(threads[i], NULL);
  }

  free(data);

  printf("%lld\n", shared_variable);

  return 0;
}
