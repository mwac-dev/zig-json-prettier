const std = @import("std");
const mem = std.mem;

pub const ParseArgsError = error{
    MissingInputPath,
    MissingOutputPath,
    InvalidIndentValue,
    MissingIndentValue,
    UnknownArgument,
    OutOfMemory,
};

pub const Args = struct {
    indent_spaces: u8 = 4,
    sort_keys: bool = false,
    minify: bool = false,
    help: bool = false,
    version: bool = false,
    input_path: ?[]const u8 = null,
    output_path: ?[]const u8 = null,
};

pub fn parseArgs(allocator: mem.Allocator) ParseArgsError!Args {
    var args = try std.process.argsWithAllocator(allocator);
    _ = args.next(); // skip executable path
    defer args.deinit();

    var parsed = Args{};
    while (args.next()) |arg| {
        std.debug.print("Arg: '{s}'\n", .{arg});

        if (mem.eql(u8, arg, "-h") or mem.eql(u8, arg, "--help")) {
            parsed.help = true;
        } else if (mem.eql(u8, arg, "-v") or mem.eql(u8, arg, "--version")) {
            parsed.version = true;
        } else if (mem.eql(u8, arg, "-i") or mem.eql(u8, arg, "--input")) {
            const val = args.next() orelse return ParseArgsError.MissingInputPath;
            parsed.input_path = val;
        } else if (mem.eql(u8, arg, "-o") or mem.eql(u8, arg, "--output")) {
            const val = args.next() orelse return ParseArgsError.MissingOutputPath;
            parsed.output_path = try allocator.dupe(u8, val);
        } else if (mem.eql(u8, arg, "-m") or mem.eql(u8, arg, "--minify")) {
            parsed.minify = true;
        } else if (mem.eql(u8, arg, "-sk") or mem.eql(u8, arg, "--sort-keys")) {
            parsed.sort_keys = true;
        } else if (mem.startsWith(u8, arg, "--indent=") or mem.startsWith(u8, arg, "-in=")) {
            const val = if (mem.startsWith(u8, arg, "--indent="))
                arg["--indent=".len..]
            else
                arg["-in=".len..];
            if (val.len == 0) return ParseArgsError.MissingIndentValue;

            if (mem.eql(u8, val, "tab")) {
                parsed.indent_spaces = 9; // special-case tab
            } else {
                const indent = std.fmt.parseInt(u8, val, 10) catch return ParseArgsError.InvalidIndentValue;
                if (indent > 8) return ParseArgsError.InvalidIndentValue;
                if (indent == 0) parsed.minify = true;
                parsed.indent_spaces = indent;
            }
        } else {
            return ParseArgsError.UnknownArgument;
        }
    }

    return parsed;
}
