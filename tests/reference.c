int global_a;

void f(int* x) {
  *x += 3;
}

int main(void) {
  f(&global_a);
  return 0;
}
