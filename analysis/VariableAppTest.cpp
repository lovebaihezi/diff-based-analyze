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
  auto &&[variables_value, module] = variables.value();
  REQUIRE(variables_value.size() == 3);

  REQUIRE(variables_value["argc"].size() == 2);
  REQUIRE(variables_value["argv"].size() == 0);
  REQUIRE(variables_value["arg_index"].size() == 2);

  app->shutdown();
}

TEST_CASE("Run APP on only name changed IR file", "[App, LLVM][.]") {
  const char *argv[] = {"./diff_analysis"};
  constexpr std::size_t argc = sizeof(argv) / sizeof(const char *);

  auto app = App::init(argc, argv);
  auto var_app = VariableApp{};

  auto previous_ir_path = "build/tests/challenges-a/rename-before.ll";
  auto current_ir_path = "build/tests/challenges-a/rename-after.ll";

  llvm::LLVMContext ctx;
  auto previous_variables = var_app.run(ctx, previous_ir_path);
  auto current_variables = var_app.run(ctx, current_ir_path);

  REQUIRE(previous_variables);

  REQUIRE(current_variables);

  auto &&[previous, prev_m] = previous_variables.value();
  auto &&[current, cur_m] = current_variables.value();

  auto diffs = current - previous;

  REQUIRE(diffs.getNameChanges().size() == 1);
  REQUIRE(diffs.getAdds().size() == 0);
  REQUIRE(diffs.getRemoves().size() == 0);

  app->shutdown();
}

TEST_CASE("APP Test Case: check the bounded inst changes", "[App, LLVM]") {
  const char *argv[] = {"./diff_analysis"};
  constexpr std::size_t argc = sizeof(argv) / sizeof(const char *);

  auto app = App::init(argc, argv);
  auto var_app = VariableApp{};

  auto previous_ir_path = "build/tests/missed_bound_check/checked.ll";
  auto current_ir_path = "build/tests/missed_bound_check/unchecked.ll";

  llvm::LLVMContext ctx;

  auto previous_variables = var_app.run(ctx, previous_ir_path);
  auto current_variables = var_app.run(ctx, current_ir_path);

  REQUIRE(previous_variables);

  REQUIRE(current_variables);

  auto &&[previous, prev_m] = previous_variables.value();
  auto &&[current, cur_m] = current_variables.value();

  auto diffs = current - previous;

  REQUIRE(diffs.getNameChanges().size() == 0);
  REQUIRE(diffs.getAdds().size() == 2);
  REQUIRE(diffs.getRemoves().size() == 0);

  auto rev_diffs = previous - current;

  REQUIRE(rev_diffs.getNameChanges().size() == 0);
  REQUIRE(rev_diffs.getAdds().size() == 0);
  REQUIRE(rev_diffs.getRemoves().size() == 2);

  app->shutdown();
}
} // namespace diff_analysis
