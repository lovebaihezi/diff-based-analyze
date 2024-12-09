#pragma once
#include <array>
#include <cstdint>
#include <string>

class UUID {
public:
  // Generate a new UUID v4
  static UUID generate();

  // Convert UUID to string representation
  std::string toString() const;

  // Comparison operators
  bool operator==(const UUID &other) const;
  bool operator!=(const UUID &other) const;

private:
  std::array<uint8_t, 16> data;

  // Private constructor used by generate()
  explicit UUID(const std::array<uint8_t, 16> &bytes);
};
