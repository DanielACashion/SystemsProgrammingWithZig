const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimizations = b.standardOptimizeOption(.{});
    const ladder_mod = b.createModule(.{
        .root_source_file = b.path("src/ladder.zig"),
        .target = target,
        .optimize = optimizations,
    });

    const cli_entry_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimizations,
    });
    const web_main_mod = b.createModule(.{
        .root_source_file = b.path("src/web_main.zig"),
        .target = target,
        .optimize = optimizations,
    });
    cli_entry_mod.addImport("ladder", ladder_mod);
    web_main_mod.addImport("ladder", ladder_mod);

    const cliexe = b.addExecutable(.{
        .root_module = cli_entry_mod,
        .name = "Chapter4WordDict",
    });
    const webexe = b.addExecutable(.{
        .root_module = web_main_mod,
        .name = "tcp_game",
    });

    b.installArtifact(cliexe);
    b.installArtifact(webexe);

    //steps
    const run_step = b.step("run", "runs the main artifact right after");
    const cli_exe_run_step = b.addRunArtifact(cliexe);
    run_step.dependOn(&cli_exe_run_step.step);

    const tcp_run_step = b.step("tcp", "runs the tcp server after build");
    const tcp_exe_run_step = b.addRunArtifact(webexe);
    tcp_run_step.dependOn(&tcp_exe_run_step.step);
}
