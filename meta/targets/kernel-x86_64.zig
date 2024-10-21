const std = @import("std");

pub fn getBuildTarget() std.zig.CrossTarget {
    var target: std.zig.CrossTarget = .{ .cpu_arch = .x86_64, .os_tag = .freestanding, .abi = .none };

    const Features = std.Target.x86.Feature;
    target.cpu_features_sub.addFeature(@intFromEnum(Features.mmx));
    target.cpu_features_sub.addFeature(@intFromEnum(Features.sse));
    target.cpu_features_sub.addFeature(@intFromEnum(Features.sse2));
    target.cpu_features_sub.addFeature(@intFromEnum(Features.avx));
    target.cpu_features_sub.addFeature(@intFromEnum(Features.avx2));
    target.cpu_features_add.addFeature(@intFromEnum(Features.soft_float));

    return target;
}

pub fn addBuildOption(b: *std.Build, kernel: *std.Build.Step.Compile) void {
    const arch = b.createModule(.{ .root_source_file = b.path("src/kernel/archs/x86_64/mod.zig") });
    kernel.root_module.addImport("arch", arch);

    kernel.setLinkerScriptPath(b.path("meta/targets/kernel-x86_64.ld"));
}
