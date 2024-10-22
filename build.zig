const std = @import("std");

const buildError = error{
    InvalidArch,
};

fn libs(b: *std.Build) !std.ArrayList(*std.Build.Module) {
    var liblist = std.ArrayList(*std.Build.Module).init(b.allocator);

    var dir = try std.fs.cwd().openDir("src/libs/", .{ .iterate = true });
    defer dir.close();

    var walker = try dir.walk(b.allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (std.mem.indexOf(u8, entry.path, "mod.zig") != null) {
            const path = try std.fmt.allocPrint(b.allocator, "src/libs/{s}", .{entry.path});
            try liblist.append(b.createModule(.{ .root_source_file = b.path(path) }));
        }
    }

    return liblist;
}

fn getFileName(b: *std.Build, path: []const u8) []const u8 {
    const pathBuf = b.allocator.dupe(u8, path) catch "";
    std.mem.reverse(u8, @constCast(pathBuf));

    for (0..path.len, pathBuf) |i, char| {
        if (char == '/') {
            return path[(path.len - i)..];
        }
    }

    return pathBuf;
}

pub fn build(b: *std.Build) !void {
    const cross_target_spec = b.option(std.Target.Cpu.Arch, "arch", "Target Architecture") orelse std.Target.Cpu.Arch.x86_64;
    const optimize = b.standardOptimizeOption(.{});

    var liblist = try libs(b);
    defer liblist.deinit();

    const arch = switch (cross_target_spec) {
        std.Target.Cpu.Arch.x86_64 => @import("meta/targets/kernel-x86_64.zig"),
        else => return error.InvalidArch,
    };

    const target = arch.getBuildTarget();

    const kernel = b.addExecutable(.{
        .name = "kernel.elf",
        .root_source_file = b.path("src/kernel/core/main.zig"),
        .target = b.resolveTargetQuery(target),
        .optimize = optimize,
        .code_model = .kernel,
    });

    var modules = std.StringHashMap(*std.Build.Module).init(b.allocator);
    defer modules.deinit();

    for (liblist.items) |lib| {
        const libname = getFileName(b, lib.root_source_file.?.dirname().src_path.sub_path);
        try modules.put(libname, lib);
        kernel.root_module.addImport(libname, lib);
    }

    const limine = b.dependency("limine", .{});
    kernel.root_module.addImport("limine", limine.module("limine"));
    try modules.put("limine", limine.module("limine"));

    arch.addBuildOption(b, kernel, modules);

    kernel.want_lto = false;

    b.installArtifact(kernel);
}
