const std = @import("std");
const dir = std.fs.Dir;
const json = @import("std").json;
const utils = @import("utils.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const path = "input.json";
    const outputPath = "./output";

    // Opening the file
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    // Reading the file content
    const contents = try file.readToEndAlloc(allocator, 10 * 1024); // 10 KB max - can adjust later
    defer allocator.free(contents);

    // Parsing JSON
    var parsed = try json.parseFromSlice(json.Value, allocator, contents, .{});
    defer parsed.deinit();

    var outputDir = try utils.ensureDirExists(outputPath);
    defer outputDir.close();

    var outputFile = try outputDir.createFile("output.json", .{ .truncate = true });
    defer outputFile.close();

    _ = try json.stringify(parsed.value, .{ .whitespace = .indent_4 }, outputFile.writer());
}
