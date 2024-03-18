#include <assert.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>

size_t *arrays = NULL;

typedef struct {
  size_t len;
  size_t index;
} Data;

void *increment_thread(void *arg) {
  Data *data = (Data *)arg;
  for (size_t i = 0; i < data->len; i++) {
    arrays[i] = i + data->index % 2;
  }
  return NULL;
}

void *init_data(void *arg) {
  Data *data = (Data *)arg;
  arrays = malloc(sizeof(size_t) * data->len);
  return NULL;
}

int main(int argc, char *argv[]) {
  pthread_t threads[31];

  Data *data = (Data *)malloc(sizeof(Data));

  assert(data != NULL);

  data->len = argc > 1 ? atoi(argv[1]) : 10;
  data->index = 0;

  pthread_create(&threads[0], NULL, init_data, (void *)data);

  for (size_t i = 1; i < sizeof(threads) / sizeof(pthread_t); i += 1) {
    Data *each_data = (Data *)malloc(sizeof(Data));

    assert(each_data != NULL);

    each_data->len = argc > 1 ? atoi(argv[1]) : 10;
    each_data->index = i;

    pthread_create(&threads[i], NULL, increment_thread, (void *)each_data);
  }

  for (size_t i = 0; i < sizeof(threads) / sizeof(pthread_t); i += 1) {
    pthread_join(threads[i], NULL);
  }

  free(data);
  free(arrays);

  long long sum = 0;
  for (size_t i = 0; i < data->len; i += 1) {
    sum += arrays[i];
  }
  printf("%lld", sum);

  return 0;
}
