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

pub fn sortJsonValuesRecursive(allocator: std.mem.Allocator, value: *std.json.Value) !void {
    switch (value.*) {
        .object => |*obj| {
            const Entry = struct {
                key: []const u8,
                value: *std.json.Value,
            };

            var entries = std.ArrayList(Entry).init(allocator);
            defer entries.deinit();

            var it = obj.iterator();
            while (it.next()) |entry| {
                try entries.append(.{
                    .key = entry.key_ptr.*,
                    .value = entry.value_ptr,
                });
                try sortJsonValuesRecursive(allocator, entry.value_ptr);
            }

            std.mem.sort(Entry, entries.items, {}, struct {
                pub fn lessThan(_: void, a: Entry, b: Entry) bool {
                    return std.mem.lessThan(u8, a.key, b.key);
                }
            }.lessThan);

            obj.clearRetainingCapacity();
            for (entries.items) |entry| {
                try obj.put(entry.key, entry.value.*);
            }
        },
        .array => |*arr| {
            for (arr.items) |*item| {
                try sortJsonValuesRecursive(allocator, item);
            }
        },
        else => {},
    }
}
