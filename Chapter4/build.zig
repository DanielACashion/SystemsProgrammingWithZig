const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimizations = b.standardOptimizeOption(.{});
    const main_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimizations,
    });
    const exe = b.addExecutable(.{
        .root_module = main_mod,
        .name = "Chapter4WordDict",
    });
    b.installArtifact(exe);

    //steps
    const run_step = b.step("run", "runs the main artifact right after");
    const exe_run_step = b.addRunArtifact(exe);
    run_step.dependOn(&exe_run_step.step);
}
