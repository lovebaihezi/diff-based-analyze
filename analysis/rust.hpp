#pragma once

#include <memory>

namespace diff_analysis {
template <typename T> using Box = std::unique_ptr<T>;
}
