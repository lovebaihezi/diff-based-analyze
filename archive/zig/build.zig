const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "analysis",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    var env = std.process.getEnvMap(b.allocator) catch @panic("failed to load env map");
    defer env.deinit();
    const libLLVM = env.get("DIFF_LLVM_SHARED_LIB") orelse "LLVM";
    const libclang = env.get("DIFF_clang_SHARED_LIB") orelse "clang";

    exe.linkLibC();
    exe.linkLibCpp();

    exe.linkSystemLibrary2("ssl", .{ .needed = true });
    exe.linkSystemLibrary2("crypto", .{ .preferred_link_mode = .static, .needed = true });
    exe.linkSystemLibrary2("pcre", .{ .preferred_link_mode = .static, .needed = true });
    // exe.addCSourceFile(.{ .file = b.path("./src/llvmir.cpp"), .flags = &.{ "-std=c++2a", "-O3" } });
    exe.addIncludePath(b.path("./libgit2/include"));
    exe.addLibraryPath(b.path("./libgit2/lib"));
    exe.addLibraryPath(b.path("./zlib"));
    exe.addLibraryPath(b.path("./llvm/lib"));
    exe.addIncludePath(b.path("./llvm/include"));

    exe.linkSystemLibrary2("git2", .{ .preferred_link_mode = .static, .needed = true });
    exe.linkSystemLibrary2("z", .{ .preferred_link_mode = .dynamic, .needed = true });
    exe.linkSystemLibrary2(libclang, .{ .preferred_link_mode = .dynamic, .needed = true });
    //exe.linkSystemLibrary2("compile2ir", .{ .preferred_link_mode = .static, .needed = true });
    //exe.linkSystemLibrary2("clangTooling", .{ .preferred_link_mode = .static, .needed = true });
    //exe.linkSystemLibrary2("clangFrontend", .{ .preferred_link_mode = .static, .needed = true });
    //exe.linkSystemLibrary2("clangFrontendTool", .{ .preferred_link_mode = .static, .needed = true });
    //exe.linkSystemLibrary2("clangDriver", .{ .preferred_link_mode = .static, .needed = true });
    //exe.linkSystemLibrary2("clangSerialization", .{ .preferred_link_mode = .static, .needed = true });
    //exe.linkSystemLibrary2("clangCodeGen", .{ .preferred_link_mode = .static, .needed = true });
    //exe.linkSystemLibrary2("clangParse", .{ .preferred_link_mode = .static, .needed = true });
    //exe.linkSystemLibrary2("clangSema", .{ .preferred_link_mode = .static, .needed = true });
    //exe.linkSystemLibrary2("clangStaticAnalyzerFrontend", .{ .preferred_link_mode = .static, .needed = true });
    //exe.linkSystemLibrary2("clangStaticAnalyzerCheckers", .{ .preferred_link_mode = .static, .needed = true });
    //exe.linkSystemLibrary2("clangStaticAnalyzerCore", .{ .preferred_link_mode = .static, .needed = true });
    //exe.linkSystemLibrary2("clangAnalysis", .{ .preferred_link_mode = .static, .needed = true });
    //exe.linkSystemLibrary2("clangARCMigrate", .{ .preferred_link_mode = .static, .needed = true });
    //exe.linkSystemLibrary2("clangRewrite", .{ .preferred_link_mode = .static, .needed = true });
    //exe.linkSystemLibrary2("clangRewriteFrontend", .{ .preferred_link_mode = .static, .needed = true });
    //exe.linkSystemLibrary2("clangEdit", .{ .preferred_link_mode = .static, .needed = true });
    //exe.linkSystemLibrary2("clangAST", .{ .preferred_link_mode = .static, .needed = true });
    //exe.linkSystemLibrary2("clangLex", .{ .preferred_link_mode = .static, .needed = true });
    //exe.linkSystemLibrary2("clangBasic", .{ .preferred_link_mode = .static, .needed = true });
    exe.linkSystemLibrary2(libLLVM, .{ .preferred_link_mode = .dynamic, .needed = true });

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    unit_tests.linkLibC();
    unit_tests.linkLibCpp();

    unit_tests.linkSystemLibrary2("ssl", .{ .needed = true });
    unit_tests.linkSystemLibrary2("crypto", .{ .preferred_link_mode = .static, .needed = true });
    unit_tests.linkSystemLibrary2("pcre", .{ .preferred_link_mode = .static, .needed = true });
    // unit_tests.addCSourceFile(.{ .file = b.path("./src/compile2ir.cpp"), .flags = &.{ "-std=c++17", "-O3" } });
    unit_tests.addIncludePath(b.path("./libgit2/include"));
    unit_tests.addLibraryPath(b.path("./libgit2/lib"));
    unit_tests.addLibraryPath(b.path("./zlib"));
    // unit_tests.addLibraryPath(b.path("./llvm/lib"));
    // unit_tests.addIncludePath(b.path("./llvm/include"));
    // unit_tests.addLibraryPath(b.path("."));

    unit_tests.linkSystemLibrary2("git2", .{ .preferred_link_mode = .static, .needed = true });
    unit_tests.linkSystemLibrary2("z", .{ .preferred_link_mode = .dynamic, .needed = true });
    unit_tests.linkSystemLibrary2(libclang, .{ .preferred_link_mode = .dynamic, .needed = true });
    //unit_tests.linkSystemLibrary2("compile2ir", .{ .preferred_link_mode = .static, .needed = true });
    //unit_tests.linkSystemLibrary2("clangTooling", .{ .preferred_link_mode = .static, .needed = true });
    //unit_tests.linkSystemLibrary2("clangFrontend", .{ .preferred_link_mode = .static, .needed = true });
    //unit_tests.linkSystemLibrary2("clangFrontendTool", .{ .preferred_link_mode = .static, .needed = true });
    //unit_tests.linkSystemLibrary2("clangDriver", .{ .preferred_link_mode = .static, .needed = true });
    //unit_tests.linkSystemLibrary2("clangSerialization", .{ .preferred_link_mode = .static, .needed = true });
    //unit_tests.linkSystemLibrary2("clangCodeGen", .{ .preferred_link_mode = .static, .needed = true });
    //unit_tests.linkSystemLibrary2("clangParse", .{ .preferred_link_mode = .static, .needed = true });
    //unit_tests.linkSystemLibrary2("clangSema", .{ .preferred_link_mode = .static, .needed = true });
    //unit_tests.linkSystemLibrary2("clangStaticAnalyzerFrontend", .{ .preferred_link_mode = .static, .needed = true });
    //unit_tests.linkSystemLibrary2("clangStaticAnalyzerCheckers", .{ .preferred_link_mode = .static, .needed = true });
    //unit_tests.linkSystemLibrary2("clangStaticAnalyzerCore", .{ .preferred_link_mode = .static, .needed = true });
    //unit_tests.linkSystemLibrary2("clangAnalysis", .{ .preferred_link_mode = .static, .needed = true });
    //unit_tests.linkSystemLibrary2("clangARCMigrate", .{ .preferred_link_mode = .static, .needed = true });
    //unit_tests.linkSystemLibrary2("clangRewrite", .{ .preferred_link_mode = .static, .needed = true });
    //unit_tests.linkSystemLibrary2("clangRewriteFrontend", .{ .preferred_link_mode = .static, .needed = true });
    //unit_tests.linkSystemLibrary2("clangEdit", .{ .preferred_link_mode = .static, .needed = true });
    //unit_tests.linkSystemLibrary2("clangAST", .{ .preferred_link_mode = .static, .needed = true });
    //unit_tests.linkSystemLibrary2("clangLex", .{ .preferred_link_mode = .static, .needed = true });
    //unit_tests.linkSystemLibrary2("clangBasic", .{ .preferred_link_mode = .static, .needed = true });
    unit_tests.linkSystemLibrary2(libLLVM, .{ .preferred_link_mode = .dynamic, .needed = true });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
