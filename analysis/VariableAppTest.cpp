#include "VariableApp.hpp"
#include "App.hpp"
#include "catch2/catch_test_macros.hpp"
#include <cstddef>
#include <string_view>

#define TESTING 1

namespace diff_analysis {
TEST_CASE("Run App on sinle File to generate Inst Variable", "[App, LLVM]") {
  const char *argv[] = {"./diff_analysis",
                        "build/tests/challenges-a/rename-before.ll"};
  constexpr std::size_t argc = sizeof(argv) / sizeof(const char *);
  REQUIRE(argc == 2);

  auto app = App::init(argc, argv);
  auto var_app = VariableApp{};
  auto variables = var_app.run(std::string_view{argv[1]});

  REQUIRE(variables.has_value());
  REQUIRE(variables.value().size() == 3);

  auto variables_value = variables.value();

  REQUIRE(variables_value["argc"].instructions.size() == 2);
  REQUIRE(variables_value["argv"].instructions.size() == 0);
  REQUIRE(variables_value["arg_index"].instructions.size() == 2);

  app->shutdown();
}
} // namespace diff_analysis
