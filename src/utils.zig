const std = @import("std");
const dir = std.fs.Dir;

pub fn ensureDirExists(path: []const u8) !std.fs.Dir {
    const cwd = std.fs.cwd();

    return cwd.openDir(path, .{}) catch |err| {
        if (err == dir.OpenError.FileNotFound) {
            try cwd.makeDir(path);
            return try cwd.openDir(path, .{});
        }
        return err;
    };
}
