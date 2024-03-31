#include <sched.h>
#include <stdatomic.h>

typedef struct Data {
  pid_t pid;
  const char* slice;
  size_t slice_len;
} Data;

typedef struct PointToAnother {
  struct PointToAnother* others;
  size_t len;
  struct Data* data;
} PointToAnother;

typedef struct InnerLikedList {
  struct InnerLikedList* next;
} ILL;

typedef struct NotAtomicProtect {
  atomic_int len;
  char** names;
} NotAtomicProtect;

