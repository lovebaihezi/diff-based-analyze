#include "uuidv4.hpp"
#include <iomanip>
#include <random>
#include <sstream>

UUID UUID::generate() {
  std::random_device rd;
  std::uniform_int_distribution<uint8_t> dist(0, 255);

  std::array<uint8_t, 16> bytes;

  // Generate random bytes
  for (size_t i = 0; i < 16; ++i) {
    bytes[i] = dist(rd);
  }

  // Set version to 4
  bytes[6] = (bytes[6] & 0x0F) | 0x40;

  // Set variant to RFC4122
  bytes[8] = (bytes[8] & 0x3F) | 0x80;

  return UUID(bytes);
}

UUID::UUID(const std::array<uint8_t, 16> &bytes) : data(bytes) {}

std::string UUID::toString() const {
  std::stringstream ss;
  ss << std::hex << std::setfill('0');

  for (size_t i = 0; i < 16; ++i) {
    if (i == 4 || i == 6 || i == 8 || i == 10) {
      ss << "-";
    }
    ss << std::setw(2) << static_cast<int>(data[i]);
  }

  return ss.str();
}

bool UUID::operator==(const UUID &other) const { return data == other.data; }

bool UUID::operator!=(const UUID &other) const { return !(*this == other); }
