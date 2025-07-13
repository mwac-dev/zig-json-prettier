const std = @import("std");
const dir = std.fs.Dir;
const json = @import("std").json;
const utils = @import("utils.zig");
const args = @import("args.zig");

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
    var args_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer args_allocator.deinit();

    const parsed_args = args.parseArgs(args_allocator.allocator()) catch |err| switch (err) {
        args.ParseArgsError.MissingInputPath => {
            std.debug.print("Error: Missing input path.\n", .{});
            return;
        },
        args.ParseArgsError.MissingOutputPath => {
            std.debug.print("Error: Missing output path.\n", .{});
            return;
        },
        args.ParseArgsError.InvalidIndentValue => {
            std.debug.print("Error: Invalid indent value.\n", .{});
            return;
        },
        args.ParseArgsError.MissingIndentValue => {
            std.debug.print("Error: Missing value for --indent option. Use --indent=N where N is 0-8 or 'tab'.\n", .{});
            return;
        },
        args.ParseArgsError.UnknownArgument => {
            std.debug.print("Error: Unknown argument\n", .{});
            return;
        },
        args.ParseArgsError.OutOfMemory => {
            std.debug.print("Error: Out of memory.\n", .{});
            return;
        },
    };

    const parsed_indent = parsed_args.indent_spaces;

    std.debug.print("Parsed args: {any}\n Parsed indent: {any}", .{ parsed_args, parsed_indent });

    _ = try json.stringify(parsed.value, .{ .whitespace = .indent_4 }, outputFile.writer());
}
