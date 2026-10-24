const std = @import("std");
pub const win32 = @import("win32.zig");
const tray = @import("tray.zig");

pub const Tray = tray.Tray;
pub const Menu = tray.Menu;
pub const MenuItem = tray.MenuItem;
pub const Icon = tray.Icon;
pub const Options = tray.Options;
pub const Error = tray.Error;
pub const utf8ToWideZ = tray.utf8ToWideZ;

test "utf8ToWideZ ascii and unicode" {
    var buf: [32]win32.WCHAR = undefined;
    utf8ToWideZ(&buf, "Hello");
    try std.testing.expectEqual(@as(win32.WCHAR, 'H'), buf[0]);
    try std.testing.expectEqual(@as(win32.WCHAR, 'e'), buf[1]);
    try std.testing.expectEqual(@as(win32.WCHAR, 'l'), buf[2]);
    try std.testing.expectEqual(@as(win32.WCHAR, 'l'), buf[3]);
    try std.testing.expectEqual(@as(win32.WCHAR, 'o'), buf[4]);
    try std.testing.expectEqual(@as(win32.WCHAR, 0), buf[5]);

    utf8ToWideZ(&buf, "Трей");
    try std.testing.expectEqual(@as(win32.WCHAR, 0x0422), buf[0]);
    try std.testing.expectEqual(@as(win32.WCHAR, 0x0440), buf[1]);
    try std.testing.expectEqual(@as(win32.WCHAR, 0x0435), buf[2]);
    try std.testing.expectEqual(@as(win32.WCHAR, 0x0439), buf[3]);
    try std.testing.expectEqual(@as(win32.WCHAR, 0), buf[4]);
}

test "menu item construction" {
    const allocator = std.testing.allocator;
    var menu: Menu = .empty;
    defer menu.deinit(allocator);

    try menu.add(allocator, .{
        .id = 1,
        .text = "Item 1",
    });
    try menu.addSeparator(allocator);
    try menu.add(allocator, .{
        .id = 2,
        .text = "Item 2",
    });

    try std.testing.expectEqual(@as(usize, 3), menu.items.items.len);
    try std.testing.expectEqual(@as(u16, 1), menu.items.items[0].id);
    try std.testing.expect(menu.items.items[1].separator);
    try std.testing.expectEqual(@as(u16, 2), menu.items.items[2].id);
}
