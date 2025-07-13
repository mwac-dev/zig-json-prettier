const std = @import("std");
const dir = std.fs.Dir;
const json = @import("std").json;
const utils = @import("utils.zig");
const args = @import("args.zig");
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
            std.debug.print("Error: Invalid indent value.\n Use --indent=N where N is 0-8 or 'tab'", .{});
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

    var json_options: json.StringifyOptions = .{ .whitespace = switch (parsed_indent) {
        0 => .minified,
        1 => .indent_1,
        2 => .indent_2,
        3 => .indent_3,
        4 => .indent_4,
        8 => .indent_8,
        9 => .indent_tab,
        else => .indent_4,
    } };

    if (parsed_args.minify) {
        json_options.whitespace = .minified;
    }

    // if (parsed_args.sort_keys) {
    //     try parsed.value.sortObjectKeys();
    // }

    var outputPath: []const u8 = "./zjp_output";
    if (parsed_args.output_path) |out_path| {
        outputPath = out_path;
    }
    var outputDir = try utils.ensureDirExists(outputPath);
    defer outputDir.close();

    var outputFile = try outputDir.createFile("output.json", .{ .truncate = true });
    defer outputFile.close();

    _ = try json.stringify(parsed.value, json_options, outputFile.writer());
}
