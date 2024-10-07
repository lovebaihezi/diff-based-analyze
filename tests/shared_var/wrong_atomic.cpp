// This is a personal academic project. Dear PVS-Studio, please check it.
// PVS-Studio Static Code Analyzer for C, C++, C#, and Java:
// https://pvs-studio.com

#include <atomic>
#include <cstdlib>
#include <iostream>
#include <mutex>
#include <thread>
#include <vector>

class SharedArray {
private:
  std::vector<std::atomic<int>> shared_array;
  std::mutex mutex;

public:
  SharedArray(size_t len) : shared_array(len) {}

  void increment(size_t index, size_t len) {
    std::lock_guard<std::mutex> lock(mutex);
    for (size_t i = 0; i < len; i++) {
      shared_array[i] = i + index % 2;
    }
  }

  long long sum() {
    std::lock_guard<std::mutex> locker(this->mutex);
    long long sum = 0;
    for (const auto &val : shared_array) {
      sum += val;
    }
    return sum;
  }
};

void increment_thread(SharedArray &arr, size_t index, size_t len) {
  arr.increment(index, len);
}

int main(int argc, char *argv[]) {
  size_t len = argc > 1 ? std::atoi(argv[1]) : 10;
  SharedArray arrays(len);

  std::vector<std::thread> threads;
  for (size_t i = 0; i < 31; i++) {
    threads.emplace_back(increment_thread, std::ref(arrays), i, len);
  }

  for (auto &thread : threads) {
    thread.join();
  }

  std::cout << arrays.sum() << std::endl;

  return 0;
}
