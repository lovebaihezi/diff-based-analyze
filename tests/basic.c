extern int g_1;
extern int g_2;

int f1(int *arg1, int arg2, int arg3) {
    g_1 += 1;
    int y = *arg1;
    *arg1 += 1;
    return y;
}

int f2(int *arg1, int arg2) {
    if (arg1 != 0x0) {
        int x = *arg1;
        if (arg2) {
            g_2 *= 4;
            x += 2;
        }
        return x;
    } else {
        return 0;
    }
}

void x(int *others) {
    int** ptr = &others;
    **ptr += 2;
    return;
}

void f(int init) {
    int x = init;
    x = 2;
    x += 3;
    int y = 2;
    y = x;
    int z = f2(&y, x);
    f1(&y, z, x);
}

int main(int argc, char *args[]) {
    switch (argc) {
    case 0:
        return 1;
    case 1:
        return 0;
    default:
        f(argc);
    }
    x(&g_1);
    return 0;
}
