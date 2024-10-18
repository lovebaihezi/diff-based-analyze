// This is a personal academic project. Dear PVS-Studio, please check it.
// PVS-Studio Static Code Analyzer for C, C++, C#, and Java:
// https://pvs-studio.com

#include <atomic>
#include <iostream>
#include <mutex>
#include <thread>

class SharedData {
private:
  std::atomic<int> var1{0};
  std::atomic<int> var2{0};
  std::mutex mtx;

public:
  void modify() {
    // Acquire the lock before modifying var1 and var2
    std::unique_lock<std::mutex> lock(mtx);
    var1.store(10, std::memory_order_relaxed);
    var2.store(20, std::memory_order_relaxed);
  }

  void compare() {
    int local_var1, local_var2;

    while (true) {
      // Read var1 and var2 without holding the lock
      local_var1 = var1.load(std::memory_order_relaxed);
      local_var2 = var2.load(std::memory_order_relaxed);

      if (local_var1 == local_var2) {
        std::cout << "var1 and var2 are equal: " << local_var1 << std::endl;
      } else {
        std::cout << "var1: " << local_var1 << ", var2: " << local_var2
                  << std::endl;
      }

      std::this_thread::sleep_for(std::chrono::seconds(1));
    }
  }
};

int main() {
  SharedData data;

  // Create the modify thread
  std::thread modify_thread(&SharedData::modify, &data);

  // Create the compare thread
  std::thread compare_thread(&SharedData::compare, &data);

  // Wait for the modify thread to finish
  modify_thread.join();

  // Let the compare thread run indefinitely
  compare_thread.join();

  return 0;
}
