const std = @import("std");
const dir = std.fs.Dir;

pub fn ensureDirExists(path: []const u8) !std.fs.Dir {
    return std.fs.cwd().openDir(path, .{}) catch |err| {
        if (err == dir.OpenError.FileNotFound) {
            try std.fs.cwd().makeDir(path);
            return try std.fs.cwd().openDir(path, .{});
        }
        return err;
    };
}
