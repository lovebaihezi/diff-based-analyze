#include "VariableApp.hpp"
#include "App.hpp"
#include "catch2/catch_test_macros.hpp"
#include <cstddef>
#include <string_view>

#define TESTING 1

namespace diff_analysis {
TEST_CASE("Run App on single File to generate Inst Variable", "[App, LLVM]") {
  const char *argv[] = {"./diff_analysis",
                        "build/tests/challenges-a/rename-before.ll"};
  constexpr std::size_t argc = sizeof(argv) / sizeof(const char *);
  REQUIRE(argc == 2);

  auto app = App::init(argc, argv);
  auto var_app = VariableApp{};
  llvm::LLVMContext ctx;
  auto variables = var_app.run(ctx, std::string_view{argv[1]});

  REQUIRE(variables.has_value());
  auto&& [variables_value, module] = variables.value();
  REQUIRE(variables_value.size() == 3);

  REQUIRE(variables_value["argc"].size() == 2);
  REQUIRE(variables_value["argv"].size() == 0);
  REQUIRE(variables_value["arg_index"].size() == 2);

  app->shutdown();
}

TEST_CASE("Run APP on only name changed IR file", "[App, LLVM]") {
  const char *argv[] = {"./diff_analysis"};
  constexpr std::size_t argc = sizeof(argv) / sizeof(const char *);

  auto app = App::init(argc, argv);
  auto var_app = VariableApp{};

  auto previous_ir_path = "build/tests/challenges-a/rename-before.ll";
  auto current_ir_path = "build/tests/challenges-a/rename-after.ll";

  llvm::LLVMContext ctx;
  auto diffs = var_app.diff(ctx, std::string_view{previous_ir_path},
                            std::string_view{current_ir_path});

  REQUIRE(diffs.has_value());

  auto diffs_value = diffs.value();
  REQUIRE(diffs_value.getNameChanges().size() == 1);
  REQUIRE(diffs_value.getAdded().size() == 0);
  REQUIRE(diffs_value.getRemoved().size() == 0);

  app->shutdown();
}
} // namespace diff_analysis
