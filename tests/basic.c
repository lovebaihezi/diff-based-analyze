int f1(int* arg1, int arg2, int arg3) {
    int y = *arg1;
    y += 1;
    return y;
}

int f2(int *arg1) {
    if (arg1 != 0x0) {
        int x = *arg1;
        x += 2;
        return x;
    } else {
        return 0;
    }
}

void f(void) {
    int x = 1;
    x = 2;
    x += 3;
    int y = 2;
    y = x;
    f1(&y, f2(&x), 2);
}

int main(void) {
    return 0;
}
