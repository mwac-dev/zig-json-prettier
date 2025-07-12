const std = @import("std");
const json = @import("std").json;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const path = "input.json";

    // Opening the file
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    // Reading the file content
    const contents = try file.readToEndAlloc(allocator, 10 * 1024); // 10 KB max - can adjust later
    defer allocator.free(contents);

    // Parsing JSON
    var parsed = try json.parseFromSlice(json.Value, allocator, contents, .{});
    defer parsed.deinit();

    // print contents for now
    try json.stringify(parsed.value, .{ .whitespace = .indent_4 }, std.io.getStdOut().writer());
}
