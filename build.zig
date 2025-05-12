const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const reiter = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    try b.modules.put(b.dupe("reiter"), reiter);

    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/tests.zig"),
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);

    // examples
    inline for (.{
        .{ .name = "arraylist", .src = "examples/arraylist/main.zig" },
    }) |example| {
        const example_step = b.step(
            try std.fmt.allocPrint(
                b.allocator,
                "{s}",
                .{example.name},
            ),
            "build example",
        );

        const example_run_step = b.step(
            try std.fmt.allocPrint(
                b.allocator,
                "run-{s}",
                .{example.name},
            ),
            "run example",
        );

        var exe = b.addExecutable(.{
            .name = example.name,
            .root_source_file = b.path(example.src),
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addImport("reiter", reiter);

        const run_example = b.addRunArtifact(exe);
        example_run_step.dependOn(&run_example.step);

        const example_build_step = b.addInstallArtifact(exe, .{});
        example_step.dependOn(&example_build_step.step);
    }
}
