// This is a personal academic project. Dear PVS-Studio, please check it.
// PVS-Studio Static Code Analyzer for C, C++, C#, and Java:
// https://pvs-studio.com

#include <stdio.h>
#include <stdatomic.h>
#include <pthread.h>
#include <unistd.h>

atomic_int var1 = 0;
atomic_int var2 = 0;

void* thread_modify(void* arg) {
    // Modify var1 and var2 atomically
    atomic_store(&var1, 10);
    atomic_store(&var2, 20);
    return NULL;
}

void* thread_compare(void* arg) {
    int local_var1, local_var2;
    
    while (1) {
        // Load var1 and var2 atomically into local variables
        local_var1 = atomic_load(&var1);
        local_var2 = atomic_load(&var2);
        
        if (local_var1 == local_var2) {
            printf("var1 and var2 are equal: %d\n", local_var1);
        } else {
            printf("var1: %d, var2: %d\n", local_var1, local_var2);
        }
    }
    
    return NULL;
}

int main(void) {
    pthread_t modify_thread, compare_thread;
    
    // Create the modify thread
    pthread_create(&modify_thread, NULL, thread_modify, NULL);
    
    // Create the compare thread
    pthread_create(&compare_thread, NULL, thread_compare, NULL);
    
    // Wait for the modify thread to finish
    pthread_join(modify_thread, NULL);
    
    // Let the compare thread run indefinitely
    pthread_join(compare_thread, NULL);
    
    return 0;
}
