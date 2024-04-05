const std = @import("std");
const find = @import("src/find_file.zig").find;

fn addLibs(b: *std.Build, exe: *std.Build.Step.Compile) void {
    exe.linkLibC();
    const env = std.process.getEnvMap(b.allocator) catch @panic("failed to get env map");

    const llvm_path = env.get("LLVM_PATH") orelse @panic("failed to get LLVM_PATH env from env map");
    const include_path = b.pathJoin(&.{ llvm_path, "include" });
    const library_path = b.pathJoin(&.{ llvm_path, "lib" });
    exe.addIncludePath(.{ .path = include_path });
    exe.addLibraryPath(.{ .path = library_path });
    const clang_a = b.pathJoin(&.{ library_path, "libclang.a" });
    exe.addObjectFile(.{ .path = clang_a });

    var libgit2 = std.fs.cwd().openDir("libgit2", .{ .iterate = true }) catch @panic("failed to open libgit2");
    defer libgit2.close();
    const libgit2_path_or = find(b.allocator, libgit2, "libgit2.a") catch @panic("find libgit2.a in libgit2 dir failed due to other issue");
    const libgit2_path = libgit2_path_or orelse @panic("there is no libgit2.a under libgit2 and is sub dir");
    const libgit2_include_path = "./libgit2/include";
    exe.addIncludePath(.{ .path = libgit2_include_path });
    exe.addObjectFile(.{ .path = libgit2_path });

    var usr_lib = std.fs.openDirAbsolute("/usr/lib", .{ .iterate = true }) catch @panic("failed to open /usr/lib");
    defer usr_lib.close();
    const libssl_path_or = find(b.allocator, usr_lib, "libssl.a") catch @panic("find libssh.a under /usr/lib failed");
    const libssl_path = libssl_path_or orelse @panic("there is no libssh.a exists under /usr/lib");
    exe.addObjectFile(.{ .path = libssl_path });
}

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
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    addLibs(b, exe);

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
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    unit_tests.linkLibC();
    unit_tests.linkSystemLibrary("git2");
    unit_tests.linkSystemLibrary("clang");

    const run_unit_tests = b.addRunArtifact(unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
