const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimizations = b.standardOptimizeOption(.{});
    const main_mod = b.createModule(.{
        .target = target,
        .optimize = optimizations,
        .root_source_file = b.path("src/main.zig"),
    });
    const exe = b.addExecutable(.{
        .name = "chapter_5",
        .root_module = main_mod,
    });
    b.installArtifact(exe);

    const run_step = b.step("run", "runs current exe");
    const exe_run_step = b.addRunArtifact(exe);
    run_step.dependOn(&exe_run_step.step);
}
