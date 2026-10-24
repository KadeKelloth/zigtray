const std = @import("std");
const zigtray = @import("zigtray");

var notify_count: u32 = 0;

fn onHello(t: *zigtray.Tray) void {
    notify_count += 1;
    t.showNotification("zigtray", "Notification from native Zig tray!");
}

fn onExit(t: *zigtray.Tray) void {
    t.stop();
}

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;

    var tray = try zigtray.Tray.init(gpa, .{
        .tooltip = "zigtray example",
        .icon = .default,
    });
    defer tray.deinit();

    var menu: zigtray.Menu = .empty;
    try menu.add(gpa, .{
        .id = 1,
        .text = "Send Notification",
        .action = onHello,
        .icon = .default,
    });
    try menu.addSeparator(gpa);
    try menu.add(gpa, .{
        .id = 2,
        .text = "Exit",
        .action = onExit,
    });

    tray.setMenu(menu);
    tray.showNotification("zigtray", "Application started in system tray.");
    tray.run();
}
